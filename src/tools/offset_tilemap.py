#!/usr/bin/env python3

from sys import argv


assert len(argv) >= 3, f"Usage: {argv[0]} path/to/input.tilemap path/to/output.%X.offset.tilemap"


second_arg = argv[2].split(".")
offset = int(second_arg[-3], 16)

with open(argv[1], "rb") as input:
    with open(argv[2], "wb") as output:    
        output.write(bytes((byte + offset  for byte in input.read())))
