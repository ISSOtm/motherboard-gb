; This is auto-generated ASM. Be careful if hand-modifying it.
; ~ gen_map.py

	db 27 ; DMG BGP
	db 216, 39, 0, 107 ; SGB BGP, OBP0, OBP1, textbox pal
	dw 1, 2, 3, 0 ; SGB palettes
	db $80 | 0 ; SGB attribute file number
	dw 144, 568 ; Height, width
	dbankw VillageMapScript ; Map script pointer

	db 1 ; Number of NPCs
	dw 128, 298 ; Y,X pos
	db 0 ; Base attr
	db BANK(BikeDrawPtrs) ; Display struct bank
	dw BikeDrawPtrs ; Display struct ptr
	dw EmptyFunc
	db BANK(BikeTiles)
	dw BikeTiles
	db (BikeTilesEnd - BikeTiles) / 16 ; Number of tiles

	db 1 ; Number of triggers
	dstruct Trigger, .trigger0, TRIGGER_BTNTRIGGER, 128, 1, 200 - 1, 32 - 1, LOW(wTriggerArgPool) + 0
	db 5 ; Number of arg bytes
	db PADF_A, TRIGTYPE_WARP, MAP_WHITE_HOUSE, 0, 8 << 1 ; Trigger 0 args

	dw .warpData

	db SCROLLING_HORIZ ; Scroll type
	db 2 - 16 ; SCY

	db 2 ; Nb layers

	db -1 ; Scroll ratio
	db 4 ; Height (tiles)
	dbankw villageMapLayer0
	PUSHS
SECTION "village map layer 0", ROMX
villageMapLayer0:
	db 128, 132, 134, 137, 137, 137, 144, 147, 147, 150, 153, 156, 158, 160, 147, 147, 147, 147, 147, 147
	db 129, 133, 135, 138, 140, 140, 145, 148, 147, 151, 154, 140, 140, 161, 163, 147, 164, 165, 166, 147
	db 130, 130, 136, 139, 140, 142, 146, 149, 130, 152, 155, 157, 159, 162, 130, 130, 130, 130, 130, 130
	db 131, 131, 131, 131, 141, 143, 131, 131, 131, 131, 131, 131, 131, 131, 131, 131, 131, 131, 131, 131
	POPS

	db 0 ; Scroll ratio
	db 15 ; Height (tiles)
	dbankw villageMapLayer1
	PUSHS
SECTION "village map layer 1", ROMX
villageMapLayer1:
	dw .col0
	dw .col1
	dw .col2
	dw .col3
	dw .col4
	dw .col5
	dw .col6
	dw .col7
	dw .col8
	dw .col9
	dw .col10
	dw .col11
	dw .col12
	dw .col13
	dw .col14
	dw .col15
	dw .col16
	dw .col17
	dw .col18
	dw .col19
	dw .col20
	dw .col21
	dw .col22
	dw .col23
	dw .col24
	dw .col25
	dw .col26
	dw .col27
	dw .col28
	dw .col29
	dw .col30
	dw .col31
	dw .col32
	dw .col33
	dw .col34
	dw .col35
	dw .col36
	dw .col37
	dw .col38
	dw .col39
	dw .col40
	dw .col41
	dw .col42
	dw .col43
	dw .col44
	dw .col45
	dw .col46
	dw .col47
	dw .col48
	dw .col49
	dw .col50
	dw .col51
	dw .col52
	dw .col53
	dw .col54
	dw .col55
	dw .col56
	dw .col57
	dw .col58
	dw .col59
	dw .col60
	dw .col61
	dw .col62
	dw .col63
	dw .col64
	dw .col65
	dw .col66
	dw .col67
	dw .col68
	dw .col69
	dw .col70

.col0
	db 147, 233, 147, 147, 167, 234, 168, 235, 236, 237, 238, 169, 170, 171, 172
	db 6
	db 105
	dw `11122222, `12212222, `22211222, `22221222, `22222122, `22222122, `22222212, `22222221
	dw `00021212, `21200001, `12121210, `21212121, `00021212, `21200000, `12121212, `21212121
	dw `12121211, `21212111, `12121121, `21211331, `12121332, `21213322, `12133222, `21132222
	dw `11332222, `21222222, `13222222, `32222222, `32222222, `32222222, `32222222, `32222222
	dw `22222222, `22222222, `22222222, `22222222, `12222222, `12222222, `11222222, `21222222
	dw `21222222, `21122222, `22122222, `22122222, `22212222, `22212222, `22221222, `22221122

.col1
	db 147, 147, 173, 147, 174, 239, 240, 241, 242, 243, 147, 175, 176, 177, 172
	db 5
	db 111
	dw `12121212, `21212121, `00021212, `21200000, `12121212, `21212121, `00000012, `21212100
	dw `12121211, `21212111, `12121111, `21211111, `12121211, `21112111, `12133111, `12233111
	dw `33332111, `32222111, `32221111, `12222122, `12221122, `12221111, `11211111, `21210111
	dw `22000011, `21100000, `21110001, `21111111, `22111111, `22111111, `21111111, `21111111
	dw `21011111, `20011111, `22111111, `21101111, `20001011, `22200001, `22200000, `22222200

.col2
	db 147, 178, 147, 147, 167, 244, 245, 179, 179, 246, 247, 248, 180, 181, 172
	db 5
	db 116
	dw `12111212, `21111121, `12111212, `21111111, `00000112, `21111000, `11111111, `00000000
	dw `11111111, `12211111, `12211110, `11111000, `11100000, `11111111, `11111111, `11111111
	dw `11111111, `11111221, `10111221, `10011111, `11000110, `11000000, `00000000, `02000000
	dw `22010122, `22001122, `22010122, `22001122, `22010122, `22001122, `22010122, `22001122
	dw `22010122, `22001122, `22010122, `22001122, `22010122, `22001122, `22010122, `22001122

