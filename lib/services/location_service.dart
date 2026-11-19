// Pembungkus plugin geolocator untuk rekam aktivitas.
//
// Pola sama dengan WeatherService: satu-satunya file yang menyentuh plugin,
// punya hook [debugStream] untuk tes, dan tidak pernah memanggil platform
// channel di flutter_test (tanpa itu tes akan MissingPluginException).
//
// Di Android, stream dibuka dengan ForegroundNotificationConfig sehingga
// geolocator menjalankan foreground service "location": GPS tetap merekam
// saat layar mati / HP di saku, dengan notifikasi yang tidak bisa diusap.
// Izin yang dipakai hanya "saat app digunakan" (fine/coarse) — foreground
// service yang dimulai dari layar depan tidak butuh ACCESS_BACKGROUND_LOCATION.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'activity_math.dart' show GeoFix;

/// Hasil pengecekan izin & layanan lokasi sebelum mulai merekam.
enum LocationGate {
  ok,
  serviceOff, // GPS HP dimatikan
  denied, // user menolak (masih bisa diminta lagi)
  deniedForever, // ditolak permanen: harus lewat Pengaturan
  unsupported, // platform tanpa GPS (web/desktop/tes)
}

class LocationService {
  LocationService._();

  /// Stream titik palsu untuk tes/preview. Null di produksi.
  @visibleForTesting
  static Stream<GeoFix>? debugStream;

  /// Paksa hasil [ensureReady] di tes. Null di produksi.
  @visibleForTesting
  static LocationGate? debugGate;

  static bool get _isFlutterTest {
    if (kIsWeb) return false;
    return Platform.environment['FLUTTER_TEST'] == 'true';
  }

  static bool get _supported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Cek layanan GPS & izin; minta izin bila belum pernah ditanya.
  static Future<LocationGate> ensureReady() async {
    final g = debugGate;
    if (g != null) return g;
    if (debugStream != null) return LocationGate.ok;
    if (_isFlutterTest || !_supported) return LocationGate.unsupported;
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationGate.serviceOff;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return switch (p) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationGate.ok,
      LocationPermission.deniedForever => LocationGate.deniedForever,
      _ => LocationGate.denied,
    };
  }

  static Future<void> openLocationSettings() async {
    if (_isFlutterTest || !_supported) return;
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    if (_isFlutterTest || !_supported) return;
    await Geolocator.openAppSettings();
  }

  /// Stream titik GPS akurasi tinggi. [activityLabel] tampil di notifikasi
  /// foreground service ("Merekam Lari").
  static Stream<GeoFix> positions({required String activityLabel}) {
    final d = debugStream;
    if (d != null) return d;
    if (_isFlutterTest || !_supported) return const Stream.empty();

    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'SELF VOLTA merekam $activityLabel',
          notificationText:
              'GPS aktif. Buka aplikasi untuk jeda atau selesai.',
          notificationChannelName: 'Rekam Aktivitas',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      settings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        // Repo belum punya folder ios/; aktifkan bersama UIBackgroundModes.
        allowBackgroundLocationUpdates: false,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => GeoFix(
        lat: p.latitude,
        lng: p.longitude,
        alt: p.altitude == 0 ? null : p.altitude,
        acc: p.accuracy,
        t: p.timestamp.millisecondsSinceEpoch,
      ),
    );
  }
}
