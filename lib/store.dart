import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'services/activity_math.dart';
import 'services/alarm_audio.dart';
import 'services/todo_notifications.dart';

class Txn {
  final int id, hari, jml;
  final String ket, kat, bln;
  Txn(this.id, this.hari, this.ket, this.jml, this.kat, {this.bln = ''});
  Map<String, dynamic> toJson() => {
    'id': id,
    'hari': hari,
    'ket': ket,
    'jml': jml,
    'kat': kat,
    'bln': bln,
  };
  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
    j['id'] as int,
    j['hari'] as int? ?? 1,
    j['ket'] as String? ?? '',
    j['jml'] as int? ?? 0,
    j['kat'] as String? ?? 'lain',
    bln: j['bln'] as String? ?? '',
  );
}

/// Catatan menu makan bebas per tanggal (opsional, boleh >3).
/// bln format "yyyy-MM" agar ikut bulan tampil.
class MealNote {
  final int id, hari;
  final String bln, text;
  MealNote(this.id, this.hari, this.bln, this.text);
  Map<String, dynamic> toJson() => {
    'id': id,
    'hari': hari,
    'bln': bln,
    'text': text,
  };
  factory MealNote.fromJson(Map<String, dynamic> j) => MealNote(
    j['id'] as int,
    j['hari'] as int? ?? 1,
    j['bln'] as String? ?? '',
    j['text'] as String? ?? '',
  );
}

class CustomMeal {
  final String id;
  final String name;
  final String
  mealTime; // 'Sarapan', 'Makan Siang', 'Makan Malam', 'Snack Booster'
  final int dayIndex; // 0..6 (Senin..Minggu)
  final int kalori;
  final int protein;
  final int karbo;
  final List<String> bahan;
  final String langkah;
  final int estimasiBiaya;

  CustomMeal({
    required this.id,
    required this.name,
    this.mealTime = 'Makan Siang',
    this.dayIndex = 0,
    this.kalori = 450,
    this.protein = 20,
    this.karbo = 55,
    this.bahan = const [],
    this.langkah = '',
    this.estimasiBiaya = 8000,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mealTime': mealTime,
    'dayIndex': dayIndex,
    'kalori': kalori,
    'protein': protein,
    'karbo': karbo,
    'bahan': bahan,
    'langkah': langkah,
    'estimasiBiaya': estimasiBiaya,
  };

  factory CustomMeal.fromJson(Map<String, dynamic> j) => CustomMeal(
    id: j['id'] as String? ?? UniqueKey().toString(),
    name: j['name'] as String? ?? 'Menu Kustom',
    mealTime: j['mealTime'] as String? ?? 'Makan Siang',
    dayIndex: j['dayIndex'] as int? ?? 0,
    kalori: j['kalori'] as int? ?? 450,
    protein: j['protein'] as int? ?? 20,
    karbo: j['karbo'] as int? ?? 55,
    bahan: (j['bahan'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    langkah: j['langkah'] as String? ?? '',
    estimasiBiaya: j['estimasiBiaya'] as int? ?? 8000,
  );
}

class PianoDep {
  final int id, week, amt;
  final String date;
  PianoDep(this.id, this.week, this.amt, this.date);
  Map<String, dynamic> toJson() => {
    'id': id,
    'week': week,
    'amt': amt,
    'date': date,
  };
  factory PianoDep.fromJson(Map<String, dynamic> j) => PianoDep(
    j['id'] as int,
    j['week'] as int? ?? 1,
    j['amt'] as int? ?? 0,
    j['date'] as String? ?? '',
  );
}

/// Tugas to-do harian (port aplikasi web "Hari").
/// date = "yyyy-MM-dd" ('' = hari ini), timeMin = menit dalam sehari
/// (-1 = tanpa jam), xp = bonus XP saat tuntas (default 10),
/// doneAt = tanggal penyelesaian (pengelompokan tab Selesai).
class SvTask {
  final int id;
  final String title, note, cat;
  final int pri; // 0 Santai | 1 Sedang | 2 Penting
  final String date;
  final int timeMin;
  final bool reminder, done;

  /// Nada pengingat khusus tugas. String kosong = ikut setelan global.
  final String sound;

  /// '' | 'harian' | 'mingguan' | 'bulanan'.
  final String repeat;

  /// Tampil sebagai alarm layar penuh (bangunkan layar terkunci).
  final bool alarm;

  /// Ikut dicatat di tracker rutinitas bulanan saat tugas selesai.
  final bool routine;

  /// Kelompok tugas hasil pengulangan. 0 = belum terhubung ke seri.
  final int seriesId;
  final String doneAt;
  final int xp;

  const SvTask({
    required this.id,
    required this.title,
    this.note = '',
    this.cat = 'Pribadi',
    this.pri = 0,
    this.date = '',
    this.timeMin = -1,
    this.reminder = false,
    this.done = false,
    this.sound = '',
    this.repeat = '',
    this.alarm = false,
    this.routine = false,
    this.seriesId = 0,
    this.doneAt = '',
    this.xp = 10,
  });

  SvTask copyWith({
    int? id,
    String? title,
    String? note,
    String? cat,
    int? pri,
    String? date,
    int? timeMin,
    bool? reminder,
    bool? done,
    String? sound,
    String? repeat,
    bool? alarm,
    bool? routine,
    int? seriesId,
    String? doneAt,
    int? xp,
  }) => SvTask(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note ?? this.note,
    cat: cat ?? this.cat,
    pri: pri ?? this.pri,
    date: date ?? this.date,
    timeMin: timeMin ?? this.timeMin,
    reminder: reminder ?? this.reminder,
    done: done ?? this.done,
    sound: sound ?? this.sound,
    repeat: repeat ?? this.repeat,
    alarm: alarm ?? this.alarm,
    routine: routine ?? this.routine,
    seriesId: seriesId ?? this.seriesId,
    doneAt: doneAt ?? this.doneAt,
    xp: xp ?? this.xp,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    't': title,
    'n': note,
    'c': cat,
    'p': pri,
    'd': date,
    'tm': timeMin,
    'r': reminder,
    'x': xp,
    'snd': sound,
    'rep': repeat,
    'al': alarm,
    'rout': routine,
    'ser': seriesId,
    'ok': done,
    'okAt': doneAt,
  };

  factory SvTask.fromJson(Map<String, dynamic> j) => SvTask(
    id: j['id'] as int? ?? 0,
    title: j['t'] as String? ?? '',
    note: j['n'] as String? ?? '',
    cat: j['c'] as String? ?? 'Pribadi',
    pri: j['p'] as int? ?? 0,
    date: j['d'] as String? ?? '',
    timeMin: j['tm'] as int? ?? -1,
    reminder: j['r'] == true,
    done: j['ok'] == true,
    sound: j['snd'] as String? ?? '',
    repeat: j['rep'] as String? ?? '',
    alarm: j['al'] == true,
    routine: j['rout'] == true,
    seriesId: j['ser'] as int? ?? 0,
    doneAt: j['okAt'] as String? ?? '',
    xp: j['x'] as int? ?? 10,
  );
}

/// Satu baris di tracker rutinitas bulanan.
class RoutineMark {
  final String date; // yyyy-MM-dd
  final int taskId;
  final String title;

  const RoutineMark({
    required this.date,
    required this.taskId,
    required this.title,
  });

  Map<String, dynamic> toJson() => {'d': date, 'id': taskId, 't': title};

  factory RoutineMark.fromJson(Map<String, dynamic> j) => RoutineMark(
    date: j['d'] as String? ?? '',
    taskId: j['id'] as int? ?? 0,
    title: j['t'] as String? ?? '',
  );
}

/// Mata pelajaran / aktivitas belajar yang dilacak di halaman Study.
/// `targetMin` = target menit per minggu (default 180 = 3 jam).
class StudySubject {
  final int id;
  final String name;
  final int targetMin;

  const StudySubject({
    required this.id,
    required this.name,
    this.targetMin = 180,
  });

  StudySubject copyWith({String? name, int? targetMin}) => StudySubject(
    id: id,
    name: name ?? this.name,
    targetMin: targetMin ?? this.targetMin,
  );

  Map<String, dynamic> toJson() => {'id': id, 'n': name, 't': targetMin};

  factory StudySubject.fromJson(Map<String, dynamic> j) => StudySubject(
    id: j['id'] as int? ?? 0,
    name: j['n'] as String? ?? '',
    targetMin: j['t'] as int? ?? 180,
  );
}

/// Satu sesi belajar yang sudah selesai (menit + tanggal).
class StudySession {
  final int subjectId;
  final String date; // "yyyy-MM-dd"
  final int minutes;

  const StudySession({
    required this.subjectId,
    required this.date,
    required this.minutes,
  });

  Map<String, dynamic> toJson() => {'s': subjectId, 'd': date, 'm': minutes};

  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
    subjectId: j['s'] as int? ?? 0,
    date: j['d'] as String? ?? '',
    minutes: j['m'] as int? ?? 0,
  );
}

/// Satu aktivitas GPS tersimpan (lari / jalan kaki / sepeda).
/// Rute disimpan sebagai encoded polyline per segmen (dipisah jeda) dan
/// sudah disederhanakan maks ±600 titik supaya `sv_v1` tetap ringan.
class GpsActivity {
  final String id;
  final ActivityType type;
  final String name;
  final DateTime start;
  final int elapsedSec; // total sejak mulai, tanpa masa jeda manual
  final int movingSec; // tanpa auto-pause (berhenti di lampu merah dll.)
  final double distanceM;
  final double elevGainM; // perkiraan
  final int kcal; // perkiraan
  final List<int> splits; // detik per km tuntas
  final List<String> route; // encoded polyline per segmen

  const GpsActivity({
    required this.id,
    required this.type,
    required this.name,
    required this.start,
    required this.elapsedSec,
    required this.movingSec,
    required this.distanceM,
    required this.elevGainM,
    required this.kcal,
    this.splits = const [],
    this.route = const [],
  });

  /// "yyyy-MM-dd" tanggal mulai (zona lokal).
  String get date =>
      '${start.year.toString().padLeft(4, '0')}-'
      '${start.month.toString().padLeft(2, '0')}-'
      '${start.day.toString().padLeft(2, '0')}';

  bool get earnsXp => distanceM >= type.xpMinMeters;

  List<List<LatLngLite>> get segments {
    final out = <List<LatLngLite>>[];
    for (final r in route) {
      try {
        final pts = ActivityMath.decode(r);
        if (pts.isNotEmpty) out.add(pts);
      } on FormatException {
        // Segmen rusak dilewati; statistik tetap tampil.
      }
    }
    return out;
  }

  GpsActivity rename(String n) => GpsActivity(
    id: id,
    type: type,
    name: n,
    start: start,
    elapsedSec: elapsedSec,
    movingSec: movingSec,
    distanceM: distanceM,
    elevGainM: elevGainM,
    kcal: kcal,
    splits: splits,
    route: route,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ty': type.name,
    'n': name,
    'st': start.toIso8601String(),
    'el': elapsedSec,
    'mv': movingSec,
    'd': double.parse(distanceM.toStringAsFixed(1)),
    'eg': double.parse(elevGainM.toStringAsFixed(1)),
    'kc': kcal,
    'sp': splits,
    'rt': route,
  };

  static GpsActivity? fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String?;
    final st = DateTime.tryParse('${j['st']}');
    if (id == null || id.isEmpty || st == null) return null;
    final type = ActivityType.parse(j['ty'] as String?);
    final rawName = (j['n'] as String? ?? '').trim();
    return GpsActivity(
      id: id,
      type: type,
      name: rawName.isNotEmpty ? rawName : type.label,
      start: st,
      elapsedSec: (j['el'] as num?)?.toInt() ?? 0,
      movingSec: (j['mv'] as num?)?.toInt() ?? 0,
      distanceM: (j['d'] as num?)?.toDouble() ?? 0,
      elevGainM: (j['eg'] as num?)?.toDouble() ?? 0,
      kcal: (j['kc'] as num?)?.toInt() ?? 0,
      splits: [
        for (final e in (j['sp'] as List? ?? const []))
          if (e is num) e.toInt(),
      ],
      route: [
        for (final e in (j['rt'] as List? ?? const []))
          if (e is String) e,
      ],
    );
  }
}

/// Informasi pemulihan saat `sv_v1` tidak bisa dibaca (dipakai UI).
class LoadRecovery {
  final String corruptKey;
  final bool recoveredFromBackup;
  final String error;
  final String? backupError;
  const LoadRecovery({
    required this.corruptKey,
    required this.recoveredFromBackup,
    required this.error,
    this.backupError,
  });
}

class AppState extends ChangeNotifier {
  static final AppState I = AppState._();
  AppState._();

