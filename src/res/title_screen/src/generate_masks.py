#!/usr/bin/python3

files = (
    "frame_0",
    "frame_1",
    "frame_2"
)

x_size,y_size = 160,144
tile_size = 8
bit_depth = 2

# Raw tilemap dump from BGB (a little less than 600 bytes)
tile_map_raw = "010203040506070809000000000A0B0C0D0E0F10000000000000000000000000111213141516170000000018191A1B1C1D1E1F20000000000000000000000000212223242526000000002728292A2B2C2D2E2F300000000000000000000000003132333435360000003738393A3B00003C3D3E3F000000000000000000000000404142434400000045464748494A0000004B4C4D0000000000000000000000004E4F5051520000535455565758595A005B5C5D5E0000000000000000000000005F6061626300006465666768696A6B6C6D6E6F70000000000000000000000000717273747500767778797A7B7C7D007E7F808182000000000000000000000000838485868788898A8B8C8D8E8F9091000092939400000000000000000000000095969798999A9B9C9D9E9FA0A1A2A30000A4A5A6000000000000000000000000A7A8A9AAABACADAEAFB0B1B2B3B4B5B600B7B8B9000000000000000000000000BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCD000000000000000000000000CECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1000000000000000000000000E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F100F2F3F4000000000000000000000000F5F6F7F8F9FAFBFCFDFEFF01020304050000060700000000000000000000000008090A0B0C0D0E0F101112131415161718191A1B0000000000000000000000001C1D1E1F202122232425262728292A2B2C2D2E2F000000000000000000000000303132333435363738393A3B3C3D3E3F404142430000000000000000000000000"
tile_map = []
third_block = False
for y in range(y_size // tile_size):
    for x in range(x_size // tile_size):
        num = int(tile_map_raw[(y * 32 + x) * 2:(y * 32 + x) * 2 + 2], 16)
        if num == 0x80:
            third_block = True
        if num < 0x80 and third_block:
           num = num + 0x100 
        tile_map.append(num)


split_IDs = [-1, 0x80, 0x101]


cur_file_names = (None,None)
cur_files = (None,None)

try:
    for file_name in files:
        cur_file_names = (cur_file_names[1], file_name)

        if cur_files[0]:
            cur_files[0].close()
        cur_files = (cur_files[1], open("src/{}_raw.chr".format(file_name), "rb"))

        if cur_file_names[0]:
            cur_files[0].seek(0)
            # Create file that diffs both frames

            def get_diffs():
                for ID in range((x_size // tile_size) * (y_size // tile_size)):
                    cur_diff = []
                    is_blank = [True, True]
                    is_different = False
                    for _ in range(tile_size * bit_depth):
                        orig_byte = cur_files[0].read(1)[0]
                        new_byte = cur_files[1].read(1)[0]
                        
                        if orig_byte != 0:
                            is_blank[0] = False
                        if new_byte != 0:
                            is_blank[1] = False
                        if orig_byte != new_byte:
                            is_different = True
                        
                        cur_diff.append(orig_byte ^ new_byte)
                    
                    if is_different:
                        if tile_map[ID] % 0x100 == 0:
                            print("WARNING: Acting on blank tile with ID {}".format(ID))
                        yield {"ID": tile_map[ID], "data": cur_diff}

            with open("{}_xor_{}.bin".format(*cur_file_names), "wb") as diff_file:
                run = {"first_ID": -1, "last_ID": None, "data": []}
                # Commit the run to the output file
                def commit_run():
                    # Structure:
                    # 1st byte = dest high byte
                    # 2nd byte = dest low byte | nb of tiles
                    # Then, the XOR masks, sequentially
                    if run["first_ID"] < 0x80:    # 0x00-0x7F
                        base_ptr = 0x9000
                    elif run["first_ID"] < 0x100: # 0x80-0xFF
                        base_ptr = 0x8800 - 0x800
                    else:                         # 0x100-0x17F
                        base_ptr = 0x8000 - 0x1000
                    target_addr = run["first_ID"] * 16 + base_ptr
                    run_len = run["last_ID"] - run["first_ID"] + 1
                    if run_len == 16:
                        run_len = 0
                    diff_file.write(bytes((target_addr // 256, target_addr % 256, run_len)))
                    diff_file.write(bytes(run["data"]))
                
                for diff in get_diffs():
                    # Check if the previous run has ended
                    # Also force splits when changing blocks
                    if diff["ID"] in split_IDs or run["first_ID"] == -1 or run["last_ID"] < diff["ID"] - 2:
                        if run["first_ID"] != -1:
                            # End previous run if there is one
                            commit_run()
                        # Start new run
                        run = {"first_ID": diff["ID"], "last_ID": diff["ID"], "data": diff["data"]}

                    else:
                        if run["last_ID"] == diff["ID"] - 2:
                            # Allow 1-tile gaps in runs
                            run["data"].extend([0] * 16)
                        # Append to run
                        run["data"].extend(diff["data"])
                        run["last_ID"] = diff["ID"]
                commit_run() # Commit last run (which cannot be empty)
                diff_file.write(bytes((0, 0)))
        
finally:
    for file in cur_files:
        if file:
            file.close()
