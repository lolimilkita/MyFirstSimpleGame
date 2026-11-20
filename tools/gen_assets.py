#!/usr/bin/env python3
"""Membuat aset pixel art + SFX BERTAHAN secara prosedural.

Jalankan: python3 tools/gen_assets.py
Output:  assets/sprites/*.png  dan  assets/sfx/*.wav
Tidak butuh library eksternal (PNG ditulis manual pakai zlib).
"""
import math
import os
import random
import struct
import wave
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITE_DIR = os.path.join(ROOT, "assets", "sprites")
SFX_DIR = os.path.join(ROOT, "assets", "sfx")

OUTLINE = (18, 22, 16, 255)


# ---------------------------------------------------------------- PNG encoder
def write_png(path, w, h, px):
    raw = b"".join(
        b"\x00" + bytes(v for x in range(w) for v in px[y][x]) for y in range(h))

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    out = b"\x89PNG\r\n\x1a\n"
    out += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    out += chunk(b"IDAT", zlib.compress(raw, 9))
    out += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)


def canvas(w, h):
    return [[(0, 0, 0, 0) for _ in range(w)] for _ in range(h)]


def put(px, x, y, col):
    if 0 <= y < len(px) and 0 <= x < len(px[0]):
        px[y][x] = col


def disc(px, cx, cy, r, col):
    for y in range(len(px)):
        for x in range(len(px[0])):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px[y][x] = col


def rect(px, x0, y0, x1, y1, col):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            put(px, x, y, col)


