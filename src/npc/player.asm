
; !!! WARNING !!! Please read the following if you're going to modify this file

; The player's draw structs have a twist to them
; Since the player's got so many animation frames, its tiles are loaded as needed (instead of loading them all at once)
; So, an extra pointer to them is placed near the animation frame's data
; This is especially necessary since the player's tiles are first copied to WRAM, as part of the overlap fix mechanism

; Another thing: the player's graphics are modified if they overlap with a NPC
; Please be sure that you don't deviate from the current sprite arrangement (3 hat sprites, 2 body sprites)
; To put it differently, consider the position of the sprites relative to eachother, as well as their tile IDs, is hardcoded
; The attributes aren't - the code considers the player's facing direction

SECTION "Player data", ROMX

PlayerDrawPtrs::
    dw PlayerDownStandingDraw
    dw PlayerUpStandingDraw
    dw PlayerLeftStandingDraw
    dw PlayerRightStandingDraw
    dw PlayerDownWalkingDraw
    dw PlayerUpWalkingDraw
    dw PlayerLeftWalkingDraw
    dw PlayerRightWalkingDraw


PlayerDownStandingDraw:
    db $FF
    db $FF
    dw PlayerDownStandingFrame

    dw PlayerDownStandingTiles
PlayerDownStandingFrame:
    db 5
    db -28, -12, 0, 0
    db -28, -4, 2, 0
    db -28, 4, 4, 0
    db -12, -8, 6, 0
    db -12, 0, 8, 0


PlayerUpStandingDraw:
    db $FF
    db $FF
    dw PlayerUpStandingFrame

    dw PlayerUpStandingTiles
PlayerUpStandingFrame:
    db 5
    db -28, -12, 0, 0
    db -28, -4, 2, 0
    db -28, 4, 4, 0
    db -12, -8, 6, 0
    db -12, 0, 8, 0


PlayerLeftStandingDraw:
    db $FF ; Length of animation
    db $FF ; Number of frames in this frame
    dw .frame0

    dw PlayerSideStandingTiles
.frame0
    db 5 ; Number of OAM entries
    db -28, -12, 4, OAMF_XFLIP
    db -28, -4, 2, OAMF_XFLIP
    db -28, 4, 0, OAMF_XFLIP
    db -12, -8, 8, OAMF_XFLIP
    db -12, 0, 6, OAMF_XFLIP


PlayerRightStandingDraw:
    db $FF
    db $FF
    dw .frame0

    dw PlayerSideStandingTiles
.frame0
    db 5
    db -28, -12, 0, 0
    db -28, -4, 2, 0
    db -28, 4, 4, 0
    db -12, -8, 6, 0
    db -12, 0, 8, 0


PlayerDownWalkingDraw:
    db $40
    db $10
    dw PlayerDownStandingFrame
    db $10
    dw .frame0
    db $10
    dw PlayerDownStandingFrame
    db $10
    dw .frame1

    dw PlayerDownWalkingTiles
.frame0
    db 5
    db -27, -12, 0, 0
    db -27, -4, 2, 0
    db -27, 4, 4, 0
    db -11, -8, 6, 0
    db -11, 0, 8, 0

    dw PlayerDownWalkingTiles
.frame1
    db 5
    db -27, -13, 4, OAMF_XFLIP
    db -27, -5, 2, OAMF_XFLIP
    db -27, 3, 0, OAMF_XFLIP
    db -11, -9, 8, OAMF_XFLIP
    db -11, -1, 6, OAMF_XFLIP


PlayerUpWalkingDraw:
    db $40
    db $10
    dw PlayerUpStandingFrame
    db $10
    dw .frame0
    db $10
    dw PlayerUpStandingFrame
    db $10
    dw .frame1

    dw PlayerUpWalkingTiles
.frame0
    db 5
    db -27, -12, 0, 0
    db -27, -4, 2, 0
    db -27, 4, 4, 0
    db -11, -8, 6, 0
    db -11, 0, 8, 0

    dw PlayerUpWalkingTiles
.frame1
    db 5
    db -27, -13, 4, OAMF_XFLIP
    db -27, -5, 2, OAMF_XFLIP
    db -27, 3, 0, OAMF_XFLIP
    db -11, -9, 8, OAMF_XFLIP
    db -11, -1, 6, OAMF_XFLIP


PlayerLeftWalkingDraw:
    db $40
    db $10
    dw .frame0
    db $10
    dw .frame1
    db $10
    dw .frame0
    db $10
    dw .frame2

    dw PlayerSideWalkingTiles0