  Map<String, bool> workoutDone = {};

  /// Aktivitas GPS tersimpan, terbaru di depan.
  List<GpsActivity> activities = [];
  List<Txn> txns = [];
  List<MealNote> mealNotes = [];
  List<CustomMeal> customMeals = [];
  int budget = 750000;
  int income = 900000;
  List<Combo> combos = List.of(DEFAULT_COMBOS);
  List<PianoDep> piano = [];
  bool bumbuStock = false;
  bool bumbuBeras = false;
  bool bumbuFin = false;
  bool berasFin = false;
  // Id Txn pendukung pembelian (anti ORPHAN_LATCH_STATE): hapus riwayat
  // = reset status. -1 = tidak ada.
  int bumbuTxnId = -1;
  int berasTxnId = -1;

  // ---- Anti-cheat: buku besar XP harian (RESET OTOMATIS PUKUL 00.00) ----
  // xpDay = stamp tanggal "yyyy-MM-dd" terakhir buku besar aktif.
  // xpClaimed = sumber XP -> total yang sudah diklaim HARI INI.
  // Saat tanggal berganti: centang latihan & kuota klaim XP direset
  // otomatis; XP, level & streak tidak tersentuh.
  String xpDay = '';
  Map<String, int> xpClaimed = {};

  // ---- To-Do Harian (port aplikasi web Hari) ----
  List<SvTask> todos = [];

  /// Histori ringkas rutinitas yang sudah tuntas, dipakai tracker bulanan.
  List<RoutineMark> routineMarks = [];

  // ---- Profil Fisik, BMI & Kebutuhan Asupan Gizi Harian (Ilmiah) ----
  double weightKg = 62.0;
  double heightCm = 170.0;
  int userAge = 21;
  String userGender = 'pria'; // 'pria' | 'wanita'
  String activityLevel = 'moderate'; // 'sedentary' | 'moderate' | 'active'
  String fitnessGoal =
      'muscle_gain'; // 'muscle_gain' | 'fat_loss' | 'maintenance'

  // ---- Pengingat latihan (notifikasi sistem, jadwal diatur user) ----
  bool workoutReminderOn = true;
  Set<int> workoutReminderDays = {1, 3, 5}; // 1=Senin .. 7=Minggu (Sen/Rab/Jum)
  int workoutReminderMin = 16 * 60 + 30; // menit sejak 00.00 (16.30)

  static const _wdShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  // ---- Setelan notifikasi (nada & getar) ----
  String notifSound = 'sistem'; // 'sistem' | 'ding' | 'chime' | 'lembut'
  bool notifVibrate = true;

  // Nama file nada alarm kustom milik user. File audionya disalin native ke
  // penyimpanan app; string ini hanya untuk ditampilkan di UI.
  String customAlarmName = '';

  bool get hasCustomAlarm => customAlarmName.trim().isNotEmpty;

  static const notifSounds = ['sistem', 'ding', 'chime', 'lembut'];

  String get notifSoundLabel => switch (notifSound) {
    'ding' => 'Ding',
    'chime' => 'Chime',
    'lembut' => 'Lembut',
    _ => 'Nada sistem',
  };

  /// Simpan nama file nada alarm kustom setelah berhasil diimpor.
  Future<void> setCustomAlarmName(String name) async {
    customAlarmName = name.trim();
    notifyListeners();
    await save();
  }

  /// Hapus nada alarm kustom dari app sekaligus dari penyimpanan native.
  Future<void> clearCustomAlarm() async {
    customAlarmName = '';
    await AlarmAudio.clearCustom();
    notifyListeners();
    await save();
  }

  /// Ubah nada/getar lalu jadwalkan ulang semua pengingat (kanal Android
  /// mengunci nada saat dibuat, jadi kanal baru harus dipakai).
  Future<void> setNotifPrefs({String? sound, bool? vibrate}) async {
    if (sound != null && notifSounds.contains(sound)) notifSound = sound;
    if (vibrate != null) notifVibrate = vibrate;
    TodoNotif.configure(sound: notifSound, vibrate: notifVibrate);
    notifyListeners();
    await save();
    await resyncNotifications();
  }

  // ---- Study (pelacak sesi belajar) --------------------------------------
  List<StudySubject> studySubjects = [];
  List<StudySession> studySessions = [];

  static String _mondayKey(DateTime n) {
    final d = DateTime(
      n.year,
      n.month,
      n.day,
    ).subtract(Duration(days: n.weekday - 1));
    return _dateKeyOf(d);
  }

  static String _dateKeyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get studyMinutesWeek {
    final monday = _mondayKey(DateTime.now());
    var sum = 0;
    for (final s in studySessions) {
      if (s.date.compareTo(monday) >= 0) sum += s.minutes;
    }
    return sum;
  }

  int get studySessionsToday {
    final t = _dateKeyOf(DateTime.now());
    return studySessions.where((s) => s.date == t).length;
  }

  int studyMinutesWeekOf(int subjectId) {
    final monday = _mondayKey(DateTime.now());
    var sum = 0;
    for (final s in studySessions) {
      if (s.subjectId == subjectId && s.date.compareTo(monday) >= 0) {
        sum += s.minutes;
      }
    }
    return sum;
  }

  /// Menit belajar 7 hari terakhir (indeks 0 = 6 hari lalu, 6 = hari ini).
  List<int> get studyLast7Minutes {
    final today = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        studySessions
            .where(
              (s) => s.date == _dateKeyOf(today.subtract(Duration(days: i))),
            )
            .fold<int>(0, (a, s) => a + s.minutes),
    ];
  }

  Future<void> addStudySubject(String name, int targetMin) async {
    final n = name.trim();
    if (n.isEmpty) return;
    studySubjects = [
      ...studySubjects,
      StudySubject(
        id: DateTime.now().millisecondsSinceEpoch,
        name: n,
        targetMin: targetMin.clamp(30, 3000),
      ),
    ];
    notifyListeners();
    await save();
  }

  Future<void> deleteStudySubject(int id) async {
    studySubjects = studySubjects.where((s) => s.id != id).toList();
    studySessions = studySessions.where((s) => s.subjectId != id).toList();
    notifyListeners();
    await save();
  }

  Future<void> logStudy(int subjectId, int minutes) async {
    if (minutes <= 0) return;
    studySessions = [
      ...studySessions,
      StudySession(
        subjectId: subjectId,
        date: _dateKeyOf(DateTime.now()),
        minutes: minutes.clamp(1, 600),
      ),
    ];
    notifyListeners();
    await save();
  }

  String get workoutReminderTimeLabel {
    final h = (workoutReminderMin ~/ 60).toString().padLeft(2, '0');
    final m = (workoutReminderMin % 60).toString().padLeft(2, '0');
    return '$h.$m';
  }

  /// "Sen · Rab · Jum" — urut Senin→Minggu.
  String get workoutReminderDaysLabel {
    final ds = workoutReminderDays.toList()..sort();
    if (ds.isEmpty) return 'Belum dipilih';
    if (ds.length == 7) return 'Setiap hari';
    return ds.map((d) => _wdShort[(d - 1).clamp(0, 6)]).join(' · ');
  }

  /// Label ringkas untuk pil di header halaman Latihan.
  String get workoutReminderShort =>
      workoutReminderOn ? workoutReminderTimeLabel : 'Notif mati';

  /// Ubah jadwal pengingat latihan lalu sinkronkan ke OS. Perubahan
  /// langsung disimpan (jadwal user tidak boleh hilang bila app ditutup).
  Future<void> setWorkoutReminder({
    bool? on,
    Set<int>? days,
    int? timeMin,
  }) async {
    if (on != null) workoutReminderOn = on;
    if (days != null) workoutReminderDays = Set.of(days);
    if (timeMin != null) workoutReminderMin = timeMin.clamp(0, 1439);
    // Minimal satu hari: pengingat tanpa hari = tidak pernah berbunyi.
    if (workoutReminderOn && workoutReminderDays.isEmpty) {
      workoutReminderDays = {DateTime.now().weekday};
    }
    notifyListeners();
    await save();
    await TodoNotif.syncWorkout(
      on: workoutReminderOn,
      days: workoutReminderDays,
      timeMin: workoutReminderMin,
    );
  }

