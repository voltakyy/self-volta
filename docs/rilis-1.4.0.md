# Rilis 1.4.0+39 — Rekam Aktivitas GPS (Lari, Jalan Kaki, Sepeda)

| Item | Nilai |
| --- | --- |
| versionName / versionCode | `1.4.0` / `39` |
| Jenis rilis | **Shorebird RELEASE baru** (plugin native `geolocator`), bukan patch |
| Rancangan | [`docs/rancangan-rekam-aktivitas.md`](rancangan-rekam-aktivitas.md) |

## Fitur baru

- Kartu **Rekam Lari, Jalan & Sepeda** di halaman Latihan: ringkasan minggu ini
  (km, durasi, hari aktif), pilih jenis, lalu tombol **Mulai Rekam**.
- **Layar rekam**: durasi, jarak, pace (atau km/jam untuk sepeda), waktu bergerak,
  km tuntas, status sinyal GPS, dan rute yang tergambar langsung.
- **Tetap merekam saat layar mati** lewat foreground service, dengan notifikasi
  "SELF VOLTA merekam …". GPS dimatikan saat dijeda.
- **Auto-pause**: berhenti di lampu merah tidak merusak pace.
- **Ringkasan setelah selesai**: rute, statistik, split per km (km tercepat
  ditandai), lalu Simpan atau Buang, dan bisa ganti nama.
- **Riwayat** per bulan dengan filter jenis dan total jarak/waktu.
- **Peta OpenStreetMap opsional** (tombol "Peta", butuh internet). Tanpa internet,
  garis rute tetap tampil.
- **XP & streak**: +30 lari (≥1 km), +20 jalan (≥1,5 km), +25 sepeda (≥3 km),
  sekali per jenis per hari. Hari dengan aktivitas sah ikut menjaga streak.
- **Beranda**: kartu Workout menampilkan aktivitas GPS hari ini.
- **Pemulihan**: bila HP mematikan app di tengah rekaman, rekaman dipulihkan
  dalam keadaan jeda saat app dibuka lagi.

## Izin Android baru

`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_LOCATION`. Tidak memakai izin lokasi latar belakang.

## Catatan untuk pengguna

- Saat pertama merekam, pilih **"Izinkan saat aplikasi digunakan"**.
- Di Xiaomi/Oppo/Vivo, matikan optimasi baterai untuk SELF VOLTA supaya rekaman
  panjang tidak dihentikan sistem.
- Data rute hanya tersimpan di HP ini dan ikut file cadangan (ekspor/impor).

## Cara rilis

```bash
shorebird release android --artifact apk --target-platform android-arm64
```

Patch lama tidak bisa membawa fitur ini karena ada plugin native baru.
