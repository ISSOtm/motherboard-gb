
NB_ROM_BANKS = 4

SECTION "Header", ROM0[$100]

EntryPoint::
    ld b, $60
    jr LogoFade

    dbr 0, $150 - $104

    ; Header ends here

CRCs: ; ENSURE THIS HAS ZERO LOW BIT OF ADDR
    ds 2 * NB_ROM_BANKS ; The CRC16 check values will go here (in continuity with the two checksum bytes), **LITTLE-ENDIAN**

LogoFade:
    xor a
    ldh [rAUDENA], a

.fadeLogo
    ld c, 7 ; Number of frames between each logo fade step
.logoWait
    ld a, [rLY]
    cp a, SCRN_Y
    jr nc, .logoWait
.waitVBlank
    ld a, [rLY]
    cp a, SCRN_Y
    jr c, .waitVBlank
    dec c
    jr nz, .logoWait
    ; Shift all colors (fading the logo progressively)
    ld a, b
    rra
    rra
    and $FC ; Ensures a proper rotation and sets Z for final check
    ldh [rBGP], a
    ld b, a
    jr nz, .fadeLogo ; End if the palette is fully blank (flag set from `and $FC`)

    ; xor a
    ldh [rDIV], a

    ; xor a
    ldh [hIsSGB], a

Reset::
    di
    ld sp, wStackBottom

    ld a, BANK(Init)
    rst bankswitch
    call Init

    ; Check if the UP+LEFT+SELECT+B combo is held; if so, perform a CRC self-test
    ; B and C set above
    ld a, $10 ; Select buttons
    ld [$ff00+c], a
REPT 6
    ld a, [$ff00+c]
ENDR
    and $0F
    cp b
    jr nz, .skipCRC
    ld a, $20
    ld [$ff00+c], a
REPT 6
    ld a, [$ff00+c]
ENDR
    and $0F
    cp b
    jp z, CheckCRC
.skipCRC
    ld a, $30
    ld [$ff00+c], a


    ld a, (vVWFTiles - $8000) / 16
    ld [wTextCurTile], a

    xor a
    ld [wTextCurPixel], a
    ld [wTextCharset], a
    ld [wNbNewlines], a
    ld [wTextPaused], a
    ld [wTextStackSize], a
    ld hl, wTextTileBuffer
    ld c, $20
    ; xor a
    rst memset_small

    ld hl, _SCRN0
    ld bc, SCRN_Y_B * SCRN_VX_B
    ; xor a
    call LCDMemset

    ; xor a
    ld [wTextLetterDelay], a
    inc a ; ld a, 1
    ld [wWrapTileID], a
    ; ld a, 1
    ld b, BANK(LicensedText)
    ld hl, LicensedText
    call PrintVWFText
    ld hl, _SCRN0 + 8 * SCRN_VX_B + 2
    call SetPenPosition
    call PrintVWFChar
    call DrawVWFChars

    PUSHS
SECTION "Licensed text", ROMX

LicensedText:
    dstr "NOT LICENSED BY NINTENDO"
    POPS

    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [hLCDC], a
    ld hl, $2700
    ld b, l ; ld b, 0
.fadeIn
    ld a, b
    ldh [hBGP], a
    wait 5 frames
    ld a, h
    add hl, hl
    rr b
    add hl, hl
    rr b
    and a
    jr nz, .fadeIn

    ; Don't do SGB init if soft-resetting on a SGB
    ldh a, [hIsSGB]
    and a
    jr nz, .skipSGBInit
    ld a, BANK(DoSGBSetup)
    rst bankswitch
    call DoSGBSetup

    ; If we were on a SGB, then the init took some time: compensate by waiting less
    ; Estimated time: 30 frames
    ldh a, [hIsSGB]
    and a
    ld c, 30 frames
    jr nz, .waitLicense
.skipSGBInit
    ld c, 60 frames
.waitLicense
    rst wait_vblank
    dec c
    jr nz, .waitLicense

    ld hl, hBGP
    ld b, 4
.fadeOut
    sra [hl] ; Bit 7 is guaranteed to be set due to previous shift, so we can use `sra`
    sra [hl]
    wait 5 frames
    dec b
    jr nz, .fadeOut


    ; Clear rDIV to make the game more consistent with emulators even without the boot ROM
    ; (Would trigger an APU sequence if the APU was enabled at all)
    xor a
    ldh [rDIV], a

    ; Prevent soft-resetting in the middle of setting up
    inc a ; ld a, 1
    ldh [hSoftResettingPermitted], a

    ld a, BANK(StudioScreen)
    rst bankswitch
    call StudioScreen

    ld b, BANK(LanguageMenuHeader)
    ld de, LanguageMenuHeader
    call AddMenu
