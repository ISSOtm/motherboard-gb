#!/usr/bin/python3

from sys import argv
import json

assert len(argv) > 2, "Usage: {} palettes.json palettes.bin".format(argv[0])


def bytes_from_color(color):
    # RRRR RXXX GGGG GXXX BBBB BXXX
    #             \/
    #           0BBB BBGG GGGR RRRR
    return ((color & 0xF8) << 7 | (color & 0xF800) >> 6 | (color & 0xF80000) >> 19).to_bytes(2, "little")


with open(argv[1], "rt") as json_file:
    pal_data = json.load(json_file)

with open(argv[2], "wb") as out_file:
    for palette in pal_data:
        for color in palette:
            out_file.write(bytes_from_color(int(color, 16)))
