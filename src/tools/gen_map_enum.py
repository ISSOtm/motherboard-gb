#!/usr/bin/env python3

from pathlib import Path
import json
from sys import argv
import re

assert len(argv) >= 2, f"Usage:\t{argv[0]} path/to/src/maps.asm"


control_comment = re.compile("^\s*;#")
include_file = re.compile("^\s*INCLUDE\s+\"maps/(?P<filename>.+)\.asm\"", re.IGNORECASE)

lines = ["\tenum_start\n"]
with open(argv[1], "rt") as maps_file:
    while not control_comment.match(maps_file.readline()):
        pass
    while True:
        line = maps_file.readline()
        if control_comment.match(line):
            break
        map_file_name = include_file.match(line).group("filename")
        with open(f"src/res/maps/{map_file_name}/{map_file_name}.json", "rt") as map_file:
            lines.append(f"\tenum_elem MAP_{json.load(map_file)['name'].upper()}\n")

with open("src/constants/maps.asm", "wt") as f:
    f.writelines(lines)
