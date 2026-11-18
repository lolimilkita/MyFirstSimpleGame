# GDD Ringkas — "BERTAHAN" (endless zombie shooter)

**Versi:** 0.1 (pra-produksi) · **Target:** Android, portrait 9:16, satu tangan · **Engine:** Godot 4.7.2, renderer Compatibility

## Keputusan terkunci (17 Nov 2026)

| Topik | Keputusan |
|---|---|
| Arah gameplay | Arena bertahan top-down (bukan road-scroller) |
| Gaya visual | **Pixel art**, sprite 16–32 px, palet terbatas |
| Darah | **Tanpa darah** (partikel hijau gelap), ada toggle di menu |
| Bahasa UI | Indonesia (Inggris menyusul kalau perlu) |
| Judul kerja | **BERTAHAN** |

---

## 0. Perubahan dari konsep #8

Konsep #8 aslinya "naik terus" (vertical ascent). Untuk tema zombie saya ubah jadi **arena bertahan
(top-down, kamera tetap)**, karena:

1. Zombie terbaca jelas dari atas — kawanan mengepung, bukan sekadar muncul dari atas layar.
2. "Naik terus" + "drag untuk gerak" saling bertabrakan arah; pemain akan tertahan di bawah layar.
3. Arena membuat auto-aim terasa berguna (ancaman dari segala arah, bukan satu jalur).
4. Latar jadi 1 tile berulang → aset paling murah.

**Fantasi:** kamu survivor terakhir di halaman belakang rumah; pistol menembak sendiri, kamu fokus bertahan hidup.

---

## 1. Loop inti

> Geser jari → karakter ikut → pistol auto-tembak zombie terdekat → zombie mati, keluar koin/HP →
> gelombang makin padat → kena 3x = mati → skor + best score → **retry satu tap**.

Putaran mikro 20–40 detik. Target sesi pemain: 90–180 detik per run.

## 2. Kontrol

| Aksi | Input | Respons |
|---|---|---|
| Gerak | Drag di mana saja (relatif 1:1) | Karakter mengikuti delta jari, tanpa joystick virtual |
| Tembak | Otomatis, tiap **0,35 s** | Target = zombie terdekat dalam radius **260 px** (pistol) |
| Aim manual | — | Sengaja tidak ada di v1 |

Kenapa auto-fire: satu jempol sudah dipakai gerak; menambah tombol tembak membuat game ini jadi dua tangan
dan menghilangkan keunggulan "bisa main sambil berdiri di angkot".

**Batas gerak:** clamp ke area arena (margin 32 px), kamera tidak bergerak.

## 3. Aturan main

- **HP 3.** Kena zombie = −1 HP, knockback 80 px, invulnerable 1,0 s (karakter berkedip).
- **Mati** saat HP 0 → slow-motion 0,4 s → kartu game over (skor, best, tombol Retry & Menu).
- **Tidak ada amunisi.** Reload tidak ada — auto-fire terus jalan. Kesulitan datang dari kepadatan, bukan sumber daya.
- **Koin** menambah skor; **health kit** memulihkan 1 HP (maks 3).

## 4. Skor

```
skor = (kill × nilai) + (detik bertahan × 1) + bonus gelombang
walker 10 · runner 15 · brute 40
```

Best score & total kill disimpan di `user://save.cfg`. Tidak ada leaderboard online di v1.

## 5. Kurva kesulitan

| Waktu | Yang terjadi |
|---|---|
| 0–15 s | 1 zombie / **0,35 s**, walker 80 px/s — tekanan langsung terasa |
| tiap 10 s | interval spawn ×**0,93**, kecepatan zombie ×1,03 (kecepatan di-cap 1,6×) |
| 45 s | **runner** muncul (130 px/s, HP 1) |
| 90 s | **brute** muncul (55 px/s, HP 6, skor 40) |
| 75 s, lalu tiap 75 s | **horde burst**: 10 zombie dari satu sisi, diberi tanda panah merah 1,5 s sebelumnya |
| 150 s+ | campuran runner+brute; health kit makin jarang |

Batas keras: maksimum **40 zombie hidup** dan **60 peluru** di layar. Kalau cap tercapai, spawn ditunda —
ini menjaga 60 fps di HP kelas menengah dan mencegah pemain mati karena "spawn di atas kepala".

Larangan desain: **tidak boleh spawn dalam radius 200 px dari pemain** (kecuali horde burst yang sudah diberi tanda).

## 6. Progresi dalam satu run

Naik level senjata berdasarkan total kill (reset tiap run):

| Kill | Upgrade |
|---|---|
| 15 | fire rate 0,32 s → 0,26 s |
| 40 | multishot 2 (dua peluru sejajar) |
| 80 | pierce 1 (peluru menembus 1 zombie) |
| 140 | fire rate → 0,22 s |
| 220 | multishot 3 |

Tanpa sistem pilih-upgrade (roguelite) di v1 — itu menambah 2 layar UI dan 1 sistem state.

## 7. Rasa / juice (yang bikin nagih)

