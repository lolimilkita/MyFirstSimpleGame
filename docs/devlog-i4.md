# Devlog I4 — View Lebih Besar & Android 14

Tanggal: 20 Nov 2026 · Build: `build/MyFirstSimpleGame.apk` (debug, versi 0.4.0)

## Masalah

Di layar 1080×2400, dunia game dipetakan dari 720×1600 unit, sehingga karakter hanya menempati
**~5,5% lebar layar** (±60 px) — terasa kecil dan lapangannya kosong.

## Solusi: zoom-in lewat viewport

Viewport dasar diubah **720×1600 → 540×1200** (rasio 9:20 tetap). Arena dihitung dari viewport,
jadi dunia otomatis mengecil sementara **ukuran karakter, zombie, dan sprite tidak diubah** →
semuanya tampil **1,33× lebih besar**.

Agar ritme permainan tidak ikut berubah, jarak dan kecepatan diskalakan ×0,75:

| Parameter | Sebelum | Sesudah |
|---|---|---|
| Viewport | 720×1600 | **540×1200** |
| Kecepatan walker / runner / brute | 80 / 132 / 56 | 60 / 99 / 42 |
| Jangkauan tembak | 260 | 195 |
| Kecepatan peluru / jarak | 900 / 320 | 675 / 240 |
| Magnet | 120 | 90 |
| Knockback | 260 | 195 |
| Margin spawn | 60 | 45 |
| Maks zombie | 55 | 45 |

Ukuran zombie, pemain, dan ikon kartu **tidak** diperkecil — itu sebabnya hasilnya terasa lebih besar,
bukan sekadar versi mini dari tampilan lama.

## Android 14

- System image `system-images;android-34;google_apis;x86_64` diunduh, AVD baru **gamedev14** dibuat.
- APK dipasang dan dimainkan di sana: `ro.build.version.release = 14`, `adb install` sukses,
  kartu upgrade tampil dan bisa dipilih (lihat `docs/09-android14-cards.png`, `docs/10-android14-play.png`).
- Konfigurasi: `minSdk 24` (Android 7.0), `targetSdk 36`. Target tinggi tidak menghalangi Android 14 —
  perilaku mengikuti versi perangkat.

## Catatan

Dialog "System UI isn't responding" yang muncul di emulator berasal dari SystemUI emulator yang
memakai render software (SwiftShader), bukan dari aplikasi; game tetap berjalan di belakangnya
dan tetap menerima sentuhan setelah dialog ditutup.
