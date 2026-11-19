# Devlog I3 — Kartu Upgrade & Ikon

Tanggal: 19–20 Nov 2026 · Build: `build/MyFirstSimpleGame.apk` (debug, versi 0.3.0)

## Latar belakang

Sebelumnya upgrade berjalan otomatis berdasarkan jumlah kill (15/40/80/140/220). Pemain tidak
memilih apa pun, jadi setiap run terasa sama. Permintaan: **drop upgrade acak** dengan pilihan
(contoh: peluru ganda atau kecepatan naik).

## Referensi mekanisme

| Game | Cara kerja |
|---|---|
| **Brotato** | Setiap level up menawarkan **4 upgrade** dari 4 tingkat kelangkaan (I–IV); bisa reroll ([Brotato Wiki](https://brotato.wiki.spellsandguns.com/Upgrades)) |
| Vampire Survivors | Level up → pause → 3–4 pilihan senjata/pasif, maksimal 6 slot |
| Archero | Level up → 3 kartu skill acak, pilih satu |

Pola yang diambil: **pause → 3 kartu acak → pilih 1**. Reroll belum dipakai (butuh mata uang
dan satu tombol lagi; ditunda).

## Yang dibuat

- **8 kartu**: Tembak Cepat (−18% jeda), Peluru Ganda (+1 peluru), Peluru Tembus (+1), Kaki Ringan
  (+12% gerak), Darah Tebal (+1 nyawa), Magnet (+60%), Peluru Besar (+1 damage), Bidik Jauh (+18% jangkauan).
- Tiap kartu punya **bobot** dan **batas tumpukan**; kartu penuh tidak ikut undian.
- Ambang level: 8 kill, lalu `kill + 6 + level×2`.
- Game **pause** (`get_tree().paused`) saat memilih; HUD di-set `process_mode = ALWAYS` agar tetap
  menerima sentuhan saat tree beku.
- Stat pemain jadi variabel (fire_interval, shots, pierce, damage, move_mult, magnet, max_hp, range)
  yang diubah oleh `apply_upgrade()`.

## Ikon

Ikon lama 128×128 (dari `icon.svg`) sehingga tampil kecil/buram di launcher. Sekarang:
`assets/icon/icon_512.png` (512×512), `adaptive_fg.png` + `adaptive_bg.png` (432×432), semuanya
digenerate `tools/gen_assets.py`. Konten adaptive foreground dijaga di dalam safe zone 264 px.

## Bug & perbaikan

1. **`var pos := event.position` gagal parse** — `InputEvent` tidak punya tipe `position` statis;
   diperbaiki dengan cast eksplisit ke `InputEventScreenTouch`.
2. **Judul "NAIK LEVEL" tertimpa kartu pertama** — posisi header masih hard-code; sekarang dihitung
   dari tinggi total tumpukan kartu (`top - 26`).
3. **HUD tidak menerima input saat pause** — `process_mode` Control harus `ALWAYS` (nilai 3).

## Verifikasi

- Headless dengan `BT_AUTOPICK=1`: level up terpicu di 8 kill, kartu terpilih otomatis, stat berubah
  (`PICK max_hp` → hp 4/4), tanpa error script.
- Emulator: kartu tampil, permainan berhenti, ketuk kartu → lanjut dengan LV 2 dan koin berjatuhan
  (lihat `docs/06-upgrade-cards.png`, `docs/07-after-pick.png`).

## Belum

Reroll, animasi kartu, ikon kecil di tiap kartu, dan tuning bobot setelah tes pemain sungguhan.