  /// Jadwalkan ulang SEMUA notifikasi (to-do + latihan). Dipanggil tiap app
  /// dibuka: setelah update/izin baru, jadwal lama bisa hilang dan tugas
  /// lama belum punya slot notifikasi.
  Future<void> resyncNotifications() async {
    if (!TodoNotif.ready) return;
    await TodoNotif.cancelAll();
    for (final t in todos) {
      _syncNotif(t);
    }
    await TodoNotif.syncWorkout(
      on: workoutReminderOn,
      days: workoutReminderDays,
      timeMin: workoutReminderMin,
    );
  }

  double get bmi {
    if (heightCm <= 0) return 0.0;
    final hM = heightCm / 100.0;
    return weightKg / (hM * hM);
  }

  String get bmiCategory {
    final b = bmi;
    if (b <= 0) return '-';
    if (b < 18.5) return 'Kurus (Underweight)';
    if (b < 23.0) return 'Ideal (Normal)';
    if (b < 25.0) return 'Kelebihan (Overweight)';
    return 'Obesitas';
  }

  String get bmiRecommendation {
    final b = bmi;
    if (b < 18.5) {
      return 'Perlu surplus kalori +300 kkal & protein telur/tempe untuk menaikkan massa otot.';
    } else if (b < 23.0) {
      return 'Postur ideal! Pertahankan kalori & tingkatkan repetisi kalistenik untuk definisi otot.';
    } else if (b < 25.0) {
      return 'Kombinasikan latihan kalistenik progresif dengan menu rebus-kukus rendah lemak.';
    } else {
      return 'Fokus defisit kalori teratur, perbanyak jalan kaki & kurangi makanan berminyak.';
    }
  }

  double get minIdealWeight {
    final hM = heightCm / 100.0;
    return 18.5 * hM * hM;
  }

  double get maxIdealWeight {
    final hM = heightCm / 100.0;
    return 22.9 * hM * hM;
  }

  // --- KALKULASI ASUPAN HARIAN (BMR, TDEE & MAKRONUTRIEN) ---
  int get bmr {
    if (weightKg <= 0 || heightCm <= 0) return 1550;
    if (userGender == 'wanita') {
      return ((10 * weightKg) + (6.25 * heightCm) - (5 * userAge) - 161)
          .round();
    }
    return ((10 * weightKg) + (6.25 * heightCm) - (5 * userAge) + 5).round();
  }

  int get tdee {
    double mult = 1.375; // moderate (kalistenik 3x seminggu)
    if (activityLevel == 'sedentary') mult = 1.2;
    if (activityLevel == 'active') mult = 1.55;
    return (bmr * mult).round();
  }

  int get dailyCalories {
    if (fitnessGoal == 'muscle_gain') {
      return tdee + 300; // Surplus bersih hypertrophy
    } else if (fitnessGoal == 'fat_loss') {
      return (tdee - 350).clamp(1200, 4000); // Defisit cutting aman
    }
    return tdee; // Maintenance
  }

  int get dailyProtein {
    double mult = 1.8;
    if (fitnessGoal == 'muscle_gain') {
      mult = 2.0; // 2.0g/kg untuk pertumbuhan otot kalistenik
    }
    if (fitnessGoal == 'fat_loss') {
      mult = 2.2; // 2.2g/kg untuk mencegah atrofi saat defisit
    }
    return (weightKg * mult).round().clamp(60, 250);
  }

  int get dailyFat {
    // 22% kalori harian dari lemak esensial (1g lemak = 9 kkal)
    return ((dailyCalories * 0.22) / 9.0).round().clamp(30, 120);
  }

  int get dailyCarbs {
    // Sisa kalori setelah protein (4 kkal/g) dan lemak (9 kkal/g)
    final calFromProtein = dailyProtein * 4;
    final calFromFat = dailyFat * 9;
    final remainingCal = dailyCalories - calFromProtein - calFromFat;
    return (remainingCal / 4.0).round().clamp(80, 500);
  }

  int get dailyWaterMl {
    int extra = activityLevel == 'active' ? 600 : 400;
    return (weightKg * 35 + extra).round().clamp(2000, 4500);
  }

  // Rekomendasi porsi 1 kali makan (1/3 dari target harian)
  int get mealTargetCalories => (dailyCalories / 3.0).round();
  int get mealTargetProtein => (dailyProtein / 3.0).round();
  int get mealTargetCarbs => (dailyCarbs / 3.0).round();

  void updateBodyProfile(double weight, double height) {
    weightKg = weight;
    heightCm = height;
    unawaited(save());
  }

  void updateBiometrics({
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? activity,
    String? goal,
  }) {
    if (weight != null) weightKg = weight;
    if (height != null) heightCm = height;
    if (age != null) userAge = age;
    if (gender != null) userGender = gender;
    if (activity != null) activityLevel = activity;
    if (goal != null) fitnessGoal = goal;
    unawaited(save());
  }

  // ---- Gamifikasi & Leveling Seimbang (Anti-Jumping Bug) ----
  int xp = 150;
  int streak = 7;

  static const List<int> _levelThresholds = [
    0, // Level 1: 0 - 249 XP
    250, // Level 2: 250 - 599 XP
    600, // Level 3: 600 - 1099 XP
    1100, // Level 4: 1100 - 1799 XP
    1800, // Level 5: 1800 - 2699 XP
    2700, // Level 6: 2700 - 3799 XP
    3800, // Level 7: 3800 - 5099 XP
    5100, // Level 8: 5100 - 6599 XP
    6600, // Level 9: 6600 - 8299 XP
    8300, // Level 10: 8300+ XP
  ];

