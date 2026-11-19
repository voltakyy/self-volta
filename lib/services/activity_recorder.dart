// Sesi rekam aktivitas yang sedang berjalan.
//
// Sengaja TIDAK disimpan di AppState: titik GPS datang tiap 1–2 detik dan
// AppState didengar oleh hampir semua halaman. Recorder ini notifier
// tersendiri, hidup selama proses app hidup (tetap jalan walau user pindah
// tab atau keluar dari layar rekam), dan baru menulis ke AppState saat
// user menekan Simpan.
//
// Ketahanan: setiap 15 detik (dan saat jeda/lanjut) titik mentah ditulis ke
// key `sv_track_live`. Bila app dibunuh sistem di tengah lari, saat dibuka
// lagi rekaman dipulihkan dalam keadaan jeda — user tinggal Lanjut atau
// Selesai. Key ini terpisah dari `sv_v1` supaya checkpoint yang sering
// tidak ikut menyalin seluruh data app ke `sv_v1_bak`.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../store.dart';
import 'activity_math.dart';
import 'location_service.dart';

enum RecState { idle, recording, paused }

/// Kualitas sinyal untuk pil status di layar rekam.
enum GpsSignal { off, searching, weak, good }

class ActivityRecorder extends ChangeNotifier {
  ActivityRecorder._();
  static final ActivityRecorder I = ActivityRecorder._();

  static const checkpointKey = 'sv_track_live';

  /// Jam yang bisa diganti di tes.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  RecState state = RecState.idle;
  ActivityType type = ActivityType.run;
  TrackRecorder? track;
  DateTime? startedAt;

  /// True bila sesi ini hasil pemulihan checkpoint (app sempat mati).
  bool recovered = false;

  int _activeMsBefore = 0; // akumulasi waktu aktif sebelum segmen sekarang
  DateTime? _segStart; // awal segmen aktif (null saat jeda)
  DateTime? _lastFixAt;
  StreamSubscription<GeoFix>? _sub;
  Timer? _tick;
  Timer? _ckpt;

  bool get isActive => state != RecState.idle;

  /// Durasi aktif (tanpa masa jeda manual), dalam detik.
  int get elapsedSec {
    var ms = _activeMsBefore;
    final s = _segStart;
    if (s != null) ms += clock().difference(s).inMilliseconds;
    return ms ~/ 1000;
  }

  double get distanceM => track?.distanceM ?? 0;
  int get movingSec => track?.movingSec ?? 0;

  GpsSignal get signal {
    if (state != RecState.recording) return GpsSignal.off;
    final at = _lastFixAt;
    if (at == null || clock().difference(at).inSeconds > 12) {
      return GpsSignal.searching;
    }
    final acc = track?.lastAccuracy;
    if (acc == null || acc > 20) return GpsSignal.weak;
    return GpsSignal.good;
  }

  /// Mulai merekam. Mengembalikan status izin; rekaman hanya berjalan bila
  /// hasilnya [LocationGate.ok].
  Future<LocationGate> start(ActivityType t) async {
    if (isActive) return LocationGate.ok;
    final gate = await LocationService.ensureReady();
    if (gate != LocationGate.ok) return gate;
    type = t;
    track = TrackRecorder(t);
    startedAt = clock();
    _activeMsBefore = 0;
    _segStart = startedAt;
    _lastFixAt = null;
    recovered = false;
    state = RecState.recording;
    _listen();
    _startTimers();
    notifyListeners();
    unawaited(_checkpoint());
    return gate;
  }

  void pause() {
    if (state != RecState.recording) return;
    final s = _segStart;
    if (s != null) _activeMsBefore += clock().difference(s).inMilliseconds;
    _segStart = null;
    track?.pause();
    state = RecState.paused;
    // GPS dimatikan saat jeda: hemat baterai & notifikasi service hilang.
    unawaited(_sub?.cancel());
    _sub = null;
    notifyListeners();
    unawaited(_checkpoint());
  }

  /// Lanjutkan setelah jeda (atau setelah pemulihan checkpoint).
  Future<LocationGate> resume() async {
    if (state != RecState.paused) return LocationGate.ok;
    final gate = await LocationService.ensureReady();
    if (gate != LocationGate.ok) return gate;
    track?.resume();
    _segStart = clock();
    _lastFixAt = null;
    state = RecState.recording;
    _listen();
    _startTimers();
    notifyListeners();
    unawaited(_checkpoint());
    return gate;
  }

