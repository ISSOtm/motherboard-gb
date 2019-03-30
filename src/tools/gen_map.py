#!/usr/bin/python3

from sys import argv
from PIL import Image
import json
from pathlib import Path


# For side-scrolling maps:
# Each tilemap row has associated tiles
# The tiles are loaded at the same time as the tilemap
# TODO: Make sure to offset rows so they never update tiles on the same pixel (doable since they have shifted scroll amounts)


assert len(argv) >= 2, "Usage: {} path/to/metadata.json [ignored_args]".format(argv[0])

path = Path(argv[1])
with open(path, "rt") as jsonfile:
    metadata = json.load(jsonfile)
size = ()
scroll_lines = [] # Lines specific to the scroll type


if metadata["scroll_type"] == "SCROLLING_HORIZ":
    tiles = []
    ref_cnts = []

    width = 160

    for layer in metadata["layers"]:
        layer["col_data"] = [] # Init this for later
        with Image.open("{}/{}.png".format(path.parent, layer["ID"])) as img:

            layer["width"],layer["height"] = img.size
            if layer["ratio"] != -1:
                layer_width = layer["width"] << layer["ratio"]
                if layer_width > width:
                    width = layer_width
            assert layer["width"] % 8 == 0 and layer["height"] % 8 == 0, "Image size must be a multiple of 8 pixels"

            # Iterate over the image once to form its palette
            palette = set()
            for x in range(layer["width"]):
                for y in range(layer["height"]):
                    palette.add(img.getpixel((x, y)))
            palette = list(palette)
            # If image is RGB (therefore returns a tuple), put brightest color in first position
            if type(palette[0]) == tuple:
                palette.sort(key=lambda l: sum(l)/3, reverse=True)

            layer["columns"] = []

            for col in range(0, layer["width"], 8): # Iterate on all columns
                column = [] # Tilemap for this column
                col_tiles = set() # List of all tiles for this column (for ref counting)
                for row in range(0, layer["height"], 8): # Iterate on all rows in the column

                    tile = [ [ palette.index(img.getpixel((x, y))) for x in range(col, col+8) ] for y in range(row, row+8) ]
                    assert True not in map(lambda l: True not in map(lambda x: x <= 3, l), tile), "Error in tile (x: {}, y: {})".format(col, row)
                    try:
                        index = tiles.index(tile)
                    except ValueError:
                        index = len(tiles)
                        tiles.append(tile)
                        ref_cnts.append(0)
                    column.append(index)
                    col_tiles.add(index)

                for index in col_tiles:
                    # If the layer is static, ensure all its tiles are "common"
                    if layer["ratio"] == -1:
                        ref_cnts[index] += 2
                    else:
                        ref_cnts[index] += 1
                layer["columns"].append(column)

    if width > 0x800:
        print("*** WARNING: code is not equipped to handle side-scrolling maps larger than {} pixels!!".format(0x800), file=sys.stderr)

    # Tiles are laid out in a simple way:
    # First, all shared tiles in a single block
    # Then, the location where tiles will be loaded as rows are retraced
    shared_tile_ids = [] # IDs in the 
    cur_tile = 128

    # Compute all "shared" tiles
    for tile_id in range(len(tiles)):
        if ref_cnts[tile_id] != 1:
            shared_tile_ids.append(tile_id)
            cur_tile = (cur_tile + 1) % 256

    first_tile = cur_tile


    for cam_x in range(width):
        for layer in metadata["layers"]:
            if layer["ratio"] != -1: # Don't process static layers, since their tiles have all been marked as common anyways
                old_col = ((cam_x - 1) >> layer["ratio"]) >> 3
                new_col = (cam_x >> layer["ratio"]) >> 3
                if old_col != new_col:

                    # New challenger! I mean column!
                    start_tile = cur_tile
                    column = []
                    col_tiles = []
                    nonunique_indexes = []
                    for tile_id in layer["columns"][new_col]:
                        if ref_cnts[tile_id] == 1:
                            # Unique tile
                            if cur_tile == 128: # Wrap around the space left by the shared tiles, not everything
                                cur_tile = first_tile
                                for index in nonunique_indexes:
                                    column[index] = cur_tile
                                    cur_tile += 1
                                start_tile = first_tile # Modify start location
                            nonunique_indexes.append(len(column))
                            column.append(cur_tile)
                            col_tiles.append(tiles[tile_id])
                            cur_tile = (cur_tile + 1) % 256
                        else:
                            # Shared tile
                            column.append((shared_tile_ids.index(tile_id) + 128) % 256)
                    layer["col_data"].append((column, col_tiles, start_tile))


    with open(Path("{}/{}.chr".format(path.parent, path.stem)), "wb") as f:
        # Write shared tiles
        for tile_id in shared_tile_ids:
            for row in tiles[tile_id]:
                f.write(int("".join(map(lambda x: str(x  & 1), row)), 2).to_bytes(1, "little"))
                f.write(int("".join(map(lambda x: str(x >> 1), row)), 2).to_bytes(1, "little"))

    height = 144
    scroll_lines.append("\tdb {} - 16 ; SCY\n".format(metadata["scy"]))
    scroll_lines.append("\n\tdb {} ; Nb layers\n".format(len(metadata["layers"])))
    for layer_id in range(len(metadata["layers"])):
        layer = metadata["layers"][layer_id]
        scroll_lines.append("\n")
        scroll_lines.append("\tdb {} ; Scroll ratio\n".format(layer["ratio"]))
        scroll_lines.append("\tdb {} ; Height (tiles)\n".format(int(layer["height"] / 8)))
        nb_cols = len(layer["col_data"])
        scroll_lines.append("\tdbankw {}MapLayer{}\n".format(path.stem, layer_id))
        scroll_lines.append("\tPUSHS\n")
        scroll_lines.append("SECTION \"{} map layer {}\", ROMX\n".format(path.stem, layer_id))
        scroll_lines.append("{}MapLayer{}:\n".format(path.stem, layer_id))
        if layer["ratio"] == -1:
            # Static layers instead store the tilemap in standard format
            for i in range(len(layer["columns"][0])):
                scroll_lines.append("\tdb {}\n".format(", ".join([str(column[i] ^ 128) for column in layer["columns"]])))
        else:
            scroll_lines.extend(["\tdw .col{}\n".format(i) for i in range(nb_cols)]) # All pointers to column data
            for col_id in range(nb_cols):
                scroll_lines.append("\n.col{}\n".format(col_id))
                column = layer["col_data"][col_id]
                scroll_lines.append("\tdb {}\n".format(", ".join(map(str, column[0])))) # Tile map
                col_len = len(column[1])
                scroll_lines.append("\tdb {}\n".format(col_len)) # Nb of tiles in col map
                if col_len:
                    scroll_lines.append("\tdb {}\n".format(column[2] ^ 0x80)) # Destination tile ID (such that 0 is $8800)
                    for tile in column[1]:
                        scroll_lines.append("\tdw {}\n".format(", ".join( ["`" + "".join(map(str, row)) for row in tile] )))
        scroll_lines.append("\tPOPS\n")
    nb_shared_tiles = len(shared_tile_ids)


