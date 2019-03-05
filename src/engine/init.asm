
SECTION "Init code", ROMX

Init::
    xor a
    ldh [rAUDENA], a

    ldh a, [rLCDC]
    add a, a
    jr nc, .lcdOff
.waitVBlank
    ld a, [rLY]
    cp SCRN_Y
    jr c, .waitVBlank
    xor a
    ldh [rLCDC], a
.lcdOff


    ; Perform some init

    ; Init HRAM
    ; Also clears IE, but we're gonna overwrite it just after
    ld c, LOW(hClearStart)
.clearHRAM
    ; xor a
    ld [$ff00+c], a
    inc c
    jr nz, .clearHRAM

    ; Copy OAM DMA routine
    ld hl, OAMDMA
    lb bc, OAMDMAEnd - OAMDMA, LOW(hOAMDMA)
.copyOAMDMA
    ld a, [hli]
    ld [$ff00+c], a
    inc c
    dec b
    jr nz, .copyOAMDMA

    ld a, LOW(hScanlineFXBuffer1)
    ldh [hWhichScanlineBuffer], a
    ld a, $FF
    ldh [hScanlineFXBuffer1], a
    ld a, STATF_LYC
    ldh [rSTAT], a

    ld a, LOW(wFastCopyQueue)
    ldh [hFastCopyLowByte], a
    ldh [hFastCopyCurLowByte], a

    ; Turning the screen on and off repeatedly looks OK on all console models...
    ; ...except on SGB, which freaks out in a weird way.
    ; So, we wait until SsAB are released before continuing
    lb bc, %1001, LOW(rP1) ; Load b for below
.waitResetStopped
    ld a, $10 ; Select buttons
    ld [$FF00+c], a
REPT 6
    ld a, [$FF00+c]
ENDR
    and a
    ld a, $30
    ld [$FF00+c], a
    jr z, .waitResetStopped

    ld a, LCDCF_ON | LCDCF_BGON
    ldh [hLCDC], a
    ldh [rLCDC], a

    ld a, IEF_VBLANK | IEF_LCDC
    ldh [rIE], a
    xor a
    ei ; Delayed until the next instruction: perfectly safe!
    ldh [rIF], a

    ; xor a
    ldh [hBGP], a
    ret