- Muzzle flash 2 frame + selongsong keluar, screen shake 2 px saat menembak, 6 px saat kena.
- Zombie kena: flash putih 0,08 s, partikel kecil, lalu fade 0,25 s.
- Kena damage: vignette merah 0,3 s + suara "thud" rendah.
- Koin menyedot ke pemain (magnet radius 80 px) — memuaskan tanpa menambah kontrol.
- Getaran HP 20 ms saat tembakan terakhir membunuh zombie (opsional, bisa dimatikan).

Efek darah: **default mati**, ada toggle "Efek Darah" di menu (menjaga rating usia Play Store dan preferensi pemain).

## 8. Daftar aset minimal

| Kategori | Jumlah | Catatan |
|---|---|---|
| Karakter | 1 | top-down, 2 frame (diam/geser) |
| Zombie | 3 tipe | 1 sprite dasar + recolor (hijau/kuning/merah), brute di-scale 1,4× |
| Peluru | 1 | kotak 3×8 px dengan glow |
| Partikel | 2 | hit (putih) + mati (hijau gelap) |
| Latar | 1 tile | aspal/halaman 128×128, di-tile |
| Dekor | 3 opsional | pagar, tong sampah, mobil |
| UI | 1 set | font, ikon hati, panel game over |
| Audio | 4 SFX + 1 loop | tembak, kena, zombie mati, hurt, ambience |

Total: ±12 gambar kecil. Semua bisa dibuat dari bentuk geometris di iterasi pertama (grey box).

## 9. Implementasi Godot (catatan teknis)

```
Main (Node2D)
├── Arena (TileMapLayer)          # latar
├── Player (CharacterBody2D)      # drag movement + HP
├── Zombies (Node2D)              # container + pool
├── Bullets (Node2D)              # pool 60
├── Pickups (Node2D)
├── Director (Node)               # timer, kesulitan, horde burst
└── HUD (CanvasLayer)             # HP, skor, game over
```

- Collision layer: player 1 · zombie 2 · peluru 4 · pickup 8.
- Zombie–zombie **tanpa physics push** (mahal); pakai separation steering sederhana agar tidak menumpuk sempurna.
- Auto-aim: `get_nodes_in_group("zombies")` lalu pilih jarak kuadrat terkecil — aman untuk ≤40 node.
- Reload/mati: semua pool di-`hide()` dan di-reset, **tanpa reload scene** (retry instan, < 0,2 s).
- `Director` menyimpan `elapsed`, `spawn_interval`, `speed_mult`, `wave` — semua balancing di satu file.
- Viewport 720×1280, stretch `canvas_items`, aspect `expand`.

## 10. Rencana 3 iterasi build

**I1 — Grey box (target: 1 sesi)**
Lingkaran pemain, kotak zombie, auto-fire, tabrakan, HP 3, skor, mati, retry.
Uji: apakah gerak 1:1 drag terasa enak? Apakah auto-aim terasa pintar atau bodoh?
Build APK → tes emulator. **Belum ada art, belum ada suara.**

**I2 — Loop lengkap (target: 2 sesi)**
Art minimal (siluet berwarna), 3 tipe zombie, upgrade tier, pickup, horde burst, HUD, game over + best score, 4 SFX.

**I3 — Polish & rilis (target: 2 sesi)**
Juice (shake, partikel, vignette), tutorial 5 detik, toggle darah, ikon adaptif Android, signing,
tes di emulator + HP asli, build release APK.

## 11. Di luar cakupan v1 (sengaja ditolak)

Multiplayer · IAP/iklan · leaderboard online · joystick virtual · dash/dodge · banyak senjata ·
boss · cerita · sistem upgrade antar-run.

## 12. Ukuran keberhasilan

- Run pertama pemain bertahan **25–45 detik** (kalau < 15 s, terlalu kejam; > 60 s, terlalu mudah).
- Retry terjadi < 1 detik setelah mati.
- 60 fps stabil dengan 40 zombie di emulator x86_64.
- APK debug < 40 MB.

## 13. Hasil I1 (terukur, 17 Nov 2026)

Angka di atas sudah dibakukan ke build. Pemain yang **diam** mati pada 21–35 detik
(rata-rata 27,6 s dari 9 percobaan); pemain yang bergerak bertahan lebih lama.

Tiga perubahan dari rencana awal, semuanya karena data, bukan selera:

1. **Jangkauan pistol 480 → 260 px.** Dengan 480 px, zombie mati ~6 detik sebelum menyentuh
   pemain; pemain diam pun tidak tersentuh selama 37 detik. Tidak ada tekanan = tidak ada game.
2. **Spawn awal 1,1 s → 0,35 s** dan decay 0,96 → 0,93 per 10 detik, agar laju spawn melebihi
   laju tembak (≈2,9/detik) sehingga kawanan benar-benar menumpuk.
3. **Arena mengikuti viewport** (`get_viewport_rect()`), bukan kotak tetap 720×1280, supaya layar
   9:20 tidak menyisakan pita kosong.

Detail lengkap + tabel sweep ada di `projects/bertahan/docs/devlog-i1.md`.
