
SECTION "rst00", ROM0[$0000]
; Please do not call
; Traps execution errors (mostly to $FFFF / $0000)
rst00:
    ; Pad, in case we come from FFFF and read a 2-byte operand
    nop
    nop
    jp NullExecError

SECTION "rst08", ROM0[$0008]
; Please call using `rst memcpy_small`
; Copies c bytes of data from de to hl
MemcpySmall:
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, MemcpySmall
EmptyFunc::
    ret

SECTION "rst10", ROM0[$0010]
; Please call using `rst memset_small`
; Sets c bytes at hl with the value in a
MemsetSmall:
    ld [hli], a
    dec c
    jr nz, MemsetSmall
    ret

SECTION "rst18", ROM0[$0017]
; Please do not call. Use `rst memset`, or, if absolutely needed, `call rst18`.
; Sets bc bytes at hl with the value in d
Memset:
    ld a, d
; Please call using `rst memset`
; Sets bc bytes at hl with the value in a
rst18:
    ld d, a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memset
    ret

SECTION "rst20", ROM0[$0020]
; Please call using `rst bankswitch`
; Properly switches to a ROM bank
; @param a The ROM bank to switch to
; NOTE: only switches the lower 8 bytes, the upper bit (for 512 banks) is not considered
ROMbankswitch:
    ldh [hCurROMBank], a
    ld [rROMB0], a
    ret

