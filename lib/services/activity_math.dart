// Matematika rekam aktivitas GPS (lari, jalan kaki, sepeda).
//
// Semua di file ini Dart murni: tidak menyentuh plugin, jaringan, atau
// waktu sistem. Titik GPS masuk lewat [TrackRecorder.addFix] lengkap dengan
// stempel waktunya sendiri, jadi hasil hitungan bisa diuji persis di tes
// unit dan bisa diputar ulang dari checkpoint bila app sempat mati.
//
// Prinsip "tanpa data karangan" sama dengan WeatherService: angka yang
// memang hanya perkiraan (kalori, elevasi) diberi label perkiraan di UI,
// dan langkah kaki TIDAK ditampilkan karena tidak ada sensornya.

import 'dart:math' as math;

/// Jenis aktivitas. Nama enum dipakai sebagai kunci JSON, jangan diubah.
enum ActivityType {
  run,
  walk,
  ride;

  static ActivityType parse(String? s) => switch (s) {
    'walk' => ActivityType.walk,
    'ride' => ActivityType.ride,
    _ => ActivityType.run,
  };

  String get label => switch (this) {
    ActivityType.run => 'Lari',
    ActivityType.walk => 'Jalan Kaki',
    ActivityType.ride => 'Sepeda',
  };

  String get shortLabel => switch (this) {
    ActivityType.run => 'Lari',
    ActivityType.walk => 'Jalan',
    ActivityType.ride => 'Sepeda',
  };

  /// Sepeda dibaca sebagai kecepatan (km/jam); lari & jalan sebagai pace.
  bool get usesSpeed => this == ActivityType.ride;

  /// Kecepatan maksimum yang masih masuk akal (m/s). Titik yang menyiratkan
  /// lompatan lebih cepat dari ini dianggap GPS meloncat dan dibuang.
  double get maxSpeed => switch (this) {
    ActivityType.run => 8.0, // 28,8 km/jam: di atas rekor sprint dunia rata-rata
    ActivityType.walk => 4.0, // 14,4 km/jam
    ActivityType.ride => 25.0, // 90 km/jam
  };

  /// Di bawah kecepatan ini dianggap berhenti (auto-pause): waktunya tidak
  /// masuk "waktu bergerak".
  double get minMovingSpeed => switch (this) {
    ActivityType.run => 0.8,
    ActivityType.walk => 0.4,
    ActivityType.ride => 1.2,
  };

  /// Jarak minimum (meter) agar aktivitas layak diberi XP. Mencegah XP dari
  /// rekaman 10 detik di dalam kamar.
  int get xpMinMeters => switch (this) {
    ActivityType.run => 1000,
    ActivityType.walk => 1500,
    ActivityType.ride => 3000,
  };

  int get xpReward => switch (this) {
    ActivityType.run => 30,
    ActivityType.walk => 20,
    ActivityType.ride => 25,
  };
}

/// Satu titik GPS. [t] = milidetik sejak epoch, [acc] = akurasi horizontal
/// (meter, makin kecil makin baik), [alt] = ketinggian (meter) atau null.
class GeoFix {
  final double lat;
  final double lng;
  final double? alt;
  final double acc;
  final int t;

  const GeoFix({
    required this.lat,
    required this.lng,
    required this.t,
    this.alt,
    this.acc = 5,
  });

  List<num> toJson() => [
    double.parse(lat.toStringAsFixed(6)),
    double.parse(lng.toStringAsFixed(6)),
    t,
    double.parse(acc.toStringAsFixed(1)),
    if (alt != null) double.parse(alt!.toStringAsFixed(1)),
  ];

  static GeoFix? fromJson(dynamic v) {
    if (v is! List || v.length < 4) return null;
    final lat = (v[0] as num?)?.toDouble();
    final lng = (v[1] as num?)?.toDouble();
    final t = (v[2] as num?)?.toInt();
    final acc = (v[3] as num?)?.toDouble();
    if (lat == null || lng == null || t == null || acc == null) return null;
    return GeoFix(
      lat: lat,
      lng: lng,
      t: t,
      acc: acc,
      alt: v.length > 4 ? (v[4] as num?)?.toDouble() : null,
    );
  }
}

