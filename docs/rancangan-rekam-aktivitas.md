# Rancangan — Rekam Aktivitas GPS (Lari, Jalan Kaki, Sepeda)

Status: diimplementasikan di branch `feat/rekam-aktivitas-gps` (v1.4.0+39).
Target rilis: **Shorebird RELEASE baru** (plugin native `geolocator`), bukan patch.

## 1. Latar & keputusan

Permintaan awal: "fitur Strava". Setelah diskusi, keputusannya:

| Pertanyaan | Keputusan | Alasan |
| --- | --- | --- |
| Integrasi Strava API atau buat sendiri? | **Buat sendiri, tanpa Strava API** | Strava wajib OAuth + `client_secret` (tidak ada PKCE) dan akun. Itu bertabrakan dengan prinsip SELF VOLTA: offline-first, tanpa akun, tanpa tracking. |
| Jenis aktivitas | Lari, Jalan kaki, Sepeda | Pace untuk lari/jalan, kecepatan km/jam untuk sepeda. |
| Tampilan rute | Garis rute offline + peta OSM opsional | Rute selalu tergambar tanpa internet; peta hanya dimuat bila user menekan "Peta". |
| Layar mati / HP di saku | Foreground service lokasi | Wajib untuk lari sungguhan. |
| Letak UI | Kartu di halaman Latihan | Bottom nav tetap 5 item; hasil ikut XP, streak, dan kartu Workout di Beranda. |
| Pengguna | 1 orang | Tidak perlu server/akun. |

Nama fitur sengaja **"Rekam Aktivitas"**, tanpa nama, logo, atau warna oranye
Strava. Aksennya memakai amber pilar Workout.

## 2. Arsitektur

```
WorkoutPage ─┬─ AktivitasCard ──► RekamAktivitasPage ──► AktivitasDetailPage(pending)
             │        │                    │                        │ Simpan
             │        └─► RiwayatAktivitasPage ─► AktivitasDetailPage
             │
ActivityRecorder (ChangeNotifier, singleton, hidup selama proses)
   ├─ LocationService  (satu-satunya file yang menyentuh plugin geolocator)
   ├─ TrackRecorder    (Dart murni: filter, jarak, split, elevasi)
   └─ checkpoint `sv_track_live` (SharedPreferences, tiap 15 dtk)
                         │ Simpan
                         ▼
AppState.activities ─► `sv_v1` / `sv_v1_bak` / ekspor-impor cadangan
```

File baru:

| File | Isi |
| --- | --- |
| `lib/services/activity_math.dart` | `ActivityType`, `GeoFix`, `TrackRecorder`, haversine, pace/kecepatan, kalori, encoded polyline, Douglas–Peucker. Tanpa plugin, sepenuhnya teruji unit. |
| `lib/services/location_service.dart` | Izin + stream GPS. Hook `debugStream`/`debugGate` dan guard `FLUTTER_TEST`, sama seperti `WeatherService`. |
| `lib/services/activity_recorder.dart` | Sesi rekam berjalan, jeda/lanjut, checkpoint & pemulihan. |
| `lib/pages/aktivitas_page.dart` | Kartu, layar rekam, ringkasan/detail, riwayat, `RouteView`. |

Kenapa recorder **tidak** di `AppState`: titik GPS datang tiap 1–2 detik,
sedangkan `AppState` didengar hampir semua halaman. Recorder punya notifier
sendiri dan baru menulis ke `AppState` saat user menekan **Simpan**.

## 3. Aturan hitung (TrackRecorder)

- **Akurasi > 30 m** → titik dibuang (di dalam gedung atau sinyal lemah).
- **Titik pertama setelah mulai/lanjut** hanya jadi jangkar segmen baru, jadi
  tidak ada garis lurus atau jarak palsu yang melintasi masa jeda.
- **Lompatan** lebih cepat dari batas jenis (lari 8 m/s, jalan 4 m/s, sepeda 25 m/s) → dibuang.
- **Jitter**: gerak < max(3 m, ½ akurasi) dianggap diam.
- **Auto-pause**: waktu bergerak hanya bertambah bila kecepatan segmen ≥ ambang
  (lari 0,8 m/s, jalan 0,4 m/s, sepeda 1,2 m/s) dan jeda antar titik ≤ 30 dtk.
- **Split per km**: detik bergerak saat garis km dilewati, diinterpolasi.
- **Elevasi naik** (perkiraan): histeresis 5 m terhadap derau altitude GPS.
- **Kalori** (perkiraan): lari 1,0 × kg × km, jalan 0,5 × kg × km, sepeda MET
  menurut kecepatan rata-rata (Compendium of Physical Activities). Berat dari Profil.
- **Langkah kaki tidak ditampilkan** karena tidak ada sensornya (prinsip "tanpa data karangan").

## 4. Data

```jsonc
// AppState.toJson()['activities'][i]
{
  "id": "a1763450000000",      // a + epoch ms mulai
  "ty": "run",                 // run | walk | ride
  "n":  "Lari Sore",
  "st": "2026-11-18T16:40:00.000",
  "el": 1900,                  // detik, tanpa masa jeda manual
  "mv": 1800,                  // detik bergerak (tanpa auto-pause)
  "d":  5020.5,                // meter
  "eg": 12.0,                  // meter naik (perkiraan)
  "kc": 318,                   // kkal (perkiraan)
  "sp": [355, 360, 362],       // detik per km
  "rt": ["_p~iF~ps|U..."]      // encoded polyline per segmen
}
```

