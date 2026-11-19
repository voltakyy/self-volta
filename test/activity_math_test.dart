// Matematika rekam aktivitas GPS: jarak, filter titik, auto-pause, split,
// elevasi, kalori, encoded polyline, penyederhanaan rute, replay checkpoint.

import 'package:flutter_test/flutter_test.dart';
import 'package:self_volta/services/activity_math.dart';

/// 1 derajat lintang dalam meter (R = 6371008.8 m).
const mPerDegLat = 111195.08;

/// Titik lurus ke utara: [speed] m/s, satu titik tiap [everySec] detik.
List<GeoFix> straight({
  required int n,
  double speed = 3,
  int everySec = 2,
  double lat0 = -7.78,
  double lng0 = 110.37,
  int t0 = 1000000,
  double acc = 5,
  double? alt,
}) => [
  for (var i = 0; i < n; i++)
    GeoFix(
      lat: lat0 + (i * speed * everySec) / mPerDegLat,
      lng: lng0,
      t: t0 + i * everySec * 1000,
      acc: acc,
      alt: alt,
    ),
];

void main() {
  group('ActivityMath', () {
    test('haversine: 1 derajat lintang ≈ 111,195 km', () {
      final d = ActivityMath.distance(0, 0, 1, 0);
      expect(d, closeTo(111195, 5));
    });

    test('encoded polyline cocok contoh resmi Google & bolak-balik', () {
      const pts = [
        LatLngLite(38.5, -120.2),
        LatLngLite(40.7, -120.95),
        LatLngLite(43.252, -126.453),
      ];
      final enc = ActivityMath.encode(pts);
      expect(enc, '_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(ActivityMath.decode(enc), pts);
    });

    test('polyline terpotong melempar FormatException, bukan crash lain', () {
      expect(() => ActivityMath.decode('_p~iF~ps|U_'), throwsFormatException);
    });

    test('simplify: garis lurus jadi 2 titik, ujung tetap', () {
      final pts = [
        for (var i = 0; i < 50; i++) LatLngLite(-7.78 + i * 1e-4, 110.37),
      ];
      final s = ActivityMath.simplify(pts, 3);
      expect(s, [pts.first, pts.last]);
    });

    test('simplifyToBudget menekan rute zig-zag ke ≤ 600 titik', () {
      final pts = [
        for (var i = 0; i < 3000; i++)
          LatLngLite(-7.78 + i * 1e-5, 110.37 + (i.isEven ? 0 : 2e-4)),
      ];
      final out = ActivityMath.simplifyToBudget([pts]);
      final total = out.fold(0, (s, x) => s + x.length);
      expect(total, lessThanOrEqualTo(600));
      expect(out.single.first, pts.first);
      expect(out.single.last, pts.last);
    });

    test('format pace, kecepatan, km, jam', () {
      expect(ActivityMath.pace(1000, 300), '5:00');
      expect(ActivityMath.pace(5000, 1625), '5:25');
      expect(ActivityMath.pace(10, 300), '—');
      expect(ActivityMath.speed(18000, 3600), '18,0');
      expect(ActivityMath.km(5023), '5,02');
      expect(ActivityMath.clock(65), '01:05');
      expect(ActivityMath.clock(3725), '1:02:05');
    });

    test('kalori: lari ≈ berat x km, jalan setengahnya, sepeda pakai MET', () {
      expect(
        ActivityMath.kcal(
          type: ActivityType.run,
          meters: 5000,
          movingSec: 1800,
          weightKg: 60,
        ),
        300,
      );
      expect(
        ActivityMath.kcal(
          type: ActivityType.walk,
          meters: 4000,
          movingSec: 2880,
          weightKg: 60,
        ),
        120,
      );
      // 20 km/jam selama 1 jam -> MET 8 x 60 kg = 480.
      expect(
        ActivityMath.kcal(
          type: ActivityType.ride,
          meters: 20000,
          movingSec: 3600,
          weightKg: 60,
        ),
        480,
      );
      expect(
        ActivityMath.kcal(
          type: ActivityType.run,
          meters: 0,
          movingSec: 0,
          weightKg: 60,
        ),
        0,
      );
    });
  });

  group('TrackRecorder', () {
    test('lari 3 m/s: jarak, waktu bergerak, split 1 km', () {
      final r = TrackRecorder(ActivityType.run);
      // 201 titik x 6 m = 1200 m dalam 400 detik.
      for (final f in straight(n: 201)) {
        expect(r.addFix(f), FixVerdict.accepted);
      }
      expect(r.distanceM, closeTo(1200, 1));
      expect(r.movingSec, 400);
      expect(r.splits.length, 1);
      expect(r.splits.single, closeTo(333, 1)); // 1000 m / 3 m/s
    });

    test('titik dengan akurasi buruk dibuang', () {
      final r = TrackRecorder(ActivityType.run);
      final pts = straight(n: 10);
      r.addFix(pts[0]);
      final bad = GeoFix(lat: pts[1].lat, lng: pts[1].lng, t: pts[1].t, acc: 60);
      expect(r.addFix(bad), FixVerdict.inaccurate);
      expect(r.distanceM, 0);
    });

    test('lompatan GPS (teleport 500 m dalam 2 dtk) dibuang', () {
      final r = TrackRecorder(ActivityType.run);
      final pts = straight(n: 3);
      r.addFix(pts[0]);
      r.addFix(pts[1]);
      final jump = GeoFix(
        lat: pts[1].lat + 500 / mPerDegLat,
        lng: pts[1].lng,
        t: pts[1].t + 2000,
      );
      expect(r.addFix(jump), FixVerdict.jump);
      expect(r.distanceM, closeTo(6, 0.1));
    });

    test('diam di tempat (jitter < 3 m) tidak menambah jarak/waktu', () {
      final r = TrackRecorder(ActivityType.run);
      const base = GeoFix(lat: -7.78, lng: 110.37, t: 0);
      r.addFix(base);
      for (var i = 1; i <= 30; i++) {
        final v = r.addFix(
          GeoFix(
            lat: -7.78 + (i.isEven ? 1 : -1) * 1 / mPerDegLat,
            lng: 110.37,
            t: i * 2000,
          ),
        );
        expect(v, FixVerdict.stationary);
      }
      expect(r.distanceM, 0);
      expect(r.movingSec, 0);
    });

    test('auto-pause: jalan sangat pelan tidak dihitung waktu bergerak', () {
      final r = TrackRecorder(ActivityType.run);
      // 0,5 m/s (< 0,8 m/s ambang lari), titik tiap 10 dtk = 5 m.
      for (final f in straight(n: 20, speed: 0.5, everySec: 10)) {
        r.addFix(f);
      }
      expect(r.distanceM, closeTo(95, 1));
      expect(r.movingSec, 0);
    });

    test('jeda: perpindahan selama jeda tidak dihitung (tanpa garis lurus)', () {
      final r = TrackRecorder(ActivityType.run);
      final a = straight(n: 11); // 60 m
      for (final f in a) {
        r.addFix(f);
      }
      r.pause();
      expect(r.addFix(a.last), FixVerdict.paused);
      r.resume();
      // Lanjut 500 m lebih jauh, 10 menit kemudian.
      final b = straight(
        n: 11,
        lat0: a.last.lat + 500 / mPerDegLat,
        t0: a.last.t + 600000,
      );
      for (final f in b) {
        r.addFix(f);
      }
      expect(r.distanceM, closeTo(120, 1));
      expect(r.segments.length, 2);
      expect(r.route.length, 2);
    });

    test('elevasi: derau ±2 m diabaikan, tanjakan 12 m terhitung', () {
      final r = TrackRecorder(ActivityType.run);
      final pts = straight(n: 40);
      for (var i = 0; i < pts.length; i++) {
        final noise = i.isEven ? 2.0 : -2.0;
        final climb = i >= 20 ? 12.0 : 0.0;
        r.addFix(
          GeoFix(
            lat: pts[i].lat,
            lng: pts[i].lng,
            t: pts[i].t,
            alt: 100 + noise + climb,
          ),
        );
      }
      expect(r.elevGainM, inInclusiveRange(10, 16));
    });

    test('replay checkpoint menghasilkan angka yang sama persis', () {
      final r = TrackRecorder(ActivityType.ride);
      final a = straight(n: 60, speed: 6);
      for (final f in a.take(30)) {
        r.addFix(f);
      }
      r.pause();
      r.resume();
      for (final f in a.skip(30)) {
        r.addFix(f);
      }
      final again = TrackRecorder.replay(
        ActivityType.ride,
        [for (final f in r.raw) GeoFix.fromJson(f.toJson())!],
        r.marks,
      );
      expect(again.distanceM, closeTo(r.distanceM, 0.5));
      expect(again.movingSec, r.movingSec);
      expect(again.segments.length, r.segments.length);
    });
  });
}
