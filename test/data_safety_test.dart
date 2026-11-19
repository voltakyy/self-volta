// Fase 1 — DATA AMAN.
//
// Membuktikan tiga syarat selesai Fase 1:
//   1. export -> import menghasilkan data identik;
//   2. save() beruntun tidak menghilangkan data;
//   3. data rusak tidak hilang diam-diam (disalin + dipulihkan + dilaporkan).
//
// Catatan: AppState adalah singleton, jadi tiap test menyiapkan ulang state
// memori (resetAllData) dan "disk" palsu (SharedPreferences.setMockInitialValues).
// `save()`/`flushNow()` mengembalikan Future milik pemanggil (bukan Completer
// bersama), sehingga aman di-`await` dari zona test mana pun.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_volta/data.dart';
import 'package:self_volta/services/activity_math.dart';
import 'package:self_volta/services/backup_service.dart';
import 'package:self_volta/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kondisi awal bersih: memori dikosongkan, lalu "instalasi baru".
Future<void> freshInstall() async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  await AppState.I.resetAllData();
  await AppState.I.load();
}

/// Isi data contoh yang menyentuh hampir semua bagian blob `sv_v1`.
void seedSampleData() {
  final s = AppState.I;
  s.calYear = 2026;
  s.calMonth = 11;
  s.txns = [
    Txn(1, 3, 'Makan siang', 15000, 'makan', bln: '2026-11'),
    Txn(2, 5, 'Gaji', 900000, 'masuk', bln: '2026-11'),
  ];
  s.mealNotes = [MealNote(7, 3, '2026-11', 'nasi + telur')];
  s.customMeals = [
    CustomMeal(
      id: 'cm_1',
      name: 'Bubur ayam',
      mealTime: 'Sarapan',
      dayIndex: 2,
      kalori: 350,
      protein: 15,
      karbo: 40,
      bahan: const ['beras', 'ayam'],
      langkah: 'Rebus, aduk, sajikan.',
      estimasiBiaya: 12000,
    ),
  ];
  s.piano = [PianoDep(111, 2, 50000, '3-11-2026')];
  s.combos = List.of(DEFAULT_COMBOS);
  s.workoutDone = {'a1': true, 'b2': true};
  s.activities = [
    GpsActivity(
      id: 'a1763450000000',
      type: ActivityType.run,
      name: 'Lari Sore',
      start: DateTime(2026, 11, 10, 16, 40),
      elapsedSec: 1900,
      movingSec: 1800,
      distanceM: 5020.5,
      elevGainM: 12,
      kcal: 318,
      splits: const [355, 360, 362, 358, 365],
      route: const ['_p~iF~ps|U_ulLnnqC_mqNvxq`@'],
    ),
  ];
  s.todos = [
    const SvTask(
      id: 9,
      title: 'Belajar Flutter',
      note: 'Bab persistensi',
      cat: 'Pekerjaan',
      pri: 2,
      date: '2026-11-10',
      timeMin: 540,
      reminder: true,
      xp: 25,
    ),
  ];
  s.xpClaimed = {'workout_a1': 20, 'todo_9_2026-11-10': 25};
  s.xpDay = AppState.todayKey;
  s.xp = 345;
  s.streak = 4;
  s.budget = 800000;
  s.income = 1000000;
  s.bumbuStock = true;
  s.bumbuFin = true;
  s.bumbuTxnId = 1;
  s.weightKg = 63.5;
  s.heightCm = 171.0;
}

String canonical(String jsonText) => jsonEncode(jsonDecode(jsonText));