- Rute disederhanakan ke **≤ 600 titik** sebelum disimpan (±5 KB per aktivitas),
  sehingga blob `sv_v1` dan file cadangan tetap ringan.
- Ikut di `toJson`/`_applyJson`/`_clearAllData`/`resetAllData` dan **impor gabung**
  (dedupe per `id`). Segmen polyline rusak dilewati tanpa menggagalkan load.
- Checkpoint rekaman berjalan disimpan di key terpisah `sv_track_live` (titik
  mentah + tanda jeda). Key ini terpisah supaya checkpoint 15 detik tidak ikut
  menyalin seluruh data ke `sv_v1_bak`. Saat app dibuka lagi, `main.dart`
  memanggil `restoreCheckpoint()` dan rekaman muncul dalam keadaan **jeda**,
  lalu user memilih Lanjut atau Selesai.

## 5. XP, streak, Beranda

- XP sekali per jenis per hari (`gps_run` +30, `gps_walk` +20, `gps_ride` +25),
  hanya bila jarak ≥ 1 km (lari), 1,5 km (jalan), atau 3 km (sepeda). Ini memakai
  `claimXp` sehingga ikut aturan anti-grind dan rollover tengah malam.
- Hapus aktivitas: XP ditarik secara simetris bila tidak ada aktivitas sah
  sejenis lain hari itu.
- `recalculateStreak()` menghitung tanggal aktivitas GPS yang sah sebagai hari
  aktif. Ini perlu karena `workoutDone` direset harian.
- Kartu Workout Beranda: baris bawah menampilkan misalnya "… · Lari 3,2 km".

## 6. Android

- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_LOCATION` (Android 14+).
- **Tidak** memakai `ACCESS_BACKGROUND_LOCATION`. Foreground service yang dimulai
  dari layar depan cukup dengan izin "saat digunakan", dan izin latar belakang
  memicu review Play Store yang ketat. `test/android_manifest_test.dart` menjaga ini.
- Service `GeolocatorLocationService` (tipe `location`) dideklarasikan oleh
  plugin `geolocator_android`. Notifikasinya tidak bisa diusap selama merekam,
  dan GPS dimatikan saat jeda.
- iOS: repo belum punya folder `ios/`. Bila ditambah, aktifkan
  `UIBackgroundModes: location` lalu ubah `allowBackgroundLocationUpdates` ke `true`.

## 7. UI (mengikuti docs/ui-guidelines.md)

- Token `Star`/`Paper`, aksen `Star.workout`, teks kecil di atas tint memakai
  `Paper.amberInk`, Manrope, angka `tabularFigures`, kartu `Neu.raised`,
  progres mingguan `SegmentTrack(7)`, target sentuh ≥ 48 dp.
- Tema terang di semua layar (pengecualian gelap hanya layar alarm).
- Label "(perkiraan)" pada kalori dan elevasi; "—" bila nilai belum ada.
- Peta OSM: `userAgentPackageName` diisi, atribusi "OpenStreetMap contributors"
  tampil, dan garis rute tetap tergambar walau ubin gagal dimuat.
- Lolos `layout_stress_test` di 320/360/412 px, text scale 1,3/2,0, layar pendek,
  dan landscape (layar Rekam, Riwayat, Detail, ditambah kartu di Latihan & Beranda).

## 8. Tes

- `test/activity_math_test.dart`: haversine, polyline (contoh resmi Google),
  simplify, format, kalori, filter akurasi/lompatan/jitter, auto-pause, jeda tanpa
  jembatan jarak, elevasi, replay checkpoint.
- `test/activity_feature_test.dart`: XP sekali/hari, ambang jarak, tarik XP saat
  hapus, simpan–muat disk, impor gabung, streak, JSON rusak, izin ditolak,
  pemulihan checkpoint, alur UI mulai → jeda → selesai → simpan.
- `test/data_safety_test.dart`: sampel data kini memuat satu aktivitas, sehingga
  ekspor/impor/gabung ikut menjaga field baru.

## 9. Belum diuji / risiko

- **Belum dicoba di HP fisik.** GPS sungguhan, foreground service, dan layar mati
  baru diverifikasi lewat stream palsu di tes.
- HP dengan "battery killer" agresif (Xiaomi/MIUI, Oppo/ColorOS, Vivo) bisa tetap
  membunuh service. Solusi user: matikan optimasi baterai untuk SELF VOLTA.
  Pemulihan checkpoint membatasi kerugian ke maksimal ±15 detik terakhir.
- Kalori & elevasi adalah perkiraan; altitude GPS bisa meleset ±10–20 m.

## 10. Ide lanjutan (belum dibuat)

- Ekspor GPX per aktivitas (lewat `file_picker` yang sudah ada).
- Target mingguan km + pengingat.
- Rekor pribadi (5K/10K tercepat) dan grafik pace per split.
- Pengumuman suara tiap km (TTS).