.col3
	db 147, 182, 183, 147, 174, 249, 250, 251, 252, 253, 184, 185, 186, 187, 172
	db 5
	db 121
	dw `12121212, `21212121, `12111111, `11133332, `33332222, `00000222, `22222000, `22222222
	dw `00000000, `22222222, `02222222, `01222222, `11222222, `11122222, `11122222, `11112222
	dw `11112222, `11122222, `11122222, `10002222, `00002222, `10012222, `11111222, `11111222
	dw `11112222, `11110122, `11111122, `11001122, `11111112, `11111112, `11111002, `11111100
	dw `11111111, `11111111, `11111101, `00111000, `00100000, `00000022, `02222222, `22222222

.col4
	db 147, 147, 188, 189, 167, 254, 190, 169, 147, 147, 191, 147, 170, 171, 172
	db 1
	db 126
	dw `12121211, `11111133, `33333333, `12222222, `12222222, `12222222, `00000022, `21222200

.col5
	db 147, 147, 147, 255, 174, 0, 192, 193, 194, 1, 2, 3, 176, 177, 172
	db 5
	db 127
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222221, `12222112, `21111222
	dw `11111111, `33333333, `33333333, `22222222, `22222222, `22222222, `22222222, `00000222
	dw `22222220, `22222220, `22222220, `22222220, `22222220, `22222220, `22222220, `22222220
	dw `22222220, `22222220, `22222220, `22222220, `22222220, `22222220, `22222220, `22222220
	dw `11122220, `21112220, `22211120, `22222110, `22222210, `22222220, `22222220, `22222220

.col6
	db 147, 147, 147, 4, 167, 195, 192, 196, 197, 5, 6, 7, 180, 181, 172
	db 4
	db 132
	dw `22222221, `22222212, `22221122, `22112222, `21122222, `11222222, `22222222, `22222222
	dw `02222222, `02222222, `02222222, `02222222, `02222222, `02222222, `02222222, `02222222
	dw `02222222, `02222222, `02222222, `02222222, `02222222, `02222222, `02222222, `02222222
	dw `02222222, `02222222, `02222222, `02222222, `02222222, `02222222, `02222222, `02222222

.col7
	db 147, 147, 8, 147, 174, 9, 192, 198, 191, 147, 147, 147, 186, 187, 172
	db 2
	db 136
	dw `22222221, `22222212, `22222122, `22221222, `22212222, `22122222, `21222222, `12222222
	dw `11121212, `33111121, `33333311, `22222233, `22222222, `22222222, `22222222, `22222222

.col8
	db 147, 10, 147, 147, 167, 11, 190, 169, 147, 12, 199, 147, 170, 171, 172
	db 3
	db 138
	dw `22222222, `22222111, `22221122, `22211222, `22112222, `21122222, `11222222, `12222222
	dw `12121212, `21212121, `12111212, `13333111, `12233333, `12222333, `11222222, `21222222
	dw `12222222, `21122222, `22211222, `22222111, `22222222, `22222222, `22222222, `22222222

.col9
	db 147, 200, 147, 147, 13, 14, 192, 175, 147, 15, 147, 147, 176, 177, 172
	db 3
	db 141
	dw `22222211, `22222113, `22221331, `21213333, `12113322, `21133322, `11333222, `21332222
	dw `13332222, `33322222, `33222222, `13222222, `12222222, `31112222, `33311222, `23332112
	dw `22222222, `22222222, `22222222, `22222222, `12222222, `21122222, `22211222, `22222111

.col10
	db 147, 147, 201, 16, 17, 147, 18, 147, 184, 147, 19, 147, 180, 181, 172
	db 4
	db 144
	dw `22222221, `22222213, `22222132, `22221332, `22213322, `22133322, `21333222, `13332222
	dw `33322222, `32322222, `32222222, `11222222, `21122222, `22111222, `22221122, `22222211
	dw `00000000, `11222222, `31122222, `33312222, `23331222, `22233122, `22223112, `22222311
	dw `11222222, `22122222, `22212222, `22221222, `22222122, `22222112, `22222211, `22222221

.col11
	db 147, 147, 20, 147, 147, 202, 192, 21, 22, 147, 23, 24, 186, 187, 172
	db 5
	db 148
	dw `22222222, `22222222, `22222222, `22222211, `22221113, `11113333, `21333322, `13322222
	dw `12222222, `31122222, `23112222, `22311222, `22331122, `22233112, `22223312, `22222331
	dw `22222333, `22222233, `22222223, `22222222, `22222222, `11222222, `22112222, `22221111
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222221, `22222221, `22222213
	dw `12222213, `11222132, `21121132, `22121332, `22121322, `22213322, `22213322, `22213322

.col12
	db 147, 147, 25, 147, 203, 26, 192, 147, 27, 28, 29, 147, 170, 171, 172
	db 5
	db 153
	dw `22221111, `22113333, `11333322, `11333222, `31122222, `22111222, `22221122, `22222211
	dw `22222222, `11222222, `11111122, `22221111, `22222221, `22222222, `22222222, `22000000
	dw `12222222, `31222222, `33122222, `23112222, `22312222, `22231222, `22231222, `22223122
	dw `12223122, `21122312, `22211212, `22222111, `22222211, `22222113, `22221132, `22221322
	dw `22213222, `22133222, `21132222, `11322222, `13222222, `13222222, `32222222, `22222222

.col13
	db 147, 30, 147, 202, 147, 31, 192, 147, 32, 33, 147, 147, 176, 177, 172
	db 4
	db 158
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222111, `22111333, `11333323
	dw `22222222, `22222222, `22222222, `22222222, `12222222, `21111112, `20000000, `02222222
	dw `22222222, `22222222, `22222222, `22222222, `22222221, `22222211, `22222113, `22211333
	dw `22113322, `21133222, `11322222, `13222222, `32222222, `22222222, `22222222, `22222222

