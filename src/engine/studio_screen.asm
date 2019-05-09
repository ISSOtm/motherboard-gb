
SECTION "Studio screen", ROMX


NB_STUDIO_TILES = $E5
CompressedStudioTiles:
    INCBIN "res/studio_screen/studio_screen.chr.pb16"
StudioMap:
    db 7, 2, 1, 10
    db 12 + 7, 2, 1, 10
    db 12 + 2, 2, 3, 13, 12
    db 20, 12
    db 20, 12
    db 1, 1, 18, 12
    db 14, 1, 5, 12
    db 20, 12
    db 20, 12
    db 20
    db 12 + 1, 7, 2, 2, 5, 3
    db 12 + 1, 7, 10, 2
    db 12 + 3, 5, 11, 1
    db 12 + 3, 5, 11, 1
    db 12 + 3, 5, 11, 1
    db 12 + 3, 5
    db 12 + 15, 4
    db 12 + 16, 3, 14
    db 1, 0 ; The 1 is a dummy, the code can only exit on zero-length *blank* runs

NB_COPYRIGHT_TILES = 227
CompressedCopyrightTiles:
    INCBIN "res/studio_screen/credits.chr.pb16"
CopyrightMap:
    INCBIN "res/studio_screen/credits.tilemap"
CopyrightMapEnd:



; Displays the studio logos on the screen
StudioScreen::
    ; Disable LCD while we set everything up
    ldh a, [rLCDC]
    add a, a
    jr nc, .lcdOff
    xor a
    ldh [hLCDC], a
    rst wait_vblank
.lcdOff
    ; Disable scanline FX (okay because LCD is disabled, so STAT won't trigger)
    dec a
    ldh [hScanlineFXBuffer1], a
    ldh [hScanlineFXBuffer2], a

    ldh a, [hIsSGB]
    and a
    ld hl, StudioSgbPacket
    call nz, SendPacketNoDelay

    ld de, CompressedStudioTiles
    ld hl, $8000
    ld b, NB_STUDIO_TILES
    call pb16_unpack_block
    ; ld de, StudioMap
    ld hl, _SCRN0
    ld a, [de]
.writeTileRow
    inc de
    ld c, a
.writeBlanks
    xor a
    ld [hli], a
    dec c
    jr nz, .writeBlanks
    ld a, [de]
    inc de
    ld c, a
.writeRLE
    inc b
    ld a, b
    ld [hli], a
    dec c
    jr nz, .writeRLE
    ld a, [de]
    and a
    jr nz, .writeTileRow
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a
    ldh [hLCDC], a
    ld a, %00011011
    ldh [hBGP], a
    wait 2 seconds


CopyrightScreen:
    xor a
    ldh [hLCDC], a
    rst wait_vblank

    ld de, CompressedCopyrightTiles
    ld hl, $8000
    ld b, NB_COPYRIGHT_TILES
    call pb16_unpack_block
    ; ld de, CopyrightMap
    ld hl, _SCRN0
    ld bc, CopyrightMapEnd - CopyrightMap
    call Mapcpy
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a
    ldh [hLCDC], a
    ; Maybe do SGB stuff
    ldh a, [hIsSGB]
    and a
    ld a, %01100011
    jr z, .notSGB
    ld hl, .sgbPacket
    call SendPacketNoDelay
    ld a, %11100100
.notSGB
    ldh [hBGP], a

    wait 64 frames ; Mandatory 1 second delay
    ld b, 0
.waitStudioScreen ; Unless user is impatient, have extra delay
    rst wait_vblank
    dec b
    ret z
    ldh a, [hHeldButtons]
    and a
    jr z, .waitStudioScreen
    ret


.sgbPacket
    sgb_packet PAL_SET, 1, 6,0, 7,0, 8,0, 9,0, 2 | $80


StudioSgbPacket:
    sgb_packet PAL_SET, 1, 4,0, 4,0, 4,0, 4,0, 1 | $80 | $60 ; Also unfreeze screen if it was

