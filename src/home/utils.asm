

; Since all these functions are independent, declare each of them in individual sections
; Lets the linker place them more liberally. Hooray!
; The label is still declared as usual to cope with VS Code's extension, which couldn't provide tooltips otherwise
f: MACRO
PURGE \1
SECTION "Utility function \1", ROM0
\1::
ENDM

SECTION "Dummy section", ROM0 ; To have the first `Memcpy` declare properly

; Copies bc bytes of data from de to hl
Memcpy::
 f Memcpy
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    ret

; Copies a null-terminated string from de to hl, including the terminating NUL
Strcpy::
 f Strcpy
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, Strcpy
    ret

; Copies c bytes of data from de to hl in a LCD-safe manner
LCDMemcpySmall::
 f LCDMemcpySmall
    wait_vram
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, LCDMemcpySmall
    ret

; Copies bc bytes of data from de to hl in a LCD-safe manner
LCDMemcpy::
 f LCDMemcpy
    wait_vram
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, LCDMemcpy
    ret

; Sets c bytes of data at hl with the value in a
LCDMemsetSmall::
 f LCDMemsetSmall
    ld b, a

; Sets c bytes of data at hl with the value in b
LCDMemsetSmallFromB::
; No f (...) because there's the slide-in above
    wait_vram
    ld a, b
    ld [hli], a
    dec c
    jr nz, LCDMemsetSmallFromB
    ret

; Sets bc bytes of data at hl with the value in a
LCDMemset::
 f LCDMemset
    ld d, a

; Sets bc bytes of data at hl with the value in d
LCDMemsetFromD::
; No f (...) because of the slide-in above
    wait_vram
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, LCDMemsetFromD
    ret


; Opens SRAM at some bank
; @param a The bank's number
; @return a CART_RAM_ENABLE, ie. $0A
GetSRAMBank::
 f GetSRAMBank
    ld [rRAMB], a
    ld a, CART_RAM_ENABLE
    ld [rRAMG], a
    ret

; Closes SRAM
; @return hl = rRAMB (I know, it sounds stupid)
CloseSRAM::
 f CloseSRAM
; Implementation note: MUST preserve the Z flag to avoid breaking the call to `PrintSRAMFailure`
    ld hl, rRAMG
    ld [hl], l ; ld [hl], 0
    ld h, HIGH(rRAMB)
    ld [hl], l ; Avoid unintentional unlocks corrupting saved data, switch to bank 0 (which is scratch)
    ret


; Gets the Nth struct in an array of 'em
; @param hl Array base
; @param bc Size of a struct
; @param a  ID of the desired struct
; @return hl Pointer to the struct's base
; @destroy a
GetNthStruct::
 f GetNthStruct
    and a
    ret z
.next
    add hl, bc
    dec a
    jr nz, .next
    ret


; Copies tiles into VRAM, using an unrolled loop to go faster
; @param de Destination (pointer) (MAKE SURE THIS IS ALIGNED TO A TILE!)
; @param hl Source
; @param c  Number of tiles
; @return hl, de Pointer to end of blocks
; @return c 0
; @destroy a
Tilecpy::
 f Tilecpy
REPT $10 / 2 - 1
    wait_vram
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc e ; inc de
ENDR
    wait_vram
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, Tilecpy
    ret


; Copies a tilemap to VRAM, assuming the LCD is off
; @param hl Destination
; @param de Source
; @return hl, de Pointer to end of blocks
; @return bc Zero
; @return a Equal to h
Mapcpy::
 f Mapcpy
    ld b, SCRN_Y_B
.copyRow
    ld c, SCRN_X_B
.copyTile
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, .copyTile
    ld a, l
    add a, SCRN_VX_B - SCRN_X_B
    ld l, a
    adc a, h
    sub l
    ld h, a
    dec b
    jr nz, .copyRow
    ret


