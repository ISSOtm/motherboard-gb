
; The entirety of this file can be summed up as follows:
;   HERE BE DRAGONS.
; If you, poor soul, must debug or change something in this file, know that I am extremely sorry.
; May K&R have mercy on your soul.

SECTION "Player overlap functions", ROMX,ALIGN[8]

PlayerOverlapFuncs::
    dw ShiftPlayerBodyOnly
    dw ShiftPlayerL1
    dw ShiftPlayerL2
    dw ShiftPlayerL3
    dw ShiftPlayerHatOnly
    dw ShiftPlayerR3
    dw ShiftPlayerR2
    dw ShiftPlayerR1


; shift_rows_left nb_rows, shift_amount
; Requirements:
; - Carry clear
; - hl set to dest
; - de set to src
shift_rows_left: MACRO
    ; Reset the two shift buffers
    ld bc, 0
    ; Also assume carry is clear
STORAGE_PTR = hPlayerShiftBytes
SHIFTED_BITS = 0
MAIN_REG_IS_C = 0

    REPT \1 - 1 ; Last iteration will be a bit special
        ld a, [de]
        dec e ; dec de
        REPT \2
            rla ; Shift row byte left
            IF MAIN_REG_IS_C == 0
                rl b
            ELSE
                rl c
            ENDC
SHIFTED_BITS = SHIFTED_BITS + 1 ; Count one shifted bit
            IF SHIFTED_BITS == 8 ; If the reg was just filled up, switch to the other one
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
            ENDC
        ENDR
        ld [hld], a ; Store shifted row byte

        IF SHIFTED_BITS >= 8
            ; One of the regs is full, flush it
            IF MAIN_REG_IS_C == 1 ; Careful, we need to flush the non-main reg!
                ld a, b
            ELSE
                ld a, c
            ENDC
            ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
SHIFTED_BITS = SHIFTED_BITS - 8
        ENDC
    ENDR

    ; Perform last iteration, which won't be followed-up, so a couple things are different
    ld a, [de]
    REPT \2
        rla
        IF MAIN_REG_IS_C == 0
            rl b
        ELSE
            rl c
        ENDC
SHIFTED_BITS = SHIFTED_BITS + 1
        IF SHIFTED_BITS == 8
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
        ENDC
    ENDR
    ld [hld], a

    IF SHIFTED_BITS >= 8
        IF MAIN_REG_IS_C == 1
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
SHIFTED_BITS = SHIFTED_BITS - 8
    ENDC
    IF SHIFTED_BITS != 0
        ; Flush main reg as well if it's non-empty
        IF MAIN_REG_IS_C == 0
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [STORAGE_PTR], a
    ENDC
ENDM

; shift_rows_right nb_rows, shift_amount
; Requirements:
; - Carry clear
; - hl set to dest
; - de set to src
shift_rows_right: MACRO
    ; Reset the two shift buffers
    ld bc, 0
    ; Also assume carry is clear
STORAGE_PTR = hPlayerShiftBytes
SHIFTED_BITS = 0
MAIN_REG_IS_C = 0

    REPT \1 - 1 ; Last iteration will be a bit special
        ld a, [de]
        inc e ; inc de
        REPT \2
            rra ; Shift row byte right
            IF MAIN_REG_IS_C == 0
                rr b
            ELSE
                rr c
            ENDC
SHIFTED_BITS = SHIFTED_BITS + 1 ; Count one shifted bit
            IF SHIFTED_BITS == 8 ; If the reg was just filled up, switch to the other one
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
            ENDC
        ENDR
        ld [hli], a ; Store shifted row byte

        IF SHIFTED_BITS >= 8
            ; One of the regs is full, flush it
            IF MAIN_REG_IS_C == 1 ; Careful, we need to flush the non-main reg!
                ld a, b
            ELSE
                ld a, c
            ENDC
            ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
SHIFTED_BITS = SHIFTED_BITS - 8
        ENDC
    ENDR

    ; Perform last iteration, which won't be followed-up, so a couple things are different
    ld a, [de]
    REPT \2
        rra
        IF MAIN_REG_IS_C == 0
            rr b
        ELSE
            rr c
        ENDC