.col14
	db 34, 35, 147, 204, 147, 36, 192, 37, 38, 39, 40, 147, 180, 181, 172
	db 7
	db 162
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222122, `22222121, `22222111
	dw `22222111, `22222111, `22222111, `22222111, `21111111, `13333333, `33232323, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22000000, `00111222, `22221111
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222221
	dw `22222111, `22221113, `22113311, `11332221, `13322222, `32222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22212222, `22111222, `22111222, `22011221, `22111221
	dw `22110211, `22111111, `12111112, `12111222, `21011222, `22111222, `22111222, `22212222

.col15
	db 41, 42, 203, 205, 147, 43, 44, 45, 46, 147, 147, 147, 186, 187, 172
	db 6
	db 169
	dw `22221222, `22211122, `22221222, `22211122, `22111112, `21111111, `11111111, `11111111
	dw `11112111, `11122211, `11122211, `11122211, `22211122, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222220, `22000002, `00222222, `22222222, `22000000
	dw `00122222, `22211222, `22222111, `22222222, `22222222, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222111, `22211133, `21113332, `13332222
	dw `33222222, `22222222, `22222222, `12222222, `11122222, `22111222, `22221122, `22222211

.col16
	db 47, 48, 147, 49, 147, 50, 206, 51, 147, 202, 147, 147, 170, 171, 172
	db 5
	db 175
	dw `22222222, `22222222, `22222222, `22222222, `22212222, `22212222, `11212222, `11112222
	dw `11112222, `11112222, `11112222, `11111111, `22221133, `22222112, `22222221, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `11111222, `22221111
	dw `22222222, `22222222, `22220000, `00002222, `22222222, `22222220, `20000002, `02222222
	dw `22222221, `22222113, `22111333, `11333322, `33322222, `22222222, `22222222, `22222222

.col17
	db 147, 52, 53, 147, 54, 55, 56, 57, 198, 204, 147, 147, 176, 177, 172
	db 6
	db 180
	dw `22222222, `22222222, `22222222, `12222222, `31111122, `23333311, `12333333, `21122233
	dw `22211222, `22222111, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222
	dw `11122222, `22211222, `22222111, `22222222, `22222222, `22222222, `22222222, `22222000
	dw `22000222, `00222222, `22222222, `22222220, `22220002, `00002222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22221111, `21111333
	dw `11333222, `33222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222

.col18
	db 147, 58, 59, 147, 60, 61, 62, 147, 147, 205, 147, 185, 180, 181, 172
	db 5
	db 186
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `11112222, `33331112, `33333311
	dw `22233333, `11222233, `11111122, `22221111, `22222221, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `11222222, `21000000, `20000000, `00200000, `22222000
	dw `22222220, `22222200, `22220002, `00002222, `22222222, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222111, `22211133, `11111112, `33332221, `33322222

.col19
	db 147, 63, 64, 147, 65, 66, 67, 207, 207, 68, 207, 207, 186, 187, 172
	db 6
	db 191
	dw `22222222, `22222221, `22222211, `22222112, `22221122, `22112222, `11122222, `12222222
	dw `11112222, `33311222, `33333112, `22233311, `12222331, `21111112, `22222221, `22222222
	dw `20222222, `00022222, `00022222, `00022222, `00000000, `00000000, `00000000, `00000022
	dw `00002222, `00000222, `00010002, `00011220, `00021122, `00022112, `00022211, `00022221
	dw `00022222, `00011111, `00033333, `00022222, `00022222, `00022222, `00011222, `00021111
	dw `00022222, `00022222, `00022222, `00022222, `00022222, `00022222, `00011222, `00021111

