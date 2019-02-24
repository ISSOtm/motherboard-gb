
; The entirety of this file can be summed up as follows:
;   HERE BE DRAGONS.
; If you, poor soul, must debug or change something in this file, know that I am extremely sorry.
; May K&R have mercy on your soul.

SECTION "Player overlap functions", ROMX,ALIGN[4]

PlayerOverlapFuncs::
    dw ShiftPlayerBodyOnly
    dw ShiftPlayerL1
    dw ShiftPlayerL2
    dw ShiftPlayerL3
    dw ShiftPlayerHatOnly
    dw ShiftPlayerR3
    dw ShiftPlayerR2
    dw ShiftPlayerR1


; shift_bit rotate_operation
shift_bit: macro
    \1a ; Shift out bit
    IF USING_C
        \1 c
    ELSE
        \1 b
    ENDC
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + 1
    IF SHIFTED_BIT_COUNT == 8
USING_C = 1 - USING_C
    ENDC
endm
store_shifted_bits: MACRO
    IF SHIFTED_BIT_COUNT >= 8
        IF USING_C
            ld a, b
        ELSE
            ld a, c
        ENDC
        ldh [hPlayerShiftBytes + BYTE_NUM], a
BYTE_NUM = BYTE_NUM + 1
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + (-8)
MUST_RELOAD_REG = 1
    ENDC
ENDM

; rotate_bit rotate_operation
rotate_bit: macro
    IF USING_C
        \1 c
    ELSE
        \1 b
    ENDC
    \1a ; Shift out bit
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + 1
    IF SHIFTED_BIT_COUNT == 8
        IF USING_C
            \1 c
        ELSE
            \1 b
        ENDC
USING_C = 1 - USING_C
    ENDC
endm
get_rotation_bits: macro
    IF MUST_RELOAD_REG
        ldh a, [hPlayerShiftBytes + BYTE_NUM + 1]
        IF USING_C
            ld b, a
        ELSE
            ld c, a
        ENDC
MUST_RELOAD_REG = 0
    ENDC
ENDM


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


ShiftPlayerR1: ; Left-shift the body once, right-shift the hat thrice
    ld hl, wPlayerShiftedTiles + 16 * 6 + 12 * 4 - 1
    ld de, wPlayerTiles + $9F

; Shift left player body tiles
USING_C = 0
SHIFTED_BIT_COUNT = 0
BYTE_NUM = 0
MUST_RELOAD_REG = 0
    ; Carry is clear from `add a, a` of jump table code that brought us here
    ld bc, 0
REPT 16 * 2
    IF MUST_RELOAD_REG == 1
        IF USING_C
            ld b, 0
        ELSE
            ld c, 0
        ENDC
MUST_RELOAD_REG = 0
    ENDC
    ld a, [de]
    dec e ; dec de
    REPT 3
        shift_bit rl
    ENDR
    ld [hld], a
    store_shifted_bits
ENDR
; If anything is remaining, force storing it
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC

; Shift right player body tiles
USING_C = 1
SHIFTED_BIT_COUNT = 0
BYTE_NUM = -1
MUST_RELOAD_REG = 1
    get_rotation_bits ; Load b as well, since we're expecting to always have at least 8 bits of data ready
USING_C = 0
MUST_RELOAD_REG = 1
BYTE_NUM = 0
REPT 16 * 2
    get_rotation_bits
    ld a, [de]
    dec e ; dec de
    REPT 3
        rotate_bit rl
    ENDR
    ld [hld], a
    store_shifted_bits
ENDR
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC
LAST_BYTE_NUM = BYTE_NUM

; Shift left player hat tiles
USING_C = 0
SHIFTED_BIT_COUNT = 0
MUST_RELOAD_REG = 0
    ld hl, wPlayerShiftedTiles + 2 * 16 + 12
    ld e, LOW(wPlayerTiles + 16 * 1 + 16 - 12)
    xor a
    ; Carry is clear
    ld b, a ; ld bc, 0
    ld c, a
REPT 6 * 2
    IF MUST_RELOAD_REG == 1
        IF USING_C
            ld b, 0
        ELSE
            ld c, 0
        ENDC
MUST_RELOAD_REG = 0
    ENDC
    ld a, [de]
    inc e ; inc de
    shift_bit rr
    ld [hli], a
    store_shifted_bits
ENDR
; If anything is remaining, force storing it
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC

