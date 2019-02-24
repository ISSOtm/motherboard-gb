
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
    dw PlayerLeftStandingDraw
    dw PlayerLeftWalkingDraw
    dw PlayerRightStandingDraw
    dw PlayerRightWalkingDraw

PlayerLeftStandingDraw:
    db $10 ; Length of animation
    db $10 ; Number of frames in this frame
    dw .frame0

    dw PlayerSideStandingTiles
.frame0
    db 5 ; Number of OAM entries

    db -29
    db -12
    db 4
    db OAMF_XFLIP

    db -29
    db -4
    db 2
    db OAMF_XFLIP

    db -29
    db 4
    db 0
    db OAMF_XFLIP

    db -13
    db -8
    db 8
    db OAMF_XFLIP

    db -13
    db 0
    db 6
    db OAMF_XFLIP

PlayerLeftWalkingDraw:
    db
    db
    dw

PlayerRightStandingDraw:
    db $10
    db $10
    dw .frame0

    dw PlayerSideStandingTiles
.frame0
    db 5

    db -29
    db -12
    db 0
    db 0

    db -29
    db -4
    db 2
    db 0

    db -29
    db 4
    db 4
    db 0

    db -13
    db -8
    db 6
    db 0

    db -13
    db 0
    db 8
    db 0

PlayerRightWalkingDraw:
    db 
    db 
    dw  


SECTION "Player tiles", ROMX

PlayerSideStandingTiles:
INCBIN "res/npc/player/side/standing.chr"