.col20
	db 147, 69, 70, 71, 72, 73, 195, 74, 147, 147, 75, 147, 170, 171, 172
	db 7
	db 197
	dw `11122222, `12212222, `22212222, `22221222, `22222122, `22222122, `22222212, `22222221
	dw `22222222, `22222222, `22222222, `22222222, `12222222, `31222222, `11112222, `23311222
	dw `23331122, `22233312, `22222331, `22222233, `22222223, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `02222222, `00222222, `20022222, `22200022
	dw `22222200, `22222222, `22222222, `00002222, `22220002, `22222220, `22222222, `22222222
	dw `11122222, `22211222, `22222111, `22222222, `22222222, `22222222, `22222222, `22222222
	dw `11122222, `22211222, `22222111, `22222222, `22222222, `22222222, `22222222, `22222222

.col21
	db 147, 147, 173, 76, 77, 78, 147, 206, 147, 147, 206, 79, 176, 177, 172
	db 4
	db 204
	dw `22222222, `22222222, `22222222, `12222222, `31122222, `23112222, `22311222, `22233122
	dw `22223312, `22222311, `22222231, `22222223, `22222222, `22222222, `22222222, `22222222
	dw `02222222, `20022222, `22200002, `22222220, `22222222, `00002111, `22110000, `11333333
	dw `22222221, `22222111, `22211321, `22122211, `21231101, `21010000, `10000000, `00000000

.col22
	db 147, 178, 147, 147, 80, 81, 147, 82, 83, 84, 85, 86, 180, 181, 172
	db 7
	db 208
	dw `22222222, `22222222, `12221222, `11212122, `21121212, `22112121, `22211212, `22221121
	dw `22222112, `22222211, `22222211, `00001112, `21110000, `12222222, `00222222, `22000000
	dw `22222220, `22222200, `22222011, `22220011, `22200000, `21011110, `20111101, `00000000
	dw `00000000, `21222220, `22112220, `22211220, `22221120, `22222110, `22222210, `22222220
	dw `22211220, `22211120, `22111120, `22121120, `22121110, `22122110, `22121110, `21111110
	dw `21122110, `21211110, `11111110, `21111110, `22222100, `22211100, `22111100, `21111100
	dw `11111000, `11101000, `11001000, `11010001, `00000001, `00000001, `00000001, `00000001

.col23
	db 147, 182, 183, 147, 174, 87, 88, 208, 209, 210, 140, 211, 186, 187, 172
	db 2
	db 215
	dw `12121113, `21113333, `13333222, `33222222, `22222222, `00000000, `22222222, `22222222
	dw `00000000, `22222222, `22222222, `22220000, `22200111, `22001111, `20000000, `00011111

.col24
	db 147, 147, 188, 189, 89, 90, 212, 208, 209, 210, 140, 211, 170, 171, 172
	db 2
	db 217
	dw `22222222, `22222122, `12222212, `21222121, `12122212, `21212111, `12111222, `11211222
	dw `33331121, `32222111, `22222111, `22222111, `22222221, `22222222, `00000000, `22222222

.col25
	db 147, 147, 147, 91, 92, 93, 212, 208, 94, 95, 96, 97, 176, 177, 172
	db 7
	db 219
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222211, `12222112, `21211222
	dw `22112222, `22211111, `22122222, `12222222, `12232222, `22211112, `22111122, `11111211
	dw `11111111, `31111111, `11111111, `11111111, `11111221, `22222222, `22222222, `00000000
	dw `00000000, `11111111, `21210000, `12120111, `32320000, `23232011, `33333011, `11111011
	dw `11111011, `33333011, `33333011, `11111011, `33333011, `33333011, `33333011, `33333011
	dw `33333011, `33333011, `33333011, `33333011, `33333011, `33333011, `33333011, `33333011
	dw `33333011, `33333011, `00000011, `11111111, `11101111, `11010111, `10111011, `11111111

.col26
	db 147, 147, 147, 98, 99, 100, 212, 208, 213, 172, 172, 101, 180, 181, 172
	db 4
	db 226
	dw `22222211, `22221122, `22212222, `22122222, `11222222, `22222222, `22222221, `22221113
	dw `21113333, `13333222, `12222222, `21111111, `22213333, `22221222, `21221222, `11311122
	dw `21111122, `11111122, `11111122, `11111112, `12222221, `22222222, `22222222, `22222222
	dw `01111111, `01001001, `01001001, `01001001, `01001001, `01001001, `01001001, `01001001

.col27
	db 147, 147, 214, 102, 103, 104, 105, 106, 213, 172, 172, 107, 186, 187, 172
	db 6
	db 230
	dw `22222222, `22222222, `22222222, `22222211, `22221133, `22113322, `11332222, `33222222
	dw `22222212, `22222111, `22222211, `11111111, `33333311, `22333333, `22222222, `22222111
	dw `22222211, `22222221, `22222222, `22222222, `11222222, `22112222, `22221111, `22222222
	dw `00000000, `22222222, `22222222, `00000000, `10111110, `10111111, `01000000, `10111101
	dw `10111110, `01000001, `11111011, `11111101, `00000010, `11101111, `11110111, `00001000
	dw `11111111, `00010010, `00010010, `00010010, `00010010, `00010010, `00010010, `00010010

.col28
	db 147, 215, 147, 108, 109, 110, 111, 216, 112, 113, 114, 115, 170, 171, 172
	db 8
	db 236
	dw `22222222, `22222221, `11111113, `33113333, `22122222, `22112222, `21112222, `21112222
	dw `21112112, `22121112, `12121112, `11111122, `11112222, `31111111, `31113333, `22122211
	dw `12121111, `11111111, `21111122, `21112222, `22122222, `22222222, `22222222, `11122222
	dw `00000000, `22211122, `22222211, `00000000, `11111110, `01111111, `10000000, `11111101
	dw `00000000, `11111111, `00000001, `11111102, `00000002, `11111023, `11111033, `00011011
	dw `00011011, `00011033, `00011033, `00011011, `00011033, `00011033, `00011033, `00011033
	dw `00011033, `00011033, `00011033, `00011033, `00011033, `00011033, `00011033, `00011033
	dw `11011033, `01011033, `01011000, `01011111, `01011110, `01011101, `01011011, `01011111

.col29
	db 147, 200, 147, 116, 117, 118, 119, 216, 209, 210, 120, 121, 176, 177, 172
	db 6
	db 244
	dw `22221111, `11113333, `33332232, `32222222, `22222222, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `11222222, `33112222
	dw `13331112, `12222331, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222
	dw `00000000, `22222222, `22222222, `00000000, `11111110, `01111111, `10000000, `11111101
	dw `33333333, `33333333, `33333333, `33333333, `33333311, `33311123, `33123221, `31221111
	dw `31110011, `30000000, `00111111, `10113111, `10131311, `00113111, `10111111, `10333333

.col30
	db 147, 147, 201, 217, 147, 122, 123, 216, 209, 210, 124, 125, 180, 181, 172
	db 4
	db 250
	dw `22222222, `12222222, `31122222, `23311222, `22233112, `22222331, `22222233, `22222222
	dw `00000000, `22222222, `22222222, `00000002, `11111100, `01111110, `10000000, `11111111
	dw `33333333, `33333333, `33333333, `33333333, `11333333, `21131111, `12112231, `11221122
	dw `01111111, `00000000, `11111111, `13111131, `31311313, `13111131, `11111111, `33333333