elif metadata["scroll_type"] == "SCROLLING_4_WAY":
    with Image.open("{}/{}.png".format(path.parent, path.stem)) as img:
        width,height = img.size
    if height // 8 > 256:
        print("*** WARNING: code is not equipped to handle maps taller than {} pixels!".format(0x800))
    if width // 8 > 256:
        print("*** WARNING: code is not equipped to handle maps wider than {} pixels!".format(0x800))

    scroll_lines.append("\tdbankw {}Tilemap\n".format(path.stem))
    scroll_lines.append("\tPUSHS\n")
    scroll_lines.append("SECTION \"{} map tilemap\", ROMX\n".format(path.stem))
    scroll_lines.append("{}Tilemap:\n".format(path.stem))
    scroll_lines.append("INCBIN \"{}/{}.bit7.tilemap\"\n".format(path.parent, path.stem)) # Require a bit7-flipped tilemap
    scroll_lines.append("\tPOPS\n")
    nb_shared_tiles = Path("{}/{}.chr".format(path.parent, path.stem)).stat().st_size // 16


else:
    raise ValueError("Unknown scrolling type {}".format(metadata["scroll_type"]))


assert nb_shared_tiles < 256, "Maps cannot load more than 256 tiles!"
assert len(metadata["warp-tos"]) <= 16, "Maps cannot have more than 16 warp-to points!"