  /// Hentikan rekaman dan bentuk aktivitas (BELUM disimpan ke AppState).
  /// Null bila tidak ada sesi aktif.
  Future<GpsActivity?> finish({double? weightKg}) async {
    if (!isActive) return null;
    if (state == RecState.recording) pause();
    final tr = track!;
    final st = startedAt!;
    final segs = ActivityMath.simplifyToBudget(tr.route);
    final act = GpsActivity(
      id: 'a${st.millisecondsSinceEpoch}',
      type: type,
      name: defaultName(type, st),
      start: st,
      elapsedSec: elapsedSec,
      movingSec: tr.movingSec,
      distanceM: tr.distanceM,
      elevGainM: tr.elevGainM,
      kcal: ActivityMath.kcal(
        type: type,
        meters: tr.distanceM,
        movingSec: tr.movingSec,
        weightKg: weightKg ?? AppState.I.weightKg,
      ),
      splits: tr.splits,
      route: [
        for (final s in segs)
          if (s.length >= 2) ActivityMath.encode(s),
      ],
    );
    await _reset();
    return act;
  }

  /// Buang rekaman tanpa menyimpan.
  Future<void> discard() => _reset();

  static String defaultName(ActivityType t, DateTime at) {
    final h = at.hour;
    final part = h < 11
        ? 'Pagi'
        : h < 15
        ? 'Siang'
        : h < 18
        ? 'Sore'
        : 'Malam';
    return '${t.label} $part';
  }

  // ---------------------------------------------------------------------

  void _listen() {
    unawaited(_sub?.cancel());
    _sub = LocationService.positions(activityLabel: type.label.toLowerCase())
        .listen(
          _onFix,
          onError: (Object e) {
            debugPrint('[ActivityRecorder] GPS error: $e');
            notifyListeners();
          },
        );
  }

  void _onFix(GeoFix f) {
    final tr = track;
    if (tr == null || state != RecState.recording) return;
    _lastFixAt = clock();
    tr.addFix(f);
    notifyListeners();
  }

  void _startTimers() {
    _tick?.cancel();
    _ckpt?.cancel();
    // Detak 1 dtk hanya untuk jam di layar; hitungan jarak dari titik GPS.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == RecState.recording) notifyListeners();
    });
    _ckpt = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_checkpoint()),
    );
  }

  Future<void> _reset() async {
    await _sub?.cancel();
    _sub = null;
    _tick?.cancel();
    _ckpt?.cancel();
    _tick = null;
    _ckpt = null;
    state = RecState.idle;
    track = null;
    startedAt = null;
    _segStart = null;
    _lastFixAt = null;
    _activeMsBefore = 0;
    recovered = false;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(checkpointKey);
  }

  Future<void> _checkpoint() async {
    final tr = track;
    final st = startedAt;
    if (tr == null || st == null || !isActive) return;
    final data = {
      'ty': type.name,
      'st': st.toIso8601String(),
      'ab': elapsedSec * 1000,
      'raw': [for (final f in tr.raw) f.toJson()],
      'mk': [
        for (final m in tr.marks) [m.$1, m.$2 ? 1 : 0],
      ],
    };
    try {
      final p = await SharedPreferences.getInstance();
      // Sesi bisa saja sudah selesai/dibuang selama menunggu: jangan
      // hidupkan lagi checkpoint yang sudah dihapus _reset().
      if (!isActive || !identical(track, tr)) return;
      await p.setString(checkpointKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[ActivityRecorder] checkpoint gagal: $e');
    }
  }

  /// Dipanggil sekali saat app dibuka: pulihkan rekaman yang terputus.
  /// Hasilnya sesi dalam keadaan JEDA dengan [recovered] = true.
  Future<bool> restoreCheckpoint() async {
    if (isActive) return false;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(checkpointKey);
    if (raw == null) return false;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final st = DateTime.parse('${j['st']}');
      final t = ActivityType.parse(j['ty'] as String?);
      final fixes = [
        for (final e in (j['raw'] as List? ?? const [])) ?GeoFix.fromJson(e),
      ];
      final marks = <(int, bool)>[
        for (final m in (j['mk'] as List? ?? const []))
          if (m is List && m.length == 2) ((m[0] as num).toInt(), m[1] == 1),
      ];
      final tr = TrackRecorder.replay(t, fixes, marks);
      if (!tr.paused) tr.pause();
      type = t;
      track = tr;
      startedAt = st;
      _activeMsBefore = (j['ab'] as num?)?.toInt() ?? 0;
      _segStart = null;
      state = RecState.paused;
      recovered = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ActivityRecorder] checkpoint rusak, dibuang: $e');
      await p.remove(checkpointKey);
      return false;
    }
  }

  /// Khusus tes: kembalikan ke kondisi awal tanpa menyentuh disk.
  @visibleForTesting
  Future<void> debugReset() async {
    await _sub?.cancel();
    _sub = null;
    _tick?.cancel();
    _ckpt?.cancel();
    state = RecState.idle;
    track = null;
    startedAt = null;
    _segStart = null;
    _activeMsBefore = 0;
    recovered = false;
  }
}
