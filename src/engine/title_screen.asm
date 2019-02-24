
FRAMES_BETWEEN_ANIMATIONS = 30 ; The original material ran at 2fps, BUT an animation takes ~3 frames to update (from drawing all the tiles).

SECTION "Title screen", ROMX

TitleScreen::
    xor a
    ldh [hLCDC], a
    rst wait_vblank

    ld hl, $8000
    ld de, .tiles
    ld b, $80
    call pb16_unpack_block
    ; ld b, 0 ; Copy 256 more tiles
    call pb16_unpack_block

    ; ld hl, _SCRN0
    ; ld de, .tilemapDirectives
    ; ld b, 0
    ld a, [de]
.writeTileRow
    inc de
    ld c, a
.writeRLE
    inc b
    jr nz, .dontSkipBlankTile
    inc b
.dontSkipBlankTile
    ld a, b
    ld [hli], a
    dec c
    jr nz, .writeRLE
    ld a, [de]
    inc de
    ld c, a
.writeBlanks
    xor a
    ld [hli], a
    dec c
    jr nz, .writeBlanks
    ld a, [de]
    and a
    jr nz, .writeTileRow

    ; xor a
    ld [wTitleScreenAnimCounter], a
    ld [wTitleScreenAnimDelay], a

    ; xor a
    ldh [hSCY], a
    ldh [hSCX], a
    ld a, SCRN_Y
    ldh [hWY], a

    call GetFreeScanlineBuf
    ld b, a
    ld a, $60
    ld [$ff00+c], a
    inc c
    ld a, LOW(rLCDC)
    ld [$ff00+c], a
    inc c
    ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_BGON
    ld [$ff00+c], a
    inc c
    ld a, $FF
    ld [$ff00+c], a
    ld a, b
    ldh [hWhichScanlineBuffer], a

    ld hl, wShadowOAM
    ld de, .initialOAM
    ld c, .initialOAMEnd - .initialOAM
    rst memcpy_small
;    ld c, $A0 - (.initialOAMEnd - .initialOAM)
;    xor a
;    rst memset_small
    ld a, h ; ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a

    ldh a, [hIsSGB]
    and a
    ld hl, .sgbPacket
    call nz, SendPackets ; Do delay, in case the user acts super fast and the SGB glitches out
    ld a, %11100100
    ldh [hBGP], a
    ldh [hOBP0], a
    ld a, %00110001
    ldh [hOBP1], a

    ld a, LCDCF_ON | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_BGON
    ldh [hLCDC], a
    ldh [rLCDC], a

.mainLoop
    rst wait_vblank

    ld hl, wTitleScreenAnimDelay
    ld a, [hl]
    inc a
    ld [hl], a
    ; Gfx are loaded as frame 0, so we'll begin by animating frame 1
    
    ; Animations are done by XOR'ing tile data with data to go back and forth from frame 1 to frame 0 or 2 (depending on counter)
    ; Each frame lasts 32 frames (1/2 second)
    sub FRAMES_BETWEEN_ANIMATIONS ; Each animation frame lasts 16 frames
    jp c, .dontAnimate
    ld [wTitleScreenAnimDelay], a ; Reset delay
    ld a, [wTitleScreenAnimCounter]
    inc a
    and 3 ; Wrap between the 4 frames
    ld [wTitleScreenAnimCounter], a

    ld c, a
    add a, a
    add a, LOW(.objAnimationPointers)
    ld l, a
    adc a, HIGH(.objAnimationPointers)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld de, wShadowOAM
    ld b, (.initialOAMEnd - .initialOAM) / 4
.modifyOAMPositions
    ld a, [hli] ; Y pos
    ld [de], a
    inc de
    ld a, [hli] ; X pos
    ld [de], a
    inc de
    ; Frame 0 re-uses the initial OAM, which is encoded differently
    ld a, c
    and a
    jr nz, .notFrame0
    inc hl
    inc hl