SECTION "rst28", ROM0[$0028]
; Please call using `rst call_hl`
; Jumps to hl. Use as a placeholder for `call hl`!
; Will error out if the target is in RAM
CallHL:
    bit 7, h ; Prevent jumping into RAM (doesn't protec against returning to it, but hey :D)
    jr nz, .err
    jp hl
.err
    jp HLJumpingError

SECTION "rst30", ROM0[$0030]
; Please call using `rst wait_vblank`
; Waits for the VBlank interrupt
; Note: if the interrupt occurs without being waited for, it will skip performing some actions
WaitVBlank:
    xor a
    inc a
    ldh [hVBlankFlag], a
.waitVBlank
    halt
    jr .waitVBlank

SECTION "rst38", ROM0[$0038]
; Please do not call
; Traps execution of the $FF byte (which serves as padding of the ROM)
rst38:
    jp Rst38Error


SECTION "Interrupt vectors", ROM0[$0040]

transfer_reg: MACRO
    ldh a, [h\1]
    ldh [r\1], a
ENDM

    ; VBlank
    push af
    transfer_reg LCDC
    jp VBlankHandler

    ; LCD
    push af
    ldh a, [rLYC]
    and a ; Check if on scanline 0, which means music
    ; Scanline 0 FX are handled by the music, kinda
    jr nz, LCDHandler ; Jump to LCD handler, because it's the most likely case
    jr MusicHandler

    ; Timer
    reti

; Fit in a 7-byte function, too!

; Jumps at the function specified by a far pointer
; @param hl A pointer to the far pointer in question; format: 1 byte: bank, 2 bytes LE: ptr
JumpToFarPtr::
    ld a, [hli]
    rst bankswitch
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jr CallHL

    ; Serial
    reti

; And another one!

; Jumps immediately to de, no questions asked (except RAM targets?).
CallDE::
    push de
    bit 7, d
    ret z
    jp DEJumpingError

    ; Joypad
    reti


; Dispatching a LY=LYC interrupt can take between 5 and 12 cycles
; Adding the 11 cycles of the code above, we're between 16 and 23.
; Mode 3 takes up to 72 cycles, and the write must not occur before that, and it must not occur after the next Mode 2 ends (42 cycle leeway)
; So, we need to wait at least 72 - 16 = 52 cycles, part of which will be spent doing updates: TIME TO CYCLE-COUNT!
LCDHandler:
    push bc
    ldh a, [hScanlineFXIndex]
    ld c, a
    ld a, [$ff00+c] ; Get port ID
    ld b, a ; Save port ID for later
    inc c
    inc c
    ld a, [$ff00+c] ; Get next effect's scanline
    dec a ; Compensate for processing time
    ldh [rLYC], a ; Get set up (this should reset the STAT interrupt trigger line)
    ld a, c ; Point to next effect's port ID
    inc a
    ldh [hScanlineFXIndex], a
    dec c
    ld a, [$FF00+c] ; Get effect's value
    ld c, a ; Since we don't need the read index anymore, use c to retrieve the value faster later
    ; Wait a bit to write during HBlank, to avoid gfx artifacts
    ; We spent 28 cycles above, out of the required 52
    ; That leaves 20 cycles
    ; However, the first write occurs 8 cycles after the loop exits, so there's really 12 cycles to be waited
    ; Each iteration of the loop takes 4 cycles, except the last one which only takes 3
    ; This means we need to do (12 - 3) / 4 + 1 = 2 iterations + 1 cycle
    ; This one cycle will only appear on the textbox, and shouldn't be problematic unless the preceding scanline is busy
    ; And, HBlank is really short so we need to finish up quickly
    ld a, 2
.waitMode0
    dec a
    jr nz, .waitMode0

    ; Check if we're trying to write to $FF*00* (rP1)
    ld a, b
    and a ; Note: `and $7F` can be used instead to have control on bit 7 (if ever needed)
    ld a, c ; Get back value
    ; $00 (rP1) is hooked to instead perform textbox ops, since writing to it has no use
    jr z, .textbox ; The textbox performs its write slightly earlier, so use the extra jump cycle to delay it slightly

    ld c, b ; Retrieve port
    res 7, c
    ld [$ff00+c], a ; Apply FX
    bit 7, b
    jr z, .onlyOneEffect
    ldh a, [hSecondFXAddr]
    ld c, a
    ldh a, [hSecondFXValue]
    ld [$ff00+c], a
.onlyOneEffect
    pop bc
    pop af
    reti

.textbox
    ldh [rSCY], a ; Store value, which is actually for SCY (dat plot twist, eh?)
    xor a
    ldh [rSCX], a
    ldh a, [hLCDC] ; Retrieve LCDC value
    and ~(LCDCF_WINON | LCDCF_OBJON)
    or LCDCF_BG9C00 | LCDCF_BG8000
    ldh [rLCDC], a
    ldh a, [hTextboxBGP]
    ldh [rBGP], a
    ; Note: this is scrapped support for sprites on the textbox
    ; It was initially planned for JP diacritics.
    ; If for whatever reason, you need to re-activate this feature...
    ; ...uncomment this, and remove "LCDCF_OBJON" from above.
    ; 
    ; ; Perform OAM DMA to get textbox's sprites
    ; ; Luckily, sprites are hidden during DMA
    ; ; Also no sprites should be present on the textbox 1st row, hiding our trickery >:P
    ; ld a, HIGH(wTextboxOAM)
    ; call hOAMDMA
    ; ; Reload OAM on next frame
    ; ldh a, [hCurrentOAMBuffer]
    ; ldh [hOAMBuffer], a
    pop bc
    pop af
    reti

; Cycle counting is important here as well: if an effect needs to trigger on scanline 1, its code must start running on scanline 0
; But, we hooked scanline 0 for our own purposes! And, scanline 0 triggers partway through VBlank! (111 cycles)
; ...Actually, according to @liji32, the interrupt will trigger again at the beginning of render line 0, so we don't need to worry
MusicHandler:
    push bc
    ; Set up things for the actual raster FX
    ldh a, [hScanlineFXIndex]
    ld c, a
    inc a
    ldh [hScanlineFXIndex], a
    ld a, [$FF00+c] ; Get scanline
    dec a ; Usual accounting
    ldh [rLYC], a
    ; The music code needs to be interruptable, especially if we need a scanline 0 int
    ei
    ; TODO: add music code
    pop bc
    pop af
    ret


SECTION "VBlank handler", ROM0

VBlankHandler:
    push bc

    ; ============= Here are things that need to be updated, even on lag frames ==============

    ; Update IO from HRAM shadow
    transfer_reg SCY
    transfer_reg SCX
    transfer_reg WY
    transfer_reg WX
    transfer_reg BGP
    transfer_reg OBP0
    transfer_reg OBP1


    ; Prepare raster FX stuff
    ; NOTE: this assumes no effect is scheduled on line 0
    ; This should never happen; instead, use the HRAM shadow regs (hSCY, etc.)
    ldh a, [hWhichScanlineBuffer]
    ldh [hScanlineFXIndex], a
    ; Set int to happen on first scanline, for music (partway into VBlank, but oh well)
    xor a
    ldh [rLYC], a


    ; Perform fast VRAM copy if asked to
    ldh a, [hFastCopyNbReq]
    and a
    jp z, .dontDoFastTransfer
    push de
    push hl
    ; Save sp and set it to source
    ld [wSPBuffer], sp
    ; Get ready to read params
    ldh a, [hFastCopyCurLowByte]
    ld c, a
.serveOneCopyReq ; Roughly 11 cycles + 74 cycles/tile
    ld b, HIGH(wFastCopyQueue)
    ld a, [bc] ; Read bank
    ld [rROMB0], a
    inc c ; inc bc
    ; Read src
    ld a, [bc]
    ld l, a
    inc c ; inc bc
    ld a, [bc]
    ld h, a
    inc c ; inc bc
    ld sp, hl
    ; Read dest
    ld a, [bc]
    ld l, a
    inc c ; inc bc
    ld a, [bc]
    ld h, a
    inc c ; inc bc
    ld a, [bc] ; Read completion flags ptr (low)
    ld e, a
    inc c ; inc bc
    ; Check if the copy is going to be in our budget
    ld a, [bc] ; Read first bad scanline
    ld d, a
    inc c ; inc bc
    ld a, [bc] ; Read len
    ld b, a
    ldh a, [rLY]
    cp d
    jr nc, .abort
    inc c ; inc bc
    ; And begin the fun
    srl b ; Shift now so we get parity into carry (carry is currently clear)
    inc b ; Compensate for half cycle
    ; Write ACK for systems dependent on the transfer
    ld d, HIGH(wFastCopyACKs)
    ld a, 1
    ld [de], a
    jr c, .oneTile ; Do a light Duff's Device
    dec b ; Actually, there won't be any half cycle
.twoTiles
REPT 8
    pop de
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
ENDR
.oneTile
REPT 8
    pop de
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
ENDR
    dec b
    jr nz, .twoTiles
    ld a, c
    and $7F
    ld c, a
    ldh a, [hFastCopyNbReq]
    dec a
    ldh [hFastCopyNbReq], a
    jp nz, .serveOneCopyReq
.abort
    ; Update low byte
    ld a, c
    and -8
    ldh [hFastCopyCurLowByte], a
    ; Restore regs
    ldh a, [hCurROMBank]
    ld [rROMB0], a
    ld sp, wSPBuffer
    pop hl
    ld sp, hl
    pop hl
    pop de
.dontDoFastTransfer


    ; Update OAM if needed
    ; Do this last so it will go through even without time, but it must not be interrupted on DMG
    ; This will simply cause sprites to not be displayed on the top few scanlines, but that's not as bad as palettes not loading at all, huh?
    ldh a, [hOAMBufferHigh]
    and a
    jr z, .dontUpdateOAM
    ld b, a
    ; Reset OAM buffer high vect
    xor a
    ldh [hOAMBufferHigh], a
    ; Perform DMA as specified
    ld a, b
    call hOAMDMA
.dontUpdateOAM


    ; =============== End of things that should not be interrupted ===============
    ei


    ; =============== In case of lag, don't update further, to avoid breaking stuff ===============

    ldh a, [hVBlankFlag]
    and a
    jr z, .lagFrame


    ; Poll joypad and update regs
    ; Must not be done on non-lag frames to avoid breaking SGB transfers

    ld c, LOW(rP1)
    ld a, $20 ; Select D-pad
    ld [$ff00+c], a
REPT 6
    ld a, [$ff00+c]
ENDR
    or $F0 ; Set 4 upper bits (give them consistency)
    ld b, a

    ; Filter impossible D-pad combinations
    and $0C ; Filter only Down and Up
    ld a, b
    jr nz, .notUpAndDown
    or $0C ; If both are pressed, "unpress" them
    ld b, a
.notUpAndDown
    and $03 ; Filter only Left and Right
    jr nz, .notLeftAndRight
    ld a, b
    or $03 ; If both are pressed, "unpress" them
    ld b, a
.notLeftAndRight
    swap b ; Put D-pad buttons in upper nibble

    ld a, $10 ; Select buttons
    ld [$ff00+c], a
REPT 6
    ld a, [$ff00+c]
ENDR
    ; On SsAB held, soft-reset
    and $0F
    jr z, .perhapsReset
.dontReset

    or $F0 ; Set 4 upper bits
    xor b ; Mix with D-pad bits, and invert all bits (such that pressed=1) thanks to "or $F0"
    ld b, a

    ; Release joypad
    ld a, $30
    ld [$ff00+c], a

    ldh a, [hHeldButtons]
    cpl
    and b
    ldh [hPressedButtons], a

    ld a, b
    ldh [hHeldButtons], a

    pop bc
    pop af


    ; The main code was waiting for VBlank, so make it escape the infinite loop
    xor a
    ldh [hVBlankFlag], a ; Mark VBlank as ACK'd
    pop af ; "Return" from vblank wait routine
    ret


.lagFrame
    pop bc
    pop af
    ret


.perhapsReset
    ldh a, [hSoftResettingPermitted]
    and a ; If non-zero, we are allowed to soft-reset
    jr z, .dontReset ; If zero, jump back - the value we came here with was zero, so it's not problematic
    jp Reset
