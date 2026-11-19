// Fitur Rekam Aktivitas: penyimpanan, XP/streak, checkpoint, dan alur UI
// mulai → jeda → selesai → simpan memakai stream GPS palsu (tanpa plugin).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_volta/pages/aktivitas_page.dart';
import 'package:self_volta/services/activity_math.dart';
import 'package:self_volta/services/activity_recorder.dart';
import 'package:self_volta/services/location_service.dart';
import 'package:self_volta/store.dart';
import 'package:self_volta/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mPerDegLat = 111195.08;

Future<void> freshInstall() async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  await ActivityRecorder.I.debugReset();
  await AppState.I.resetAllData();
  await AppState.I.load();
}

GpsActivity act({
  String id = 'a1',
  ActivityType type = ActivityType.run,
  double meters = 3000,
  DateTime? start,
}) {
  final s = start ?? DateTime.now();
  return GpsActivity(
    id: id,
    type: type,
    name: type.label,
    start: s,
    elapsedSec: 1100,
    movingSec: 1000,
    distanceM: meters,
    elevGainM: 0,
    kcal: 180,
    splits: const [330, 335, 335],
    route: [
      ActivityMath.encode(const [
        LatLngLite(-7.78, 110.37),
        LatLngLite(-7.77, 110.37),
      ]),
    ],
  );
}