SHIFTED_BITS = SHIFTED_BITS + 1
        IF SHIFTED_BITS == 8
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
        ENDC
    ENDR
    ld [hli], a

    IF SHIFTED_BITS >= 8
        IF MAIN_REG_IS_C == 1
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
SHIFTED_BITS = SHIFTED_BITS - 8
    ENDC
    IF SHIFTED_BITS != 0
        ; Flush main reg as well if it's non-empty
        IF MAIN_REG_IS_C == 0
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [STORAGE_PTR], a
    ENDC
ENDM

; rotate_rows_left nb_rows, shift_amount
rotate_rows_left: MACRO
READ_PTR = hPlayerShiftBytes
STORAGE_PTR = hPlayerShiftBytes
MAIN_REG_IS_C = 0
FRESH_BITS = 8
MUST_FLUSH_REG = 0
    ldh a, [READ_PTR]
READ_PTR = READ_PTR + 1
    rla ; Pre-shift one of the bits, reason below
    ld b, a

    ; Basically, we want a 16-bit rotate
    ; However, using `rl`, we can only have a 17-bit rotate easily
    ; The solution is to shift one bit early (see above)
    ; This causes a garbage bit to be shifted in the register, but it'll be shifted back into carry after 8 rotates, so that's fine

    REPT \1 - 1
        ld a, [de]
        dec e ; dec de
        REPT \2
            ; We will always have a shifted bit in carry here
            rla
            IF MAIN_REG_IS_C == 0
                rl b
            ELSE
                rl c
            ENDC
FRESH_BITS = FRESH_BITS - 1
            IF FRESH_BITS == 8
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
MUST_FLUSH_REG = 1
            ENDC
        ENDR
        ld [hld], a

        IF MUST_FLUSH_REG == 1
MUST_FLUSH_REG = 0
            IF MAIN_REG_IS_C == 1
                ld a, b
            ELSE
                ld a, c
            ENDC
            ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
        ENDC

        ; If we aren't going to have enough bits to fulfill the next iteration, get some more
        IF FRESH_BITS < \2
            ldh a, [READ_PTR]
            rla
READ_PTR = READ_PTR + 1
            IF MAIN_REG_IS_C == 1
                ld b, a
            ELSE
                ld c, a
            ENDC
FRESH_BITS = FRESH_BITS + 8
        ENDC
    ENDR

    ld a, [de]
    REPT \2
        ; We will always have a shifted bit in carry here
        rla
        IF MAIN_REG_IS_C == 0
            rl b
        ELSE
            rl c
        ENDC
FRESH_BITS = FRESH_BITS - 1
        IF FRESH_BITS == 8
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
MUST_FLUSH_REG = 1
        ENDC
    ENDR
    ld [hld], a

    IF MUST_FLUSH_REG == 1
MUST_FLUSH_REG = 0
        IF MAIN_REG_IS_C == 1
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
    ENDC

    ; There has to be bits in the current main register, here's why:
    ; The only way the current main register has no bits in it is if they were all in the other register and it just got flushed
    ; This is impossible, because bits are not reloaded if there are enough to complete the following iteration - and 0 bits left *is* enough.
    IF MAIN_REG_IS_C == 0
        ld a, b
    ELSE
        ld a, c
    ENDC
    ldh [STORAGE_PTR], a
ENDM

; rotate_rows_right nb_rows, shift_amount
rotate_rows_right: MACRO
READ_PTR = hPlayerShiftBytes
STORAGE_PTR = hPlayerShiftBytes
MAIN_REG_IS_C = 0
FRESH_BITS = 8
MUST_FLUSH_REG = 0
    ldh a, [READ_PTR]
READ_PTR = READ_PTR + 1
    rra ; Pre-shift one of the bits, reason below
    ld b, a

    ; Basically, we want a 16-bit rotate
    ; However, using `rr`, we can only have a 17-bit rotate easily
    ; The solution is to shift one bit early (see above)
    ; This causes a garbage bit to be shifted in the register, but it'll be shifted back into carry after 8 rotates, so that's fine

    REPT \1 - 1
        ld a, [de]
        inc e ; inc de
        REPT \2
            ; We will always have a shifted bit in carry here
            rra
            IF MAIN_REG_IS_C == 0
                rr b
            ELSE
                rr c
            ENDC
FRESH_BITS = FRESH_BITS - 1
            IF FRESH_BITS == 8
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
MUST_FLUSH_REG = 1
            ENDC
        ENDR
        ld [hli], a

        IF MUST_FLUSH_REG == 1
