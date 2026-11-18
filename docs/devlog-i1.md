# Devlog I1 — Grey Box BERTAHAN

Tanggal: 17 Nov 2026 · Build: `build/bertahan.apk` (debug, 54 MB, arm64-v8a + x86_64)

## Tujuan iterasi

Menjawab dua pertanyaan saja, tanpa art dan tanpa suara:

1. Apakah **drag 1:1** terasa enak untuk menggerakkan survivor?
2. Apakah **auto-aim ke zombie terdekat** terasa pintar, atau malah bodoh?

## Yang sudah ada

- Gerak drag relatif 1:1, dikunci ke tepi arena.
- Auto-fire 0,35 s ke zombie terdekat (radius 260 px).
- Zombie mengejar + separation sederhana (tidak menumpuk sempurna).
- HP 3, i-frame 1,0 s + kedip, knockback saat kena.
- Skor (kill × 10 + detik), kill counter, HUD hati.
- Mati → overlay GAME OVER → ketuk = main lagi (tanpa reload scene).
- Arena mengikuti ukuran viewport sebenarnya (9:20 → 720×1600 unit).

## Tiga temuan yang mengubah desain

**1. Auto-fire terlalu kuat (bug keseimbangan).**
Dengan jangkauan awal 480 px dan tembak 0,32 s, zombie mati ~6 detik sebelum sampai.
Pemain diam pun tidak pernah tersentuh selama 37 detik — tidak ada tekanan sama sekali.
Perbaikan: jangkauan pistol **260 px** (juga lebih masuk akal untuk survivor) dan spawn
dirapatkan dari 1,1 s → 0,35 s.

**2. Deteksi mati tidak pernah ter-log (bug instrumentasi).**
Debug print berada setelah `if not running: return`, jadi baris `run=false` tidak pernah tercetak
dan semua sweep awal salah menyimpulkan "tidak pernah mati". Setelah log kematian dipindah,
baru terlihat angka sebenarnya.

**3. Arena tidak menutup layar (bug layout).**
Viewport 720×1280 (16:9) dipaksa ke layar 1080×2400 (9:20) sehingga muncul pita kosong di bawah.
Perbaikan: arena dihitung dari `get_viewport_rect()` saat `_ready`, lalu dipakai untuk spawn,
batas gerak pemain, dan penggambaran lantai.

## Hasil tuning (pemain diam = kasus terburuk)

| Percobaan | Range | Tembak | Spawn awal | Decay | Zombie speed | Damage pertama | Mati |
|---|---|---|---|---|---|---|---|
| awal | 480 | 0,32 | 1,10 | 0,96 | 70 | tidak pernah | tidak pernah |
| G | 260 | 0,35 | 0,28 | 0,95 | 80 | 17,3 s | — |
| **H (dipakai)** | **260** | **0,35** | **0,35** | **0,93** | **80** | **25,5 s** | **21–35 s** |
| I | 260 | 0,45 | 0,40 | 0,90 | 85 | 21,1 s | — |

Sembilan kali mati berturut-turut pada konfigurasi H: 21,5 · 30,6 · 26,7 · 23,3 · 35,0 · 23,4 · 30,3 · 27,8 · 29,6 detik
(rata-rata 27,6 s). Pemain yang bergerak akan bertahan lebih lama — di atas target minimum 25 s.

Jumlah zombie saat mati: 28–32 (cap 40 tidak pernah tersentuh).

## Catatan performa

Emulator memakai `swiftshader_indirect` (render CPU): 87% frame janky, 8 frame per `dumpsys gfxinfo`.
Angka ini **tidak mewakili HP asli** dan tidak dipakai sebagai patokan; target 60 fps harus diuji
di perangkat fisik pada I3. Godot berjalan di emulator lewat ANGLE + SwiftShader (GLES 3.1), bukan GPU asli.

## Yang sengaja belum ada (sesuai GDD)

Tipe zombie (runner/brute), pickup, upgrade tier, horde burst, suara, best score tersimpan, ikon.

## Langkah berikutnya (I2)

Art siluet berwarna → 3 tipe zombie → pickup → upgrade tier → horde burst → suara → best score.
