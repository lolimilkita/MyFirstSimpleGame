# Devlog I2 — BERTAHAN

Tanggal: 18 Nov 2026 · Build: `build/bertahan.apk` (debug, 54 MB, versionName 0.2.0)

## Yang ditambahkan

| Sistem | Detail |
|---|---|
| 3 tipe zombie | walker (HP 1, 80 px/s) · runner (HP 1, 132 px/s, muncul 45 s) · brute (HP 6, 56 px/s, muncul 90 s) |
| HP zombie naik | `1 + max(0, t-45)/90` → 2× di 135 s, 3× di 225 s |
| Pickup | koin (+25 skor, drop 29%) dan medkit (+1 HP, drop 3% saat HP<3), magnet 120 px, umur 14 s |
| Upgrade tier | 15 kill (tembak cepat) · 40 (2 peluru) · 80 (tembus) · 140 (lebih cepat) · 220 (3 peluru) |
| Horde burst | tiap 75 s, 10 zombie dari satu sisi, ditandai panah merah 1,5 s |
| Best score | `user://save.cfg` (ConfigFile), ditampilkan sebagai REKOR |
| Audio | 6 SFX prosedural (tembak, kena, mati, sakit, pickup, upgrade) dengan pool 8 pemutar |
| Art | 8 sprite pixel art + tile lantai, semuanya digenerate `tools/gen_assets.py` |

Semua aset dihasilkan skrip Python tanpa library eksternal (PNG ditulis manual via zlib, WAV via
modul `wave`), jadi bisa diubah dan diulang kapan saja: `python3 tools/gen_assets.py`.

## Empat bug yang ditemukan

**1. `Can't change this state while flushing queries` (error berulang tiap pickup).**
Root cause-nya bukan `queue_free` seperti dugaan pertama. Saya bisect: matikan drop → 0 error;
matikan despawn tapi biarkan pickup dibuat → error tetap ada. Ternyata pickup **dibuat** di dalam
callback tabrakan (zombie mati → `_maybe_drop` → `add_child`), tepat saat physics flush.
Perbaikan: spawn pickup lewat `call_deferred`.

**2. Aset baru tidak terbaca di build (`No loader found for resource`).**
Menjalankan game headless tidak otomatis mengimpor PNG/WAV. Perlu `--import` sekali sebelum
menjalankan/ekspor. Ini masuk ke alur build.

**3. Pemain hijau di antara zombie hijau.**
Di layar HP, survivor tidak terbaca. Jaket diubah jadi biru (43,96,132) — kontras langsung terasa.
Sprite juga diperbesar (pemain 2,6×; walker 2,6×; brute 2,0× dari 24 px).

**4. Upgrade membuat game mustahil kalah.**
Tier 5 memberi 3 peluru/0,24 s ≈ 12,5 tembakan/detik, sementara spawn 2,9/detik → pemain diam pun
bertahan 100+ detik. Dua lawan yang dipasang: HP zombie naik seiring waktu dan interval spawn
dipercepat (decay 0,93 → 0,90 per 10 s, minimum 0,10 s, cap 55 zombie).

## Status pengujian (jujur)

- Headless: **0 script error, 0 physics-flush error** setelah perbaikan; tier 1–5 terbukti naik,
  pickup muncul dan tersedot, horde terpicu, best score tersimpan (terlihat REKOR 3148 di device).
- Emulator: build terpasang, HUD baru tampil, sprite & koin terlihat.
- **Belum terverifikasi visual di device:** runner/brute, panah horde, toast upgrade — jalur kodenya
  ada dan lolos headless, tapi emulator SwiftShader terlalu lambat (87% frame janky) untuk main
  sungguhan sampai 90 detik.
- **Kurva akhir belum final.** Pemain diam di simulasi masih bertahan >60 s setelah upgrade.
  Angka ini harus divalidasi di HP asli (I3) sebelum dianggap benar.

## Catatan performa

55 zombie dengan separation O(n²) ≈ 3.000 pengecekan jarak per frame — masih ringan di CPU,
tapi di emulator render software tetap janky. Target 60 fps harus diukur di HP asli.

## Berikutnya (I3)

Tes HP asli → tuning kurva akhir → tutorial 5 detik → toggle darah → ikon adaptif → signing
release → build release APK.
