

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
    inc b
    inc c
    jr .begin
.loop
    ld a, [de]
    ld [hli], a
    inc de
.begin
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
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
; DO NOT USE FOR A SIZE OF 1 BYTE
LCDMemcpySmall::
 f LCDMemcpySmall
    srl c
    jr nc, .copy
    wait_vram
    ld a, [de]
    ld [hli], a
    inc de
.copy
    wait_vram
REPT 2
    ld a, [de]
    ld [hli], a
    inc de
ENDR
    dec c
    jr nz, .copy
    ret

; Copies bc bytes of data from de to hl in a LCD-safe manner
LCDMemcpy::
 f LCDMemcpy
    inc b
    inc c
    jr .begin
.loop
    ; TODO: only wait every two bytes, if possible?
    wait_vram
    ld a, [de]
    ld [hli], a
    inc de
.begin
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
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
    inc b
    inc c
    jr .begin
.loop
    wait_vram
    ld a, d
    ld [hli], a
.begin
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
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


; Copies a tilemap to VRAM safely
; @param hl Destination
; @param de Source
; @return hl, de Pointer to end of blocks
; @return bc Zero
; @return a Equal to h
LCDMapcpy::
 f LCDMapcpy
    ld b, SCRN_Y_B
.copyRow
    ld c, SCRN_X_B
.copyTile
    wait_vram
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
; WARNING: A hitbox size of "0" is actually 1 pixel thick
; @param hMovementPosition The point to be moved (16.8 pair)
; @param hMovementHitbox The size of the point's hitbox (8.0 pair)
; @param wMovementVector The movement to be applied to the point (8.8 pair)
; @return hMovementPosition The new (valid) position for the point to be moved
DoCollisionMovement::
 f DoCollisionMovement
    ld a, [wMapCollisionPtr]
    rst bankswitch

    ; Compute active colliders
    ; ABCD being clockwise-ordered vertices, mapping is AC00 00BD
    ld a, [wMovementVector+1] ; Y high
    add a, a
    ld a, %10000010
    jr c, .movingUpwards
    jr nz, .movingDownwards
    ld a, [wMovementVector] ; Y low
    and a
    jr z, .noVertMovement
.movingDownwards
    ld a, %01000001
.movingUpwards
.noVertMovement ; Jumping here with a = 0
    ld b, a

    ld a, [wMovementVector+3] ; X high
    add a, a
    ld a, %10000001
    jr c, .movingLeftwards
    jr nz, .movingRightwards
    ld a, [wMovementVector+2]
    and a
    jr z, .noHorizMovement
.movingRightwards
    ld a, %01000010
.movingLeftwards
.noHorizMovement
    or b
    ret z ; If no active colliders, return immediately without moving
    ldh [hActiveColliders], a

    ; 1/2
    ld hl, wMovementVector + 3
    sra [hl]
    dec l ; dec hl
    rr [hl]
    dec l ; dec hl
    sra [hl]
    dec l ; dec hl
    rr [hl]
    call .tryMoving

    ; 1/2 + 1/4
    ld hl, wMovementVector + 3
    sra [hl]
    dec l ; dec hl
    rr [hl]
    dec l ; dec hl
    sra [hl]
    dec l ; dec hl
    rr [hl]
    call .tryMoving

    ; 1/2 + 1/4 + 1/4
.tryMoving
    ; TODO: skip collision step when staying within the same pixel
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
    ; Algorithm:
    ; Get mapping ID at base + TILE(height) * TILE(x) + TILE(y)
    ; Get mapping byte
    ; Shift mapping byte and return
    ; `TILE(n)` means `n // 8`

    ; Get TILE(x)
    ldh a, [hMovementPosition+5]
    rra
    ld h, a
    ldh a, [hMovementPosition+4]
    ld c, a ; Preserved by mult for later
    rra
REPT 2
    srl h
    rra
ENDR
    ; Multiply by TILE(height)
    ld e, a ; Mult param 1 (preserved, not that we care)
    ldh a, [hMapHeight]
    ld h, a ; Mult param 2
    call Mult8x8
    ; Compute base + TILE(y)
    ldh a, [hMovementPosition+2]
    rra
    ld d, a
    ldh a, [hMovementPosition+1]
    ld b, a ; Preserve for later
    rra
REPT 2
    srl d
    rra