  int get level {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= _levelThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  int get xpForCurrentLevel {
    final lvl = level;
    if (lvl <= 1) return 0;
    return _levelThresholds[(lvl - 1).clamp(0, _levelThresholds.length - 1)];
  }

  int get xpForNextLevel {
    final lvl = level;
    if (lvl >= _levelThresholds.length) {
      return _levelThresholds.last + 1500;
    }
    return _levelThresholds[lvl];
  }

  int get xpInLevel {
    return (xp - xpForCurrentLevel).clamp(0, targetXpInLevel);
  }

  int get targetXpInLevel {
    final diff = xpForNextLevel - xpForCurrentLevel;
    return diff > 0 ? diff : 250;
  }

  double get levelProgress {
    return (xpInLevel / targetXpInLevel).clamp(0.0, 1.0);
  }

  String get levelTitle {
    final l = level;
    if (l <= 1) return 'Pemula Disiplin';
    if (l == 2) return 'Konsisten Kost';
    if (l == 3) return 'Pejuang Nutrisi';
    if (l == 4) return 'Calisthenics Novice';
    if (l == 5) return 'Atlet Kalistenik';
    if (l == 6) return 'Spartan Volta';
    if (l == 7) return 'Master Nutrisi';
    return 'Legenda Volta';
  }

  void addXp(int amount) {
    xp = (xp + amount).clamp(0, 999999);
    recalculateStreak();
    notifyListeners();
    unawaited(save());
  }

  void removeXp(int amount) {
    xp = (xp - amount).clamp(0, 999999);
    notifyListeners();
    unawaited(save());
  }

  /// Hitung ulang streak harian aktif secara dinamis dari aktivitas nyata.
  /// Memeriksa hari-hari berturut-turut di mana user aktif (tuntas tugas,
  /// rutin, makan, air, latihan, atau transaksi).
  int recalculateStreak() {
    final activeDates = <String>{};

    for (final m in routineMarks) {
      if (m.date.length >= 10) activeDates.add(m.date.substring(0, 10));
    }

    eaten.forEach((k, v) {
      if (v == true) {
        final parts = k.split('_');
        if (parts.length >= 4) {
          final y = int.tryParse(parts[1]);
          final m = int.tryParse(parts[2]);
          final d = int.tryParse(parts[3]);
          if (y != null && m != null && d != null) {
            activeDates.add(
              '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
            );
          }
        }
      }
    });

    workoutDone.forEach((k, v) {
      if (v == true) {
        final dStr = k.split('_').first;
        if (dStr.length >= 10) activeDates.add(dStr.substring(0, 10));
      }
    });

    // Aktivitas GPS punya tanggalnya sendiri (workoutDone direset harian).
    for (final a in activities) {
      if (a.earnsXp) activeDates.add(a.date);
    }

    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yestStr = '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    int currentStreak = 0;
    DateTime checkDate;

    if (activeDates.contains(todayStr)) {
      currentStreak++;
      checkDate = yesterday;
    } else if (activeDates.contains(yestStr)) {
      currentStreak++;
      checkDate = yesterday.subtract(const Duration(days: 1));
    } else {
      return streak > 0 ? streak : 1;
    }

    while (true) {
      final dateStr = '${checkDate.year.toString().padLeft(4, '0')}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (activeDates.contains(dateStr)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (currentStreak != streak && currentStreak > 0) {
      streak = currentStreak;
      notifyListeners();
      unawaited(save());
    }
    return streak;
  }

  // ---- Aktivitas GPS (lari / jalan / sepeda) ----

  static String _xpKeyOf(ActivityType t) => 'gps_${t.name}';

  /// Simpan aktivitas selesai. XP diberikan sekali per jenis per hari dan
  /// hanya bila jarak memenuhi ambang minimal (anti-grind). Mengembalikan
  /// XP yang diberikan (0 bila tidak ada).
  Future<int> addActivity(GpsActivity a) async {
    activities
      ..removeWhere((x) => x.id == a.id)
      ..add(a)
      ..sort((x, y) => y.start.compareTo(x.start));
    var gained = 0;
    if (a.earnsXp && a.date == todayKey) {
      if (claimXp(_xpKeyOf(a.type), a.type.xpReward)) gained = a.type.xpReward;
    }
    recalculateStreak();
    notifyListeners();
    await flushNow(); // rekaman GPS tidak bisa diulang: tulis segera
    return gained;
  }

  Future<void> renameActivity(String id, String name) async {
    final i = activities.indexWhere((a) => a.id == id);
    final n = name.trim();
    if (i < 0 || n.isEmpty) return;
    activities[i] = activities[i].rename(n);
    notifyListeners();
    await flushNow();
  }

  /// Hapus aktivitas. Simetris dengan klaim: bila XP jenis ini diklaim
  /// hari ini dan tidak ada aktivitas sah lain hari ini, XP ditarik.
  Future<void> deleteActivity(String id) async {
    final i = activities.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = activities.removeAt(i);
    final key = _xpKeyOf(a.type);
    if (a.date == todayKey && isClaimed(key)) {
      final stillValid = activities.any(
        (x) => x.type == a.type && x.date == todayKey && x.earnsXp,
      );
      if (!stillValid) {
        final amt = xpClaimed.remove(key) ?? 0;
        if (amt > 0) removeXp(amt);
      }
    }
    notifyListeners();
    await flushNow();
  }

  /// Aktivitas minggu berjalan (Senin 00.00 s/d sekarang).
  List<GpsActivity> get activitiesThisWeek {
    final n = DateTime.now();
    final monday = DateTime(n.year, n.month, n.day - (n.weekday - 1));
    return [
      for (final a in activities)
        if (!a.start.isBefore(monday)) a,
    ];
  }

  double get weekActivityMeters =>
      activitiesThisWeek.fold(0.0, (s, a) => s + a.distanceM);

  /// Hari (1=Senin..7=Minggu) minggu ini yang punya aktivitas GPS.
  Set<int> get weekActivityDays => {
    for (final a in activitiesThisWeek) a.start.weekday,
  };

  List<GpsActivity> get activitiesToday => [
    for (final a in activities)
      if (a.date == todayKey) a,
  ];

  // ---- Buku besar XP harian (anti grinding) ----
  /// Kunci tanggal hari ini "yyyy-MM-dd".
  static String get todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Rollover otomatis pukul 00.00: saat tanggal berganti, semua centang
  /// latihan (sesi mingguan, choice plan, guard) dan kuota klaim XP
  /// hari-an dihapus. XP, level & streak TIDAK ikut direset.
  /// Dipanggil saat load + timer 30 dtk di shell agar app yang
  /// dibiarkan terbuka lintas tengah malam ikut tereset tepat waktu.
  /// Mengembalikan true bila terjadi reset.
  bool rolloverIfNewDay() {
    final t = todayKey;
    if (xpDay == t) return false;
    xpDay = t;
    xpClaimed.clear();
    workoutDone.clear();
    todoFiredInApp.clear();
    // Tugas berulang yang terlewat tetap melahirkan jadwal berikutnya,
    // supaya alarm/rutinitas tidak berhenti hanya karena satu hari bolong.
    for (final task in List<SvTask>.of(todos)) {
      if (task.done || task.repeat.isEmpty) continue;
      if (dateOf(task).compareTo(t) >= 0) continue;
      _spawnNextOccurrence(task);
    }
    // Pergantian hari = perubahan penting: tulis langsung (tanpa timer
    // debounce) supaya tidak ada sisa timer & data langsung aman.
    unawaited(flushNow());
    return true;
  }

  /// Klaim XP sekali-klaim per sumber per hari. Bila sumber sama sudah
  /// diklaim hari ini, XP TIDAK ditambahkan dan fungsi mengembalikan
  /// false (UI menampilkan pesan "sudah diklaim, besok tersedia lagi").
  bool claimXp(String source, int amount) {
    rolloverIfNewDay(); // no-op bila buku besar sudah hari ini.
    if (xpClaimed.containsKey(source)) return false;
    xpClaimed[source] = amount;
    addXp(amount);
    return true;
  }

  /// Status sumber XP: true = sudah diklaim hari ini.
  bool isClaimed(String source) {
    if (xpDay != todayKey) return false;
    return xpClaimed.containsKey(source);
  }

  /// Reset total semua data aplikasi kembali ke awal (Fresh Program Start)
  Future<void> resetAllData() async {
    // Data saat ini disalin dulu ke `sv_v1_bak` (aturan 1.1) supaya reset
    // yang tidak disengaja masih punya cadangan.
    await flushNow();
    eatenM.clear();
    boughtM.clear();
    workoutDone.clear();
    activities.clear();
    txns.clear();
    mealNotes.clear();
    customMeals.clear();
    piano.clear();
    xp = 0;
    streak = 1;
    budget = 750000;
    income = 900000;
    bumbuStock = false;
    bumbuBeras = false;
    bumbuFin = false;
    berasFin = false;
    bumbuTxnId = -1;
    berasTxnId = -1;
    xpDay = '';
    xpClaimed.clear();
    todos = [];
    routineMarks = [];
    // Buang juga jadwal notifikasi to-do yang tersimpan di OS.
    unawaited(TodoNotif.cancelAll());
    final p = await SharedPreferences.getInstance();
    await p.remove(prefKey);
    customAlarmName = '';
    await AlarmAudio.clearCustom();
    notifyListeners();
  }

  // ---- kalender: bulan tampil (default = bulan berjalan) ----
  // Format kunci bulan: "yyyy-MM" (mis. "2026-10").
  int calYear = DateTime.now().year;
  int calMonth = DateTime.now().month;
  String get selKey => '$calYear-${calMonth.toString().padLeft(2, '0')}';
  static String keyOf(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  /// Jumlah hari bulan tampil (kabisat otomatis via DateTime).
  int daysInSelMonth() => DateTime(calYear, calMonth + 1, 0).day;
  static int daysIn(int y, int m) => DateTime(y, m + 1, 0).day;

  /// Total slot makan bulan tampil (3/hari; tgl 31 ikut dihitung bila ada).
  int monthMealTotal() => daysInSelMonth() * 3;

  void goMonth(int y, int m) {
    var yy = y, mm = m;
    while (mm < 1) {
      mm += 12;
      yy--;
    }
    while (mm > 12) {
      mm -= 12;
      yy++;
    }
    calYear = yy;
    calMonth = mm;
    unawaited(save());
  }

  void goToday() {
    final n = DateTime.now();
    calYear = n.year;
    calMonth = n.month;
    unawaited(save());
  }

  // ---- tracking per-bulan: tiap tanggal 1 = lembaran baru ----
  // Bucket "yyyy-MM" -> Map key makan/beli format lama (e{h}-{m}, b{id}).
  Map<String, Map<String, bool>> eatenM = {};
  Map<String, Map<String, bool>> boughtM = {};

  /// Proksi bucket bulan tampil — semua kode lama (eatIn, sheets, kartu,
  /// test format e{h}-{m}) tetap jalan tanpa berubah.
  Map<String, bool> get eaten => eatenM.putIfAbsent(selKey, () => {});
  Map<String, bool> get bought => boughtM.putIfAbsent(selKey, () => {});

  // ---------------------------------------------------------------
  // PERSISTENSI (Fase 1 — data aman)
  //   sv_v1                  : data utama
  //   sv_v1_bak              : cadangan, ditulis SEBELUM data utama
  //   sv_v1_corrupt_<tgl>    : salinan data yang gagal di-parse
  // ---------------------------------------------------------------
  static const String prefKey = 'sv_v1';
  static const String prefKeyBak = 'sv_v1_bak';
  static const String corruptPrefix = 'sv_v1_corrupt_';

  Timer? _saveDebounce;
  bool _writing = false;
  final List<Completer<void>> _writeWaiters = <Completer<void>>[];
  Object? lastSaveError;

  /// Saat true, penulisan hanya menyentuh `sv_v1` dan membiarkan
  /// `sv_v1_bak` berisi data SEBELUM impor (aturan 1.1).
  bool _preserveBackup = false;

  /// Terisi bila `load()` menemukan data rusak. UI membacanya sekali untuk
  /// menampilkan dialog, lalu mengosongkannya (lihat `shell.dart`).
  LoadRecovery? loadRecovery;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    loadRecovery = null;
    final raw = p.getString(prefKey);
    if (raw == null) {
      // Instalasi baru: seed tugas contoh + aktifkan buku besar hari ini.
      todos = defaultTodos();
      rolloverIfNewDay();
      await flushNow(); // instalasi baru: tulis segera
      return;
    }
    try {
      await _applyJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, s) {
      // JANGAN telan diam-diam: simpan salinan rusak, coba `sv_v1_bak`,
      // lalu beri tahu pengguna lewat dialog.
      await _recoverFromCorrupt(p, raw, e, s);
    }
  }

  /// Pulihkan dari `sv_v1_bak` setelah `sv_v1` gagal di-parse.
  Future<void> _recoverFromCorrupt(
    SharedPreferences p,
    String raw,
    Object error,
    StackTrace stack,
  ) async {
    debugPrint('[AppState] sv_v1 rusak: $error\n$stack');
    var corruptKey = '$corruptPrefix$todayKey';
    if (p.containsKey(corruptKey)) {
      corruptKey =
          '$corruptPrefix${todayKey}_${DateTime.now().millisecondsSinceEpoch}';
    }
    await p.setString(corruptKey, raw);
    var recovered = false;
    String? backupError;
    _clearAllData(); // jangan biarkan state lama tercampur hasil pemulihan
    final bak = p.getString(prefKeyBak);
    if (bak != null) {
      try {
        await _applyJson(jsonDecode(bak) as Map<String, dynamic>);
        recovered = true;
        debugPrint('[AppState] dipulihkan dari sv_v1_bak');
      } catch (e2) {
        backupError = e2.toString();
        debugPrint('[AppState] sv_v1_bak juga rusak: $e2');
        _clearAllData();
      }
    }
    loadRecovery = LoadRecovery(
      corruptKey: corruptKey,
      recoveredFromBackup: recovered,
      error: error.toString(),
      backupError: backupError,
    );
    await flushNow();
  }

  /// Kosongkan state di memori ke kondisi awal (TIDAK menyentuh disk).
  void _clearAllData() {
    eatenM.clear();
    boughtM.clear();
    workoutDone.clear();
    activities.clear();
    txns.clear();
    mealNotes.clear();
    customMeals.clear();
    combos.clear();
    piano.clear();
    todos.clear();
    routineMarks.clear();
    xpClaimed.clear();
    todoFiredInApp.clear();
    budget = 750000;
    income = 900000;
    bumbuStock = false;
    bumbuBeras = false;
    bumbuFin = false;
    berasFin = false;
    bumbuTxnId = -1;
    berasTxnId = -1;
    xp = 0;
    streak = 0;
    xpDay = '';
    weightKg = 62.0;
    heightCm = 170.0;
    userAge = 21;
    userGender = 'pria';
    activityLevel = 'moderate';
    fitnessGoal = 'muscle_gain';
    workoutReminderOn = true;
    workoutReminderDays = {1, 3, 5};
    workoutReminderMin = 16 * 60 + 30;
    notifSound = 'sistem';
    notifVibrate = true;
    customAlarmName = '';
    studySubjects = [];
    studySessions = [];
    final now = DateTime.now();
    calYear = now.year;
    calMonth = now.month;
  }

  /// Terapkan isi JSON ke state. Body migrasi lama dipertahankan apa
  /// adanya; hanya dipindah ke fungsi agar bisa dipakai ulang saat
  /// pemulihan dari cadangan dan saat impor.
  Future<void> _applyJson(Map<String, dynamic> j) async {
    final now = DateTime.now();
    calYear = j['calYear'] as int? ?? now.year;
    calMonth = j['calMonth'] as int? ?? now.month;
    final cur = keyOf(calYear, calMonth);
    // Format baru: bucket per-bulan.
    final em = j['eatenM'];
    if (em is Map && em.isNotEmpty) {
      em.forEach((k, v) {
        eatenM[k.toString()] = _mb(v);
      });
    } else {
      // Migrasi: map datar lama -> bulan tampil (data tidak hilang).
      final legacy = _mb(j['eaten']);
      legacy.removeWhere((k, _) => !RegExp(r'^e\d+-[123]$').hasMatch(k));
      if (legacy.isNotEmpty) eatenM[cur] = legacy;
    }
    final bm = j['boughtM'];
    if (bm is Map && bm.isNotEmpty) {
      bm.forEach((k, v) {
        boughtM[k.toString()] = _mb(v);
      });
    } else {
      final legacy = _mb(j['bought']);
      if (legacy.isNotEmpty) boughtM[cur] = legacy;
    }
    workoutDone = _mb(j['workout']);
    activities = [
      for (final e in (j['activities'] as List? ?? const []))
        if (e is Map<String, dynamic>) ?GpsActivity.fromJson(e),
    ]..sort((a, b) => b.start.compareTo(a.start));
    budget = j['budget'] as int? ?? 750000;
    income = j['income'] as int? ?? 900000;
    weightKg = (j['weightKg'] as num?)?.toDouble() ?? 62.0;
    heightCm = (j['heightCm'] as num?)?.toDouble() ?? 170.0;
    userAge = j['userAge'] as int? ?? 21;
    userGender = j['userGender'] as String? ?? 'pria';
    activityLevel = j['activityLevel'] as String? ?? 'moderate';
    fitnessGoal = j['fitnessGoal'] as String? ?? 'muscle_gain';
    workoutReminderOn = j['workoutReminderOn'] as bool? ?? true;
    workoutReminderMin = (j['workoutReminderMin'] as int?) ?? (16 * 60 + 30);
    final wdRaw = j['workoutReminderDays'];
    if (wdRaw is List) {
      final wd = <int>{
        for (final e in wdRaw)
          if (e is int && e >= DateTime.monday && e <= DateTime.sunday) e,
      };
      if (wd.isNotEmpty) workoutReminderDays = wd;
    }
    final ns = j['notifSound'] as String?;
    if (ns != null && notifSounds.contains(ns)) notifSound = ns;
    notifVibrate = j['notifVibrate'] as bool? ?? true;
    customAlarmName = (j['customAlarmName'] as String? ?? '').trim();
    TodoNotif.configure(sound: notifSound, vibrate: notifVibrate);
    studySubjects = (j['studySubjects'] as List? ?? [])
        .map((e) => StudySubject.fromJson(e as Map<String, dynamic>))
        .where((s) => s.name.isNotEmpty)
        .toList();
    studySessions = (j['studySessions'] as List? ?? [])
        .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
        .where((s) => s.minutes > 0 && s.date.isNotEmpty)
        .toList();
    xp = j['xp'] as int? ?? 150;
    streak = j['streak'] as int? ?? 7;
    txns = (j['txns'] as List? ?? [])
        .map((e) => Txn.fromJson(e as Map<String, dynamic>))
        .toList();
    mealNotes = (j['mealNotes'] as List? ?? [])
        .map((e) => MealNote.fromJson(e as Map<String, dynamic>))
        .toList();
    customMeals = (j['customMeals'] as List? ?? [])
        .map((e) => CustomMeal.fromJson(e as Map<String, dynamic>))
        .toList();
    // Migrasi: txn tanpa bulan -> bulan tampil.
    for (var i = 0; i < txns.length; i++) {
      if (txns[i].bln.isEmpty) {
        final t = txns[i];
        txns[i] = Txn(t.id, t.hari, t.ket, t.jml, t.kat, bln: cur);
      }
    }
    combos = (j['combos'] as List? ?? [])
        .map((e) => Combo.fromJson(e as Map<String, dynamic>))
        .toList();
    if (combos.isEmpty) combos = List.of(DEFAULT_COMBOS);
    piano = (j['piano'] as List? ?? [])
        .map((e) => PianoDep.fromJson(e as Map<String, dynamic>))
        .toList();
    final bu = (j['bumbu'] as Map<String, dynamic>?) ?? {};
    bumbuStock = bu['stock'] as bool? ?? false;
    bumbuBeras = bu['beras'] as bool? ?? false;
    bumbuFin = bu['fin'] as bool? ?? false;
    berasFin = bu['berasFin'] as bool? ?? false;
    bumbuTxnId = bu['bumbuTxnId'] as int? ?? -1;
    berasTxnId = bu['berasTxnId'] as int? ?? -1;
    // Buku besar XP harian.
    xpDay = j['xpDay'] as String? ?? '';
    final xc = j['xpClaimed'];
    if (xc is Map) {
      xc.forEach((k, v) => xpClaimed[k.toString()] = v is int ? v : 0);
    }
    // To-Do: key 'todos' absen = instalasi baru sekali seed;
    // key ada (meski list kosong) = ikuti pilihan user.
    if (j.containsKey('todos')) {
      todos = (j['todos'] as List? ?? [])
          .map((e) => SvTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      todos = defaultTodos();
    }
    routineMarks = (j['routineMarks'] as List? ?? [])
        .map((e) => RoutineMark.fromJson(e as Map<String, dynamic>))
        .where((m) => m.date.isNotEmpty)
        .toList();
    // Rolover tengah malam: data lama lintas hari dibersihkan saat load.
    rolloverIfNewDay();
    // Self-healing: flag yatim (tercatat-beli tapi record hilang,
    // mis. data lama sebelum pelacakan id) diperbaiki saat load.
    var repaired = false;
    repaired = _repairOne(true) || repaired;
    repaired = _repairOne(false) || repaired;
    if (repaired) await flushNow(); // perbaikan data: tulis segera
  }

  static Map<String, bool> _mb(dynamic v) {
    final out = <String, bool>{};
    if (v is Map) {
      v.forEach((k, val) => out[k.toString()] = val == true);
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
    'calYear': calYear,
    'calMonth': calMonth,
    'eatenM': eatenM,
    'boughtM': boughtM,
    'workout': workoutDone,
    'activities': activities.map((a) => a.toJson()).toList(),
    'txns': txns.map((t) => t.toJson()).toList(),
    'mealNotes': mealNotes.map((n) => n.toJson()).toList(),
    'customMeals': customMeals.map((m) => m.toJson()).toList(),
    'budget': budget,
    'income': income,
    'combos': combos.map((c) => c.toJson()).toList(),
    'piano': piano.map((d) => d.toJson()).toList(),
    'bumbu': {
      'stock': bumbuStock,
      'beras': bumbuBeras,
      'fin': bumbuFin,
      'berasFin': berasFin,
      'bumbuTxnId': bumbuTxnId,
      'berasTxnId': berasTxnId,
    },
    'weightKg': weightKg,
    'heightCm': heightCm,
    'xpDay': xpDay,
    'xpClaimed': xpClaimed,
    'todos': todos.map((t) => t.toJson()).toList(),
    'routineMarks': routineMarks.map((m) => m.toJson()).toList(),
    'userAge': userAge,
    'userGender': userGender,
    'activityLevel': activityLevel,
    'fitnessGoal': fitnessGoal,
    'workoutReminderOn': workoutReminderOn,
    'workoutReminderDays': (workoutReminderDays.toList()..sort()),
    'workoutReminderMin': workoutReminderMin,
    'notifSound': notifSound,
    'notifVibrate': notifVibrate,
    'customAlarmName': customAlarmName,
    'studySubjects': studySubjects.map((s) => s.toJson()).toList(),
    'studySessions': studySessions.map((s) => s.toJson()).toList(),
    'xp': xp,
    'streak': streak,
  };

  /// Simpan dengan **debounce 300 ms**. Aman dipanggil berulang tanpa
  /// `await`; Future yang dikembalikan tetap selesai setelah data BENAR-
  /// BENAR tertulis ke disk, jadi `await save()` di titik penting sah.
  Future<void> save() {
    _saveDebounce?.cancel();
    final completer = Completer<void>();
    _writeWaiters.add(completer);
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      _saveDebounce = null;
      unawaited(_drainWrites());
    });
    return completer.future;
  }

  /// Tulis **sekarang** tanpa menunggu debounce. Wajib di-`await` untuk
  /// data yang tidak boleh hilang: transaksi keuangan, reset, impor.
  Future<void> flushNow() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    final completer = Completer<void>();
    _writeWaiters.add(completer);
    unawaited(_drainWrites());
    return completer.future;
  }