.notFrame0
    inc de
    inc de
    dec b
    jr nz, .modifyOAMPositions
    ld a, d ; ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a
    ; Some sprites have a different color on frames 0/1/3 and 2.
    ; Modify the palette to modify less OAM
    ; Will update on next frame, normally on the same frame as OAM
    ld a, c
    and 2
    jr z, .dontToggleOBP
    ldh a, [hOBP1]
    xor %00111100
    ldh [hOBP1], a
.dontToggleOBP

    ld a, c
    and 2 ; a = 0-1 * 2
    add a, LOW(.bgAnimationPointers)
    ld l, a
    adc a, HIGH(.bgAnimationPointers)
    sub l
    ld h, a
    ld a, [hli]
    ld d, [hl]
    ld e, a
.doBGXor
    ld a, [de]
    ld h, a
    inc de
    ld a, [de]
    inc de
    ld l, a
    or h
    jp z, .bgXorDone
    ld a, [de]
    ld c, a
    inc de
.xorBGTile
REPT 8
    ld a, [de] ; Get 1st mask
    ld b, a
    inc de
    ld a, [de]
    or b
    jr z, .skipRow\@
    wait_vram
    ld a, b ; Get 1st mask again
    xor [hl]
    ld [hli], a
    ld a, [de] ; Get 2nd mask
    xor [hl]
    ld [hld], a
.skipRow\@
    inc hl
    inc hl
    inc de
ENDR
    dec c
    jp nz, .xorBGTile
    jp .doBGXor
.bgXorDone

.dontAnimate
    ldh a, [hPressedButtons]
    and PADF_START
    jp z, .mainLoop
    ret


.sgbPacket
    sgb_packet PAL_SET, 1, 5,0, 5,0, 5,0, 5,0, 1


.tiles
INCBIN "res/title_screen/frame_0.chr.pb16"
.tilesEnd

.tilemapDirectives
    db 9
    db 4
    db 7
    db 12

    db 7
    db 4
    db 9
    db 12

    db 6
    db 4
    db 10
    db 12
    
    db 6
    db 3
    db 5
    db 2
    db 4
    db 12

    db 5
    db 3
    db 6
    db 3
    db 3
    db 12

    db 5
    db 2
    db 8
    db 1
    db 4
    db 12

    db 5
    db 2
    db 13
    db 12

    db 5
    db 1
    db 8
    db 1
    db 5
    db 12

    db 15
    db 2
    db 3
    db 12

    db 15
    db 2
    db 3
    db 12

    db 16
    db 1
    db 3
    db 12

    db 20
    db 12

    db 20
    db 12
    
    db 16
    db 1
    db 3
    db 12

    db 16
    db 2
    db 2
    db 12

    db 20
    db 12

    db 20
    db 12

    db 20
    db 1

    db 0

.initialOAM
    dspr   1,  20, $44, OAMF_PAL1
    dspr   8,  32, $45, OAMF_PAL1
    dspr   7,  96, $46, OAMF_PAL0
    dspr   3, 137, $47, OAMF_PAL0
    dspr  15, 120, $48, OAMF_PAL1
    dspr  22,  14, $49, OAMF_PAL1
    dspr  21,  32, $4A, OAMF_PAL1
    dspr  33,  48, $4B, OAMF_PAL1
    dspr  33,  56, $4C, OAMF_PAL1
    dspr  29, 151, $4D, OAMF_PAL1
    dspr  65,   5, $4E, OAMF_PAL1
    dspr  56,  25, $4F, OAMF_PAL1
    dspr  73, 103, $50, OAMF_PAL1
    dspr  81,  16, $51, OAMF_PAL1
    dspr  84,  33, $52, OAMF_PAL1
    dspr  77,  54, $53, OAMF_PAL1
    dspr  81,  73, $54, OAMF_PAL1
    dspr  85,  81, $52, OAMF_PAL1
    dspr  90,  92, $55, OAMF_PAL1
    dspr  89, 139, $56, OAMF_PAL1
    dspr 103,  79, $57, OAMF_PAL1
    dspr  74, 150, $58, OAMF_PAL1
    dspr 101,  87, $58, OAMF_PAL1
    dspr 103, 151, $59, OAMF_PAL1
    dspr 115,   3, $5A, OAMF_PAL1
    dspr 125,   0, $5B, OAMF_PAL1
    dspr 124,  86, $5C, OAMF_PAL1
    dspr 132, 158, $5D, OAMF_PAL1
    ; Sprites unused on this frame, but used on others
    db     0,   0, $5E, OAMF_PAL1
    db     0,   0, $5F, OAMF_PAL1
    db     0,   0, $60, OAMF_PAL1
    db     0,   0, $61, OAMF_PAL1
    db     0,   0, $62, OAMF_PAL1
    db     0,   0, $63, OAMF_PAL1
    db     0,   0, $64, OAMF_PAL1
    db     0,   0, $65, OAMF_PAL1
    db     0,   0, $66, OAMF_PAL1
    db     0,   0, $4E, OAMF_PAL1
    db     0,   0, $5C, OAMF_PAL1
    db     0,   0, $61, OAMF_PAL1
