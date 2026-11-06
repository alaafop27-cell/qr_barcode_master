#!/usr/bin/env python3
"""Draws the app launcher icon with pure Python (no Pillow needed) and writes
it into every android mipmap folder. Called by patch_android.py in CI.

Design: blue gradient, white QR-style pattern with 3 finder squares and an
amber scan line.
"""
import glob
import os
import struct
import zlib

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

BLUE_A = (43, 108, 255)
BLUE_B = (6, 40, 140)
WHITE = (255, 255, 255)
AMBER = (255, 193, 7)

GRID = 15            # modules per side
X0, SPAN = 0.20, 0.60
CELL = SPAN / GRID
FINDERS = [(0, 0), (10, 0), (0, 10)]   # top-left corner of each 5x5 finder


def _lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def _module(ix, iy):
    """True if the module at grid position (ix, iy) is white."""
    for fx, fy in FINDERS:
        if fx <= ix < fx + 5 and fy <= iy < fy + 5:
            cx, cy = ix - fx, iy - fy
            ring = cx in (0, 4) or cy in (0, 4)
            return ring or (cx == 2 and cy == 2)
        if fx - 1 <= ix < fx + 6 and fy - 1 <= iy < fy + 6:
            return False  # quiet zone around finders
    return ((ix * 73856093) ^ (iy * 19349663)) % 100 < 48


def _color(u, v):
    if abs(v - 0.5) < 0.014 and 0.13 < u < 0.87:
        return AMBER
    if X0 <= u < X0 + SPAN and X0 <= v < X0 + SPAN:
        ix = int((u - X0) / CELL)
        iy = int((v - X0) / CELL)
        if _module(ix, iy):
            return WHITE
    return _lerp(BLUE_A, BLUE_B, (u + v) / 2)


def _render(size):
    ss = 3  # supersampling for smooth edges
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            r = g = b = 0.0
            for sy in range(ss):
                for sx in range(ss):
                    c = _color((x + (sx + 0.5) / ss) / size, (y + (sy + 0.5) / ss) / size)
                    r += c[0]
                    g += c[1]
                    b += c[2]
            n = ss * ss
            row += bytes((round(r / n), round(g / n), round(b / n)))
        rows.append(bytes(row))
    return rows


def _png(size, rows):
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def write_icons(res_dir):
    for folder, size in SIZES.items():
        out_dir = os.path.join(res_dir, folder)
        os.makedirs(out_dir, exist_ok=True)
        with open(os.path.join(out_dir, "ic_launcher.png"), "wb") as f:
            f.write(_png(size, _render(size)))
    # If the template ships an adaptive icon, remove it so our PNG is used.
    for xml in glob.glob(os.path.join(res_dir, "mipmap-anydpi*", "ic_launcher*.xml")):
        os.remove(xml)
    print("App icons written.")


if __name__ == "__main__":
    write_icons(os.path.join("android", "app", "src", "main", "res"))
