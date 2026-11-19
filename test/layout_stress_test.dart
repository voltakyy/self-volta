import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:self_volta/store.dart';
import 'package:self_volta/theme.dart';
import 'package:self_volta/services/prayer_service.dart';
import 'package:self_volta/pages/air_page.dart';
import 'package:self_volta/pages/aktivitas_page.dart';
import 'package:self_volta/services/activity_math.dart';
import 'package:self_volta/pages/booster_page.dart';
import 'package:self_volta/pages/buat_page.dart';
import 'package:self_volta/pages/choice_plan_page.dart';
import 'package:self_volta/pages/home_page.dart';
import 'package:self_volta/pages/ingin_page.dart';
import 'package:self_volta/pages/jadwal_page.dart';
import 'package:self_volta/pages/keuangan_page.dart';
import 'package:self_volta/pages/minggu_page.dart';
import 'package:self_volta/pages/panduan_page.dart';
import 'package:self_volta/pages/planning_page.dart';
import 'package:self_volta/pages/profile_page.dart';
import 'package:self_volta/pages/tips_page.dart';
import 'package:self_volta/pages/todo_page.dart';
import 'package:self_volta/pages/workout_page.dart';
import 'package:self_volta/pages/study_page.dart';
import 'package:self_volta/pages/shell.dart';

/// Stress-test layout: semua halaman pada lebar sempit, font scale besar,
/// dan layar pendek. Tujuannya menangkap overflow horizontal/vertikal di
/// grid, kartu, dan baris yang tidak terlihat pada viewport normal.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.I.load();
    // Satu aktivitas GPS hari ini: kartu Latihan, kartu Beranda, riwayat,
    // dan detail ikut dirender dengan data (bukan hanya keadaan kosong).
    AppState.I.activities = [_sampleActivity()];
    PrayerService.instance;
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
    await loader.load();
  });

  final pages = <String, Widget Function()>{
    'Beranda': () => HomePage(onNavigate: (_) {}),
    'Profil': () => ProfilePage(onNavigate: (_) {}),
    'Latihan': () => const WorkoutPage(),
    'Planning': () => const PlanningPage(),
    'Keuangan': () => const KeuanganPage(),
    'Air': () => const AirPage(),
    'Booster': () => const BoosterPage(),
    'Tips': () => const TipsPage(),
    'Panduan': () => const PanduanPage(),
    'To-Do': () => TodoPage(onNavigate: (_) {}),
    'Jadwal': () => JadwalPage(onNavigate: (_) {}),
    'Study': () => const StudyPage(),
    'Choice Plan': () => const ChoicePlanPage(),
    'Ingin': () => const InginPage(),
    'Buat Kombinasi': () => const BuatPage(),
    'Minggu 1-2': () => const MingguPage(m1: true, onGo: _noop),
    'Rekam Aktivitas': () => const RekamAktivitasPage(),
    'Riwayat Aktivitas': () => const RiwayatAktivitasPage(),
    'Detail Aktivitas': () =>
        AktivitasDetailPage(activity: _sampleActivity(), pending: true),
  };

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    required Size size,
    required double scale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: page),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Lebar sempit + tinggi sangat besar supaya semua list malas ikut dibangun.
  for (final entry in pages.entries) {
    for (final width in const [320.0, 360.0, 412.0]) {
      for (final scale in const [1.3, 2.0]) {
        testWidgets(
          '${entry.key} ${width.toInt()}x7000 scale $scale tidak overflow',
          (tester) async {
            final problems = <String>[];
            final old = FlutterError.onError;
            FlutterError.onError = (details) {
              problems.add(details.toString());
            };

            try {
              await pumpPage(
                tester,
                entry.value(),
                size: Size(width, 7000),
                scale: scale,
              );
            } finally {
              FlutterError.onError = old;
            }
            expect(problems, isEmpty, reason: problems.join('\n'));
          },
        );
      }
    }
  }

  // Layar pendek / landscape: fixed bottom bar, header, dan grid harus tetap
  // muat tanpa overflow vertikal.
  const stressPages = [
    'Beranda',
    'Profil',
    'Keuangan',
    'To-Do',
    'Jadwal',
    'Planning',
    'Rekam Aktivitas',
    'Detail Aktivitas',
  ];
  for (final name in stressPages) {
    for (final size in const [Size(320, 568), Size(360, 640), Size(800, 360)]) {
      testWidgets(
        '$name ${size.width.toInt()}x${size.height.toInt()} scale 1.3 '
        'tidak overflow',
        (tester) async {
          final problems = <String>[];
          final old = FlutterError.onError;
          FlutterError.onError = (details) {
            problems.add(details.toString());
          };

          try {
            await pumpPage(tester, pages[name]!(), size: size, scale: 1.3);
          } finally {
            FlutterError.onError = old;
          }
          expect(problems, isEmpty, reason: problems.join('\n'));
        },
      );
    }
  }

  // Grid spesifik: kalender Beranda, badge Profil, kalender Keuangan, dan
  // grid aktivitas To-Do pada font scale ekstrem.
  for (final name in const ['Beranda', 'Profil', 'Keuangan', 'To-Do']) {
    testWidgets('grid $name 320px scale 2.0 tidak overflow', (tester) async {
      final problems = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        problems.add(details.toString());
      };

      try {
        await pumpPage(
          tester,
          pages[name]!(),
          size: const Size(320, 7000),
          scale: 2.0,
        );
      } finally {
        FlutterError.onError = old;
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  // Shell penuh: app bar, bottom nav, dan drawer pada layar sempit.
  for (final width in const [320.0, 360.0]) {
    for (final scale in const [1.3, 2.0]) {
      testWidgets('Shell ${width.toInt()} scale $scale tidak overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 7000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final problems = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (details) {
          problems.add(details.toString());
        };

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildTheme(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 7000),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const HomeShell(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 300));

          // Buka drawer yang berisi 11 tujuan.
          await tester.tap(find.byTooltip('Menu Utama'));
          await tester.pump(const Duration(milliseconds: 400));
        } finally {
          FlutterError.onError = old;
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}

void _noop(String _) {}

GpsActivity _sampleActivity() {
  final now = DateTime.now();
  final pts = [
    for (var i = 0; i < 40; i++)
      LatLngLite(-7.78 + i * 1.2e-4, 110.37 + (i % 7) * 1.5e-4),
  ];
  return GpsActivity(
    id: 'a_layout',
    type: ActivityType.run,
    name: 'Lari Sore Keliling Kampus Panjang Sekali Namanya',
    start: DateTime(now.year, now.month, now.day, 16, 40),
    elapsedSec: 3725,
    movingSec: 3600,
    distanceM: 10234,
    elevGainM: 48,
    kcal: 634,
    splits: const [345, 352, 360, 371, 349, 358, 362, 340, 355, 366],
    route: [ActivityMath.encode(pts)],
  );
}
