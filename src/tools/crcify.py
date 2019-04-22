#!/usr/bin/python3
import sys


# Generate CRC table
crc_table = []
for i in range(0x100):
    value = i << 8
    for _ in range(8):
        value <<= 1
        if value & 0x10000:
            value ^= 0x1021
        value &= 0xFFFF
    crc_table.append(value)


crc_value = 0

def crc_init():
    global crc_value
    crc_value = 0xFFFF

def crc_feed(byte):
    global crc_value
    crc_value ^= byte << 8
    crc_value ^= crc_table[crc_value >> 8]


with open(sys.argv[1], "rb+") as in_file:
    ofs = 0
    bank = 0
    nb_banks = 1
    while bank < nb_banks:
        crc_init()
        for _ in range(0x4000):
            b = in_file.read(1)[0]
            # ROM checksum and CRC's aren't counted
            if ofs < 0x14E or ofs >= 0x150 + nb_banks * 2:
                if ofs == 0x148:
                    nb_banks = 2**(b+1)
                crc_feed(b)
            ofs += 1
        
        in_file.seek(0x150 + bank * 2)
        encoded_crc = []
        for _ in range(2):
            encoded_crc.append(crc_value & 0xFF)
            crc_value >>= 8
        in_file.write(bytes(encoded_crc))
        in_file.seek(ofs)

        bank += 1
