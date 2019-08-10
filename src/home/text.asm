
SECTION "Text engine functions", ROM0

ProcessText::
    ; Check if text is halted, and if so, halt
    ld a, [wTextPaused]
    add a, a
    ret c

    call PrintVWFChar
    call DrawVWFChars
    ld a, [wTextSrcPtr+1]
    inc a
    ret nz
    ; Close textbox
    ld [wTextboxScanline], a
    ldh a, [hIsSGB]
    and a
    ret z
    ld a, ATTR_SET << 3 | 1
    ld [wRestoreSGBLayoutPacket], a
    ld a, PAL_PACK_ACTION_RESTORE
    ld [wPalettePacketAction], a
    ret


SECTION "Textbox functions", ROMX

OpenTextbox::
    ; Set up gfx transfer request
    ldh a, [hFastCopyLowByte]
    ld l, a
    ld h, HIGH(wFastCopyQueue)
    ld a, BANK(TextboxTiles)
    ld [hli], a
    ld a, LOW(TextboxTiles)
    ld [hli], a
    ld a, HIGH(TextboxTiles)
    ld [hli], a
    ld a, LOW(vTextboxBorderTiles)
    ld [hli], a
    ld a, HIGH(vTextboxBorderTiles)
    ld [hli], a
    ld a, LOW(wDummyFastCopyACK)
    ld [hli], a
    ld a, $94
    ld [hli], a
    ld a, 8
    ld [hli], a
    ld a, l
    ld hl, hFastCopyNbReq
    inc [hl]
    and $7F
    ldh [hFastCopyLowByte], a

    ; Set up textbox's layout
    ; Row 0
    ld hl, vTextboxTilemap
    lb bc, LOW(vTextboxBorderTiles / 16), SCRN_X_B - 2
    ; UL corner (00)
    wait_vram
    ld a, b
    ld [hli], a
    ; Upper border (01)
    inc b
    ; ld c, SCRN_X_B - 2
    call LCDMemsetSmallFromB
    ; UR corner (02)
    inc b
    wait_vram
    ld [hl], b
    ; Row 1
    ld l, LOW(vTextboxTilemap + SCRN_VX_B)
    ; Left edge (03)
    inc b
    ld a, b
    ld [hli], a
    ; Middle
    lb bc, 0, SCRN_X_B - 2
    call LCDMemsetSmallFromB
    ; Right edge (04)
    wait_vram
    ld a, LOW(vTextboxBorderTiles / 16) + 4
    ld [hl], a
    ; Row 2
    ld l, LOW(vTextboxTilemap + SCRN_VX_B * 2)
    ; Left edge (03)
    dec a
    ld [hli], a
    ; Middle
    ld c, SCRN_X_B - 2
    call LCDMemsetSmallFromB
    ; Right edge (04)
    wait_vram
    ld a, LOW(vTextboxBorderTiles / 16) + 4
    ld [hl], a
    ; Row 3
    ld l, LOW(vTextboxTilemap + SCRN_VX_B * 3)
    ; LL corner (05)
    inc a
    ld [hli], a
    ; Lower edge (06)
    inc a
    ld c, SCRN_X_B - 2
    call LCDMemsetSmall ; Copies A to B
    ; LR corner (07)
    inc b
    ld [hl], b

    ld a, SCRN_Y - 4 * 8 ; Display 4 tiles
    ld [wTextboxScanline], a

    ldh a, [hIsSGB]
    and a
    ret z
    ld a, PAL_PACK_ACTION_TEXTBOX_LAYOUT
    ld [wPalettePacketAction], a
    ret


SECTION "Textbox SGB layout packet", ROMX

TextboxSGBLayoutPacket::
    sgb_packet ATTR_BLK, 1, 1, %001, 3, 0, 14, 19, 17


SECTION "Textbox gfx", ROMX

TextboxTiles::
INCBIN "res/textbox/textbox.chr"
