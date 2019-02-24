
SECTION "Player gfx loader", ROM0

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