def outline(px, col=OUTLINE):
    h, w = len(px), len(px[0])
    src = [[px[y][x] for x in range(w)] for y in range(h)]
    for y in range(h):
        for x in range(w):
            if src[y][x][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[ny][nx][3] != 0:
                    px[y][x] = col
                    break


# ------------------------------------------------------------------- sprites
K = 2  # resolusi sprite 2x agar tetap tajam saat di-zoom


def make_survivor(k=K):
    S = 16 * k
    px = canvas(S, S)
    disc(px, 8 * k, 9 * k, 5.4 * k, (43, 96, 132, 255))
    disc(px, 8 * k, 9 * k, 3.4 * k, (66, 140, 184, 255))
    rect(px, 11 * k, 8 * k, 15 * k, 9 * k, (52, 52, 58, 255))
    rect(px, 13 * k, 8 * k, 15 * k, 8 * k, (110, 110, 120, 255))
    disc(px, 8 * k, 6 * k, 3.1 * k, (196, 148, 108, 255))
    disc(px, 8 * k, 5 * k, 2.2 * k, (72, 54, 40, 255))
    outline(px)
    return px


def make_zombie(body, head, arms, size=16, r=5.6, k=K):
    px = canvas(size * k, size * k)
    c = size / 2.0
    disc(px, c * k, (c + 1.2) * k, r * k, body)
    disc(px, c * k, (c + 1.2) * k, r * 0.55 * k, head)
    rect(px, (c - r - 1) * k, c * k, (c - r + 1) * k, (c + 3) * k, arms)
    rect(px, (c + r - 1) * k, c * k, (c + r + 1) * k, (c + 3) * k, arms)
    outline(px)
    return px


def make_brute(k=K):
    px = canvas(24 * k, 24 * k)
    disc(px, 12 * k, 13 * k, 8.6 * k, (93, 64, 55, 255))
    disc(px, 12 * k, 13 * k, 5.2 * k, (121, 85, 72, 255))
    disc(px, 12 * k, 9 * k, 4.0 * k, (161, 136, 127, 255))
    rect(px, 2 * k, 13 * k, 6 * k, 18 * k, (78, 52, 46, 255))
    rect(px, 18 * k, 13 * k, 22 * k, 18 * k, (78, 52, 46, 255))
    outline(px)
    return px


def make_coin(k=K):
    px = canvas(12 * k, 12 * k)
    disc(px, 6 * k, 6 * k, 5.0 * k, (255, 213, 79, 255))
    disc(px, 6 * k, 6 * k, 3.4 * k, (255, 179, 0, 255))
    disc(px, 6 * k, 5 * k, 1.8 * k, (255, 236, 179, 255))
    outline(px)
    return px


def make_medkit(k=K):
    px = canvas(14 * k, 12 * k)
    rect(px, 1 * k, 2 * k, 12 * k, 10 * k, (236, 239, 241, 255))
    rect(px, 1 * k, 2 * k, 12 * k, 3 * k, (207, 216, 220, 255))
    rect(px, 5 * k, 4 * k, 8 * k, 9 * k, (229, 57, 53, 255))
    rect(px, 3 * k, 6 * k, 10 * k, 7 * k, (229, 57, 53, 255))
    outline(px)
    return px


def make_bullet(k=K):
    px = canvas(4 * k, 8 * k)
    rect(px, 0, 1 * k, 3 * k, 6 * k, (255, 224, 130, 255))
    rect(px, 1 * k, 0, 2 * k, 0, (255, 255, 255, 255))
    outline(px, (120, 90, 20, 255))
    return px


def make_ground():
    px = canvas(32, 32)
    rnd = random.Random(7)
    base = (35, 40, 46, 255)
    for y in range(32):
        for x in range(32):
            v = rnd.choice([0, 0, 0, 1, -1])
            px[y][x] = (base[0] + v * 3, base[1] + v * 3, base[2] + v * 3, 255)
    for _ in range(5):
        x, y = rnd.randrange(2, 29), rnd.randrange(2, 29)
        rect(px, x, y, x + rnd.randrange(1, 4), y, (30, 34, 39, 255))
    return px


# ------------------------------------------------------------------ app icon
def make_icon(size=512):
    px = canvas(size, size)
    c = size / 2.0
    s = size / 512.0
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / (size * 0.62)
            k = max(0.0, min(1.0, d))
            px[y][x] = (int(22 * (1 - k) + 9 * k), int(32 * (1 - k) + 14 * k),
                        int(28 * (1 - k) + 10 * k), 255)

    def blob(cx, cy, r, fill, ring=8):
        disc(px, cx * s, cy * s, (r + ring) * s, OUTLINE)
        disc(px, cx * s, cy * s, r * s, fill)

    blob(118, 150, 60, (107, 142, 35, 255))
    blob(118, 130, 30, (85, 107, 47, 255), 6)
    blob(400, 178, 52, (107, 142, 35, 255))
    blob(400, 162, 26, (85, 107, 47, 255), 6)

    blob(256, 336, 104, (43, 96, 132, 255), 10)
    blob(256, 336, 62, (66, 140, 184, 255), 6)
    blob(256, 238, 66, (196, 148, 108, 255), 8)
    blob(256, 214, 50, (72, 54, 40, 255), 6)

    rect(px, int(296 * s), int(310 * s), int(456 * s), int(352 * s), OUTLINE)
    rect(px, int(306 * s), int(320 * s), int(456 * s), int(342 * s), (58, 58, 66, 255))
    rect(px, int(318 * s), int(324 * s), int(452 * s), int(332 * s), (120, 120, 132, 255))
    return px


def make_adaptive_fg(size=432):
    px = canvas(size, size)
    c = size / 2.0
    disc(px, c, c + 26, 74, (43, 96, 132, 255))
    disc(px, c, c + 26, 45, (66, 140, 184, 255))
    disc(px, c, c - 34, 48, (196, 148, 108, 255))
    disc(px, c, c - 52, 36, (72, 54, 40, 255))
    rect(px, int(c + 40), int(c + 16), int(c + 104), int(c + 38), (52, 52, 58, 255))
    outline(px)
    return px


def make_adaptive_bg(size=432):
    px = canvas(size, size)
    c = size / 2.0
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / (size * 0.7)
            k = max(0.0, min(1.0, d))
            px[y][x] = (int(24 * (1 - k) + 10 * k), int(34 * (1 - k) + 15 * k),
                        int(28 * (1 - k) + 11 * k), 255)
    for i in range(0, size, 48):
        rect(px, i, 0, i, size - 1, (30, 42, 34, 255))
    return px


# --------------------------------------------------------------------- audio
SR = 22050


def env(i, n, attack=0.01, release=0.6):
    a = int(SR * attack)
    if i < a:
        return i / max(a, 1)
    tail = (n - i) / max(n * release, 1)
    return max(0.0, min(1.0, tail))


def tone(freq_from, freq_to, dur, kind="square", vol=0.5, noise=0.0):
    n = int(SR * dur)
    out = []
    phase = 0.0
    rnd = random.Random(3)
    for i in range(n):
        f = freq_from + (freq_to - freq_from) * (i / n)
        phase += f / SR
        if kind == "square":
            s = 1.0 if math.sin(2 * math.pi * phase) > 0 else -1.0
        elif kind == "saw":
            s = 2.0 * (phase - math.floor(phase + 0.5))
        else:
            s = math.sin(2 * math.pi * phase)
        if noise > 0:
            s = s * (1 - noise) + (rnd.uniform(-1, 1) * noise)
        out.append(s * vol * env(i, n))
    return out


def mix(*layers):
    n = max(len(x) for x in layers)
    out = [0.0] * n
    for layer in layers:
        for i, v in enumerate(layer):
            out[i] += v
    return [max(-1.0, min(1.0, v)) for v in out]


def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples))


