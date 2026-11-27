// Tabel data lama memakai nama kapital (APP_VERSION, POLA, HURUF_ID) dan
// sengaja dipertahankan agar referensinya di seluruh halaman tidak berubah.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';

// Ubah tiap publish patch agar user bisa MELIHAT update OTA masuk.

// Versi statis saja — tanpa embel-embel "patch N".

// Update OTA Shorebird bekerja senyap di background (tidak ada notif,

// tidak ada tulisan update); user tidak perlu melihatnya.

const APP_VERSION = '1.4.0+39';

class Pola {
  final String k;

  final String t;

  final int b;

  final String belanja;

  final String cara;

  Pola(this.k, this.t, this.b, this.belanja, this.cara);

  factory Pola.fromJson(Map<String, dynamic> j) => Pola(
    j['k'] as String? ?? '',

    j['t'] as String? ?? '',

    j['b'] as int? ?? 0,

    j['belanja'] as String? ?? '',

    j['cara'] as String? ?? '',
  );
}

// GANTI dengan URL Vercel data.json milikmu saat sudah deploy.

// Selama masih placeholder, aplikasi 100% memakai data lokal (data.dart).

const DATA_URL = 'https://ganti-dengan-url-vercel-anda/data.json';

final POLA = <String, Pola>{
  'A': Pola(
    'A',
    'A | Telur + Tempe + Bening Bayam (otot)',
    22500,

    'Telur 5 (10rb) + Tempe 1/2 (2,5rb) + Bayam 1 (3rb) + Wortel (4rb) + Labu 1 (3rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[MC] Nasi + telur utuh 12 mnt + tempe di atas nasi sampai matang. [PL] Didihkan air, wortel+labu 5 mnt, bayam+bawang+garam stok 3 mnt.',
  ),

  'B': Pola(
    'B',
    'B | Tahu + Telur + Sawi (otot)',
    21000,

    'Tahu 5 (5rb) + Telur 3 (6rb) + Sawi putih (4rb) + Wortel (4rb) + Timun 2 (2rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[PL] Rebus tahu 8 mnt angkat. Air sama buat wortel+sawi 6 mnt + timun 3 mnt. [MC] Telur rebus bareng nasi.',
  ),

  'C': Pola(
    'C',
    'C | Tempe + Telur + Sup Labu (otot)',
    19000,

    'Tempe 1 (5rb) + Telur 2 (4rb) + Labu 1 (3rb) + Wortel (4rb) + Sawi hijau (3rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[MC] Tempe di atas nasi sampai matang. [PL] Sup labu+wortel 7 mnt, sawi 3 mnt. Telur ceplok air: pecah di air mendidih 4 mnt.',
  ),

  'D': Pola(
    'D',
    'D | Ayam + Tahu Bening (mingguan otot)',
    22000,

    'Ayam dada 1/4 tanpa kulit (9rb) + Tahu 2 (2rb) + Kentang (4rb) + Wortel (4rb) + Bayam (3rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[PL] Rebus ayam+bawang putih+garam stok 20 mnt, buang busa. Masuk kentang+wortel 10 mnt, tahu+bayam 3 mnt. [MC] Nasi seperti biasa.',
  ),

  'E': Pola(
    'E',
    'E | Lele + Tempe + Kelor (otot)',
    19500,

    'Lele 2 kecil (7rb) + Tempe 1/2 (2,5rb) + Kelor 1 (3rb) + Labu 1 (3rb) + Wortel (4rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[PL] Rebus air+bawang stok, masuk lele 12 mnt jangan diaduk. Masuk labu+wortel 6 mnt, kelor 2 mnt. [MC] Tempe kukus di atas nasi.',
  ),

  'F': Pola(
    'F',
    'F | Nila + Tahu + Oyong (otot)',
    19000,

    'Nila 2 kecil (8rb) + Tahu 3 (3rb) + Oyong 1 buah sedang +/- 300g (4rb) + Wortel (4rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[MC] Nasi setengah matang, taruh mangkok nila+bawang+garam stok di atas beras sampai jeglek. [PL] Bening oyong+wortel+tahu 8 mnt. Oyong pasar +/- Rp13rb/kg.',
  ),

  'G': Pola(
    'G',
    'G | Telur + Tempe + Kentang (otot)',
    21500,

    'Telur 4 (8rb) + Tempe 1/2 (2,5rb) + Sawi hijau/putih (3rb) + Kentang (4rb) + Wortel (4rb) + bumbu stok: bawang merah 3 siung + bawang putih 2 siung + garam 2 sdt + gula 1 sdt (dari stok, Rp0)',

    '[MC] Kocok telur+air 1:1+garam stok di mangkok, kukus di atas nasi 15 mnt + tempe. [PL] Sup kentang+wortel 10 mnt, sawi 3 mnt.',
  ),
};

