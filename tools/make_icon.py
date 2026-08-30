#!/usr/bin/env python3
"""Draw the Make It Rain launcher icon - a dollar sign over a green disc.

Rasterised from a small set of stdlib-only shape tests in a 60x60 design
space with 4x supersampling, at whatever pixel size a device's launcher slot
needs. No PNG/imaging library required, so it runs anywhere the build runs.

    python3 tools/make_icon.py resources/drawables/launcher_icon.png 96
"""
import struct
import sys
import zlib

DESIGN = 60.0
SS = 4

BG = (0x0A, 0x0A, 0x0A, 255)
RING = (0x00, 0xAA, 0x33, 255)
DOLLAR = (0x00, 0xFF, 0x55, 255)
CLEAR = (0, 0, 0, 0)


def in_disc(px, py, cx, cy, r):
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r


def in_ring(px, py, cx, cy, r0, r1):
    d2 = (px - cx) ** 2 + (py - cy) ** 2
    return r0 * r0 <= d2 <= r1 * r1


def in_bar(px, py, x0, y0, x1, y1, half):
    dx, dy = x1 - x0, y1 - y0
    length2 = dx * dx + dy * dy
    if length2 == 0.0:
        return in_disc(px, py, x0, y0, half)
    t = ((px - x0) * dx + (py - y0) * dy) / length2
    t = max(0.0, min(1.0, t))
    return (px - (x0 + t * dx)) ** 2 + (py - (y0 + t * dy)) ** 2 <= half * half


def in_s_arc(px, py, cx, cy, r, thick, top):
    """Half of a ring - the top or bottom curl of the dollar sign's S."""
    if not in_ring(px, py, cx, cy, r - thick, r + thick):
        return False
    return (py <= cy) if top else (py >= cy)


def sample(px, py):
    colour = CLEAR
    if in_disc(px, py, 30, 30, 29.0):
        colour = BG
    if in_ring(px, py, 30, 30, 26.0, 29.0):
        colour = RING

    # The dollar sign: a vertical stroke through two opposed half-rings.
    if in_s_arc(px, py, 30.0, 22.0, 9.0, 2.4, top=False):
        colour = DOLLAR
    if in_s_arc(px, py, 30.0, 38.0, 9.0, 2.4, top=True):
        colour = DOLLAR
    if in_bar(px, py, 30.0, 12.0, 30.0, 48.0, 2.2):
        colour = DOLLAR

    return colour


def render(size):
    scale = DESIGN / size
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            r = g = b = a = 0.0
            for sy in range(SS):
                for sx in range(SS):
                    px = (x + (sx + 0.5) / SS) * scale
                    py = (y + (sy + 0.5) / SS) * scale
                    sr, sg, sb, sa = sample(px, py)
                    weight = sa / 255.0
                    r += sr * weight
                    g += sg * weight
                    b += sb * weight
                    a += weight
            n = float(SS * SS)
            alpha = a / n
            if alpha > 0.0001:
                row += bytes((
                    min(255, int(round(r / n / alpha))),
                    min(255, int(round(g / n / alpha))),
                    min(255, int(round(b / n / alpha))),
                    int(round(alpha * 255)),
                ))
            else:
                row += bytes((0, 0, 0, 0))
        rows.append(bytes(row))
    return rows


def write_png(path, rows, size):
    raw = b"".join(b"\x00" + row for row in rows)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data +
                struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as handle:
        handle.write(png)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: make_icon.py <output.png> <size>")
    path = sys.argv[1]
    size = int(sys.argv[2])
    write_png(path, render(size), size)
    print("wrote %s (%dx%d)" % (path, size, size))


if __name__ == "__main__":
    main()