  /// Antrean tulis serial: selama satu penulisan berjalan, permintaan
  /// berikutnya menunggu (tidak ada dua tulis bersamaan). Setiap permintaan
  /// memakai Completer miliknya sendiri supaya `await` selalu selesai di
  /// zona pemanggil (lihat catatan di `test/data_safety_test.dart`).
  Future<void> _drainWrites() async {
    if (_writing) return; // penulisan yang berjalan akan mengambil waiter ini
    _writing = true;
    try {
      while (_writeWaiters.isNotEmpty) {
        final batch = List<Completer<void>>.of(_writeWaiters);
        _writeWaiters.clear();
        try {
          await _writeToDisk();
        } catch (e, s) {
          // Jangan biarkan pemanggil menggantung: catat error, lanjutkan.
          lastSaveError = e;
          debugPrint('[AppState] gagal menulis sv_v1: $e\n$s');
        }
        for (final c in batch) {
          if (!c.isCompleted) c.complete();
        }
      }
    } finally {
      _writing = false;
      if (_writeWaiters.isNotEmpty) unawaited(_drainWrites());
    }
  }

  Future<void> _writeToDisk() async {
    final p = await SharedPreferences.getInstance();
    final json = jsonEncode(toJson());
    // Cadangan DULU, baru data utama: bila proses mati di tengah tulis,
    // `sv_v1` lama tetap utuh dan `sv_v1_bak` sudah berisi state terbaru.
    // Pengecualian: selama impor, `sv_v1_bak` sengaja dibiarkan berisi
    // data SEBELUM impor agar penimpaan masih bisa dibatalkan.
    if (!_preserveBackup) {
      await p.setString(prefKeyBak, json);
    }
    await p.setString(prefKey, json);
    lastSaveError = null;
    notifyListeners();
  }

