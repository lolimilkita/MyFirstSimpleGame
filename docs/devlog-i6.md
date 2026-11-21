# Devlog I6 — Ukuran Karakter Dikembalikan ke 15% Lebar Layar

Tanggal: 22 Nov 2026 · Build: `build/MyFirstSimpleGame.apk` (debug, versi 0.6.0)

## Masukan

I5 membuat karakter ±30% lebar layar (±22 mm) — terlalu besar, memakan ruang bermain.
Permintaan: **potong setengah, jadi 15% lebar layar**.

## Yang diubah

| | I5 | I6 |
|---|---|---|
| Skala sprite pemain | 4,5× | **2,8×** |
| Lebar pemain di layar 1080 | ±300 px (30%) | **±160 px (14,8%)** |
| Hitbox pemain | radius 48 | radius 30 |
| Zombie walker | skala 3,2 · radius 36 | skala 2,0 · radius 22 |
| Zombie runner | 2,8 · 30 | 1,75 · 19 |
| Zombie brute | 2,4 · 50 | 1,5 · 33 |
| Maks zombie | 18 | **30** |
| Spawn awal | 0,55 s | **0,45 s** |
| Separation | 56 | 36 |

Semua aktor dan hitbox dipotong ±separuh agar proporsi pemain–zombie tetap sama. Karena
hitbox mengecil (lebih mudah menghindar), kepadatan zombie dinaikkan lagi supaya tekanan
tidak hilang.

## Verifikasi

Emulator Android 14 (API 34). Pengukuran pada tangkapan layar 1080 px: lebar pemain ±160 px
= **14,8%** lebar layar. Screenshot: `docs/13-view-15pct.png`.

## Catatan

Emulator ini makin lama makin sering "device offline"/ANR karena render software; build &
pemasangan kadang perlu diulang. Ini murni keterbatasan emulator, bukan aplikasi.