; Shift middle and right player hat tiles
NB_TILES = 3
REPT 2
    ld e, LOW(wPlayerTiles + NB_TILES * 16 + 16 - 12)
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM]
    rra
    ld b, a
    ld a, [de]
    inc e ; inc de
    rra
    ld [hli], a
REPT 7
    ld a, [de]
    inc e ; inc de
    rr b
    rra
    ld [hli], a
ENDR
    ld a, b
    rra
    ldh [hPlayerShiftBytes+LAST_BYTE_NUM], a
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM+1]
    swap a ; Only 4 bytes have been shifted, so to shift them out in the correct order, shift them by 4 more
    rra
    ld b, a
    ld a, [de]
    inc e ; inc de
    rra
    ld [hli], a
REPT 3
    ld a, [de]
    inc e ; inc de
    rr b
    rra
    ld [hli], a
ENDR
    ld a, b
    rra
    ldh [hPlayerShiftBytes+LAST_BYTE_NUM+1], a
NB_TILES = NB_TILES + 2
ENDR

; Write "leftovers" tiles
    ld hl, wPlayerShiftedTiles
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM+1]
    swap a ; Only 4 bytes have been shifted, so to shift the bits out in the correct order, shift them by 4 more
    ld b, a
REPT 4
    xor a
    rl b
    rra
    ld [hli], a
ENDR
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM]
    ld b, a
REPT 8
    xor a
    rl b
    rra
    ld [hli], a
ENDR

USING_C = 1
SHIFTED_BIT_COUNT = 0
BYTE_NUM = LAST_BYTE_NUM + (-2)
MUST_RELOAD_REG = 1
    get_rotation_bits ; Load b as well, since we're expecting to always have at least 8 bits of data ready
USING_C = 0
MUST_RELOAD_REG = 1
BYTE_NUM = LAST_BYTE_NUM + (-3)
REPT 16 * 2
    get_rotation_bits
    xor a
    REPT 3
        IF USING_C
            rr c
        ELSE
            rr b
        ENDC
        rra ; Shift out bit
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + 1
        IF SHIFTED_BIT_COUNT == 8
            IF USING_C
                rr c
            ELSE
                rr b
            ENDC
USING_C = 1 - USING_C
        ENDC
    ENDR
    rra
    swap a
    ld [hli], a
    IF SHIFTED_BIT_COUNT >= 8
BYTE_NUM = BYTE_NUM + (-1)
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + (-8)
MUST_RELOAD_REG = 1
    ENDC
ENDR

    ld hl, wShadowOAM + $19
    ld a, [hl]
    add a, 3
    ld [hld], a
    ld b, [hl]
    ld l, $15
    sub 8
    ld [hl], a
    ld l, $05
    sub 8
    ld [hld], a
    ld [hl], b
    ld l, $11
    ld a, [hl]
    dec a
    ld [hld], a
    ld b, [hl]
    ld l, $0D
    sub 8
    ld [hl], a
    ld l, $09
    sub 8
    ld [hl], a
    ld l, 1
    add a, 3 * 8
    ld [hld], a
    ld [hl], b
    jp CopyShiftedTiles


ShiftPlayerR2: ; TODO:
    jp OverworldLoop


ShiftPlayerR3: ; TODO:
    jp OverworldLoop


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


ShiftPlayerL3: ; Left-shift the hat thrice, right-shift the body once
    ld hl, wPlayerShiftedTiles + 16 * 2 + 12 * 4
    ld de, wPlayerTiles + $60

; Shift left player body tiles
USING_C = 0
SHIFTED_BIT_COUNT = 0
BYTE_NUM = 0
MUST_RELOAD_REG = 0
    xor a
    ; Carry is clear
    ld b, a
    ld c, a
REPT 16 * 2
    IF MUST_RELOAD_REG == 1
        IF USING_C
            ld b, 0
        ELSE
            ld c, 0
        ENDC
MUST_RELOAD_REG = 0
    ENDC
    ld a, [de]
    inc e ; inc de
    shift_bit rr
    ld [hli], a
    store_shifted_bits
ENDR
; If anything is remaining, force storing it
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC

; Shift right player body tiles
USING_C = 1
SHIFTED_BIT_COUNT = 0
BYTE_NUM = -1
MUST_RELOAD_REG = 1
    get_rotation_bits ; Load b as well, since we're expecting to always have at least 8 bits of data ready
USING_C = 0
MUST_RELOAD_REG = 1
BYTE_NUM = 0
REPT 16 * 2
    get_rotation_bits
    ld a, [de]
    inc e ; inc de
    rotate_bit rr
    ld [hli], a
    store_shifted_bits