const URUTAN = <String>[
  "A",
  "B",
  "C",
  "A",
  "D",
  "B",
  "E",
  "C",
  "F",
  "A",
  "G",
  "D",
  "B",
  "F",
  "E",
];

class Macro {
  final int k, p, c, l, s;

  Macro(this.k, this.p, this.c, this.l, this.s);

  int get kPer2 => k;

  factory Macro.fromJson(Map<String, dynamic> j) => Macro(
    j['k'] as int? ?? 0,

    j['p'] as int? ?? 0,

    j['c'] as int? ?? 0,

    j['l'] as int? ?? 0,

    j['s'] as int? ?? 0,
  );
}

final MACRO_PAKET = <String, Macro>{
  'A': Macro(790, 61, 55, 40, 12),

  'B': Macro(630, 58, 40, 32, 9),

  'C': Macro(800, 62, 70, 36, 10),

  'D': Macro(750, 84, 78, 14, 8),

  'E': Macro(610, 65, 49, 20, 8),

  'F': Macro(510, 60, 34, 15, 7),

  'G': Macro(890, 56, 97, 34, 10),
};

const PROT_PAKET = <String, int>{
  'A': 61,
  'B': 58,
  'C': 62,
  'D': 84,
  'E': 65,
  'F': 60,
  'G': 56,
};

const NASI_HARI = (k: 910, p: 19);

const BOOST_HARI = (k: 1110, p: 33);

const TARGET_KKAL = 2350;

const TARGET_P = 72;

// Ikon paket: Material Icons bawaan (selalu tampil benar di semua HP).

// JANGAN pakai emoji di sini — di sebagian HP Android emoji jadi kotak aneh.

const PAKET_ICON = <String, IconData>{
  'A': Icons.egg,

  'B': Icons.soup_kitchen,

  'C': Icons.rice_bowl,

  'D': Icons.dinner_dining,

  'E': Icons.set_meal,

  'F': Icons.ramen_dining,

  'G': Icons.lunch_dining,
};

// Header kartu paket — gradien pastel TERANG (palet SVG user).

// Ikon fallback di atasnya memakai sea gelap agar kontras.

const PAKET_GRAD = <String, List<Color>>{
  'A': [Color(0xffE7E9C8), Color(0xffF5F6E4)],

  'B': [Color(0xffCDE8E4), Color(0xffE9F5F2)],

  'C': [Color(0xffE4EDC4), Color(0xffF3F6E2)],

  'D': [Color(0xffC9E7F8), Color(0xffE9F4FC)],

  'E': [Color(0xffC2DFF2), Color(0xffE7F1FA)],

  'F': [Color(0xffE3D5EB), Color(0xffF4EEF8)],

  'G': [Color(0xffC4F2EC), Color(0xffE6FAF7)],
};

const SESSIONS = <({String id, String t, List<String> ex})>[
  (
    id: 'senin',
    t: 'Senin - Tarik dekat + Dorong',
    ex: [
      'Pull-up close 5x3-4',
      'Diamond push up 3x8-12',
      'Squat 3x15',
      'Dead bug 3x8/sisi',
    ],
  ),

  (
    id: 'rabu',
    t: 'Rabu - Tarik lebar + Kaki',
    ex: [
      'Pull-up wide 5x3-4',
      'Decline push up 3x8-12',
      'Lunges 3x10/kaki',
      'Bird dog 3x8/sisi',
    ],
  ),

  (
    id: 'jumat',
    t: 'Jumat - Full body',
    ex: [
      'Pull-up close 3x sisa-2',
      'Pike push up 3x6-10',
      'Push up slow 3x10',
      'Glute bridge 3x15',
      'Plank 3x25 detik',
      'Prone butterfly 3x10',
    ],
  ),
];

