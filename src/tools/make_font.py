#!/usr/bin/env python3

from PIL import Image
from sys import argv


assert len(argv) > 2, "Usage:\n\t{} input_file output_file".format(argv[0])

with Image.open(argv[1]) as img:
    bg_color   = img.getpixel((0, 0))
    fg_color   = img.getpixel((1, 0))
    null_color = img.getpixel((2, 0))

    width, height = img.size
    assert width % 8 == 0, "The source image's width must be a multiple of 8!"
    assert height % 8 == 1, "The source image's height must be a multiple of 8, plus 1!"

    data = []

    for ty in range(0, height - 1, 8):
        for tx in range(0, width, 8):
            size = 0
            for y in range(ty + 1, ty + 9):
                byte = 0
                size = 8
                for x in range(tx, tx + 8):
                    byte <<= 1
                    pixel = img.getpixel((x, y))
                    if pixel == fg_color:
                        byte |= 1
                    elif pixel == null_color:
                        size -= 1
                data.append(byte)
            data.append(size + 1)

with open(argv[2], "wb") as output:
    output.write(bytes(data))
