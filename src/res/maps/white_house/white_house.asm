; This is auto-generated ASM. Be careful if hand-modifying it.
; ~ gen_map.py

	db 27 ; DMG BGP
	db 216, 39, 0, 107 ; SGB BGP, OBP0, OBP1, textbox pal
	dw 3, 3, 3, 0 ; SGB palettes
	db $80 | 1 ; SGB attribute file number
	dw 152, 160 ; Height, width
	dbankw NULL ; Map script pointer

	db 0 ; Number of NPCs

	db 1 ; Number of triggers
	dstruct Trigger, .trigger0, TRIGGER_COORDSCRIPT, 149, 1, 68 - 1, 58 - 1, LOW(wTriggerArgPool) + 0
	db 4 ; Number of arg bytes
	db TRIGTYPE_WARP, MAP_VILLAGE, 0, 8 << 1 ; Trigger 0 args

	dw .warpData

	db SCROLLING_4_WAY ; Scroll type
	dbankw white_houseTilemap
	PUSHS
SECTION "white_house map tilemap", ROMX
white_houseTilemap:
INCBIN "src/res/maps/white_house/white_house.bit7.tilemap"
	POPS

	db 181 ; Nb tiles
INCBIN "src/res/maps/white_house/white_house.chr.pb16"

.warpData
	dw 148, 79 ; Player Y pos, X pos
	db ; Camera behavior
	dw EmptyFunc ; Processor