  /// JSON lengkap untuk diekspor ke file (format sama dengan `sv_v1`).
  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Impor data hasil ekspor. Data LAMA dicadangkan ke `sv_v1_bak`
  /// sebelum ditimpa. Melempar error bila JSON tidak bisa diterapkan.
  Future<void> importJson(Map<String, dynamic> j) async {
    // 1) Pastikan state sekarang tertulis + tersalin ke `sv_v1_bak`.
    await flushNow();
    // 2) Terapkan secara transaksional: bila file ternyata tidak cocok,
    //    state lama dikembalikan utuh (tidak ada data yang hilang).
    //    Selama proses ini `sv_v1_bak` tidak boleh tertimpa data baru.
    // Salinan DALAM (deep copy): `toJson()` memakai referensi map yang sama,
    // jadi tanpa encode/decode snapshot ikut kosong saat `_clearAllData()`.
    final snapshot = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    _preserveBackup = true;
    try {
      _clearAllData();
      await _applyJson(j);
    } catch (e) {
      debugPrint('[AppState] impor gagal, rollback: $e');
      _preserveBackup = false;
      _clearAllData();
      await _applyJson(snapshot);
      await flushNow(); // tulis ulang data lama ke disk
      rethrow;
    }
    // 3) Tulis hasil impor. `sv_v1_bak` tetap = data sebelum impor.
    await flushNow();
    _preserveBackup = false;
    // Jadwal notifikasi milik data LAMA sudah tidak relevan: buang lalu
    // jadwalkan ulang dari data hasil impor (to-do + pengingat latihan).
    await resyncNotifications();
  }

  /// Impor mode **GABUNG**: daftar digabung tanpa duplikat, peta harian
  /// (makan/olahraga) digabung, sedangkan nilai tunggal (XP, streak, budget,
  /// pemasukan, profil, bulan tampil, status bumbu) tetap milik data app.
  /// XP/streak TIDAK dijumlahkan supaya tidak dobel.
  /// Data lama tetap dicadangkan ke `sv_v1_bak` seperti mode timpa.
  Future<void> mergeJson(Map<String, dynamic> j) async {
    await flushNow(); // `sv_v1_bak` = kondisi sebelum penggabungan
    final snapshot = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    _preserveBackup = true;
    try {
      _mergeFrom(j);
    } catch (e) {
      debugPrint('[AppState] gabung gagal, rollback: $e');
      _preserveBackup = false;
      _clearAllData();
      await _applyJson(snapshot);
      await flushNow();
      rethrow;
    }
    await flushNow(); // tulis hasil gabung; `sv_v1_bak` tetap data lama
    _preserveBackup = false;
    await resyncNotifications();
  }