.initialOAMEnd

.bgAnimationPointers
    dw .frame_0_1_xor
    dw .frame_1_2_xor

.objAnimationPointers
    dw .initialOAM
    dw .frame1OAM
    dw .frame2OAM
    dw .frame3OAM

.frame_0_1_xor
INCBIN "res/title_screen/frame_0_xor_frame_1.bin"
.frame_1_2_xor
INCBIN "res/title_screen/frame_1_xor_frame_2.bin"

; FIXME: The numbers in the comments need to be changed (add 3 to each)
.frame1OAM
    db   9 + 16,  23 + 8 ; $41
    db  11 + 16,  41 + 8 ; $42
    db  23 + 16, 115 + 8 ; $43
    db   6 + 16, 140 + 8 ; $44
    db  17 + 16, 128 + 8 ; $45
    db        0,       0 ; $46
    db 122 + 16, 147 + 8 ; $47
    db  51 + 16,  70 + 8 ; $48
    db  51 + 16,  78 + 8 ; $49
    db  32 + 16, 154 + 8 ; $4A
    db  68 + 16,   8 + 8 ; $4B
    db  59 + 16,  32 + 8 ; $4C
    db  76 + 16, 110 + 8 ; $4D
    db  84 + 16,  19 + 8 ; $4E
    db  87 + 16,  36 + 8 ; $4F
    db  80 + 16,  57 + 8 ; $50
    db  82 + 16,  83 + 8 ; $51
    db  86 + 16,  91 + 8 ; $4F #2
    db  93 + 16,  95 + 8 ; $52
    db        0,       0 ; $53
    db 111 + 16,  96 + 8 ; $54
    db 106 + 16,  90 + 8 ; $55
    db        0,       0 ; $55 #2
    db 106 + 16, 154 + 8 ; $56
    db 118 + 16,   6 + 8 ; $57
    db 129 + 16,  10 + 8 ; $58
    db 127 + 16,  89 + 8 ; $59
    db  68 + 16,  56 + 8 ; $5A
    db  51 + 16,  83 + 8 ; $5B
    db   1 + 16,   7 + 8 ; $5C
    db  21 + 16,  95 + 8 ; $5D
    db  36 + 16,  99 + 8 ; $5E
    db  77 + 16,   0 + 8 ; $5F
    db  52 + 16, 152 + 8 ; $60
    db  69 + 16, 139 + 8 ; $61
    db 108 + 16, 139 + 8 ; $62
    db  92 + 16, 141 + 8 ; $63
    db   6 + 16, 115 + 8 ; $4B
    db  47 + 16, 137 + 8 ; $59
    db  94 + 16,  98 + 8 ; $5E