class BoosterItem {
  final String lb;

  final int k, p, bi;

  BoosterItem(this.lb, this.k, this.p, this.bi);

  factory BoosterItem.fromJson(Map<String, dynamic> j) => BoosterItem(
    j['lb'] as String? ?? '',

    j['k'] as int? ?? 0,

    j['p'] as int? ?? 0,

    j['bi'] as int? ?? 0,
  );
}

final BOOSTER_ITEM = <BoosterItem>[
  BoosterItem('Nasi +400g (tambah +/-130g tiap makan)', 520, 11, 2800),

  BoosterItem('Tempe 100g (kukus MC)', 150, 14, 1000),

  BoosterItem('Telur 1 butir (rebus/kukus)', 75, 6, 2000),

  BoosterItem('Pisang 200g (1-2 buah)', 190, 1, 2800),

  BoosterItem('Ubi 150g (kukus)', 135, 1, 2000),

  BoosterItem('Minyak 1 sdt (tetes ke nasi/sup)', 40, 0, 300),
];

const BOOSTER_TOTAL = (k: 1110, p: 33, bi: 10900);

const BOOSTER_DAY = <(String, String)>[
  ('Pagi (07.00)', 'Nasi 300g + telur + sayur - dari paket (sudah termasuk)'),

  ('Snack (10.00)', 'Pisang 200g (+/- 190 kkal)'),

  ('Siang (12.00)', 'Nasi 300g + lauk + sayur - dari paket'),

  ('Snack (15.00)', 'Tempe 100g / ubi 150g (+/- 150 kkal)'),

  ('Malam (19.00)', 'Nasi 300g + lauk + sayur + telur 1 booster (+/- 75 kkal)'),
];

class Combo {
  final int id;

  final String name;

  final List<String> polas;

  final String note;

  Combo(this.id, this.name, this.polas, this.note);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'polas': polas,
    'note': note,
  };

  factory Combo.fromJson(Map<String, dynamic> j) => Combo(
    j['id'] as int,
    j['name'] as String? ?? '',
    j['polas'].cast<String>(),
    j['note'] as String? ?? '',
  );
}

final DEFAULT_COMBOS = <Combo>[
  Combo(1, 'Termurah A+B+C', [
    'A',
    'B',
    'C',
  ], '6 hari hemat, tanpa ayam/ikan. Cocok awal bulan.'),

  Combo(2, 'Ayam D+G', [
    'D',
    'G',
  ], '4 hari protein ayam + telur, tetap 1 panci PL/MC.'),

  Combo(3, 'Ikan E+F', [
    'E',
    'F',
  ], '4 hari ikan, kukus MC + bening PL, tanpa cabai.'),

  Combo(4, 'Gampang A+G', [
    'A',
    'G',
  ], '4 hari telur saja, paling simpel pisau+MC/PL.'),

  Combo(5, 'Mix 8 Hari', [
    'A',
    'D',
    'E',
    'F',
  ], '8 hari bervariasi, rolling mingguan.'),
];

const PIANO_TARGET = 1500000;

const JATAH_HARI = 25000;

/// Nama hari Indonesia (index DateTime.weekday 1-7, Senin-Minggu).

const HARI_ID = <String>[
  '',

  'Senin',

  'Selasa',

  'Rabu',

  'Kamis',

  'Jumat',

  'Sabtu',

  'Minggu',
];

/// Nama bulan Indonesia (index 1-12) untuk halaman Kalender.

const BULAN_ID = <String>[
  '',

  'Januari',

  'Februari',

  'Maret',

  'April',

  'Mei',

  'Juni',

  'Juli',

  'Agustus',

  'September',

  'Oktober',

  'November',

  'Desember',
];

String rp(int n) {
  final s = n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );

  return 'Rp$s';
}