/// Titik rute ringan untuk digambar (tanpa waktu/akurasi).
class LatLngLite {
  final double lat;
  final double lng;
  const LatLngLite(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      other is LatLngLite && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

class ActivityMath {
  ActivityMath._();

  static const _earthR = 6371008.8; // meter (radius rata-rata IUGG)

  /// Jarak haversine dua koordinat, dalam meter.
  static double distance(double lat1, double lng1, double lat2, double lng2) {
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lng2 - lng1) * math.pi / 180;
    final a =
        math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    return 2 * _earthR * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Perkiraan kalori. Lari & jalan memakai biaya energi per km (berat x km),
  /// sepeda memakai MET menurut kecepatan rata-rata x berat x jam bergerak.
  /// Sumber koefisien: Compendium of Physical Activities (Ainsworth dkk.).
  static int kcal({
    required ActivityType type,
    required double meters,
    required int movingSec,
    required double weightKg,
  }) {
    if (meters <= 0 || movingSec <= 0 || weightKg <= 0) return 0;
    final km = meters / 1000;
    switch (type) {
      case ActivityType.run:
        return (1.0 * weightKg * km).round();
      case ActivityType.walk:
        return (0.5 * weightKg * km).round();
      case ActivityType.ride:
        final kmh = km / (movingSec / 3600);
        final met = kmh < 16
            ? 4.0
            : kmh < 19
            ? 6.8
            : kmh < 22
            ? 8.0
            : kmh < 25
            ? 10.0
            : 12.0;
        return (met * weightKg * movingSec / 3600).round();
    }
  }

  /// Pace "m:ss" per km. "—" bila belum ada jarak berarti.
  static String pace(double meters, int sec) {
    if (meters < 50 || sec <= 0) return '—';
    final perKm = sec / (meters / 1000);
    if (perKm > 99 * 60) return '—';
    final s = perKm.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Kecepatan km/jam dengan satu desimal koma ("18,4").
  static String speed(double meters, int sec) {
    if (meters < 50 || sec <= 0) return '—';
    final kmh = (meters / 1000) / (sec / 3600);
    return kmh.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Jarak km dua desimal koma ("5,02").
  static String km(double meters) =>
      (meters / 1000).toStringAsFixed(2).replaceAll('.', ',');

  /// Durasi "h:mm:ss" atau "mm:ss".
  static String clock(int sec) {
    final s = sec < 0 ? 0 : sec;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final r = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final rr = r.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$rr' : '$mm:$rr';
  }

  // ---------------------------------------------------------------------
  // Encoded polyline (algoritma Google). Rute 1 jam ≈ 4–6 KB, cukup kecil
  // untuk ikut di blob `sv_v1` dan file cadangan.
  // ---------------------------------------------------------------------

  static String encode(List<LatLngLite> pts) {
    final out = StringBuffer();
    var pLat = 0, pLng = 0;
    for (final p in pts) {
      final lat = (p.lat * 1e5).round();
      final lng = (p.lng * 1e5).round();
      _enc(lat - pLat, out);
      _enc(lng - pLng, out);
      pLat = lat;
      pLng = lng;
    }
    return out.toString();
  }

  static void _enc(int v, StringBuffer out) {
    var x = v < 0 ? ~(v << 1) : (v << 1);
    while (x >= 0x20) {
      out.writeCharCode((0x20 | (x & 0x1f)) + 63);
      x >>= 5;
    }
    out.writeCharCode(x + 63);
  }

  static List<LatLngLite> decode(String s) {
    final pts = <LatLngLite>[];
    var i = 0, lat = 0, lng = 0;
    int next() {
      var shift = 0, result = 0, b = 0;
      do {
        if (i >= s.length) throw const FormatException('polyline terpotong');
        b = s.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    }

    while (i < s.length) {
      lat += next();
      lng += next();
      pts.add(LatLngLite(lat / 1e5, lng / 1e5));
    }
    return pts;
  }

  // ---------------------------------------------------------------------
  // Penyederhanaan rute (Douglas–Peucker) agar penyimpanan tetap ringan.
  // ---------------------------------------------------------------------

  /// Sederhanakan [pts] dengan toleransi [tolM] meter.
  static List<LatLngLite> simplify(List<LatLngLite> pts, double tolM) {
    if (pts.length < 3) return List.of(pts);
    final lat0 = pts.first.lat * math.pi / 180;
    final kx = _earthR * math.cos(lat0) * math.pi / 180;
    const ky = _earthR * math.pi / 180;
    final xs = [for (final p in pts) p.lng * kx];
    final ys = [for (final p in pts) p.lat * ky];
    final keep = List<bool>.filled(pts.length, false);
    keep[0] = true;
    keep[pts.length - 1] = true;
    final stack = <(int, int)>[(0, pts.length - 1)];
    while (stack.isNotEmpty) {
      final (a, b) = stack.removeLast();
      var maxD = -1.0;
      var idx = -1;
      for (var i = a + 1; i < b; i++) {
        final d = _segDist(xs[i], ys[i], xs[a], ys[a], xs[b], ys[b]);
        if (d > maxD) {
          maxD = d;
          idx = i;
        }
      }
      if (idx != -1 && maxD > tolM) {
        keep[idx] = true;
        stack
          ..add((a, idx))
          ..add((idx, b));
      }
    }
    return [
      for (var i = 0; i < pts.length; i++)
        if (keep[i]) pts[i],
    ];
  }

  /// Sederhanakan beberapa segmen sekaligus sampai total titik ≤ [maxPoints].
  static List<List<LatLngLite>> simplifyToBudget(
    List<List<LatLngLite>> segs, {
    int maxPoints = 600,
  }) {
    var tol = 3.0;
    var out = [for (final s in segs) simplify(s, tol)];
    int total() => out.fold(0, (a, s) => a + s.length);
    while (total() > maxPoints && tol < 500) {
      tol *= 1.6;
      out = [for (final s in segs) simplify(s, tol)];
    }
    return out;
  }

  static double _segDist(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
    final t = (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }
}

/// Alasan sebuah titik GPS ditolak. Dipakai UI untuk status sinyal dan
/// oleh tes untuk memastikan filter bekerja.
enum FixVerdict { accepted, stationary, inaccurate, jump, paused, stale }

/// Mesin hitung rekaman. Tidak tahu apa-apa soal plugin: cukup diberi titik
/// GPS berurutan lewat [addFix], plus [pause]/[resume] dari tombol user.
///
/// Aturan filter:
/// * akurasi > [maxAccuracyM] → dibuang (sinyal lemah, mis. di dalam gedung)
/// * titik pertama setelah mulai/lanjut hanya jadi jangkar segmen baru,
///   tidak menambah jarak (tidak ada garis lurus melintasi masa jeda)
/// * lompatan lebih cepat dari [ActivityType.maxSpeed] → dibuang
/// * gerak < 3 m atau < setengah akurasi → dianggap diam (jitter)
/// * waktu bergerak hanya bertambah bila kecepatan segmen ≥
///   [ActivityType.minMovingSpeed] dan jeda antar titik ≤ 30 dtk
///   (auto-pause; lampu merah tidak merusak pace)
class TrackRecorder {
  final ActivityType type;
  final double maxAccuracyM;

  TrackRecorder(this.type, {this.maxAccuracyM = 30});

  /// Semua titik yang diterima, dikelompokkan per segmen (dipisah jeda).
  final List<List<GeoFix>> segments = [];

  /// Semua titik mentah yang masuk saat merekam (untuk checkpoint/replay).
  final List<GeoFix> raw = [];

  /// Indeks di [raw] tempat user menekan jeda/lanjut, untuk replay.
  final List<(int, bool)> marks = [];

  double distanceM = 0;
  int movingMs = 0;
  double elevGainM = 0;

  /// Detik bergerak kumulatif saat tiap km tuntas (bukan durasi per km).
  final List<double> splitMarks = [];

  bool _paused = false;
  bool _needAnchor = true;
  double? _altRef;
  GeoFix? _last;
  FixVerdict? lastVerdict;
  double? lastAccuracy;

  bool get paused => _paused;
  int get movingSec => movingMs ~/ 1000;

  /// Durasi tiap km yang sudah tuntas (detik).
  List<int> get splits {
    final out = <int>[];
    var prev = 0.0;
    for (final m in splitMarks) {
      out.add((m - prev).round());
      prev = m;
    }
    return out;
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    marks.add((raw.length, true));
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _needAnchor = true;
    marks.add((raw.length, false));
  }

  FixVerdict addFix(GeoFix f) {
    lastAccuracy = f.acc;
    final v = _addFix(f);
    lastVerdict = v;
    return v;
  }

  FixVerdict _addFix(GeoFix f) {
    if (_paused) return FixVerdict.paused;
    raw.add(f);
    if (f.acc > maxAccuracyM) return FixVerdict.inaccurate;
    final last = _last;
    if (last != null && f.t <= last.t) return FixVerdict.stale;

    if (_needAnchor || last == null) {
      segments.add([f]);
      _last = f;
      _needAnchor = false;
      _altRef = f.alt ?? _altRef;
      return FixVerdict.accepted;
    }

    final d = ActivityMath.distance(last.lat, last.lng, f.lat, f.lng);
    final dtMs = f.t - last.t;
    final spd = d / (dtMs / 1000);
    if (spd > type.maxSpeed) return FixVerdict.jump;
    final jitter = math.max(3.0, math.min(last.acc, f.acc) * 0.5);
    if (d < jitter) return FixVerdict.stationary;

    // Titik sah: tambah jarak, waktu bergerak, split, elevasi.
    final before = distanceM;
    distanceM += d;
    if (spd >= type.minMovingSpeed && dtMs <= 30000) {
      final startMs = movingMs.toDouble();
      movingMs += dtMs;
      // Split: catat detik bergerak saat garis km dilewati (interpolasi).
      var nextKm = (splitMarks.length + 1) * 1000.0;
      while (distanceM >= nextKm) {
        final frac = (nextKm - before) / d;
        splitMarks.add((startMs + frac * dtMs) / 1000);
        nextKm += 1000;
      }
    } else {
      // Jarak tetap dihitung, tapi km yang lewat saat "diam" ditutup pada
      // waktu bergerak saat ini supaya split tidak bolong.
      while (distanceM >= (splitMarks.length + 1) * 1000.0) {
        splitMarks.add(movingMs / 1000);
      }
    }
    _elevation(f);
    segments.last.add(f);
    _last = f;
    return FixVerdict.accepted;
  }

  /// Elevasi naik dengan histeresis 5 m: GPS mudah naik-turun beberapa
  /// meter walau jalan datar, jadi hanya kenaikan nyata yang dihitung.
  void _elevation(GeoFix f) {
    final a = f.alt;
    if (a == null) return;
    final ref = _altRef;
    if (ref == null) {
      _altRef = a;
      return;
    }
    if (a - ref >= 5) {
      elevGainM += a - ref;
      _altRef = a;
    } else if (ref - a >= 5) {
      _altRef = a;
    }
  }

  /// Rute sebagai segmen titik ringan (untuk digambar / disimpan).
  List<List<LatLngLite>> get route => [
    for (final s in segments)
      if (s.isNotEmpty) [for (final f in s) LatLngLite(f.lat, f.lng)],
  ];

  /// Bangun ulang recorder dari titik mentah + tanda jeda (checkpoint).
  static TrackRecorder replay(
    ActivityType type,
    List<GeoFix> raw,
    List<(int, bool)> marks,
  ) {
    final r = TrackRecorder(type);
    var mi = 0;
    for (var i = 0; i <= raw.length; i++) {
      while (mi < marks.length && marks[mi].$1 == i) {
        marks[mi].$2 ? r.pause() : r.resume();
        mi++;
      }
      if (i < raw.length) r.addFix(raw[i]);
    }
    return r;
  }
}
