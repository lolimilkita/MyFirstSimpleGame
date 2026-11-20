# Devlog I5 — Karakter Seukuran Jempol

Tanggal: 20 Nov 2026 · Build: `build/MyFirstSimpleGame.apk` (debug, versi 0.5.0)

## Target

"Karakter sebesar jempol orang dewasa." Lebar jempol ±20–25 mm; layar HP ±70 mm →
karakter harus menempati **±30% lebar layar** (sebelumnya hanya 7,7%).

## Yang diubah

| | I4 | I5 |
|---|---|---|
| Viewport | 540×1200 | **400×889** |
| Sprite pemain | 16 px, skala 2,6 (≈42 unit) | **32 px, skala 4,5 (≈97 unit)** |
| Lebar karakter di layar 1080 | ±80 px (5,5 mm) | **±260–340 px (≈22 mm)** |
| Zombie walker | 17 unit | 36 unit |
| Maks zombie | 45 | 18 |
| Spawn awal | 0,35 s | 0,55 s |
| Kecepatan | 60/99/42 | 45/73/31 |
| Jangkauan | 195 | 145 |

Dua hal penting:

1. **Resolusi sprite dinaikkan 2×** (16→32 px, brute 24→48). Tanpa ini, sprite 16 px yang
   diperbesar 5× terlihat seperti balok kasar. Sekarang tetap tajam di zoom besar.
2. **Kepadatan zombie diturunkan** (maks 18, spawn 0,55 s) karena satu zombie kini selebar
   ±250 px — 30 zombie akan menutupi seluruh layar dan mustahil dihindari.

## Perbaikan tampilan

Sprite pemain sebelumnya **diputar** mengikuti arah bidik. Pada zoom besar rotasi itu membuat
kepala (rambut) berada di bawah dan lengan di atas — terlihat jungkir balik. Sekarang sprite
selalu tegak; arah tembak tetap ditunjukkan oleh peluru.

## Verifikasi

Dijalankan di emulator **Android 14 (API 34)**; screenshot: `docs/11-thumb-view.png`
(karakter tegak, ±30% lebar layar), `docs/12-thumb-crowd.png` (versi sebelum kepadatan diturunkan).

## Catatan

Dengan hitbox sebesar ini, permainan jadi lebih sulit: kontak zombie lebih sering terjadi.
Headless menunjukkan HP mulai berkurang sekitar detik ke-15. Kalau terasa terlalu kejam,
langkah berikutnya: kecilkan hitbox zombie ~20% (visual tetap besar) atau tambah i-frame.