.frame0
    db 5 ; Number of OAM entries
    db -28, -12, 4, OAMF_XFLIP
    db -28, -4, 2, OAMF_XFLIP
    db -28, 4, 0, OAMF_XFLIP
    db -12, -8, 8, OAMF_XFLIP
    db -12, 0, 6, OAMF_XFLIP

    dw PlayerSideWalkingTiles1
.frame1
    db 5 ; Number of OAM entries
    db -27, -12, 4, OAMF_XFLIP
    db -27, -4, 2, OAMF_XFLIP
    db -27, 4, 0, OAMF_XFLIP
    db -11, -8, 8, OAMF_XFLIP
    db -11, 0, 6, OAMF_XFLIP

    dw PlayerSideWalkingTiles2
.frame2
    db 5 ; Number of OAM entries
    db -27, -12, 4, OAMF_XFLIP
    db -27, -4, 2, OAMF_XFLIP
    db -27, 4, 0, OAMF_XFLIP
    db -11, -8, 8, OAMF_XFLIP
    db -11, 0, 6, OAMF_XFLIP


PlayerRightWalkingDraw:
    db $40
    db $10
    dw .frame0
    db $10
    dw .frame1
    db $10
    dw .frame0
    db $10
    dw .frame2

    dw PlayerSideWalkingTiles0
.frame0
    db 5
    db -28, -12, 0, 0
    db -28, -4, 2, 0
    db -28, 4, 4, 0
    db -12, -8, 6, 0
    db -12, 0, 8, 0

    dw PlayerSideWalkingTiles1
.frame1
    db 5
    db -27, -12, 0, 0
    db -27, -4, 2, 0
    db -27, 4, 4, 0
    db -11, -8, 6, 0
    db -11, 0, 8, 0

    dw PlayerSideWalkingTiles2
.frame2
    db 5
    db -27, -12, 0, 0
    db -27, -4, 2, 0
    db -27, 4, 4, 0
    db -11, -8, 6, 0
    db -11, 0, 8, 0


SECTION "Player tiles", ROMX

; Load some player gfx
; @param de A pointer to the gfx to be loaded (will be loaded from BANK("Player tiles"))
; @return hl hFastCopyNbReq
; @return a New value of hFastCopyLowByte
LoadPlayerGfx::
    ; Copy the data from `de` to the WRAM player tile buffer
    ld a, BANK("Player tiles")
    rst bankswitch
    ld hl, wPlayerTiles+16
    ld c, 16
    rst memcpy_small
    ld l, LOW(wPlayerTiles+48)
    ld c, 16
    rst memcpy_small
    ld l, LOW(wPlayerTiles+80)
    ld c, 16
    rst memcpy_small
    ld l, LOW(wPlayerTiles+96)
    ld c, 16 * 4
    rst memcpy_small
LoadCurrentPlayerGfx::
    ; Check if the player gfx copy is already pending
    ld a, [wPlayerFastCopyACK]
    and a
    ret z
    ; If not, reset the ACK flag,
    xor a
    ld [wPlayerFastCopyACK], a
    ; ...And craft the copy request
    ld h, HIGH(wFastCopyQueue)
    ldh a, [hFastCopyLowByte]
    ld l, a
    ld [wPlayerReqPtrLow], a
    ; a can be anything, since we're not copying from ROMX... (even oob numbers are fine)
    ld [hli], a
    xor a ; ld a, LOW(wPlayerTiles)
    ld [hli], a
    ld a, HIGH(wPlayerTiles)
    ld [hli], a
    ld a, LOW(vPlayerTiles + 16 * 4)
    ld [hli], a
    ld a, HIGH(vPlayerTiles + 16 * 4)
    ld [hli], a
    ld a, LOW(wPlayerFastCopyACK)
    ld [hli], a
    ld a, $93
    ld [hli], a
    ld a, NB_PLAYER_TILES
    ld [hli], a
    ld a, l
    ld hl, hFastCopyNbReq
    inc [hl]
    and $7F
    ldh [hFastCopyLowByte], a
    ret


PlayerDownStandingTiles:
INCBIN "res/npc/player/front_back/down_standing.chr"
PlayerUpStandingTiles:
INCBIN "res/npc/player/front_back/up_standing.chr"
PlayerSideStandingTiles:
INCBIN "res/npc/player/side/standing.chr"


PlayerDownWalkingTiles:
INCBIN "res/npc/player/front_back/down_walking.chr"
PlayerUpWalkingTiles:
INCBIN "res/npc/player/front_back/up_walking.chr"
PlayerSideWalkingTiles0:
INCBIN "res/npc/player/side/walking0.chr"
PlayerSideWalkingTiles1:
INCBIN "res/npc/player/side/walking1.chr"
PlayerSideWalkingTiles2:
INCBIN "res/npc/player/side/walking2.chr"