; Calculates a point's position relative to the camera
; @param hl Pointer to point struct (must contain Y then X, 1 byte subpixels then 1 word pixels)
; @return hl Advanced by 6
; @destroy a, bc
GetCameraRelativePosition::
 f GetCameraRelativePosition
    inc hl
    ld a, [wCameraYPos]
    cpl
    ; It's important that we add the extra "invert" 1 (usually with `inc a`)
    ; with the rest to get a workable carry behavior (with 0, specifically)
    scf
    adc [hl]
    ld [hCameraRelativePosition], a
    inc hl
    ld a, [wCameraYPos+1]
    cpl
    adc [hl] ; Add one less if carry occurred
    ld [hCameraRelativePosition+1], a
    inc hl

    inc hl
    ld a, [wCameraXPos]
    cpl
    scf
    adc [hl]
    ld [hCameraRelativePosition+2], a
    inc hl
    ld a, [wCameraXPos+1]
    cpl
    adc [hl]
    ld [hCameraRelativePosition+3], a
    inc hl
    ret


; Does a 8x8 -> 16 multiplication
; @param h Mulitplier 1 (destroyed)
; @param e Multiplier 2 (preserved)
; @return hl Result
; @return d 0
; @return b 0
Mult8x8::
 f Mult8x8
    ld l, 0
    ld d, l ; ld d, 0
    ; Do 1st operation here, it'll be faster
    sla h
    jr nc, .noCarry1
    ld l, e
.noCarry1
    ld b, 7
.loop
    add hl, hl
    jr nc, .noCarry
    add hl, de
.noCarry
    dec b
    jr nz, .loop
    ret


; Get the current language's string from an array
; They must be in the order defined by the language enum
; @param hl A pointer to an array of pointers to the strings
; @return hl A pointer to the correct string
; @return a LOW(hl)
GetLanguageString::
 f GetLanguageString
    ld a, [wLanguage]
    add a, a
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ret


; Move a point according to the current map's collision
; Uses a dichotomy approach to mitigate coordinate asymmetry and reduce computations
; NOTE: All parameters are fixed-point integer pairs
; WARNING: This code may function unexpectedly for movement vectors greater than 4 pixels, please enforce speed caps thx
; @param hMovementPosition The point to be moved (16.8 pair)
; @param hMovementHitbox The size of the point's hitbox (8.0 pair)
; @param wMovementVector The movement to be applied to the point (8.8 pair)
; @return hMovementPosition The new (valid) position for the point to be moved
DoCollisionMovement::
 f DoCollisionMovement
    ; 1/2
    call .halveVector
    call .tryMoving
    ; 1/2 + 1/4
    call .halveVector
    call .tryMoving

    ; 1/2 + 1/4 + 1/4
.tryMoving
    ld hl, wMovementVector
    ld c, LOW(hMovementPosition)
    call .applyMovement
    call .collision
    ld hl, wMovementVector
    ld c, LOW(hMovementPosition)
    call c, .revertMovement
    ld hl, wMovementVector + 2
    ld c, LOW(hMovementPosition + 3)
    call .applyMovement
    call .collision
    ret nc
    ld hl, wMovementVector + 2
    ld c, LOW(hMovementPosition + 3)
.revertMovement
    ldh a, [c]
    sub a, [hl]
    ldh [c], a
    inc l ; inc hl
    inc c
    ld b, [hl]
    ldh a, [c]
    sbc a, b
    ldh [c], a
    inc c
    ldh a, [c]
    sbc a, 0
    rl b
    adc a, 0
    ldh [c], a
    ret

.applyMovement
    ldh a, [c]
    add a, [hl]
    ldh [c], a
    inc l ; inc hl
    inc c
    ld b, [hl]
    ldh a, [c]
    adc a, b
    ldh [c], a
    inc c
    ldh a, [c]
    adc a, 0
    rl b
    sbc a, 0
    ldh [c], a
    ret

.collision
    ; TODO:
    and a
    ret


.halveVector
    ld hl, wMovementVector + 3
    sra [hl]
    dec hl
    rr [hl]

    dec hl
    sra [hl]
    dec hl
    rr [hl]
    ret



PURGE f
