
SECTION "Main menu header", ROMX

MainMenuHeader::
    db BANK("Main menu data")
    dw MainMenuInit
    db PADF_A | PADF_B | PADF_DOWN | PADF_UP
    db 0 ; Prevent repeat press
    dw MainMenuHook, 0, 0, 0, 0, 0, 0, 0
    db 0 ; "Previous item"
    db 1 ; Allow wrapping
    db 0 ; Default item
    db 4 ; Size
    dw MainMenuRedraw
    dw MainMenuItems
    dw MainMenuClose

SECTION "Main menu data", ROMX

MainMenuInit:
    ; Clear OAM because sprites will otherwise linger during the VRAM clearing
    ld hl, wShadowOAM
    xor a
    ld c, 40
.clearOAM
    ld [hli], a
    inc l
    inc l
    inc l
    dec c
    jr nz, .clearOAM
    ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a
    ; This will take a little over a frame, OAM transfer will happen during it
    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_Y_B
    xor a
    call LCDMemset
    ; It's safe to modify the buffer directly if it's to terminate it
    dec a ; ld a, $FF
    ldh [hScanlineFXBuffer1], a
    ld a, LOW(hScanlineFXBuffer1)
    ldh [hWhichScanlineBuffer], a

    ld hl, MainMenuItems
    call GetLanguageString
    ld a, 1 ; FIXME: check if save file is present instead
    ldh [hSaveFilePresent], a
    and a
    jr nz, .saveFilePresent
    ; If no save file is present, skip drawing the "CONTINUE" option
.skipContinue
    ld a, [hli]
    cp $0A ; '\n'
    jr nz, .skipContinue
    ; Decrement menu size
    ld hl, wMenu0_Size
    dec [hl]
.saveFilePresent
    xor a
    ld [wTextLetterDelay], a ; Instant print
    ; Force text to start at tile 1 or 2 so we have room to load more gfx
    inc a ; ld a, 1
    ld [wTextCurTile], a
    ld a, SCRN_X
    ld [wTextLineLength], a
    ld a, SCRN_Y_B
    ld [wTextNbLines], a
    ld [wTextRemainingLines], a
    ; a is non-zero
    ld b, BANK(MainMenuItems)
    call PrintVWFText
    ld hl, _SCRN0 + 8 * SCRN_VX_B + 5
    call SetPenPosition
    call PrintVWFChar

    ld hl, $8500
    ld de, .tiles
    ld c, .tilesEnd - .tiles
    call LCDMemcpySmall

    ld hl, wShadowOAM
    ; ld de, .oam
    ld c, .oamEnd - .oam
    rst memcpy_small
    ld a, h ; ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a

    ; Final setup, things will appear now
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BGON
    ldh [hLCDC], a
    jp DrawVWFChars

.tiles
INCBIN "res/main_menu/main_menu.oam.chr"
.tilesEnd

.oam
    dspr 61, 22, $50, 0
    dspr 61, 30, $52, 0
.oamEnd

MainMenuRedraw:
    ld hl, sp+2
    ld a, [hli]
    ld h, [hl]
    ld l, a
    dec hl
    dec hl
    dec hl
    ld a, [hl] ; Get cur item
    add a, a
    add a, a
    add a, a
    add a, 61 + 16
    ld [wShadowOAM], a
    ld [wShadowOAM+4], a
    ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a
    ret

MainMenuItems:
    dw .en
    dw .sp
    dw .fr
    dw .jp

INCLUDE "res/text/main_menu.asm"

MainMenuClose:
    ret

