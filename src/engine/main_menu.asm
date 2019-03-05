
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
    db 0
    dw 0, 0, 0, 0, 0, 0, 0, 0
    db 0
    db 1
    db 0
    db 2
    dw MainMenuRedraw
    dw MainMenuItems
    dw MainMenuClose


SECTION "Main menu data", ROMX

MainMenuInit:
    ret

MainMenuRedraw:
    ret

MainMenuItems:
    db "New Game\n"
    db "Options"
    db 0

MainMenuClose:
    ret