MUST_FLUSH_REG = 0
            IF MAIN_REG_IS_C == 1
                ld a, b
            ELSE
                ld a, c
            ENDC
            ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
        ENDC

        ; If we aren't going to have enough bits to fulfill the next iteration, get some more
        IF FRESH_BITS < \2
            ldh a, [READ_PTR]
            rra
READ_PTR = READ_PTR + 1
            IF MAIN_REG_IS_C == 1
                ld b, a
            ELSE
                ld c, a
            ENDC
FRESH_BITS = FRESH_BITS + 8
        ENDC
    ENDR

    ld a, [de]
    REPT \2
        ; We will always have a shifted bit in carry here
        rra
        IF MAIN_REG_IS_C == 0
            rr b
        ELSE
            rr c
        ENDC
FRESH_BITS = FRESH_BITS - 1
        IF FRESH_BITS == 8
MAIN_REG_IS_C = MAIN_REG_IS_C ^ 1
MUST_FLUSH_REG = 1
        ENDC
    ENDR
    ld [hli], a

    IF MUST_FLUSH_REG == 1
MUST_FLUSH_REG = 0
        IF MAIN_REG_IS_C == 1
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [STORAGE_PTR], a
STORAGE_PTR = STORAGE_PTR + 1
    ENDC

    ; There has to be bits in the current main register, here's why:
    ; The only way the current main register has no bits in it is if they were all in the other register and it just got flushed
    ; This is impossible, because bits are not reloaded if there are enough to complete the following iteration - and 0 bits left *is* enough.
    IF MAIN_REG_IS_C == 0
        ld a, b
    ELSE
        ld a, c
    ENDC
    ldh [STORAGE_PTR], a
ENDM




    ; Two of these cases are extra special, so they don't follow the pattern defined above
ShiftPlayerBodyOnly:
    ld hl, wPlayerShiftedTiles + 16 * 6 + 12 * 4 - 1
    ld de, wPlayerTiles + $9F
BYTE_NUM = 0
REPT 16 * 2 / 2
    ld a, [de]
    dec e ; dec de
    ld b, a
    swap a
    and $F0
    ld [hld], a
    ld a, [de]
    dec e ; dec de
    swap a
    ld c, a
    and $F0
    ld [hld], a
    ld a, c
    xor b
    and $0F
    xor b
    ldh [hPlayerShiftBytes + BYTE_NUM], a
BYTE_NUM = BYTE_NUM + 1
ENDR
BYTE_NUM = 0
REPT 16 * 2 / 2
    ldh a, [hPlayerShiftBytes + BYTE_NUM]
    ld b, a
    ld a, [de]
    dec e ; dec de
    ld c, a
    xor b
    and $0F
    xor b
    swap a
    ld [hld], a
    ld a, c
    xor b
    and $F0
    xor b
    ld b, a
    ld a, [de]
    dec e ; dec de
    swap a
    ld c, a
    xor b
    and $F0
    xor b
    ld [hld], a
    ld a, c
    xor b
    and $0F
    xor b
    ldh [hPlayerShiftBytes + BYTE_NUM], a
BYTE_NUM = BYTE_NUM + 1
ENDR
BUF_NUM = $7F
REPT 3
BUF_NUM = BUF_NUM + (-$20)
    ld e, BUF_NUM
REPT 6 * 2
    ld a, [de]
    dec e ; dec de
    ld [hld], a
ENDR
ENDR
BYTE_NUM = 0
REPT 16 * 2 / 2
    ldh a, [hPlayerShiftBytes + BYTE_NUM]
    ld b, a
    and $0F
    ld [hld], a
    ld a, b
    swap a
    and $0F
    ld [hld], a
BYTE_NUM = BYTE_NUM + 1
ENDR

    ld hl, wShadowOAM + $19
    ld a, [hl]
    add a, 4
    ld [hld], a
    ld b, [hl]
    ld l, $15
    sub 8
    ld [hl], a
    ld l, $05
    sub 8
    ld [hld], a
    ld [hl], b
    jp CopyShiftedTiles


ShiftPlayerHatOnly:
    ld hl, wPlayerShiftedTiles + 16 * 6 + 12 * 4 - 1
    ld de, wPlayerTiles + $9F
REPT 16 * 4
    ld a, [de]
    dec e ; dec de
    ld [hld], a