MainMenuHook:
    ld hl, sp+2
    ld a, [hli]
    ld h, [hl]
    ld l, a
    inc hl

    ; Options menu doesn't close this one
    ldh a, [hSaveFilePresent]
    rra
    ccf
    ld a, [hl]
    adc a, 0
    sub 2 ; Options
    ret c ; Only the first 2 options close the menu
    ; Others open a submenu, get ptr to its header
    add a, a
    add a, LOW(.submenus)
    ld l, a
    adc a, HIGH(.submenus)
    sub l
    ld h, a
    ld a, [hli]
    ld d, [hl]
    ld e, a
    ; Override default action (closing menu) with new one (opening submenu)
    ld hl, wMenuAction
    ld a, MENU_ACTION_NEW_MENU
    ld [hli], a
    ld a, BANK("Main menu submenus headers")
    ld [hli], a
    ld a, e
    ld [hli], a
    ld [hl], d

    ; Gray out screen on SGB to allow transition to proceed without attribute clash
    ldh a, [hIsSGB]
    and a
    ret z
    ld hl, .grayOutPacket
    jp SendPacketNoDelay

.grayOutPacket
    sgb_packet PAL_SET, 1 ; FIXME: add packet data

.submenus
    dw OptionsMenuHeader
    dw MusicPlayerHeader



SECTION "Main menu submenus headers", ROMX

OptionsMenuHeader:
    db BANK("Options menu data")
    dw OptionsMenuInit
    db PADF_A | PADF_B | PADF_LEFT | PADF_RIGHT | PADF_DOWN | PADF_UP
    db 0 ; Prevent repeat press
    dw 0, 0, 0, 0, 0, 0, 0, 0
    db 0 ; "Previous item"
    db 1 ; Allow wrapping
    db 0 ; Default item
    db 2 ; Size
    dw OptionsMenuRedraw
    dw OptionsMenuItems
    dw OptionsMenuClose
PUSHS

SECTION "Options menu data", ROMX

OptionsMenuInit:
    ret

OptionsMenuRedraw:
    ret

OptionsMenuItems:

OptionsMenuClose:
    ret


SECTION "Music player data", ROMX

MusicPlayerLeft:
    ld a, MENU_ACTION_MOVE_UP
    db $11 ; ld bc, imm16

MusicPlayerRight:
    ld a, MENU_ACTION_MOVE_DOWN
    ld [wMenuAction], a
    ret

MusicPlayerA:
    ret

NB_TRACKS = 0
music_player_entry: MACRO
    db \1, \2, 0
NB_TRACKS = NB_TRACKS + 1
ENDM
MusicPlayerItems:
    music_player_entry MUSIC_MENU, "MAIN MENU"

MusicPlayerInit:
    ld a, $70
    ld [wTextCurTile], a
    ld hl, MusicPlayerItems + 1
    ld b, BANK(MusicPlayerItems)
    ld a, SCRN_X
    ld [wTextLineLength], a
    ld a, SCRN_Y_B
    ld [wTextNbLines], a
    ld [wTextRemainingLines], a
    ; a is non-zero
    call PrintVWFText
    ld hl, $9C43
    call SetPenPosition
    call PrintVWFChar
    ; Draw cassette tape
    ld hl, $8900
    ld de, .tiles
    ld bc, .tilesEnd - .tiles
    call LCDMemcpy
    ld hl, $9C00
    ; ld de, .tilemap
    call LCDMapcpy
    jp DrawVWFChars

.tiles
INCBIN "res/main_menu/music_player.chr"
.tilesEnd

.tilemap
INCBIN "res/main_menu/music_player.90.offset.tilemap"

MusicPlayerRedraw:
    ret

MusicPlayerClose:
    ret

POPS
MusicPlayerHeader:
    db BANK("Music player data")
    dw MusicPlayerInit
    db PADF_A | PADF_B | PADF_LEFT | PADF_RIGHT
    db 1 ; Allow repeat press
    dw MusicPlayerA, 0, 0, 0, MusicPlayerRight, MusicPlayerLeft, 0, 0
    db 0 ; "Previous item"
    db 1 ; Allow wrapping
    db 0 ; Default item
    db NB_TRACKS ; Size
    dw MusicPlayerRedraw
    dw MusicPlayerItems
    dw MusicPlayerClose
