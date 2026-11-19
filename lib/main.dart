import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/alarm_page.dart';
import 'pages/shell.dart';
import 'services/activity_recorder.dart';
import 'services/todo_notifications.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  applySystemOverlay();
  TodoNotif.onPayload = (payload) {
    unawaited(openAlarmFromPayload(payload));
  };
  await AppState.I.load();
  // Rekaman GPS yang terputus (app dibunuh sistem) dipulihkan dalam
  // keadaan jeda; user memilih Lanjut / Selesai di halaman Latihan.
  await ActivityRecorder.I.restoreCheckpoint();
  unawaited(AppState.I.syncData());
  runApp(const SelfVoltaApp());
  // Notifikasi adalah fitur native: inisialisasi setelah frame pertama,
  // minta izin SEKALI (agar notifikasi benar-benar aktif), lalu jadwalkan
  // ulang semua pengingat (to-do + latihan) supaya tidak ada yang hilang
  // setelah update aplikasi.
  unawaited(() async {
    await TodoNotif.init();
    TodoNotif.configure(
      sound: AppState.I.notifSound,
      vibrate: AppState.I.notifVibrate,
    );
    await TodoNotif.ensurePermissionOnce();
    await AppState.I.resyncNotifications();
    final initial = await TodoNotif.initialPayload();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(openAlarmFromPayload(initial));
      });
    }
  }());
}

class SelfVoltaApp extends StatelessWidget {
  const SelfVoltaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SELF VOLTA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Picker tanggal/jam & teks bawaan dalam bahasa Indonesia.
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Scroll memantul khas iOS di semua halaman (tanpa glow Android).
      scrollBehavior: const _IosScroll(),
      navigatorKey: appNavigatorKey,
      home: const HomeShell(),
    );
  }
}

/// ScrollBehavior iOS: fisika memantul + tanpa overscroll-glow Android.
class _IosScroll extends MaterialScrollBehavior {
  const _IosScroll();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