ENDR
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC
LAST_BYTE_NUM = BYTE_NUM

; Shift right player hat tiles
USING_C = 0
SHIFTED_BIT_COUNT = 0
MUST_RELOAD_REG = 0
    ld hl, wPlayerShiftedTiles + 2 * 16 + 4 * 12 - 1
    ld e, LOW(wPlayerTiles + 6 * 16 - 1)
    ; Carry is clear
    ld bc, 0
REPT 6 * 2
    IF MUST_RELOAD_REG == 1
        IF USING_C
            ld b, 0
        ELSE
            ld c, 0
        ENDC
MUST_RELOAD_REG = 0
    ENDC
    ld a, [de]
    dec e ; dec de
    REPT 3
        shift_bit rl
    ENDR
    ld [hld], a
    store_shifted_bits
ENDR
; If anything is remaining, force storing it
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC

; Shift middle and left player hat tiles
NB_TILES = 4
REPT 2
    ld e, LOW(wPlayerTiles + NB_TILES * 16 - 1)
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM]
    rla
    ld b, a
    ld a, [de]
    dec e ; dec de
    rla
    ld [hld], a
REPT 7
    ld a, [de]
    dec e ; dec de
    rl b
    rla
    ld [hld], a
ENDR
    ld a, b
    rla
    ldh [hPlayerShiftBytes+LAST_BYTE_NUM], a
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM+1]
    swap a ; Only 4 bytes have been shifted, so to shift them out in the correct order, shift them by 4 more
    rla
    ld b, a
    ld a, [de]
    dec e ; dec de
    rla
    ld [hld], a
REPT 3
    ld a, [de]
    dec e ; dec de
    rl b
    rla
    ld [hld], a
ENDR
    ld a, b
    rla
    ldh [hPlayerShiftBytes+LAST_BYTE_NUM+1], a
NB_TILES = NB_TILES + (-2)
ENDR

; Write "leftovers" tiles
    ld hl, wPlayerShiftedTiles
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM]
    ld b, a
REPT 8
    xor a
    rl b
    rla
    ld [hli], a
ENDR
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM+1]
    ld b, a
REPT 4
    ld a, [de]
    dec e ; dec de
    rl b
    rla
    ld [hli], a
ENDR

USING_C = 1
SHIFTED_BIT_COUNT = 0
BYTE_NUM = -1
MUST_RELOAD_REG = 1
    get_rotation_bits ; Load b as well, since we're expecting to always have at least 8 bits of data ready
USING_C = 0
MUST_RELOAD_REG = 1
BYTE_NUM = 0
REPT 16 * 2
    get_rotation_bits
    xor a
    REPT 3
        rotate_bit rr
    ENDR
    ld [hli], a
    IF SHIFTED_BIT_COUNT >= 8
BYTE_NUM = BYTE_NUM + 1
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + (-8)
MUST_RELOAD_REG = 1
    ENDC
ENDR

    ld hl, wShadowOAM + $19
    ld a, [hl]
    dec a
    ld [hld], a
    ld b, [hl]
    ld l, $15
    sub 8
    ld [hl], a
    ld l, $05
    add a, 2 * 8
    ld [hld], a
    ld [hl], b
    ld l, $11
    ld a, [hl]
    add a, 3
    ld [hld], a
    ld b, [hl]
    ld l, $0D
    sub 8
    ld [hl], a
    ld l, $09
    sub 8
    ld [hl], a
    ld l, 1
    sub 8
    ld [hld], a
    ld [hl], b
    jp CopyShiftedTiles


ShiftPlayerL2: ; TODO:
    jp OverworldLoop


ShiftPlayerL1: ; Left-shift the hat once, right-shift the body thrice
    ld hl, wPlayerShiftedTiles + 16 * 2 + 12 * 4
    ld de, wPlayerTiles + $60

; Shift left player body tiles
USING_C = 0
SHIFTED_BIT_COUNT = 0
BYTE_NUM = 0
MUST_RELOAD_REG = 0
    xor a
    ; Carry is clear
    ld b, a
    ld c, a
REPT 16 * 2
    IF MUST_RELOAD_REG == 1
        IF USING_C
            ld b, 0
        ELSE
            ld c, 0
        ENDC
MUST_RELOAD_REG = 0
    ENDC
    ld a, [de]
    inc e ; inc de
    REPT 3
        shift_bit rr
    ENDR
    ld [hli], a
    store_shifted_bits