# Write the metadata
lines = ["; This is auto-generated ASM. Be careful if hand-modifying it.\n; ~ gen_map.py\n\n"]
lines.append("\tdb {} ; DMG BGP\n".format(int(metadata["bgp"], 2)))
lines.append("\tdb {}, {}, {}, {} ; SGB BGP, OBP0, OBP1, textbox pal\n".format(int(metadata["sgb"]["bgp"], 2), int(metadata["sgb"]["obp0"], 2), int(metadata["sgb"]["obp1"], 2), int(metadata["sgb"]["text_pal"], 2)))
lines.append("\tdw {} ; SGB palettes\n".format(", ".join(map(str, metadata["sgb"]["palettes"]))))
lines.append("\tdb $80 | {} ; SGB attribute file number\n".format(metadata["sgb"]["attr_file"]))
lines.append("\tdw {}, {} ; Height, width\n".format(height,width))
lines.append("\tdbankw {} ; Map script pointer\n".format(metadata["map_script"]))

lines.append("\n\tdb {} ; Number of NPCs\n".format(len(metadata["npcs"])))
for npc in metadata["npcs"]:
    lines.append("\tdw {}, {} ; Y,X pos\n".format(npc["y"], npc["x"]))
    lines.append("\tdb {} ; Base attr\n".format(npc["attr"]))
    lines.append("\tdb BANK({}DrawPtrs) ; Display struct bank\n".format(npc["name"]))
    lines.append("\tdw {}DrawPtrs ; Display struct ptr\n".format(npc["name"]))
    lines.append("\tdw {}\n".format(npc["processor"]))
    lines.append("\tdb BANK({}Tiles)\n".format(npc["name"]))
    lines.append("\tdw {}Tiles\n".format(npc["name"]))
    lines.append("\tdb ({}TilesEnd - {}Tiles) / 16 ; Number of tiles\n".format(npc["name"], npc["name"]))

lines.append("\n\tdb {} ; Number of triggers\n".format(len(metadata["triggers"])))
if len(metadata["triggers"]) != 0:
    i = 0
    arg_ofs = 0
    for trigger in metadata["triggers"]:
        lines.append("\tdstruct Trigger, .trigger{}, TRIGGER_{}, {}, {}, {} - 1, {} - 1, LOW(wTriggerArgPool) + {}\n".format(i, trigger["type"].upper(), trigger["y"], trigger["y_size"], trigger["x"], trigger["x_size"], arg_ofs))
        i += 1
        arg_ofs += len(trigger["args"])
    lines.append("\tdb {} ; Number of arg bytes\n".format(arg_ofs))
    i = 0
    for trigger in metadata["triggers"]:
        lines.append("\tdb {} ; Trigger {} args\n".format(", ".join(trigger["args"]), i))
        i += 1

lines.append("\n\tdw .warpData\n")

lines.append("\n\tdb {} ; Scroll type\n".format(metadata["scroll_type"]))
lines.extend(scroll_lines)

lines.append("\n\tdb {} ; Nb tiles\n".format(nb_shared_tiles)) # Nb of tiles
lines.append("INCBIN \"{}/{}.chr.pb16\"\n".format(path.parent, path.stem)) # Tiles
lines.append("\n.warpData\n")
for warpto in metadata["warp-tos"]:
    lines.append("\tdw {}, {} ; Player Y pos, X pos\n".format(warpto["y"], warpto["x"]))
    lines.append("\tdb ; Camera behavior\n")
    lines.append("\tdw {} ; Processor\n\n".format(warpto["processor"]))



with open("{}/{}.asm".format(path.parent, path.stem), "wt") as f:
    f.writelines(lines)