.processLanguageMenu
    rst wait_vblank
    call ProcessMenus
    ld a, [wNbMenus]
    and a
    jr nz, .processLanguageMenu

    ld a, BANK(TitleScreen)
    rst bankswitch
    call TitleScreen

    jp MainMenu


    ; Performs CRC verification
CRC_POLYNOM   equ $1021
    ; Uses direct allocation because it's not gonna interfere with anything else, and I'm not reeeally gonna unionize everything
wCRCSuccess   equ $C000
wCRCLowTable  equ $D000
wCRCHighTable equ $D100

CheckCRC:
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG9800 | LCDCF_BG8800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a
    ldh [hLCDC], a

    ld a, %01100100
    ldh [hBGP], a

    ; Compute CRC table to speed up later calculations
    ld de, wCRCHighTable
.computeCRCTable
    ld h, e
    ld l, 0
    ld c, 8
.bitLoop
    add hl, hl
    jr nc, .bitClear
    ld a, l
    xor LOW(CRC_POLYNOM)
    ld l, a
    ld a, h
    xor HIGH(CRC_POLYNOM)
    ld h, a
.bitClear
    dec c
    jr nz, .bitLoop
    dec d
    ld a, l
    ld [de], a
    inc d
    ld a, h
    ld [de], a
    inc e
    jr nz, .computeCRCTable

    ld hl, $0000
    ld c, l ; ld c, 0 ; Low byte of pointer to result
.CRCLoop
    ld b, $FF ; CRC low
    ld e, b ; lb de, HIGH(wCRCHighTable), $FF ; CRC high & pointer to table
    jr .feedByte ; Skip "skip hack"
.skipBytes
    ld l, LOW(LogoFade)
.feedByte
    ; Update CRC in `eb`
    ld a, [hli]
    xor e ; XOR with high byte
    ld e, a ; Store back
    dec d ; Switch to low byte table
    ld a, [de] ; Get low byte mask
    xor b ; XOR with low byte
    ld b, a ; Store back
    inc d ; Switch to high byte table
    ld a, [de] ; Get high byte mask
    xor e ; XOR with high byte
    ld e, a ; Store back
    ; Check if we should skip
    ld a, h
    dec a
    ld a, l
    jr nz, .dontSkipBytes
    cp LOW($014E)
    jr z, .skipBytes
.dontSkipBytes
    ; Check if reached end of a bank
    and a
    jr nz, .feedByte
    ld a, h
    and %111111
    jr nz, .feedByte
    ; Now check if the CRC matches
    ; Get pointer to current
    ld a, c
    add a, LOW(CRCs) >> 1
    add a, a
    ld l, a
    adc a, HIGH(CRCs)
    sub l
    ld h, a
    ld a, [hli]
    cp b
    jr nz, .CRCFail
    ld a, [hli]
    cp e
    jr z, .CRCSuccess
.CRCFail
    db $3E ; ld a, $AF
.CRCSuccess
    xor a
    ld b, HIGH(wCRCSuccess)
    ld [bc], a
    ldh a, [hBGP]
    rlca
    rlca
    ldh [hBGP], a
    ; Prepare next bank
    ld hl, $4000
    inc c
    ld a, c
    rst bankswitch ; Will switch to a bad bank on last iter, but that's not a problem.
    ; ld a, c
    cp NB_ROM_BANKS
    jr nz, .CRCLoop

    ; Now, time to display the results!
    xor a
    ldh [hSCX], a
    ldh [hSCY], a
    ld a, %11100100
    ldh [hBGP], a
    ld hl, $9000
    lb bc, 0, 16
    call LCDMemsetSmallFromB
    ld hl, $8AF0
    lb bc, $FF, 16
    call LCDMemsetSmallFromB
    ld hl, $97F0
    wait_vram
    ; xor a
    ld [hli], a
    ld [hli], a
    lb bc, $FE, 7
.writeFFTile
    wait_vram
    ld [hli], a
    ld a, b
    ld [hli], a
    dec c
    jr nz, .writeFFTile
    ; ld hl, _SCRN0
    lb bc, $7F, SCRN_VX_B + 1
    call LCDMemsetSmallFromB
    ld de, wCRCSuccess
    ld c, NB_ROM_BANKS
.copyResults
    wait_vram
    ld a, [de]
    ld [hli], a
    inc e ; inc de
    ld a, l
    and -SCRN_VX_B
    cp SCRN_X_B - 1
    jr nz, .dontSkipRow
    wait_vram
    ld a, $7F
    ld [hli], a
    ld a, l
    add a, SCRN_VX_B - SCRN_X_B
    ld l, a
    adc a, h
    sub l
    ld h, a
.dontSkipRow
    dec c
    jr nz, .copyResults

.fillRemainderOfScreen
    wait_vram
    ld a, $7F
    ld [hli], a
    ld a, h
    cp HIGH(_SCRN1)
    jr nz, .fillRemainderOfScreen

.lockUp
    jr .lockUp