.col31
	db 147, 147, 233, 217, 147, 234, 235, 236, 237, 238, 239, 240, 186, 187, 172
	db 8
	db 105
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `11122222, `22111222, `22222111
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `12222222, `11122222, `33112222
	dw `00000000, `22233112, `22223331, `22222233, `22222222, `02222222, `00222222, `00022222
	dw `11102222, `00000122, `11111011, `11111002, `00000000, `11101111, `11110111, `00000000
	dw `00000000, `11102222, `21200000, `12101111, `32301111, `23201111, `33301111, `11101111
	dw `11101111, `33301111, `33301111, `11101111, `33301111, `33301111, `33301111, `33301111
	dw `33301111, `33301111, `33301111, `33301111, `33301111, `33301111, `13301111, `13301111
	dw `13301111, `00301111, `10000111, `10110111, `10110111, `10110111, `10010111, `30110111

.col32
	db 147, 147, 147, 241, 198, 147, 242, 243, 244, 245, 246, 247, 170, 171, 172
	db 7
	db 113
	dw `11222222, `33111222, `22333111, `22222333, `22222222, `22222222, `22222222, `22222222
	dw `00000000, `22222222, `22222222, `11222222, `31122222, `33112222, `22331222, `22231122
	dw `22233312, `22222331, `12222223, `21112222, `22221122, `02222111, `10222222, `00022222
	dw `00022222, `22222222, `00000000, `11111111, `11111100, `11110000, `11100110, `11001110
	dw `10000102, `10110022, `00110022, `00010222, `01100222, `01102222, `01102222, `01102222
	dw `00002222, `01102222, `01102222, `01102222, `00002222, `01102222, `01102222, `01102222
	dw `00002222, `01102222, `01102222, `01102222, `00002222, `01102222, `01102222, `01102222

.col33
	db 147, 147, 147, 248, 147, 249, 192, 250, 251, 147, 147, 198, 176, 177, 172
	db 4
	db 120
	dw `22222211, `22221112, `21111222, `11122222, `33311222, `22211111, `22221133, `22222211
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `00000000
	dw `22222222, `22222222, `11222222, `31122222, `33122222, `23312222, `11331222, `21133122
	dw `22211212, `22221112, `00000000, `11111111, `00000000, `11110111, `11110111, `00000000

.col34
	db 147, 147, 215, 252, 253, 254, 192, 147, 255, 0, 1, 2, 180, 181, 172
	db 7
	db 124
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `11222222, `33111222
	dw `13333122, `21223311, `22122233, `22211223, `22222122, `22222211, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `00000000, `22222222
	dw `22222222, `22222222, `00000222, `11111002, `00111100, `00001111, `01100111, `01100011
	dw `00011001, `20010001, `22000101, `22201100, `22200110, `22220000, `22220110, `22220110
	dw `22220110, `22220110, `22220000, `22220110, `22220000, `22220110, `22220110, `22220110
	dw `22220110, `22220000, `22220110, `22220000, `22220110, `22220110, `22220110, `22220110

.col35
	db 147, 147, 200, 147, 3, 4, 192, 147, 5, 6, 179, 179, 186, 187, 172
	db 4
	db 131
	dw `22222222, `22222222, `11222222, `31122222, `33311222, `22233122, `12223311, `21122233
	dw `22211223, `22222112, `22222221, `22222222, `22222222, `00000000, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `02222222, `00222222, `10022222, `11002222
	dw `11102222, `11110222, `11110222, `11111022, `11111102, `11111102, `11111110, `11111110

.col36
	db 147, 147, 147, 201, 218, 7, 147, 199, 147, 147, 8, 179, 170, 171, 172
	db 2
	db 135
	dw `31122222, `33122222, `12311222, `21133122, `00000000, `22222211, `22222223, `00000000
	dw `02222222, `10222222, `10022222, `11002222, `11100222, `11110022, `11111002, `11111100

.col37
	db 147, 147, 147, 9, 147, 10, 11, 147, 147, 147, 147, 12, 176, 177, 172
	db 4
	db 137
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `11122221, `22111112, `22222222
	dw `22222222, `22222222, `12220000, `00002121, `12122212, `11212120, `00000002, `32112121
	dw `33211212, `23331121, `22333112, `22233311, `22223331, `22222333, `22222223, `22222222
	dw `02222222, `00222222, `10022222, `11002222, `11100222, `11111022, `11111102, `11111102

.col38
	db 147, 147, 147, 13, 14, 15, 16, 17, 147, 147, 147, 147, 180, 181, 172
	db 5
	db 141
	dw `22222211, `22222122, `22211222, `22122222, `11222222, `12222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222000
	dw `22000222, `00222222, `22222222, `22222220, `12120002, `00002221, `12121212, `21212121
	dw `12121212, `21212121, `12121212, `21212121, `12111111, `11333333, `31222222, `31122222
	dw `33112222, `23311222, `22331222, `22223122, `22223312, `22222211, `22222231, `22222223

.col39
	db 147, 147, 214, 147, 18, 19, 20, 218, 21, 22, 147, 147, 186, 187, 172
	db 5
	db 146
	dw `22222222, `22222222, `22222222, `22222222, `22000000, `20000000, `00200000, `22222222
	dw `22222222, `22222100, `12220002, `00002121, `12122212, `21212121, `12121212, `21212121
	dw `12121212, `21212121, `12121212, `11111111, `33333333, `22222222, `22222222, `22222222
	dw `31222222, `33122222, `23312222, `23311222, `22331222, `22231122, `22222122, `22222112
	dw `22222212, `22222212, `22222221, `22222221, `22222221, `22222221, `22222222, `22222222

.col40
	db 147, 215, 147, 147, 23, 24, 25, 207, 207, 207, 207, 207, 170, 171, 172
	db 3
	db 151
	dw `20222222, `00022222, `00022222, `00022222, `00000000, `00000000, `00000000, `00022222
	dw `00022222, `00022222, `00022222, `00022222, `00022222, `00012221, `00021212, `00012121
	dw `00021212, `00012121, `00021212, `00011111, `00033311, `00033333, `00022222, `00022222