ENDR
BYTE_NUM = 0
REPT 6
    ld a, [de]
    dec e ; dec de
    ld b, a
    swap a
    and $F0
    ld [hld], a
    ld a, [de]
    dec e ; dec de
    swap a
    ld c, a
    and $F0
    ld [hld], a
    ld a, c
    xor b
    and $0F
    xor b
    ldh [hPlayerShiftBytes + BYTE_NUM], a
BYTE_NUM = BYTE_NUM + 1
ENDR
BUF_LOW = $5F
REPT 2
BUF_LOW = BUF_LOW + (-$20)
    ld e, BUF_LOW
BYTE_NUM = 0
REPT 6
    ldh a, [hPlayerShiftBytes + BYTE_NUM]
    ld b, a
    ld a, [de]
    dec e ; dec de
    ld c, a
    xor b
    and $0F
    xor b
    swap a
    ld [hld], a
    ld a, c
    xor b
    and $F0
    xor b
    ld b, a
    ld a, [de]
    dec e ; dec de
    swap a
    ld c, a
    xor b
    and $F0
    xor b
    ld [hld], a
    ld a, c
    xor b
    and $0F
    xor b
    ldh [hPlayerShiftBytes + BYTE_NUM], a
BYTE_NUM = BYTE_NUM + 1
ENDR
ENDR
; We can skip the two player shift tiles entirely, because they won't be shown on-screen
    ld hl, wPlayerShiftedTiles + 6 * 2 - 1
BYTE_NUM = 0
REPT 6
    ldh a, [hPlayerShiftBytes + BYTE_NUM]
    ld b, a
    and $0F
    ld [hld], a
    ld a, b
    swap a
    and $0F
    ld [hld], a
BYTE_NUM = BYTE_NUM + 1
ENDR

    ld hl, wShadowOAM + $11
    ld a, [hl]
    add a, 4
    ld [hld], a
    ld b, [hl]
    ld l, $0D
    sub 8
    ld [hl], a
    ld l, $09
    sub 8
    ld [hl], a
    ld l, $01
    sub 8
    ld [hld], a
    ld [hl], b
    jp CopyShiftedTiles

ShiftPlayerL1:
ShiftPlayerL2:
ShiftPlayerL3:
ShiftPlayerR3:
ShiftPlayerR2:
    jp OverworldLoop

ShiftPlayerR1: ; Shift hat right once, shift body left thrice
    ; Plan: shift body left, write body overflow tiles, shift hat right, write hat overflow tiles
    jp OverworldLoop ; TODO:

    ; Fall through


CopyShiftedTiles:
    ; Copy the player's base attr (such as palette) to the extension sprites
    ld a, [wPlayer_BaseAttr]
    ld [wShadowOAM + 3], a
    ld [wShadowOAM + 7], a
    ld a, 1
    ld [wPlayerTilesShifted], a
    jp OverworldLoop

PURGE BUF_LOW
PURGE BYTE_NUM


SECTION "CopyShiftedPlayerTiles", ROMX ; This function is huge, and therefore we'll be avoiding putting it in ROM0

CopyShiftedPlayerTiles:
    ; Copying this using the fast copy mechanism is not gonna fit into VBlank: we need dedicated code
    ; Yes, we're using popslide. Yes, this means interrupts can corrupt the data being read. But here's why it's not a problem:
    ; We're reading the data via `pop`s. This means the data being corrupted is data we've already read.
    ; This data is also always re-generated before being written, so that's fine as well
    ; Finally, a 16-byte don't-care buffer is present before the position SP is initially set to, which leaves plenty of room for pushing
    ; One full interrupt handler would be 5 pushes (4 regs + 1 ret addr), so that leaves 3 more "internal pushes".
    ; Further, any more pushes would go into the player tiles, which means they'll be visible (and potentially debuggable), but not crashing.
    ld [wSPBuffer], sp
    ld sp, wPlayerShiftedTiles
    ld hl, vPlayerTiles + $14
REPT 44 / 4
    pop de
    pop bc
    wait_vram
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, b
    ld [hli], a
ENDR
    ld l, $54
REPT 12 / 4
    pop de
    pop bc
    wait_vram
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, b
    ld [hli], a
ENDR
    ld l, $74
REPT 12 / 4
    pop de
    pop bc
    wait_vram
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, b
    ld [hli], a
ENDR
    ld l, $94
REPT 76 / 4
    pop de
    pop bc
    wait_vram
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, b
    ld [hli], a
ENDR
    ld sp, wSPBuffer
    pop hl
    ld sp, hl
    ret