  static int _maxInt(Iterable<int> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

  /// Gabungkan isi file ke state saat ini (tanpa menghapus apa pun).
  void _mergeFrom(Map<String, dynamic> j) {
    // ---- transaksi keuangan ----
    final seenTxn = <String>{
      for (final t in txns) '${t.bln}|${t.hari}|${t.ket}|${t.jml}|${t.kat}',
    };
    var nextTxnId = _maxInt(txns.map((t) => t.id)) + 1;
    for (final e in (j['txns'] as List? ?? const [])) {
      final t = Txn.fromJson(e as Map<String, dynamic>);
      final bln = t.bln.isEmpty ? selKey : t.bln;
      if (!seenTxn.add('$bln|${t.hari}|${t.ket}|${t.jml}|${t.kat}')) continue;
      txns.add(Txn(nextTxnId++, t.hari, t.ket, t.jml, t.kat, bln: bln));
    }

    // ---- catatan makan ----
    final seenNote = <String>{
      for (final n in mealNotes) '${n.bln}|${n.hari}|${n.text}',
    };
    var nextNoteId = _maxInt(mealNotes.map((n) => n.id)) + 1;
    for (final e in (j['mealNotes'] as List? ?? const [])) {
      final n = MealNote.fromJson(e as Map<String, dynamic>);
      final bln = n.bln.isEmpty ? selKey : n.bln;
      if (!seenNote.add('$bln|${n.hari}|${n.text}')) continue;
      mealNotes.add(MealNote(nextNoteId++, n.hari, bln, n.text));
    }

    // ---- menu kustom (id string unik) ----
    final mealIds = <String>{for (final m in customMeals) m.id};
    for (final e in (j['customMeals'] as List? ?? const [])) {
      final m = CustomMeal.fromJson(e as Map<String, dynamic>);
      if (!mealIds.add(m.id)) continue;
      customMeals.add(m);
    }

    // ---- tabungan piano (id unik) ----
    final pianoIds = <int>{for (final d in piano) d.id};
    for (final e in (j['piano'] as List? ?? const [])) {
      final d = PianoDep.fromJson(e as Map<String, dynamic>);
      if (!pianoIds.add(d.id)) continue;
      piano.add(d);
    }

    // ---- to-do (dedupe isi; id boleh bentrok karena dibuat ulang) ----
    final seenTodo = <String>{
      for (final t in todos) '${t.title}|${t.date}|${t.timeMin}|${t.cat}',
    };
    var nextTodoId = _maxInt(todos.map((t) => t.id)) + 1;
    for (final e in (j['todos'] as List? ?? const [])) {
      final t = SvTask.fromJson(e as Map<String, dynamic>);
      if (!seenTodo.add('${t.title}|${t.date}|${t.timeMin}|${t.cat}')) continue;
      todos.add(t.copyWith(id: nextTodoId++));
    }

    // ---- tracker rutinitas: gabung berdasarkan tanggal + judul ----
    final seenRoutine = <String>{
      for (final m in routineMarks) '${m.date}|${m.title}',
    };
    for (final e in (j['routineMarks'] as List? ?? const [])) {
      final m = RoutineMark.fromJson(e as Map<String, dynamic>);
      if (m.date.isEmpty || !seenRoutine.add('${m.date}|${m.title}')) continue;
      routineMarks.add(m);
    }

    // ---- peta harian: gabung, true menang ----
    void mergeMap(dynamic src, Map<String, bool> dst) {
      if (src is! Map) return;
      src.forEach((k, v) {
        final key = k.toString();
        if (v == true || !dst.containsKey(key)) dst[key] = v == true;
      });
    }

    final em = j['eatenM'];
    if (em is Map && em.isNotEmpty) {
      em.forEach((k, v) {
        final bucket = eatenM.putIfAbsent(k.toString(), () => <String, bool>{});
        mergeMap(v, bucket);
      });
    }
    final bm = j['boughtM'];
    if (bm is Map && bm.isNotEmpty) {
      bm.forEach((k, v) {
        final bucket = boughtM.putIfAbsent(
          k.toString(),
          () => <String, bool>{},
        );
        mergeMap(v, bucket);
      });
    }
    mergeMap(j['workout'], workoutDone);

    // ---- aktivitas GPS (id unik) ----
    final actIds = <String>{for (final a in activities) a.id};
    for (final e in (j['activities'] as List? ?? const [])) {
      if (e is! Map<String, dynamic>) continue;
      final a = GpsActivity.fromJson(e);
      if (a == null || !actIds.add(a.id)) continue;
      activities.add(a);
    }
    activities.sort((a, b) => b.start.compareTo(a.start));

    // ---- buku besar XP: simpan nilai terbesar per sumber ----
    final xc = j['xpClaimed'];
    if (xc is Map) {
      xc.forEach((k, v) {
        final key = k.toString();
        final val = v is int ? v : 0;
        final cur = xpClaimed[key] ?? 0;
        if (!xpClaimed.containsKey(key) || val > cur) xpClaimed[key] = val;
      });
    }
    // Nilai tunggal lain (xp, streak, budget, income, profil, bulan tampil,
    // status bumbu, combos) sengaja TIDAK diubah: data app yang menang.
  }

  // ---- meal ----
  int get eatenCount => eaten.length;
  int get boughtCount => bought.length;
  int eatIn(int paketIndex) {
    final h1 = paketIndex * 2 + 1, h2 = h1 + 1;
    var c = 0;
    for (var h = h1; h <= h2; h++) {
      for (var m = 1; m <= 3; m++) {
        if (eaten['e$h-$m'] == true) c++;
      }
    }
    return c;
  }

  /// Centang 1 tanggal kalender (0..3) di bulan tampil.
  int eatDay(int d) {
    var c = 0;
    for (var m = 1; m <= 3; m++) {
      if (eaten['e$d-$m'] == true) c++;
    }
    return c;
  }

  void addCustomMeal(CustomMeal meal) {
    customMeals.add(meal);
    unawaited(save());
    notifyListeners();
  }

  void deleteCustomMeal(String id) {
    customMeals.removeWhere((m) => m.id == id);
    unawaited(save());
    notifyListeners();
  }

  void toggleEat(String key) {
    eaten[key] = !(eaten[key] ?? false);
    if (eaten[key] == false) eaten.remove(key);
    unawaited(save());
  }

  void toggleBought(String key) {
    bought[key] = !(bought[key] ?? false);
    if (bought[key] == false) bought.remove(key);
    unawaited(save());
  }

  // ---- workout ----
  void toggleWork(String key) {
    workoutDone[key] = !(workoutDone[key] ?? false);
    if (workoutDone[key] == false) workoutDone.remove(key);
    unawaited(save());
  }

  /// Hapus semua centang latihan (fitur "Hapus Progres"). Idealnya
  /// terjadi otomatis saat rollover 00.00; permintaan manual TIDAK
  /// membuka kuota klaim XP harian (buku besar `xpClaimed` utuh).
  Future<void> resetWorkout() async {
    workoutDone.clear();
    await flushNow();
  }

  // ---- finance (total all-time; grid/grafik/tabel ikut bulan tampil) ----
  // kat 'masuk' = pemasukan (tidak dihitung sebagai pengeluaran).
  int get totalOut =>
      txns.where((t) => t.kat != 'masuk').fold(0, (a, t) => a + t.jml);
  int get totalIn =>
      txns.where((t) => t.kat == 'masuk').fold(0, (a, t) => a + t.jml);
  int txnByDay(int h) => txns
      .where((t) => t.bln == selKey && t.hari == h && t.kat != 'masuk')
      .fold(0, (a, t) => a + t.jml);
  int txnInByDay(int h) => txns
      .where((t) => t.bln == selKey && t.hari == h && t.kat == 'masuk')
      .fold(0, (a, t) => a + t.jml);
  List<Txn> get txnsSel => txns.where((t) => t.bln == selKey).toList();
  int get sisa => income + totalIn - totalOut;
  int get sisaBudget => budget - totalOut;

  /// Mengembalikan id Txn yang dibuat (untuk pelacakan, mis. pembelian bumbu).
  Future<int> addTxn(
    String ket,
    int jml, {
    int hari = 1,
    String kat = 'protein',
    bool notify = true,
    String? bln,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    txns.insert(0, Txn(id, hari, ket, jml, kat, bln: bln ?? selKey));
    await flushNow(); // transaksi keuangan: tulis segera, jangan ditunda
    return id;
  }

  /// Hapus Txn + sinkronkan state yang bergantung padanya (anti ORPHAN_LATCH).
  Future<void> delTxn(int id) async {
    txns.removeWhere((t) => t.id == id);
    if (id == bumbuTxnId && bumbuTxnId != -1) {
      bumbuTxnId = -1;
      bumbuFin = false;
      bumbuStock = false;
    }
    if (id == berasTxnId && berasTxnId != -1) {
      berasTxnId = -1;
      berasFin = false;
      bumbuBeras = false;
    }
    await flushNow();
  }

  Future<void> clearTxns() async {
    txns.clear();
    // Hapus semua = semua status pembelian ikut reset (anti ORPHAN_LATCH).
    bumbuStock = false;
    bumbuBeras = false;
    bumbuFin = false;
    berasFin = false;
    bumbuTxnId = -1;
    berasTxnId = -1;
    await flushNow();
  }

  // ---- catatan menu luar template (opsional, boleh >3 per hari) ----
  List<MealNote> notesByDay(int h) =>
      mealNotes.where((n) => n.bln == selKey && n.hari == h).toList();

  Future<void> addNote(int hari, String text) async {
    final t = text.trim();
    if (t.isEmpty || hari < 1) return;
    mealNotes.add(
      MealNote(DateTime.now().millisecondsSinceEpoch, hari, selKey, t),
    );
    await save();
  }

  Future<void> delNote(int id) async {
    mealNotes.removeWhere((n) => n.id == id);
    await save();
  }

  // ---- booster harian per tanggal (opsional) ----
  bool hasBoosterDay(int h) => txns.any(
    (t) =>
        t.bln == selKey &&
        t.hari == h &&
        t.kat == 'protein' &&
        t.ket.startsWith('Booster harian'),
  );

  Future<void> toggleBoosterDay(int h) async {
    final i = txns.indexWhere(
      (t) =>
          t.bln == selKey &&
          t.hari == h &&
          t.kat == 'protein' &&
          t.ket.startsWith('Booster harian'),
    );
    if (i >= 0) {
      txns.removeAt(i);
      await flushNow();
    } else {
      await addTxn(
        'Booster harian (±Rp10.900)',
        10900,
        hari: h,
        kat: 'protein',
      );
    }
  }

  // ---- bumbu ----
  /// Bulan ("yyyy-MM") tempat Txn id tercatat, null bila tidak ada.
  String? monthOfTxn(int id) {
    if (id == -1) return null;
    for (final t in txns) {
      if (t.id == id) return t.bln.isEmpty ? null : t.bln;
    }
    return null;
  }

  /// Perbaikan yatim: fin=true tapi record hilang. Coba adopsi record
  /// lama berdasar keterangan; bila tak ada, reset ke belum-beli.
  /// Mengembalikan true bila ada yang berubah. [isBumbu]=true untuk bumbu.
  bool _repairOne(bool isBumbu) {
    final fin = isBumbu ? bumbuFin : berasFin;
    if (!fin) return false;
    var id = isBumbu ? bumbuTxnId : berasTxnId;
    if (id != -1 && txns.any((t) => t.id == id)) return false;
    final ket = isBumbu ? 'Stok bumbu lengkap' : 'Beras 10kg tambahan';
    Txn? found;
    for (final t in txns) {
      if (t.ket.startsWith(ket)) {
        found = t;
        break;
      }
    }
    if (found != null) {
      if (isBumbu) {
        bumbuTxnId = found.id;
      } else {
        berasTxnId = found.id;
      }
      return true;
    }
    if (isBumbu) {
      bumbuTxnId = -1;
      bumbuFin = false;
      bumbuStock = false;
    } else {
      berasTxnId = -1;
      berasFin = false;
      bumbuBeras = false;
    }
    return true;
  }

  /// Dipanggil tombol "+" sebelum lompat ke Keuangan: pastikan record ada,
  /// bila yatim perbaiki dulu. Mengembalikan bulan record atau null.
  Future<String?> resolveBumbuMonth(bool isBumbu) async {
    _repairOne(isBumbu);
    final id = isBumbu ? bumbuTxnId : berasTxnId;
    final m = monthOfTxn(id);
    await save();
    return m;
  }

  Future<void> buyBumbu() async {
    bumbuStock = true;
    if (!bumbuFin) {
      bumbuFin = true;
      bumbuTxnId = await addTxn(
        'Stok bumbu lengkap (garam+gula+bawang)',
        31000,
        kat: 'lain',
      );
      return;
    }
    await save();
  }

  Future<void> buyBeras() async {
    bumbuBeras = true;
    if (!berasFin) {
      berasFin = true;
      berasTxnId = await addTxn(
        'Beras 10kg tambahan',
        150000,
        hari: 11,
        kat: 'lain',
      );
      return;
    }
    await save();
  }

  // ---- piano ----
  int get pianoTotal => piano.fold(0, (a, d) => a + d.amt);

  Future<void> addSaving(int week, int amt) async {
    piano.add(
      PianoDep(
        DateTime.now().millisecondsSinceEpoch,
        week,
        amt,
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
      ),
    );
    await flushNow();
  }

  Future<void> takeFromSisa() async {
    final left = sisa;
    if (left < 75000) return;
    final a = (left ~/ 4).clamp(75000, 120000);
    piano.add(
      PianoDep(
        DateTime.now().millisecondsSinceEpoch + 1,
        piano.length + 1,
        a,
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} (dari sisa)',
      ),
    );
    await addTxn('Dialihkan ke tabungan piano', a, hari: 1, kat: 'lain');
  }

  Future<void> delSaving(int id) async {
    piano.removeWhere((d) => d.id == id);
    await flushNow();
  }

  // ---- To-Do Harian (port aplikasi web "Hari") ----
  // XP tuntas lewat buku besar `todo_<id>_<tanggal>`: centang = +xp,
  // batal = mengembalikan xp hari itu; klaim tidak bisa digandakan.

  static String _dKey(DateTime n) =>
      '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';

  /// Tanggal efektif tugas (tanpa tanggal = hari ini).
  String dateOf(SvTask t) => t.date.isEmpty ? todayKey : t.date;

  /// Tugas aktif (belum selesai) untuk tanggal tertentu, terurut:
  /// berjam dulu, tanpa jam di belakangan, lalu prioritas tertinggi.
  List<SvTask> todosForDate(String key) {
    final l = todos.where((t) => !t.done && dateOf(t) == key).toList()
      ..sort((a, b) {
        final ta = a.timeMin < 0 ? 1 : 0, tb = b.timeMin < 0 ? 1 : 0;
        if (ta != tb) return ta - tb;
        if (a.timeMin != b.timeMin) return a.timeMin - b.timeMin;
        return b.pri - a.pri;
      });
    return l;
  }

  List<SvTask> get todosOpenToday => todosForDate(todayKey);

  /// 3 tugas paling depan untuk kartu dashboard.
  List<SvTask> get todosNextToday => todosOpenToday.take(3).toList();

  /// Selesai hari ini (untuk ring & kartu dashboard).
  List<SvTask> get todosDoneToday =>
      todos.where((t) => t.done && t.doneAt == todayKey).toList();

  /// Tembakan-banner-in-app per tugas+jam (setiap sesi; dihapus saat
  /// rollover tengah malam). Notifikasi sistem adalah jalur utama;
  /// banner hanya fallback bila plugin/izin tidak tersedia.
  final Set<String> todoFiredInApp = {};

  /// Tugas ber-pengingat yang jatuh tempo sekarang dan belum ditampilkan
  /// sebagai banner in-app pada jam ini. Menandai sekaligus getter.
  SvTask? popDueTodoReminder() {
    final n = DateTime.now();
    final nowMin = n.hour * 60 + n.minute;
    for (final t in todosOpenToday) {
      if (!t.reminder || t.timeMin < 0 || t.timeMin > nowMin) continue;
      final key = 'todo_${t.id}-${t.timeMin}';
      if (todoFiredInApp.contains(key)) continue;
      todoFiredInApp.add(key);
      return t;
    }
    return null;
  }

  /// Kirim sinkronisasi jadwal OS (fire-and-forget).
  void _syncNotif(SvTask t) {
    unawaited(
      TodoNotif.sync(
        id: t.id,
        title: t.title,
        note: t.note,
        dateKey: dateOf(t),
        timeMin: t.timeMin,
        reminder: t.reminder,
        done: t.done,
        sound: t.sound,
        alarm: t.alarm,
        repeat: t.repeat,
      ),
    );
  }

  Future<void> addTodo(SvTask t) async {
    todos.add(t);
    await save();
    _syncNotif(t);
  }

  Future<void> updateTodo(SvTask t) async {
    final i = todos.indexWhere((x) => x.id == t.id);
    if (i < 0) return;
    todos[i] = t;
    await save();
    _syncNotif(t);
  }

  Future<void> deleteTodo(int id) async {
    todos.removeWhere((t) => t.id == id);
    await save();
    unawaited(TodoNotif.cancel(id));
  }

  /// Pulihkan hasil undo hapus: kembalikan tugas ke posisi semula.
  Future<void> restoreTodo(int index, SvTask t) async {
    final i = index.clamp(0, todos.length);
    todos.insert(i, t);
    await save();
    _syncNotif(t);
  }

  /// Centang / batalkan tugas. Bonus XP hanya sekali per tugas per hari.
  Future<void> toggleTodo(int id) async {
    final i = todos.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = todos[i];
    if (t.done) {
      todos[i] = t.copyWith(done: false, doneAt: '');
      routineMarks.removeWhere(
        (m) => m.taskId == t.id && m.date == todayKey && m.title == t.title,
      );
      // Batalkan juga salinan berikutnya dari seri yang sama supaya tidak
      // ada dua tugas berulang aktif setelah centang dibatalkan.
      final series = t.seriesId == 0 ? t.id : t.seriesId;
      final removed = <int>{};
      for (final x in todos) {
        if (x.done || x.seriesId != series) continue;
        if (dateOf(x).compareTo(dateOf(t)) <= 0) continue;
        removed.add(x.id);
      }
      todos.removeWhere((x) => removed.contains(x.id));
      for (final rid in removed) {
        unawaited(TodoNotif.cancel(rid));
      }
      final src = 'todo_${t.id}_$todayKey';
      if (xpClaimed.containsKey(src)) {
        xpClaimed.remove(src);
        removeXp(t.xp);
      }
      await save();
    } else {
      todos[i] = t.copyWith(done: true, doneAt: todayKey);
      if (t.xp > 0) claimXp('todo_${t.id}_$todayKey', t.xp);
      if (t.routine) _addRoutineMark(t, todayKey);
      if (t.repeat.isNotEmpty) _spawnNextOccurrence(t);
      await save();
    }
    _syncNotif(todos[i]);
  }

  /// Dipakai layar alarm: tandai tugas tuntas dan pastikan rutinitas tercatat.
  /// Alarm yang diselesaikan selalu masuk tracker bulanan, meskipun switch
  /// "Rutinitas bulanan" di editor sedang dimatikan.
  Future<void> completeTodoFromAlarm(int id) async {
    final i = todos.indexWhere((t) => t.id == id);
    if (i < 0) return;
    if (!todos[i].done) {
      await toggleTodo(id);
    }
    _addRoutineMark(todos[i], todayKey);
    await save();
  }

  void _addRoutineMark(SvTask t, String date) {
    routineMarks.removeWhere(
      (m) => m.date == date && m.taskId == t.id && m.title == t.title,
    );
    routineMarks.add(RoutineMark(date: date, taskId: t.id, title: t.title));
  }

  /// Jumlah hari berbeda yang punya rutinitas tuntas pada bulan `yyyy-MM`.
  int routineDaysIn(String monthKey) => routineMarks
      .where((m) => m.date.startsWith(monthKey))
      .map((m) => m.date)
      .toSet()
      .length;

  List<RoutineMark> routineMarksIn(String monthKey) {
    final l = routineMarks.where((m) => m.date.startsWith(monthKey)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  /// Tanggal berikutnya untuk tugas berulang (selalu setelah hari ini).
  DateTime? _nextRepeatDate(SvTask t) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    var base = DateTime.tryParse(dateOf(t)) ?? start;
    if (base.isBefore(start)) base = start;
    switch (t.repeat) {
      case 'harian':
        base = base.add(const Duration(days: 1));
      case 'mingguan':
        base = base.add(const Duration(days: 7));
      case 'bulanan':
        final y = base.year;
        final m = base.month + 1;
        final last = DateTime(y, m + 1, 0).day;
        base = DateTime(y, m, base.day.clamp(1, last));
      default:
        return null;
    }
    return DateTime(base.year, base.month, base.day);
  }

  /// Buat salinan tugas berulang untuk tanggal berikutnya. Tidak dobel:
  /// bila seri sudah punya tugas aktif pada tanggal itu, lewati.
  void _spawnNextOccurrence(SvTask t) {
    final next = _nextRepeatDate(t);
    if (next == null) return;
    final series = t.seriesId == 0 ? t.id : t.seriesId;
    final nextKey = _dKey(next);
    final exists = todos.any(
      (x) =>
          !x.done &&
          x.seriesId == series &&
          dateOf(x) == nextKey &&
          x.repeat == t.repeat,
    );
    if (exists) return;
    final id = _maxInt(todos.map((x) => x.id)) + 1;
    final copy = SvTask(
      id: id,
      title: t.title,
      note: t.note,
      cat: t.cat,
      pri: t.pri,
      date: nextKey,
      timeMin: t.timeMin,
      reminder: t.reminder,
      sound: t.sound,
      repeat: t.repeat,
      alarm: t.alarm,
      routine: t.routine,
      seriesId: series,
      xp: t.xp,
    );
    todos.add(copy);
    _syncNotif(copy);
  }

  /// Tunda pengingat T menit dari SEKARANG (jam tugas ikut maju).
  Future<void> snoozeTodo(int id, {int minutes = 10}) async {
    final i = todos.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final n = DateTime.now().add(Duration(minutes: minutes));
    final t = todos[i];
    todos[i] = t.copyWith(
      date: _dKey(n),
      timeMin: n.hour * 60 + n.minute,
      reminder: true,
      done: false,
      doneAt: '',
    );
    await save();
    _syncNotif(todos[i]);
  }

  /// Empat tugas contoh saat pertama kali aplikasi dibuka.
  /// HARUS list biasa (growable): list `const` menyebabkan
  /// toggleTodo/addTodo gagal ("indexed set" unsupported).
  static List<SvTask> defaultTodos() => [
    const SvTask(
      id: 1,
      title: 'Jalan pagi 20 menit',
      note: 'Keliling kompleks, lalu minum air.',
      cat: 'Kesehatan',
      pri: 1,
      timeMin: 6 * 60 + 30,
    ),
    SvTask(
      id: 2,
      title: 'Isi kalender makan hari ini',
      note: 'Cek menu protein di halaman Planning.',
      cat: 'Pribadi',
      pri: 0,
      timeMin: 8 * 60,
    ),
    SvTask(
      id: 3,
      title: 'Latihan sesi fokus utama',
      note: 'Sesuai jadwal hari ini, sesuaikan set & reps.',
      cat: 'Kesehatan',
      pri: 2,
      timeMin: 16 * 60 + 30,
    ),
    SvTask(
      id: 4,
      title: 'Catat pengeluaran hari ini',
      note: 'Jajan, transport, belanja dapur.',
      cat: 'Pekerjaan',
      pri: 0,
    ),
  ];

  // ---- OTA sync (PRD 1A: Lokal -> Remote -> User Overrides) ----
  // 'lokal' = URL placeholder, pakai data.dart | 'ok' = remote dipakai |
  // 'gagal' = fetch gagal, tetap pakai data lokal. User overrides TIDAK ditimpa.
  String syncStatus = 'lokal';
  DateTime? lastSync;

  Future<void> syncData() async {
    if (DATA_URL.contains('ganti-dengan-url')) {
      syncStatus = 'lokal';
      return;
    }
    try {
      final res = await http
          .get(Uri.parse(DATA_URL))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        syncStatus = 'gagal';
        notifyListeners();
        return;
      }
      _applyRemote(jsonDecode(res.body) as Map<String, dynamic>);
      lastSync = DateTime.now();
      syncStatus = 'ok';
      notifyListeners();
    } catch (_) {
      syncStatus = 'gagal';
      notifyListeners();
    }
  }

  void _applyRemote(Map<String, dynamic> j) {
    final pola = j['pola'];
    if (pola is List && pola.isNotEmpty) {
      final m = <String, Pola>{};
      for (final e in pola) {
        final p = Pola.fromJson(e as Map<String, dynamic>);
        if (p.k.isNotEmpty) m[p.k] = p;
      }
      if (m.length >= 7) {
        POLA.clear();
        POLA.addAll(m);
      }
    }
    final macro = j['macro'];
    if (macro is Map && macro.length >= 7) {
      final m = <String, Macro>{};
      macro.forEach(
        (k, v) => m[k.toString()] = Macro.fromJson(
          (v as Map).cast<String, dynamic>(),
        ),
      );
      MACRO_PAKET.clear();
      MACRO_PAKET.addAll(m);
    }
    final booster = j['booster'];
    if (booster is List && booster.isNotEmpty) {
      final l = booster
          .map((e) => BoosterItem.fromJson(e as Map<String, dynamic>))
          .toList();
      BOOSTER_ITEM
        ..clear()
        ..addAll(l);
    }
    final combos = j['combos'];
    if (combos is List && combos.isNotEmpty) {
      DEFAULT_COMBOS
        ..clear()
        ..addAll(combos.map((e) => Combo.fromJson(e as Map<String, dynamic>)));
    }
  }

  // ---- combos ----
  int comboCost(List<String> polas) =>
      polas.fold(0, (a, k) => a + (POLA[k]?.b ?? 0));

  Future<void> saveCombo(String name, List<String> polas, String note) async {
    combos.add(Combo(DateTime.now().millisecondsSinceEpoch, name, polas, note));
    await save();
  }

  Future<void> delCombo(int id) async {
    combos.removeWhere((c) => c.id == id);
    await save();
  }
}

class UI {
  static String toast = '';
  static void msg(String m) {
    toast = m;
  }
}

void msg(String m) => UI.msg(m);