.frame2OAM
    db  15 + 16,  33 + 8 ; $41
    db  87 + 16,  24 + 8 ; $42
    db  30 + 16, 130 + 8 ; $43
    db   8 + 16, 144 + 8 ; $44
    db  20 + 16, 138 + 8 ; $45
    db  24 + 16,  98 + 8 ; $46
    db 124 + 16, 152 + 8 ; $47
    db  13 + 16,   8 + 8 ; $48
    db  13 + 16,  16 + 8 ; $49
    db  34 + 16, 159 + 8 ; $4A
    db   9 + 16, 120 + 8 ; $4B
    db  62 + 16,  37 + 8 ; $4C
    db  79 + 16, 119 + 8 ; $4D
    db  71 + 16,  13 + 8 ; $4E
    db  90 + 16,  41 + 8 ; $4F
    db  83 + 16,  62 + 8 ; $50
    db  87 + 16,  94 + 8 ; $51
    db  91 + 16, 102 + 8 ; $4F # 2
    db  96 + 16, 100 + 8 ; $52
    db        0,       0 ; $53
    db 116 + 16, 120 + 8 ; $54
    db 107 + 16,  95 + 8 ; $55
    db        0,       0 ; $55 #2
    db 109 + 16, 159 + 8 ; $56
    db 121 + 16,  11 + 8 ; $57
    db 130 + 16,  21 + 8 ; $58
    db  49 + 16, 145 + 8 ; $59
    db  72 + 16,  62 + 8 ; $5A
    db  54 + 16,  88 + 8 ; $5B
    db   7 + 16,  16 + 8 ; $5C
    db   5 + 16,  -1 + 8 ; $5D
    db  39 + 16, 104 + 8 ; $5E
    db  85 + 16,  10 + 8 ; $5F
    db  55 + 16, 158 + 8 ; $60
    db  70 + 16, 146 + 8 ; $61
    db 112 + 16, 145 + 8 ; $62
    db  95 + 16, 147 + 8 ; $63
    db   9 + 16, 120 + 8 ; $4B
    db  49 + 16, 145 + 8 ; $59
    db  97 + 16, 103 + 8 ; $5E

.frame3OAM
    db        0,       0 ; $44
    db 137 + 16, 101 + 8 ; $45
    db   1 + 16,  70 + 8 ; $46
    db  16 + 16, 152 + 8 ; $47
    db  28 + 16, 146 + 8 ; $48
    db  11 + 16,   5 + 8 ; $49
    db  51 + 16,   4 + 8 ; $4A
    db  18 + 16,  32 + 8 ; $4B
    db  18 + 16,  40 + 8 ; $4C
    db        0,       0 ; $4D
    db  16 + 16, 127 + 8 ; $4E
    db  69 + 16,  44 + 8 ; $4F
    db  93 + 16, 128 + 8 ; $50
    db  94 + 16,  31 + 8 ; $51
    db  97 + 16,  48 + 8 ; $52
    db  90 + 16,  69 + 8 ; $53
    db  94 + 16, 101 + 8 ; $54
    db  98 + 16, 109 + 8 ; $52 #2
    db  89 + 16,  75 + 8 ; $55
    db  89 + 16,  76 + 8 ; $56
    db 129 + 16, 137 + 8 ; $57
    db 114 + 16, 102 + 8 ; $58
    db  61 + 16,  95 + 8 ; $58 #1
    db        0,       0 ; $59
    db 128 + 16,  18 + 8 ; $5A
    db 137 + 16,  28 + 8 ; $5B
    db  56 + 16, 152 + 8 ; $5C
    db  79 + 16,  69 + 8 ; $5D
    db  62 + 16,  95 + 8 ; $5E
    db  14 + 16,  23 + 8 ; $5F
    db 109 + 16,  -1 + 8 ; $60
    db 143 + 16, 150 + 8 ; $61
    db  92 + 16,  17 + 8 ; $62
    db  42 + 16, 138 + 8 ; $63
    db  77 + 16, 151 + 8 ; $64
    db 119 + 16, 152 + 8 ; $65
    db 102 + 16, 154 + 8 ; $66
    db  78 + 16,  20 + 8 ; $4E #2
    db  56 + 16, 152 + 8 ; $5C #2
    db        0,       0 ; $61 #2