ENDR
; If anything is remaining, force storing it
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC

; Shift right player body tiles
USING_C = 1
SHIFTED_BIT_COUNT = 0
BYTE_NUM = -1
MUST_RELOAD_REG = 1
    get_rotation_bits ; Load b as well, since we're expecting to always have at least 8 bits of data ready
USING_C = 0
MUST_RELOAD_REG = 1
BYTE_NUM = 0
REPT 16 * 2
    get_rotation_bits
    ld a, [de]
    inc e ; inc de
    REPT 3
        rotate_bit rr
    ENDR
    ld [hli], a
    store_shifted_bits
ENDR
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC
LAST_BYTE_NUM = BYTE_NUM

; Shift right player hat tiles
USING_C = 0
SHIFTED_BIT_COUNT = 0
MUST_RELOAD_REG = 0
    ld hl, wPlayerShiftedTiles + 2 * 16 + 4 * 12 - 1
    ld e, LOW(wPlayerTiles + 6 * 16 - 1)
    ; Carry is clear
    ld bc, 0
REPT 6 * 2
    IF MUST_RELOAD_REG == 1
        IF USING_C
            ld b, 0
        ELSE
            ld c, 0
        ENDC
MUST_RELOAD_REG = 0
    ENDC
    ld a, [de]
    dec e ; dec de
    shift_bit rl
    ld [hld], a
    store_shifted_bits
ENDR
; If anything is remaining, force storing it
IF SHIFTED_BIT_COUNT != 0
SHIFTED_BIT_COUNT = 8
USING_C = 1 - USING_C
    store_shifted_bits
ENDC

; Shift middle and left player hat tiles
NB_TILES = 4
REPT 2
    ld e, LOW(wPlayerTiles + NB_TILES * 16 - 1)
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM]
    rla
    ld b, a
    ld a, [de]
    dec e ; dec de
    rla
    ld [hld], a
REPT 7
    ld a, [de]
    dec e ; dec de
    rl b
    rla
    ld [hld], a
ENDR
    ld a, b
    rla
    ldh [hPlayerShiftBytes+LAST_BYTE_NUM], a
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM+1]
    swap a ; Only 4 bytes have been shifted, so to shift them out in the correct order, shift them by 4 more
    rla
    ld b, a
    ld a, [de]
    dec e ; dec de
    rla
    ld [hld], a
REPT 3
    ld a, [de]
    dec e ; dec de
    rl b
    rla
    ld [hld], a
ENDR
    ld a, b
    rla
    ldh [hPlayerShiftBytes+LAST_BYTE_NUM+1], a
NB_TILES = NB_TILES + (-2)
ENDR

; Write "leftovers" tiles
    ld hl, wPlayerShiftedTiles
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM]
    ld b, a
REPT 8
    xor a
    rl b
    rla
    ld [hli], a
ENDR
    ldh a, [hPlayerShiftBytes+LAST_BYTE_NUM+1]
    ld b, a
REPT 4
    ld a, [de]
    dec e ; dec de
    rl b
    rla
    ld [hli], a
ENDR

USING_C = 1
SHIFTED_BIT_COUNT = 0
BYTE_NUM = -1
MUST_RELOAD_REG = 1
    get_rotation_bits ; Load b as well, since we're expecting to always have at least 8 bits of data ready
USING_C = 0
MUST_RELOAD_REG = 1
BYTE_NUM = 0
REPT 16 * 2
    get_rotation_bits
    xor a
    REPT 3
        rotate_bit rr
    ENDR
    ld [hli], a
    IF SHIFTED_BIT_COUNT >= 8
BYTE_NUM = BYTE_NUM + 1
SHIFTED_BIT_COUNT = SHIFTED_BIT_COUNT + (-8)
MUST_RELOAD_REG = 1
    ENDC
ENDR

    ld hl, wShadowOAM + $19
    ld a, [hl]
    sub 3
    ld [hld], a
    ld b, [hl]
    ld l, $15
    sub 8
    ld [hl], a
    ld l, $05
    add a, 2 * 8
    ld [hld], a
    ld [hl], b
    ld l, $11
    ld a, [hl]
    inc a
    ld [hld], a
    ld b, [hl]
    ld l, $0D
    sub 8
    ld [hl], a
    ld l, $09
    sub 8
    ld [hl], a
    ld l, 1
    sub 8
    ld [hld], a
    ld [hl], b

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
