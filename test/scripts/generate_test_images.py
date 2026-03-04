#!/usr/bin/env python3

import binascii
import os
import struct
import zlib


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "fixtures"))
IMAGES = os.path.join(ROOT, "images")
EXPLORER = os.path.join(ROOT, "explorer")


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def chunk(kind, data):
    length = struct.pack(">I", len(data))
    csum = zlib.crc32(kind + data) & 0xFFFFFFFF
    return length + kind + data + struct.pack(">I", csum)


def write_png(path, r, g, b):
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    raw = bytes([0, r, g, b])
    idat = zlib.compress(raw)
    data = sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(data)


def write_gif(path):
    # 1x1 black pixel GIF89a
    hex_data = (
        "47494638396101000100800000000000ffffff21f90401000000002c00000000"
        "010001000002024401003b"
    )
    with open(path, "wb") as f:
        f.write(binascii.unhexlify(hex_data))


def write_bmp(path, r, g, b):
    # 1x1 24-bit BMP (BGR order)
    row = bytes([b, g, r]) + b"\x00"  # row padded to 4 bytes
    pixel_offset = 54
    file_size = pixel_offset + len(row)
    dib_size = 40
    width = 1
    height = 1
    planes = 1
    bpp = 24
    compression = 0
    image_size = len(row)
    xppm = 2835
    yppm = 2835
    colors_used = 0
    important = 0

    header = b"BM" + struct.pack("<IHHI", file_size, 0, 0, pixel_offset)
    dib = struct.pack(
        "<IIIHHIIIIII",
        dib_size,
        width,
        height,
        planes,
        bpp,
        compression,
        image_size,
        xppm,
        yppm,
        colors_used,
        important,
    )

    with open(path, "wb") as f:
        f.write(header)
        f.write(dib)
        f.write(row)


def main():
    ensure_dir(IMAGES)
    ensure_dir(os.path.join(EXPLORER, "nested"))

    write_png(os.path.join(IMAGES, "pixel.png"), 255, 0, 0)
    write_gif(os.path.join(IMAGES, "pixel.gif"))
    write_bmp(os.path.join(IMAGES, "pixel.bmp"), 0, 255, 0)

    write_png(os.path.join(EXPLORER, "sample.png"), 0, 0, 255)
    write_gif(os.path.join(EXPLORER, "nested", "sample.gif"))
    write_bmp(os.path.join(EXPLORER, "nested", "sample.bmp"), 255, 255, 0)

    write_png(os.path.join(EXPLORER, ".hidden.png"), 255, 0, 255)

    print("Generated fixtures under test/fixtures/images and test/fixtures/explorer")


if __name__ == "__main__":
    main()
