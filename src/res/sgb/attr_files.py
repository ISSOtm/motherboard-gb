#!/usr/bin/python3

from sys import argv
import json

assert len(argv) > 2, "Usage: {} attr_files.json ... attr_files.bin".format(argv[0])


with open(argv[1], "rt") as json_file:
    attr_file_data = json.load(json_file)

data = []
for attr_file_name in attr_file_data:
    with open("attr_files/" + attr_file_name, "rt") as attr_file:
        for y in range(18): # An attribute file should be 18 rows, 20 cols
            line = tuple(map(int, attr_file.readline().replace("\n", "").split(" ")))
            assert len(line) == 20
            assert True not in map(lambda x: x >= 4, line) # All values must be 2-bit, tops
            for byte_x in range(0, 20, 4):
                byte = 0
                for bit_x in range(4):
                    byte = (byte << 2) | line[byte_x + bit_x]
                data.append(byte)

with open(argv[-1], "wb") as out_file:
    out_file.write(bytes(data))
