
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
    ; TODO: Load extra gfx
    ; Cursor arrow, Up, Down and START button prompts

    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_Y_B
    xor a
    call LCDMemset
    ; xor a
    ld [wTextLetterDelay], a
    inc a ; ld a, 1
    ld hl, LanguageMenuItems
    ld b, BANK(LanguageMenuItems)
    call PrintVWFText
    ld hl, _SCRN0 + SCRN_VY_B * (SCRN_X_B - NB_LANGUAGES) / 2 + 7
    call SetPenPosition
    call PrintVWFChar

    ld hl, wShadowOAM + $A0 - 1
.clearSprites
    dec l ; dec hl
    dec l ; dec hl
    dec l ; dec hl
    xor a
    ld [hld], a
    ld a, l
    sub 3
    jr nz, .clearSprites
    ; xor a
    ldh [hLangSelMenuCursorPos], a
    ; xor a
    ld [hld], a
    inc a
    ld [hld], a
    ld a, 6 * 8 + 8
    ld [hld], a
    ld [hl], 8 * 8 + 16
    ld a, $1B
    ldh [hBGP], a
    ldh [hOBP0], a
    ld a, h ; ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_BGON
    ldh [hLCDC], a

    jp DrawVWFChars

LanguageMenuRedraw:
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
    add a, 8 * 8 + 16
    ld [wShadowOAM], a
    ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a
    ret

LanguageMenuClose:
    ret


SECTION "Language menu strings", ROMX

LanguageMenuItems:
    db TEXT_BLANKS,4, "ENGLISH\n"
    db TEXT_BLANKS,3, "ESPANOL\n"
    db "FRANCAIS\n"
    db TEXT_BLANKS,3, "NIHONGO"
    db 0
