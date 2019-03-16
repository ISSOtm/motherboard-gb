
SECTION "Main menu", ROM0

MainMenu::
    ld de, MainMenuHeader
    ld b, BANK(MainMenuHeader)
    call AddMenu

.mainMenuLoop
    rst wait_vblank
    call ProcessMenus
    ld a, [wNbMenus]
    and a
    jr nz, .mainMenuLoop

    ; TODO: determine which option was selected
    jp BeginOverworld


SECTION "Main meanu header", ROMX

MainMenuHeader:
    db BANK("Main menu data")
    dw MainMenuInit
    db PADF_A | PADF_DOWN | PADF_UP
    db 0 ; Prevent repeat press
    dw 0, 0, 0, 0, 0, 0, 0, 0
    db 0 ; "Previous item"
    db 1 ; Allow wrapping
    db 0 ; Default item
    db 2 ; Size
    dw MainMenuRedraw
    dw MainMenuItems
    dw MainMenuClose


SECTION "Main menu data", ROMX

MainMenuInit:
    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_Y_B
    xor a
    call LCDMemset
    ld hl, MainMenuItems
    call GetLanguageString
    xor a
    ld [wTextLetterDelay], a
    inc a ; ld a, 1
    ld b, BANK(MainMenuItems)
    call PrintVWFText
    ld hl, _SCRN0 + 8 * SCRN_VX_B + 7
    call SetPenPosition
    call PrintVWFChar
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [hLCDC], a
    jp DrawVWFChars

MainMenuRedraw:
    ret

MainMenuItems:
    dw .en
    dw .sp
    dw .fr
    dw .jp

INCLUDE "res/text/main_menu.asm"

MainMenuClose:
    ret