.col41
	db 147, 26, 147, 147, 219, 167, 27, 198, 147, 147, 147, 185, 176, 177, 172
	db 2
	db 154
	dw `11122222, `22212222, `22211222, `22221222, `22222122, `22222122, `22222212, `22222221
	dw `12121212, `21212121, `12121212, `21212121, `11111212, `33331111, `33323333, `22222223

.col42
	db 147, 147, 173, 147, 219, 174, 28, 29, 147, 199, 147, 147, 180, 181, 172
	db 2
	db 156
	dw `12121212, `21212121, `12121212, `21212121, `12121212, `21212121, `11121212, `33112121
	dw `23331112, `22222331, `22222222, `22222222, `22222222, `22222222, `22222222, `22222222

.col43
	db 147, 178, 147, 147, 219, 167, 168, 30, 147, 147, 147, 147, 186, 31, 172
	db 2
	db 158
	dw `12121212, `11212121, `31121212, `23311121, `22233112, `22222331, `22222233, `22222222
	dw `11112211, `31111112, `11111122, `11111111, `11111012, `11110001, `11110002, `00000002

.col44
	db 147, 220, 32, 147, 219, 147, 221, 222, 147, 147, 147, 147, 223, 224, 172
	db 1
	db 160
	dw `22222212, `22222221, `22222222, `22222222, `22222221, `22222211, `22222211, `22221122

.col45
	db 147, 225, 33, 147, 219, 147, 34, 222, 147, 147, 147, 147, 223, 224, 172
	db 2
	db 161
	dw `22221222, `22212222, `12112222, `21122222, `11222222, `22222222, `22222222, `22222222
	dw `00000000, `22222222, `22222222, `21212121, `21212121, `12121212, `12121212, `22222222

.col46
	db 147, 226, 147, 147, 219, 147, 35, 36, 147, 147, 147, 147, 223, 224, 172
	db 2
	db 163
	dw `00110000, `22222222, `21101112, `21101121, `01101120, `22201101, `01201101, `21201201
	dw `22222222, `22222222, `01101201, `01101201, `22101101, `10001101, `20001101, `21212001

.col47
	db 147, 227, 147, 147, 219, 147, 37, 38, 193, 194, 39, 147, 223, 224, 172
	db 3
	db 165
	dw `00200200, `22222222, `22222211, `11111121, `00000000, `11111111, `11222222, `12111111
	dw `00000000, `22222222, `01111111, `01112222, `01121111, `01122222, `01121112, `01121112
	dw `22222222, `22222222, `22222223, `22222223, `22222333, `22223333, `22223332, `22222222

.col48
	db 147, 227, 147, 147, 219, 147, 192, 40, 196, 197, 41, 147, 223, 224, 172
	db 2
	db 168
	dw `00000000, `22222222, `11111110, `22211210, `11121110, `22221210, `11121110, `11121110
	dw `22222222, `23333333, `33333333, `33333333, `33333333, `22333333, `23333333, `23333332

.col49
	db 147, 227, 147, 147, 219, 147, 192, 192, 228, 229, 42, 147, 223, 224, 172
	db 1
	db 170
	dw `22222222, `33222222, `33333322, `33333333, `33333333, `33333333, `32222222, `22222222

.col50
	db 147, 230, 147, 147, 219, 147, 192, 192, 228, 229, 147, 147, 223, 224, 172
	db 0

.col51
	db 147, 230, 147, 147, 219, 147, 192, 192, 228, 229, 179, 147, 223, 224, 172
	db 0

.col52
	db 147, 230, 221, 147, 219, 147, 192, 192, 228, 231, 43, 44, 223, 224, 172
	db 2
	db 171
	dw `22222222, `22222233, `22233333, `23333333, `33333333, `33333333, `33333333, `33333333
	dw `33333333, `13333333, `11133333, `11113333, `11111333, `11111333, `11111133, `11111113

.col53
	db 147, 230, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 223, 224, 172
	db 10
	db 173
	dw `22222222, `22222222, `22222222, `21212121, `21212121, `12121112, `12121112, `12221122
	dw `12221122, `12221122, `12221122, `12222222, `12221122, `12221122, `12222222, `12221122
	dw `12221122, `12221122, `12222122, `12221122, `10001000, `10001000, `10001100, `12221122
	dw `12221122, `12221122, `12221122, `12221122, `12221122, `12221122, `12221122, `12221122
	dw `10001100, `12221122, `12221122, `12221122, `12221122, `12221122, `12221122, `12221122
	dw `00001100, `22221122, `22221122, `22221122, `22221122, `22221122, `22221122, `22221122
	dw `22221122, `22221122, `22221122, `23231123, `32321132, `22221122, `33331133, `22221122
	dw `22221122, `22221122, `33331133, `22221122, `22222222, `33333333, `22222222, `22222222
	dw `11111111, `33333333, `33333333, `33333333, `33333333, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33333333, `33333322, `33333333, `33333333, `33333333

.col54
	db 147, 230, 221, 147, 219, 147, 192, 192, 228, 231, 55, 56, 223, 224, 172
	db 2
	db 183
	dw `22222333, `32223333, `33333333, `33333333, `33333333, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33333333, `13333333, `31333333, `31133333, `31133333

.col55
	db 147, 230, 221, 147, 219, 57, 147, 192, 228, 229, 58, 59, 223, 224, 172
	db 3
	db 185
	dw `22222222, `22222222, `22222222, `22222222, `22000222, `20000022, `20222202, `02222220
	dw `33333311, `33333333, `33333333, `33333331, `33333311, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33333333, `33333333, `33333333, `33333322, `33332222

.col56
	db 147, 230, 221, 147, 219, 147, 192, 192, 228, 231, 60, 61, 223, 224, 172
	db 2
	db 188
	dw `22222222, `22222222, `23333332, `23333333, `33333333, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33333311, `31111111, `11111111, `11111111, `11111111