void main() {
  tearDown(() async {
    LocationService.debugStream = null;
    LocationService.debugGate = null;
    // Jangan biarkan timer detak/checkpoint bocor ke tes berikutnya.
    await ActivityRecorder.I.debugReset();
  });

  group('AppState aktivitas', () {
    test('simpan aktivitas sah memberi XP sekali per jenis per hari', () async {
      await freshInstall();
      final xp0 = AppState.I.xp;
      expect(await AppState.I.addActivity(act(id: 'a1')), 30);
      expect(await AppState.I.addActivity(act(id: 'a2')), 0);
      expect(
        await AppState.I.addActivity(act(id: 'a3', type: ActivityType.walk)),
        20,
      );
      expect(AppState.I.xp, xp0 + 50);
      expect(AppState.I.activities.length, 3);
      expect(AppState.I.activitiesToday.length, 3);
    });

    test('di bawah jarak minimum: tersimpan tanpa XP', () async {
      await freshInstall();
      final xp0 = AppState.I.xp;
      expect(await AppState.I.addActivity(act(meters: 400)), 0);
      expect(AppState.I.xp, xp0);
      expect(AppState.I.activities.single.earnsXp, isFalse);
    });

    test('hapus satu-satunya aktivitas sah hari ini menarik XP', () async {
      await freshInstall();
      final xp0 = AppState.I.xp;
      await AppState.I.addActivity(act(id: 'a1'));
      await AppState.I.addActivity(act(id: 'a2'));
      await AppState.I.deleteActivity('a1');
      expect(AppState.I.xp, xp0 + 30, reason: 'a2 masih sah, XP tetap');
      await AppState.I.deleteActivity('a2');
      expect(AppState.I.xp, xp0);
      expect(AppState.I.isClaimed('gps_run'), isFalse);
    });

    test('aktivitas ikut tersimpan ke disk dan termuat ulang utuh', () async {
      await freshInstall();
      final a = act(id: 'a_disk', start: DateTime(2026, 11, 3, 6, 15));
      await AppState.I.addActivity(a);
      final p = await SharedPreferences.getInstance();
      final raw = jsonDecode(p.getString(AppState.prefKey)!) as Map;
      expect((raw['activities'] as List).length, 1);

      AppState.I.activities = [];
      await AppState.I.load();
      final b = AppState.I.activities.single;
      expect(jsonEncode(b.toJson()), jsonEncode(a.toJson()));
      expect(b.segments.single.length, 2);
    });

    test('impor gabung menambah aktivitas baru, melewati id kembar', () async {
      await freshInstall();
      await AppState.I.addActivity(act(id: 'a1'));
      final file = {
        'activities': [
          act(id: 'a1').toJson(),
          act(id: 'a9', start: DateTime(2026, 10, 1, 7)).toJson(),
        ],
      };
      await AppState.I.mergeJson(file);
      expect(AppState.I.activities.map((a) => a.id), ['a1', 'a9']);
    });

    test('aktivitas kemarin + hari ini membentuk streak 2 hari', () async {
      await freshInstall();
      AppState.I.streak = 0;
      final y = DateTime.now().subtract(const Duration(days: 1));
      AppState.I.activities = [act(id: 'y', start: y)];
      await AppState.I.addActivity(act(id: 't'));
      expect(AppState.I.streak, 2);
    });

    test('JSON rusak di satu aktivitas tidak menggagalkan load', () {
      expect(GpsActivity.fromJson({'id': 'x'}), isNull);
      final a = GpsActivity.fromJson({
        'id': 'x',
        'st': '2026-11-01T06:00:00.000',
        'rt': ['_p~iF~ps|U_'], // terpotong
      })!;
      expect(a.segments, isEmpty);
      expect(a.type, ActivityType.run);
    });
  });

  group('ActivityRecorder', () {
    test('izin ditolak: rekaman tidak dimulai', () async {
      await freshInstall();
      LocationService.debugGate = LocationGate.denied;
      final g = await ActivityRecorder.I.start(ActivityType.run);
      expect(g, LocationGate.denied);
      expect(ActivityRecorder.I.isActive, isFalse);
    });

    test('checkpoint dipulihkan sebagai sesi jeda setelah app mati', () async {
      await freshInstall();
      final ctrl = StreamController<GeoFix>();
      LocationService.debugStream = ctrl.stream;
      final rec = ActivityRecorder.I;
      await rec.start(ActivityType.walk);
      for (var i = 0; i < 50; i++) {
        ctrl.add(
          GeoFix(lat: -7.78 + i * 3 / mPerDegLat, lng: 110.37, t: i * 2000),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(rec.distanceM, closeTo(147, 1));
      rec.pause(); // menulis checkpoint
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // "App dibunuh": state memori hilang, disk tetap.
      await rec.debugReset();
      expect(await rec.restoreCheckpoint(), isTrue);
      expect(rec.state, RecState.paused);
      expect(rec.recovered, isTrue);
      expect(rec.type, ActivityType.walk);
      expect(rec.distanceM, closeTo(147, 1));

      final a = await rec.finish(weightKg: 60);
      expect(a, isNotNull);
      expect(a!.type, ActivityType.walk);
      expect(a.route, isNotEmpty);
      final p = await SharedPreferences.getInstance();
      expect(p.containsKey(ActivityRecorder.checkpointKey), isFalse);
      await ctrl.close();
    });

    test('nama default mengikuti waktu', () {
      expect(
        ActivityRecorder.defaultName(ActivityType.run, DateTime(2026, 1, 1, 6)),
        'Lari Pagi',
      );
      expect(
        ActivityRecorder.defaultName(
          ActivityType.ride,
          DateTime(2026, 1, 1, 19),
        ),
        'Sepeda Malam',
      );
    });
  });

  testWidgets('alur UI: mulai → jeda → selesai → simpan memberi XP', (
    tester,
  ) async {
    await tester.runAsync(freshInstall);
    final ctrl = StreamController<GeoFix>();
    LocationService.debugStream = ctrl.stream;
    final xp0 = AppState.I.xp;
    final nav = GlobalKey<NavigatorState>();

    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        navigatorKey: nav,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    unawaited(
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const RekamAktivitasPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Siap merekam'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rekam-mulai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(ActivityRecorder.I.state, RecState.recording);

    // 1,2 km lari pada 3 m/s.
    for (var i = 0; i <= 200; i++) {
      ctrl.add(
        GeoFix(lat: -7.78 + i * 6 / mPerDegLat, lng: 110.37, t: i * 2000),
      );
    }
    await tester.pump(const Duration(seconds: 1));
    expect(ActivityRecorder.I.distanceM, closeTo(1200, 2));
    expect(find.textContaining('1,20'), findsWidgets);

    await tester.tap(find.byKey(const Key('rekam-jeda')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('rekam-selesai')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Aktivitas'), findsOneWidget);
    expect(find.text('Split per km'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('detail-simpan')));
    await tester.tap(find.byKey(const Key('detail-simpan')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(AppState.I.activities.length, 1);
    expect(AppState.I.activities.single.distanceM, closeTo(1200, 2));
    expect(AppState.I.xp, xp0 + 30);
    expect(find.text('Ringkasan Aktivitas'), findsNothing);
    expect(find.textContaining('+30 XP'), findsOneWidget);
    // Biarkan SnackBar & debounce simpan habis sebelum tes berakhir.
    await tester.pump(const Duration(seconds: 5));
    // Catatan: controller sengaja TIDAK di-close di zona fake-async widget
    // test (menggantung harness); subscription recorder sudah dibatalkan
    // saat jeda/selesai, dan tes non-widget di atas menutupnya normal.
    expect(ctrl.hasListener, isFalse);
  });

  testWidgets('kartu Latihan menampilkan sesi yang sedang direkam', (
    tester,
  ) async {
    await tester.runAsync(freshInstall);
    final ctrl = StreamController<GeoFix>();
    LocationService.debugStream = ctrl.stream;
    await tester.runAsync(() => ActivityRecorder.I.start(ActivityType.ride));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(body: SingleChildScrollView(child: AktivitasCard())),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('aktivitas-live')), findsOneWidget);
    expect(find.text('Sedang merekam sepeda'), findsOneWidget);

    await tester.runAsync(() => ActivityRecorder.I.discard());
    await tester.pump();
    expect(find.byKey(const Key('aktivitas-mulai')), findsOneWidget);
    expect(ctrl.hasListener, isFalse);
  });
}
