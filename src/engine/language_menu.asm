
SECTION "Language menu header", ROMX

LanguageMenuHeader::
    db BANK("Language menu")
    dw LanguageMenuInit
    db PADF_START | PADF_DOWN | PADF_UP
    db 0 ; Prevent repeat press
    dw 0, 0, 0, ForceMenuValidation, 0, 0, 0, 0
    db 0 ; Previous item
    db 1 ; Allow wrapping
    db 0 ; Default item
    db NB_LANGUAGES ; Size
    dw LanguageMenuRedraw
    dw LanguageMenuItems
    dw LanguageMenuClose


SECTION "Language menu", ROMX

LanguageMenuInit:
    rst wait_vblank
    xor a
    ldh [rLCDC], a

    ; xor a
    ld [wTextLetterDelay], a

    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_Y_B
    ; xor a
    rst memset
    inc a ; ld a, 1
    ld hl, LanguageMenuItems
    ld b, BANK(LanguageMenuItems)
    call PrintVWFText
    ld hl, _SCRN0 + SCRN_VY_B * 6 + 7
    call SetPenPosition
    call PrintVWFChar

    ; Load extra gfx
    ; Cursor, Up, Down and START button prompts
    ld de, .gfx
    ld hl, $8800
    ld b, 8
    call pb16_unpack_block

    ld a, 42
    ldh [hLangSelMenuTimer1], a
    xor a
    ldh [hLangSelMenuTimer2], a
    ; xor a
    ldh [hBGP], a
    ldh [hOBP0], a
    ld hl, wShadowOAM + $A0 - 1
    ; xor a
.clearSprites
    dec l ; dec hl
    dec l ; dec hl
    dec l ; dec hl
    ld [hld], a
    jr nz, .clearSprites
    ; xor a
    ldh [hLangSelMenuCursorPos], a
    inc hl
    ld a, h ; ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a
    ; ld de, .oam
    ld hl, wShadowOAM
    ld c, .palettePacket - .oam
    rst memcpy_small
    ld a, $1B
    ldh [hLangSelMenuPalette], a
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_BGON
    ldh [hLCDC], a
    ldh [rLCDC], a

    ld hl, .palettePacket
    ldh a, [hIsSGB]
    and a
    call nz, SendPacketNoDelay

    jp DrawVWFChars

.gfx
INCBIN "res/lang_screen/gfx.chr.pb16"

.oam
    dspr  6 * 8 -  2,  6 * 8, $80, 0
    dspr  6 * 8 - 10,  6 * 8, $82, 0
    dspr  6 * 8 +  6,  6 * 8, $82, OAMF_YFLIP
    dspr 11 * 8     ,  9 * 8, $83, 0
    dspr 12 * 8 +  3,  8 * 8, $85, 0
    dspr 12 * 8 +  3,  9 * 8, $86, 0
    dspr 12 * 8 +  3, 10 * 8, $87, 0

.palettePacket
    sgb_packet PAL_SET, 1, 4,0, 4,0, 4,0, 4,0, 1 | $80


LanguageMenuRedraw:
    ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a

    ldh a, [hLangSelMenuTimer1]
    inc a
    and $1F
    ldh [hLangSelMenuTimer1], a
    jr nz, .keepFlagFrame
    ld a, [wShadowOAM + 2]
    xor 1
    ld [wShadowOAM + 2], a
    xor a
.keepFlagFrame
    and $03
    jr nz, .paletteOK
    ldh a, [hBGP]
    ld e, a
    ldh a, [hLangSelMenuPalette]
    add a, a
    jr z, .paletteOK
    rl e
    add a, a
    ldh [hLangSelMenuPalette], a
    ld a, e
    rla
    ldh [hBGP], a
    ldh [hOBP0], a
.paletteOK

    ldh a, [hLangSelMenuTimer2]
    inc a
    and $1F
    ldh [hLangSelMenuTimer2], a
    and $18
    jr z, .hideArrows
    ld a, 6 * 8 + 8
.hideArrows
    ld [wShadowOAM + 5], a
    ld [wShadowOAM + 9], a
    ldh a, [hLangSelMenuTimer2]
    and $07
    jr nz, .keepSTARTFrame
    ld a, [wShadowOAM + 14]
    xor 7
    ld [wShadowOAM + 14], a
.keepSTARTFrame

    ldh a, [hLangSelMenuCursorPos]
    ld c, a
    ld a, b ; Selected item
    ld [wLanguage], a
    add a, a
    add a, a
    add a, a
    sub c
    ret z
    sra a ; Halve the difference to lerp a bit
    jr nz, .ok
    inc a
.ok
    add a, c
    ldh [hLangSelMenuCursorPos], a
    add a, 6 * 8 - 2 + 16
    ld [wShadowOAM], a
    sub 8
    ld [wShadowOAM + 4], a
    add a, 16
    ld [wShadowOAM + 8], a
    ret

LanguageMenuClose:
    ld a, [wPreviousMenuItem]
    ld [wLanguage], a
    ret


SECTION "Language menu strings", ROMX

LanguageMenuItems:
    db TEXT_BLANKS,4, "ENGLISH\n"
    db TEXT_BLANKS,3, "ESPANOL\n"
    db                "FRANCAIS\n"
    db TEXT_BLANKS,3, "NIHONGO"
    db 0