.col57
	db 147, 230, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 223, 224, 172
	db 10
	db 190
	dw `22222222, `22222222, `22222222, `21212121, `21212121, `12121211, `12121211, `21221211
	dw `12221211, `21221211, `12221211, `21221211, `12221221, `21221211, `12221221, `21221211
	dw `12221211, `21221211, `12221211, `21221211, `10001011, `01001011, `10001011, `21221211
	dw `12221211, `21221211, `12221211, `21221211, `12221211, `21221211, `12221211, `12221211
	dw `10001011, `12221211, `12221111, `12221211, `12211211, `11121211, `12221211, `12221212
	dw `10001010, `12221212, `12221212, `12221212, `12221212, `12221212, `22221212, `22221212
	dw `22221212, `22221212, `22221212, `23231313, `32323212, `22221212, `33331313, `22222212
	dw `22222212, `22221212, `33331313, `22222212, `22221212, `33331313, `22221212, `22221212
	dw `11111111, `11111111, `11111111, `31111111, `31111111, `33111111, `33111111, `33111111
	dw `33222212, `32222212, `22222212, `00000202, `22002202, `22002200, `22002202, `22002202

.col58
	db 147, 227, 221, 147, 72, 73, 192, 192, 228, 231, 74, 75, 223, 224, 172
	db 4
	db 200
	dw `22222222, `22222222, `22222222, `22222222, `00000000, `00000002, `00000020, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222211, `22221122, `22112222
	dw `22222222, `22222222, `22222222, `22333333, `22222222, `22222222, `22222222, `22222222
	dw `11111111, `11111111, `11111111, `10011000, `10010110, `00010000, `10010110, `10010110

.col59
	db 147, 227, 221, 76, 77, 78, 192, 192, 228, 79, 80, 81, 223, 224, 172
	db 6
	db 204
	dw `22222222, `22222222, `22222222, `22222222, `22222220, `22222200, `22222022, `22220222
	dw `22202222, `22022222, `20222222, `02222222, `22222222, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222221, `22211112, `11122222, `22222222, `22222222
	dw `22222222, `22222222, `33333333, `22222222, `22222222, `33333333, `22222223, `22222233
	dw `11122333, `11111222, `33312222, `33333333, `11113333, `11133333, `11133333, `11133333
	dw `22233333, `22233333, `22233333, `22003330, `02000330, `02003030, `02003300, `02003330

.col60
	db 147, 230, 147, 232, 82, 83, 192, 192, 228, 84, 85, 86, 223, 224, 172
	db 5
	db 210
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22212221, `22212111, `22211111
	dw `22211111, `22211111, `22211111, `11111122, `22222222, `22222222, `22222222, `22222222
	dw `22222222, `22222333, `33333333, `22333333, `22222233, `33333333, `33333333, `33333333
	dw `33333333, `23333333, `22222233, `33333333, `33333333, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `30033033, `30030333, `30003333, `30030333, `30033033

.col61
	db 147, 230, 147, 232, 87, 88, 192, 192, 228, 89, 140, 90, 223, 224, 172
	db 4
	db 215
	dw `22122222, `21112222, `22122222, `21112222, `11111222, `11111122, `11111111, `11111111
	dw `11211111, `12221111, `12221111, `21112222, `22222222, `22222222, `22222222, `22222222
	dw `33333333, `33333222, `33333333, `33333333, `33333333, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33303300, `33300000, `33330003, `33333033, `33333033

.col62
	db 147, 230, 147, 91, 92, 93, 192, 192, 228, 94, 140, 95, 223, 224, 172
	db 5
	db 219
	dw `22222222, `22222222, `22222222, `22222222, `00222222, `00022222, `22202222, `22220222
	dw `22222022, `22222202, `22222220, `22222222, `21222222, `21222222, `21222222, `11222222
	dw `11222222, `11222222, `11111112, `22222221, `22222222, `22222222, `22222222, `22222222
	dw `32222222, `22222222, `33333333, `33333332, `33333322, `33333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33000330, `30330030, `30330030, `30330030, `33000333

.col63
	db 147, 230, 147, 147, 96, 97, 192, 192, 228, 98, 99, 100, 223, 224, 172
	db 5
	db 224
	dw `22222222, `22222222, `22222222, `02222222, `20000000, `22200000, `20220000, `22222222
	dw `22222222, `22222222, `22222222, `11112222, `22221111, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `33333333, `22222222, `22222222, `33333333, `33222222, `33322222
	dw `33332222, `33332222, `33333222, `33333222, `22222222, `33333333, `33333333, `33333322
	dw `33333322, `33333322, `33333322, `03303322, `03303322, `03303320, `03303203, `00033220

