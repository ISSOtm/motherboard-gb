#!/usr/bin/env python3

from pathlib import Path
import json


lines = ["\tenum_start\n"]
for map_file_name in Path("src/res/maps/").rglob("*/*.json"):
    with open(map_file_name, "rt") as map_file:
        lines.append("\tenum_elem MAP_{}\n".format(json.load(map_file)["name"].upper()))

with open("src/constants/maps.asm", "wt") as f:
    f.writelines(lines)