ENDR
    ld e, a
    ld a, [wMapCollisionPtr+1]
    add a, e
    ld e, a
    ld a, [wMapCollisionPtr+2]
    adc a, 0
    ld d, a
    ; Summary:
    ; hl = TILE(height) * TILE(x)
    ; de = base + TILE(y)
    ; b = y
    ; c = x
    add hl, de
    ld a, [wMapCollisionMappingsPtr]
    ld d, a
    ldh a, [hActiveColliders]
    add a, a
    jr nc, .topLeftColliderOff
    ld a, [hl]
    and a ; Mapping 0 is hardcoded to "all passable"
    jr z, .topLeftColliderOff
    sub 2 ; Mapping 1 is hardcoded to "none passable"
    ret c ; Returns with carry set
    ; FIXME: assumes at most 2^5 + 2 = 34 mappings
    add a, a
    add a, a
    add a, a
    ld e, a
    ld a, b
    and %111
    or e
    ld e, a
    ld a, c
    and %111
    inc a
    ld c, a
    ld a, [de] ; Read row
.shiftRowTL
    add a, a
    dec c
    jr nz, .shiftRowTL
    ret c
    ldh a, [hMovementPosition+4]
    ld c, a
.topLeftColliderOff

    ; Move to bottom-left collider
    ; Compute vertical displacement
    ldh a, [hMovementHitbox]
    ld e, a
    ldh a, [hMovementPosition+1]
    add a, e
    ld b, a
    sub a, e
    and 7
    add a, e
    and -8
    rra
    rra
    rra
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a
    ldh a, [hActiveColliders]
    rra
    jr nc, .bottomLeftColliderOff
    ld a, [hl]
    and a ; Mapping 0 is hardcoded to "all passable"
    jr z, .bottomLeftColliderOff
    sub 2 ; Mapping 1 is hardcoded to "none passable"
    ret c ; Returns with carry set
    ; FIXME: assumes at most 2^5 + 2 = 34 mappings
    add a, a
    add a, a
    add a, a
    ld e, a
    ld a, b
    and %111
    or e
    ld e, a
    ld a, c
    and %111
    inc a
    ld c, a
    ld a, [de] ; Read row
.shiftRowBL
    add a, a
    dec c
    jr nz, .shiftRowBL
    ret c
.bottomLeftColliderOff

    ; Move to bottom-right collider
    ; Compute horizontal displacement
    ldh a, [hMovementHitbox+1]
    ld e, a
    ldh a, [hMovementPosition+4]
    add a, e
    ld c, a
    sub a, e
    and 7
    add a, e
    and -8
    jr z, .noHorizDisplacement
    rra
    rra
    rra
    ; This is assumed to be rather small, and `Mult8x8` would trash too many regs
    ld e, a
    ; TODO: this is certainly optimizable
.addHorizontalDisplacement
    ldh a, [hMapHeight]
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a
    dec e
    jr nz, .addHorizontalDisplacement
.noHorizDisplacement
    ldh a, [hActiveColliders]
    bit 6, a
    jr z, .bottomRightColliderOff
    ld a, [hl]
    and a ; Mapping 0 is hardcoded to "all passable"
    jr z, .bottomRightColliderOff
    sub 2 ; Mapping 1 is hardcoded to "none passable"
    ret c ; Returns with carry set
    ; FIXME: assumes at most 2^5 + 2 = 34 mappings
    add a, a
    add a, a
    add a, a
    ld e, a
    ld a, b
    and %111
    or e
    ld e, a
    ld a, c
    and %111
    inc a
    ld b, a ; It's fine to trash B as a counter because if it's ran, the remaining collider will re-compute it anyways
    ld a, [de] ; Read row
.shiftRowBR
    add a, a
    dec b
    jr nz, .shiftRowBR
    ret c
.bottomRightColliderOff

    ; Move to top-right collider
    ; Compute vertical displacement
    ldh a, [hMovementHitbox]
    ld e, a
    ldh a, [hMovementPosition+1]
    ld b, a
    and 7
    add a, e
    and -8
    rra
    rra
    rra
    ld e, a
    ld a, l
    sub e
    ld l, a
    jr nc, .noCarry
    dec h
.noCarry
    ldh a, [hActiveColliders]
    and %10
    ret z ; Returns with carry clear
    ld a, [hl]
    and a ; Mapping 0 is hardcoded to "all passable"
    ret z ; Returns with carry clear
    sub 2 ; Mapping 1 is hardcoded to "none passable"
    ret c ; Returns with carry set
    ; FIXME: assumes at most 2^5 + 2 = 34 mappings
    add a, a
    add a, a
    add a, a
    ld e, a
    ld a, b
    and %111
    or e
    ld e, a
    ld a, c
    and %111
    inc a
    ld c, a
    ld a, [de] ; Read row
.shiftRowTR
    add a, a
    dec c
    jr nz, .shiftRowTR
    ; Return with collider status in carry
    ret



PURGE f