def build_audio():
    os.makedirs(SFX_DIR, exist_ok=True)
    write_wav(os.path.join(SFX_DIR, "shoot.wav"),
              mix(tone(900, 320, 0.07, "square", 0.35), tone(0, 0, 0.07, "sine", 0.0, 0.5)))
    write_wav(os.path.join(SFX_DIR, "hit.wav"),
              tone(240, 90, 0.06, "sine", 0.5, 0.7))
    write_wav(os.path.join(SFX_DIR, "dead.wav"),
              mix(tone(320, 110, 0.20, "saw", 0.35), tone(0, 0, 0.20, "sine", 0.0, 0.35)))
    write_wav(os.path.join(SFX_DIR, "hurt.wav"),
              mix(tone(140, 60, 0.26, "sine", 0.6), tone(0, 0, 0.26, "sine", 0.0, 0.45)))
    write_wav(os.path.join(SFX_DIR, "pickup.wav"),
              tone(660, 990, 0.10, "square", 0.32))
    write_wav(os.path.join(SFX_DIR, "upgrade.wav"),
              mix(tone(523, 523, 0.09, "square", 0.3),
                  [0.0] * int(SR * 0.09) + tone(659, 659, 0.09, "square", 0.3),
                  [0.0] * int(SR * 0.18) + tone(784, 784, 0.16, "square", 0.3)))


def main():
    os.makedirs(SPRITE_DIR, exist_ok=True)
    sprites = {
        "survivor.png": make_survivor(),
        "zombie_walker.png": make_zombie((107, 142, 35, 255), (85, 107, 47, 255), (85, 107, 47, 255)),
        "zombie_runner.png": make_zombie((184, 198, 43, 255), (154, 168, 33, 255), (154, 168, 33, 255), 16, 4.9),
        "zombie_brute.png": make_brute(),
        "coin.png": make_coin(),
        "medkit.png": make_medkit(),
        "bullet.png": make_bullet(),
        "ground.png": make_ground(),
    }
    for name, px in sprites.items():
        write_png(os.path.join(SPRITE_DIR, name), len(px[0]), len(px), px)
        print("sprite:", name, f"{len(px[0])}x{len(px)}")
    icons = {
        "icon_512.png": make_icon(512),
        "adaptive_fg.png": make_adaptive_fg(432),
        "adaptive_bg.png": make_adaptive_bg(432),
    }
    icon_dir = os.path.join(ROOT, "assets", "icon")
    os.makedirs(icon_dir, exist_ok=True)
    for name, px in icons.items():
        write_png(os.path.join(icon_dir, name), len(px[0]), len(px), px)
        print("icon:", name, f"{len(px[0])}x{len(px)}")
    build_audio()
    print("sfx: 6 file")


if __name__ == "__main__":
    main()