void main() {
  group('1.1 ekspor / impor', () {
    test('ekspor lalu impor menghasilkan data identik', () async {
      await freshInstall();
      seedSampleData();
      await AppState.I.flushNow();

      final exported = AppState.I.exportJson();
      final before = canonical(exported);

      // Rusak state di memori dulu supaya impor benar-benar berpengaruh.
      AppState.I.txns.clear();
      AppState.I.todos.clear();
      AppState.I.xp = 0;
      AppState.I.budget = 1;
      await AppState.I.flushNow();

      await AppState.I.importJson(jsonDecode(exported) as Map<String, dynamic>);

      expect(
        canonical(AppState.I.exportJson()),
        before,
        reason: 'isi state setelah impor harus sama persis dengan file',
      );
      expect(AppState.I.txns.length, 2);
      expect(AppState.I.todos.single.title, 'Belajar Flutter');
      expect(AppState.I.xp, 345);
    });

    test('impor mencadangkan data LAMA ke sv_v1_bak', () async {
      await freshInstall();
      AppState.I.budget = 654321;
      AppState.I.xp = 222;
      await AppState.I.flushNow();
      final oldData = canonical(AppState.I.exportJson());

      // File impor berbeda (hasil ekspor lain).
      final incoming = jsonDecode(oldData) as Map<String, dynamic>;
      incoming['budget'] = 111111;
      incoming['xp'] = 10;

      await AppState.I.importJson(incoming);

      expect(AppState.I.budget, 111111);
      final p = await SharedPreferences.getInstance();
      final bak = p.getString(AppState.prefKeyBak);
      expect(bak, isNotNull);
      expect(
        canonical(bak!),
        oldData,
        reason: 'sv_v1_bak harus berisi data sebelum impor',
      );
    });

    test('impor yang gagal tidak menghilangkan data lama', () async {
      await freshInstall();
      seedSampleData();
      await AppState.I.flushNow();
      final before = canonical(AppState.I.exportJson());

      // `txns` berisi daftar tapi elemennya bukan objek -> gagal saat apply.
      await expectLater(
        AppState.I.importJson(<String, dynamic>{
          'txns': <dynamic>['bukan objek transaksi'],
          'xp': 9999,
          'budget': 1,
        }),
        throwsA(isA<TypeError>()),
      );

      expect(
        canonical(AppState.I.exportJson()),
        before,
        reason: 'state memori harus di-rollback',
      );
      final p = await SharedPreferences.getInstance();
      expect(
        canonical(p.getString(AppState.prefKey)!),
        before,
        reason: 'data di disk juga harus tetap data lama',
      );
    });

    test('reset total mencadangkan data ke sv_v1_bak lebih dulu', () async {
      await freshInstall();
      AppState.I.budget = 321000;
      AppState.I.txns = [Txn(5, 2, 'Sisa', 7000, 'lain', bln: '2026-11')];
      await AppState.I.flushNow();
      final before = canonical(AppState.I.exportJson());

      await AppState.I.resetAllData();

      final p = await SharedPreferences.getInstance();
      expect(
        p.getString(AppState.prefKey),
        isNull,
        reason: 'reset menghapus data utama',
      );
      expect(
        canonical(p.getString(AppState.prefKeyBak)!),
        before,
        reason: 'cadangan sebelum reset wajib ada',
      );
    });

    test('BackupService menolak file yang bukan cadangan SELF VOLTA', () {
      expect(() => BackupService.validate(''), throwsFormatException);
      expect(() => BackupService.validate('   '), throwsFormatException);
      expect(() => BackupService.validate('bukan json'), throwsFormatException);
      expect(() => BackupService.validate('[1,2,3]'), throwsFormatException);
      expect(() => BackupService.validate('{"foo": 1}'), throwsFormatException);
      expect(
        () => BackupService.validate('{"txns": "bukan list"}'),
        throwsFormatException,
      );
      expect(
        () => BackupService.validate('{"txns": [], "xp": "banyak"}'),
        throwsFormatException,
      );

      final ok = BackupService.validate(
        '{"txns": [], "xp": 5, "todos": [], "xpDay": "2026-11-10"}',
      );
      final summary = BackupService.summarize(ok);
      expect(summary.xp, 5);
      expect(summary.txns, 0);
      expect(summary.xpDay, '2026-11-10');
    });
  });

  group('1.2 save beruntun', () {
    test('40 save() tanpa await tidak menghilangkan data', () async {
      await freshInstall();
      final s = AppState.I;
      s.txns = [Txn(1, 1, 'Awal', 1000, 'lain', bln: '2026-11')];
      await s.flushNow();

      // Pola yang dipakai UI: save() dipanggil beruntun tanpa await.
      for (var i = 0; i < 40; i++) {
        s.xp = i;
        unawaited(s.save());
      }
      s.budget = 987654;
      await s.save(); // terakhir tetap di-await lewat flush di bawah

      await s.flushNow();

      final p = await SharedPreferences.getInstance();
      final main = jsonDecode(p.getString(AppState.prefKey)!);
      final bak = jsonDecode(p.getString(AppState.prefKeyBak)!);
      expect(main['xp'], 39, reason: 'nilai terakhir dari 40 penulisan');
      expect(main['budget'], 987654);
      expect((main['txns'] as List).length, 1);
      expect(bak['xp'], 39);
      expect(bak['budget'], 987654);
      expect(s.lastSaveError, isNull);
    });

    test('tidak ada penulisan bersamaan (antrean serial)', () async {
      await freshInstall();
      final s = AppState.I;
      final futures = <Future<void>>[];
      for (var i = 0; i < 12; i++) {
        s.xp = 100 + i;
        futures.add(s.flushNow());
      }
      await Future.wait(futures);
      final p = await SharedPreferences.getInstance();
      final main = jsonDecode(p.getString(AppState.prefKey)!);
      expect(main['xp'], 111);
      expect(s.lastSaveError, isNull);
    });
  });

  group('1.3 data rusak tidak hilang diam-diam', () {
    test(
      'sv_v1 rusak dipulihkan dari sv_v1_bak + salinan rusak disimpan',
      () async {
        // Siapkan cadangan yang sah.
        await freshInstall();
        AppState.I.budget = 432100;
        AppState.I.xp = 777;
        await AppState.I.flushNow();
        final good = (await SharedPreferences.getInstance()).getString(
          AppState.prefKeyBak,
        )!;

        // Rusak data utama, lalu "buka aplikasi" lagi.
        SharedPreferences.setMockInitialValues(<String, Object>{
          AppState.prefKey: '{"txns": [rusak',
          AppState.prefKeyBak: good,
        });
        AppState.I.budget =
            1; // pastikan nilai ini yang diganti hasil pemulihan
        await AppState.I.load();

        final rec = AppState.I.loadRecovery;
        expect(rec, isNotNull);
        expect(rec!.recoveredFromBackup, isTrue);
        expect(rec.corruptKey, startsWith(AppState.corruptPrefix));
        expect(rec.error, isNotEmpty);
        expect(AppState.I.budget, 432100);
        expect(AppState.I.xp, 777);

        final p = await SharedPreferences.getInstance();
        expect(
          p.getString(rec.corruptKey),
          '{"txns": [rusak',
          reason: 'data rusak wajib disalin, bukan dibuang',
        );
        expect(
          p.getString(AppState.prefKey),
          isNotNull,
          reason: 'data utama sudah ditulis ulang dari cadangan',
        );
      },
    );

    test(
      'rusak dan cadangan ikut rusak: data lama tetap disalin, dilaporkan',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          AppState.prefKey: '[[[',
          AppState.prefKeyBak: 'bukan json juga',
        });
        await AppState.I.load();

        final rec = AppState.I.loadRecovery;
        expect(rec, isNotNull);
        expect(rec!.recoveredFromBackup, isFalse);
        expect(rec.backupError, isNotNull);
        expect(AppState.I.txns, isEmpty);

        final p = await SharedPreferences.getInstance();
        expect(
          p.getString(rec.corruptKey),
          '[[[',
          reason: 'salinan data rusak tidak boleh hilang',
        );
      },
    );

    test('instalasi baru (tanpa data) tidak memicu dialog pemulihan', () async {
      await freshInstall();
      expect(AppState.I.loadRecovery, isNull);
    });
  });

  group('1.4 impor gabung', () {
    test('data file ditambahkan, nilai tunggal tetap milik app', () async {
      await freshInstall();
      final s = AppState.I;
      s.txns = [Txn(1, 3, 'Makan siang', 15000, 'makan', bln: '2026-11')];
      s.todos = [
        const SvTask(
          id: 5,
          title: 'Belajar',
          cat: 'Pekerjaan',
          date: '2026-11-10',
          timeMin: 540,
        ),
      ];
      s.mealNotes = [MealNote(1, 3, '2026-11', 'nasi')];
      s.piano = [PianoDep(10, 2, 50000, '3-11-2026')];
      s.workoutDone = {'a1': true};
      s.eatenM = {
        '2026-11': {'3': true},
      };
      s.xp = 500;
      s.streak = 7;
      s.budget = 900000;
      s.income = 2000000;
      s.weightKg = 60;
      s.heightCm = 170;
      await s.flushNow();

      await s.mergeJson(<String, dynamic>{
        'txns': [Txn(99, 4, 'Kopi', 20000, 'lain', bln: '2026-11').toJson()],
        'todos': [
          const SvTask(
            id: 5,
            title: 'Olahraga',
            cat: 'Kesehatan',
            date: '2026-11-10',
            timeMin: 600,
          ).toJson(),
        ],
        'mealNotes': [MealNote(88, 4, '2026-11', 'kopi').toJson()],
        'piano': [PianoDep(11, 2, 25000, '4-11-2026').toJson()],
        'workout': {'b2': true},
        'eatenM': {
          '2026-11': {'4': true},
          '2026-10': {'1': true},
        },
        'xpClaimed': {'workout_a1': 99},
        'xp': 1,
        'streak': 1,
        'budget': 1,
        'income': 1,
        'heightCm': 100,
      });

      expect(s.txns.length, 2, reason: 'transaksi file ikut masuk');
      expect(s.todos.length, 2, reason: 'to-do file ikut masuk');
      expect(s.mealNotes.length, 2);
      expect(s.piano.length, 2);
      expect(s.workoutDone['a1'], isTrue, reason: 'centang app tidak hilang');
      expect(s.workoutDone['b2'], isTrue, reason: 'centang file ikut masuk');
      expect(
        s.eatenM['2026-10']!['1'],
        isTrue,
        reason: 'bucket bulan lain dari file ikut masuk',
      );
      expect(
        s.xpClaimed['workout_a1'],
        99,
        reason: 'buku XP ambil nilai terbesar agar tidak klaim dobel',
      );
      expect(s.xp, 500, reason: 'XP tidak diganti & tidak dijumlah');
      expect(s.streak, 7);
      expect(s.budget, 900000);
      expect(s.income, 2000000);
      expect(s.heightCm, 170);
    });

    test('duplikat dilewati, id bentrok dibuat ulang', () async {
      await freshInstall();
      final s = AppState.I;
      s.txns = [Txn(1, 3, 'Makan siang', 15000, 'makan', bln: '2026-11')];
      s.todos = [
        const SvTask(
          id: 5,
          title: 'Belajar',
          cat: 'Pekerjaan',
          date: '2026-11-10',
          timeMin: 540,
        ),
      ];
      await s.flushNow();

      await s.mergeJson(<String, dynamic>{
        'txns': [
          Txn(1, 3, 'Makan siang', 15000, 'makan', bln: '2026-11').toJson(),
          Txn(1, 4, 'Kopi', 20000, 'lain', bln: '2026-11').toJson(),
        ],
        'todos': [
          const SvTask(
            id: 5,
            title: 'Belajar',
            cat: 'Pekerjaan',
            date: '2026-11-10',
            timeMin: 540,
          ).toJson(),
          const SvTask(
            id: 5,
            title: 'Lari pagi',
            cat: 'Kesehatan',
            date: '2026-11-10',
            timeMin: 300,
          ).toJson(),
        ],
      });

      expect(s.txns.length, 2, reason: 'transaksi identik tidak dobel');
      expect(s.todos.length, 2, reason: 'to-do identik tidak dobel');
      expect(
        s.txns.map((t) => t.id).toSet().length,
        2,
        reason: 'id transaksi hasil gabung harus unik',
      );
      expect(
        s.todos.map((t) => t.id).toSet().length,
        2,
        reason: 'id to-do hasil gabung harus unik',
      );
      expect(
        s.todos.firstWhere((t) => t.title == 'Lari pagi').id,
        isNot(5),
        reason: 'id bentrok diganti, bukan menimpa to-do app',
      );
    });

    test('gabung mencadangkan data SEBELUM gabung ke sv_v1_bak', () async {
      await freshInstall();
      seedSampleData();
      await AppState.I.flushNow();
      final before = canonical(AppState.I.exportJson());

      await AppState.I.mergeJson(<String, dynamic>{
        'txns': [Txn(700, 9, 'Teh', 5000, 'lain', bln: '2026-11').toJson()],
      });

      expect(AppState.I.txns.length, 3);
      final p = await SharedPreferences.getInstance();
      expect(
        canonical(p.getString(AppState.prefKeyBak)!),
        before,
        reason: 'sv_v1_bak harus berisi data sebelum penggabungan',
      );
    });

    test('gabung yang gagal tidak mengubah data lama', () async {
      await freshInstall();
      seedSampleData();
      await AppState.I.flushNow();
      final before = canonical(AppState.I.exportJson());

      await expectLater(
        AppState.I.mergeJson(<String, dynamic>{
          'txns': <dynamic>['bukan objek transaksi'],
        }),
        throwsA(isA<TypeError>()),
      );

      expect(
        canonical(AppState.I.exportJson()),
        before,
        reason: 'state memori harus di-rollback',
      );
      final p = await SharedPreferences.getInstance();
      expect(
        canonical(p.getString(AppState.prefKey)!),
        before,
        reason: 'data di disk juga tetap data lama',
      );
    });
  });
}