.col64
	db 147, 230, 147, 147, 219, 101, 192, 192, 228, 229, 102, 103, 223, 224, 172
	db 3
	db 229
	dw `22222222, `22222222, `22222222, `22222222, `11222222, `22111222, `22221122, `22222211
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `33333322, `22222222, `22222222
	dw `22222222, `22223333, `22233333, `22223333, `22222223, `22220222, `02203022, `22220222

.col65
	db 147, 230, 147, 147, 104, 105, 106, 192, 228, 229, 107, 108, 223, 224, 172
	db 5
	db 232
	dw `22222222, `22222222, `22222222, `22222222, `00000000, `00000002, `00000000, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222221, `22222211, `22222122
	dw `00000000, `22211222, `22221122, `22222112, `22222221, `22222222, `22222222, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222223, `22222221, `22222211
	dw `22222011, `33330201, `33311011, `33311111, `33111010, `21110110, `21011100, `30000000

.col66
	db 147, 230, 147, 147, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 172
	db 10
	db 237
	dw `22222222, `22222222, `22222222, `22222222, `02002221, `22222211, `00000000, `22221122
	dw `22221222, `22211222, `22112222, `21122222, `11222222, `12222222, `22222222, `22222220
	dw `00000000, `22222222, `22222222, `22222222, `22222222, `11222222, `21122220, `22112220
	dw `00000002, `20000003, `20222233, `02322333, `02323333, `02323333, `02323333, `02333333
	dw `03333333, `03333333, `03333333, `03333333, `03333333, `03333333, `03333333, `03333333
	dw `03333333, `03333333, `03333333, `03333333, `03333333, `03333333, `03333333, `03333333
	dw `03333333, `03333333, `03333333, `03333333, `03333333, `03333333, `03333333, `03333333
	dw `03333323, `03333323, `00023323, `03023323, `03023320, `00002202, `02000220, `02230221
	dw `11111110, `12121200, `22222001, `22222011, `22220111, `22220100, `22222011, `11111101
	dw `11111011, `22222111, `22220111, `11110111, `22222011, `11101100, `22221111, `22201111

.col67
	db 147, 230, 147, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 172
	db 11
	db 105
	dw `22222222, `22222222, `22222111, `22222122, `22221222, `22221222, `22212222, `22112222
	dw `22122222, `21122222, `11222222, `12222222, `12202202, `22222222, `00000000, `22222222
	dw `22222222, `22222222, `22222222, `22222222, `22222222, `22222222, `22222220, `02002002
	dw `20220222, `22202223, `22022223, `20222333, `20223333, `02223333, `02223333, `23323333
	dw `22323333, `23323333, `23333333, `23333333, `23333333, `23333333, `33333333, `33333333
	dw `33333333, `33333333, `33333333, `33333333, `33333330, `33333300, `33333000, `33330000
	dw `33330000, `33300000, `33300000, `33300000, `33000000, `33000000, `33000000, `33000000
	dw `33000000, `33000000, `33000000, `33000000, `33000000, `33000000, `33000000, `33000000
	dw `33000000, `33000000, `33000000, `23000000, `23000000, `03000000, `21000000, `11100000
	dw `11111111, `10131111, `11001110, `11111102, `01111110, `11111111, `11111111, `11011111
	dw `01111110, `11111111, `11111111, `11133111, `31111111, `31111111, `11131111, `10111111

.col68
	db 147, 230, 147, 220, 244, 245, 246, 247, 248, 172, 172, 172, 249, 250, 172
	db 7
	db 116
	dw `22222212, `22222221, `22222222, `22222222, `00200000, `22020201, `00202011, `22221122
	dw `22111222, `21122222, `22222222, `22222222, `22222222, `22222222, `00000002, `22222202
	dw `22222200, `22232320, `22232320, `23332332, `23332333, `33303332, `33333332, `33203332
	dw `20230032, `23333332, `23333333, `23333333, `23303333, `33303333, `33333333, `33332333
	dw `32333333, `32333333, `22333333, `30000033, `00000000, `00000000, `00000000, `00000000
	dw `00000010, `11111111, `11111111, `01111101, `11111020, `11111101, `11111111, `01111111
	dw `20111111, `01111110, `11111111, `11110011, `11001110, `11111111, `11111111, `11100111

.col69
	db 147, 227, 147, 225, 251, 147, 252, 253, 254, 255, 0, 1, 2, 3, 172
	db 9
	db 123
	dw `22221222, `22212222, `12112222, `21122222, `10002222, `02020000, `22222222, `22222222
	dw `00000000, `22222222, `00222222, `20020022, `22002022, `32232202, `22233200, `22233220
	dw `22332322, `22322322, `22322232, `23333323, `23333323, `23333323, `23333323, `23333322
	dw `23333322, `23333322, `23333322, `23333320, `33333320, `03333330, `00333332, `00033332
	dw `00033332, `00003332, `00003332, `00003332, `00000333, `00000333, `00000333, `00000333
	dw `00000333, `00000333, `00000333, `00000333, `00000333, `00000333, `00000333, `00000333
	dw `00000333, `00000333, `00000333, `00000333, `00000333, `00000332, `00000332, `00001122
	dw `11111011, `11011011, `10111101, `11111001, `11111100, `11111111, `11011111, `11100111
	dw `11111113, `01111133, `11111111, `11133111, `01111111, `11110011, `11111111, `11111101

.col70
	db 147, 227, 147, 226, 4, 147, 192, 5, 6, 7, 8, 9, 10, 11, 172
	db 8
	db 132
	dw `22222222, `22222222, `22222222, `22222222, `22000022, `00222222, `22222222, `22222222
	dw `01111121, `00000002, `22222201, `32222202, `33232201, `33233202, `33323201, `33300002
	dw `33000201, `30030202, `30000001, `00222202, `30222201, `00000002, `02220201, `02220202
	dw `00000001, `00032202, `33200201, `33200002, `33330201, `33332002, `33332201, `33333202
	dw `33333201, `33333202, `33333201, `33333202, `33333201, `33333202, `33333201, `33333202
	dw `33333201, `32333202, `32333201, `32333202, `32332201, `32332201, `32332201, `22232300
	dw `11111111, `11111111, `11111111, `11111111, `11111111, `01111111, `00111111, `10111111
	dw `10111111, `10111111, `10111111, `11111111, `01111111, `01111111, `10111111, `11011111
	POPS

	db 105 ; Nb tiles
INCBIN "src/res/maps/village/village.chr.pb16"

.warpData
	dw 128, 218 ; Player Y pos, X pos
	db ; Camera behavior
	dw EmptyFunc ; Processor

