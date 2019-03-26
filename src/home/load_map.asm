
SECTION "Map loader", ROM0

LoadMap:
    ;;; Load data from map header into RAM.

    ld a, BANK(MapHeaders)
    rst bankswitch
    ; Get pointer to map header
    ld a, [wTargetMap]
    ld l, a
    add a, a
    add a, l
    add a, LOW(MapHeaders)
    ld l, a
    adc a, HIGH(MapHeaders)
    sub l
    ld h, a
    ld a, [hli]
    ld e, [hl]
    inc hl
    ld d, [hl]
    rst bankswitch

    ld a, [de]
    inc de
    ld [wFadePalettes], a
    ld hl, 4 + 4 * 2 + 1
    ldh a, [hIsSGB]
    and a
    jr z, .skipSGBStuff
    ld a, [de]
    inc de
    ld [wFadePalettes], a
    ld a, [de]
    inc de
    ld [wFadePalettes+1], a
    ld a, [de]
    inc de
    ld [wFadePalettes+2], a
    ld a, [de]
    inc de
    ldh [hTextboxBGP], a
    ; Compute PAL_SET packet
    ld hl, wSGBPacket
    ld a, PAL_SET << 3 | 1 ; Packet header
    ld [hli], a
    ld c, 4 * 2 + 1 ; 4 palette IDs + 1 ATF number
    rst memcpy_small
    ; ATF number currently in `a`
    and $3F
    ld [wCurMapATFNum], a
    ; Send computed packet
    ld hl, wSGBPacket
    push de
    call SendPacketNoDelay
    ; Make the palettes reference all zeros to ensure the same color (#0) is shown
    ; This will be made consistent once fading in starts, since wFadePalettes has been modified accordingly
    xor a
    ldh [rBGP], a
    ldh [hBGP], a
    ldh [rOBP0], a
    ldh [hOBP0], a
    ldh [rOBP1], a
    ldh [hOBP1], a
    pop hl ; Restore pointer to map data
    db $3E ; ld a, imm8
.skipSGBStuff
    add hl, de

    ; Write size and (default) cam locks
    ld de, wMapHeight
    ld a, [hli] ; Height
    ld [de], a
    sub 1
    ld [wBottomCamLock], a
    inc de
    ld a, [hli]
    ld [de], a
    sbc 0
    ld [wBottomCamLock+1], a
    jr nz, .bottomLockOk
    ld a, [wBottomCamLock]
    cp SCRN_Y
    jr nc, .bottomLockOk
    ld a, SCRN_Y
    ld [wBottomCamLock], a
.bottomLockOk
    inc de
    ld a, [hli] ; Width
    ld [de], a
    sub 1
    ld [wRightCamLock], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    sbc 0
    ld [wRightCamLock+1], a
    jr nz, .rightLockOk
    ld a, [wRightCamLock]
    cp SCRN_X
    jr nc, .rightLockOk
    ld a, SCRN_X
    ld [wRightCamLock], a
.rightLockOk
    ld de, wLeftCamLock
    xor a
    ld [de], a
    inc de
    ld [de], a
    ld de, wTopCamLock
    xor a
    ld [de], a
    inc de
    ld [de], a

    ; Read map script ptr
    ld a, [hli]
    ld [wMapScriptPtr], a
    ld a, [hli]
    ld [wMapScriptPtr+1], a
    ld a, [hli]
    ld [wMapScriptPtr+2], a

    ; Load NPC data
    ld de, wNPC1
    ld a, [hli] ; Read number of NPCs
    and a
    jr z, .noNPCs
    ldh [hLoadingRemainingNPCs], a
    ldh [hLoadingNPCCount], a
    ld bc, wFastCopyQueue
    xor a ; ld a, LOW(wFastCopyQueue)
    ; Forcefully set the low pointer of the copy request to remove the need for wrapping
    ; Normally unsafe, but we should be safe to take liberties here
    ldh [hFastCopyCurLowByte], a
    ld a, LOW(vNPCTiles / 16)
    ldh [hLoadingNPCBaseTileID], a
.loadNPC
    xor a
    ld [de], a ; Y subpixel
    inc e ; inc de
    ; Y pos
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    xor a
    ld [de], a ; X subpixel
    inc e ; inc de
    ; X pos
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    xor a
    ld [de], a ; Display type
    inc e ; inc de
    ld [de], a ; Display counter
    inc e ; inc de
    ; Base tile
    ldh a, [hLoadingNPCBaseTileID]
    ld [de], a
    inc e ; inc de
    ; Base attr
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ; Display struct
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    xor a
    ld [de], a ; Status
    inc e ; inc de
    ; Processing ptr
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ; Write request to load the NPC's tiles
    ld a, [hli] ; Bank
    ld [bc], a
    inc c ; inc bc
    ld a, [hli] ; Src
    ld [bc], a
    inc c ; inc bc
    ld a, [hli]
    ld [bc], a
    inc c ; inc bc
    ; We need to free some regs, luckily we can push de to get two
    push de
    ldh a, [hLoadingNPCBaseTileID]
    ld e, a
    swap a
    ld d, a
    ; Dest
    and $F0
    ld [bc], a
    inc c ; inc bc
    ld a, d
    and $0F
    or $80
    ld [bc], a
    inc c ; inc bc
    ld a, LOW(wDummyFastCopyACK) ; ACK ptr low
    ld [bc], a
    inc c ; inc bc
    ld a, $99 ; FIXME:
    ld [bc], a
    inc c ; inc bc
    ld a, [hli] ; Len
    ld [bc], a
    inc c ; inc bc
    add a, e ; Add to current tile count
    ldh [hLoadingNPCBaseTileID], a
    pop de
    ldh a, [hLoadingRemainingNPCs]
    dec a
    ldh [hLoadingRemainingNPCs], a
    jr nz, .loadNPC
    ldh a, [hLoadingNPCCount]
    ldh [hFastCopyNbReq], a
    ld a, c
    ldh [hFastCopyLowByte], a
.noNPCs
    ; Clear data for remaining NPCs
    ld a, e
    cp LOW(wNPCArrayEnd)
    jr z, .allNPCsUsed
.clearUnusedNPCs
    ld a, $80
    inc e ; inc de
IF DEF(PedanticMemInit)
    ld [de], a
ENDC
    inc e ; inc de
    ld [de], a
    inc e ; inc de
    inc e ; inc de
IF DEF(PedanticMemInit)
    ld [de], a
ENDC
    inc e ; inc de
    ld [de], a
    ld a, e
    add a, sizeof_NPC - (NPC_XPos + 1)
    ld e, a
    cp LOW(wNPCArrayEnd)
    jr c, .clearUnusedNPCs
.allNPCsUsed



    ; Load triggers
    ld de, wTriggerPool
    ld a, [hli] ; Number of triggers
    add a, a
    add a, a
    add a, a
    jr z, .noTriggers
    ld c, a
.copyTriggerData
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    dec c
    jr nz, .copyTriggerData
    ld b, e
    ld a, [hli] ; Number of arg bytes
    ld c, a
    ld de, wTriggerArgPool
.copyTriggerArgs
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    dec c
    jr nz, .copyTriggerArgs
    inc d
    ld e, b
    ld a, e
    and a
    jr z, .dontClearTriggers
.clearTriggers
    xor a
.noTriggers ; Optimization: a is already 0 when we arrive here
    ld [de], a
    ld a, e
    add a, sizeof_Trigger
    ld e, a
    jr nz, .clearTriggers
.dontClearTriggers


    ld a, [wTargetWarp]
    ld c, a
    inc a
    ld a, [hli]
    jr z, .noWarp ; If target warp is $FF, it means "skip all warp data"
    push hl
    swap c ; Warp data is 16 bytes long ; FIXME: assumes at most 16 warp-tos per map
    add a, c
    ld h, [hl]
    ld l, a
    jr nc, .noCarry
    inc h
.noCarry
    ; Copy target player position
    ld de, wPlayer_YSubPos
    xor a
    ld [de], a ; Zero subpixels for consistency
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    xor a
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    ; TODO: Decide how to set the camera
    ld a, [hli]
    ; Finally, run custom processor to maybe alter state in a custom way
    ld a, [hli]
    ld h, [hl]
    ld l, a
    rst call_hl
    pop hl
.noWarp
    inc hl


    ; Make sure camera is within bounds
    ; No vertical camera locking in side-scroller maps
    ld a, [hli]
    ld [wScrollingType], a
    cp SCROLLING_HORIZ
    jr z, .noVertCamLock
    ld a, [wCameraYPos]
    add a, 16
    ld c, a
    ld a, [wCameraYPos+1]
    adc a, 0
    ld b, a
    and $C0
    jr nz, .lockTop ; Assume all sufficiently negative numbers are to be locked
    ld a, [wTopCamLock+1]
    cp b
    jr c, .tryBottomLock ; If lock < camera, no locking
    jr nz, .lockTop ; If lock > camera, guaranteed lock
    ld a, [wTopCamLock]
    cp c
    jr c, .tryBottomLock ; If lock < camera, no locking
.lockTop
    ld a, [wTopCamLock]
    sub 16
    ld [wCameraYPos], a
    ld a, [wTopCamLock+1]
    jr .vertCamLockDone

.tryBottomLock
    ld a, SCRN_Y
    add a, c
    ld c, a
    adc a, b
    sub c
    ld b, a
    ld a, [wBottomCamLock+1]
    cp b
    jr c, .lockBottom ; If lock < camera, guaranteed locking
    jr nz, .noVertCamLock ; If lock > camera, no locking
    ld a, [wBottomCamLock]
    cp c
    jr nc, .noVertCamLock ; If lock >= camera, no locking
.lockBottom
    ld a, [wBottomCamLock]
    sub 16 + SCRN_Y
    ld [wCameraYPos], a
    ld a, [wBottomCamLock+1]
.vertCamLockDone
    sbc 0
    ld [wCameraYPos+1], a
.noVertCamLock

    ld a, [wCameraXPos]
    add a, 8
    ld c, a
    ld a, [wCameraXPos+1]
    adc a, 0
    ld b, a
    and $C0
    jr nz, .lockLeft ; Assume all sufficiently negative numbers are to be locked
    ld a, [wLeftCamLock+1]
    cp b
    jr c, .tryRightLock ; If lock < camera, no locking
    jr nz, .lockLeft ; If lock > camera, guaranteed lock
    ld a, [wLeftCamLock]
    cp c
    jr c, .tryRightLock ; If lock < camera, no locking
.lockLeft
    ld a, [wLeftCamLock]
    sub 8
    ld [wCameraXPos], a
    ld a, [wLeftCamLock+1]
    jr .horizCamLockDone

.tryRightLock
    ld a, SCRN_X
    add a, c
    ld c, a
    adc a, b
    sub c
    ld b, a
    ld a, [wRightCamLock+1]
    cp b
    jr c, .lockRight ; If lock < camera, guaranteed locking
    jr nz, .noHorizLock ; If lock > camera, no locking
    ld a, [wRightCamLock]
    cp c
    jr nc, .noHorizLock ; If lock >= camera, no locking
.lockRight
    ld a, [wRightCamLock]
    sub 8 + SCRN_X
    ld [wCameraXPos], a
    ld a, [wRightCamLock+1]
.horizCamLockDone
    sbc 0
    ld [wCameraXPos+1], a
.noHorizLock


    ; Load map data
    ldh a, [hCurROMBank]
    push af
    ld de, wParallaxLayers + 2
    ld a, [wScrollingType]
    and 3
    ld [wScrollingType], a
    jp z, .scrolling4Way
    ; Horizontal scrolling (side-scroller)
    ld a, [hli] ; Initial vertical scroll position
    ld [wCameraYPos], a
    inc de
    ; Sign extend this
    add a, a
    sbc a, a
    ld [wCameraYPos+1], a
    ; Read parallax layer data
    ld de, wNbParallaxLayers
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld b, a
.writeParallaxLayer
    ld a, [hli] ; Ratio
    ld [de], a
    inc e ; inc de
    inc e ; inc de ; Horiz pos
    inc e ; inc de ; (2 bytes)
    ld a, [hli] ; Height
    ld [de], a
    inc e ; inc de
    ld a, [hli] ; Tile block ptr bank
    ld [de], a
    inc e ; inc de
    ld a, [hli] ; Tile block ptr low
    ld [de], a
    inc e ; inc de
    ld a, [hli] ; Tile block ptr high
    ld [de], a
    inc e ; inc de
    inc e ; inc de ; Skip padding
    dec b
    jr nz, .writeParallaxLayer
    push hl


    ; Now, draw initial rows
    rst wait_vblank
    xor a
    ldh [rLCDC], a
    ld a, [wCameraXPos]
    rrca
    rrca
    rrca
    inc a ; add a, 8 >> 3
    and $F8 >> 3
    ldh [hRedrawTilemapAddr], a
    ld a, HIGH(_SCRN0)
    ldh [hRedrawTilemapAddr+1], a
    ld de, wNbParallaxLayers
    ld a, [de]
    inc e ; inc de
.drawParallaxLayer
    ldh [hRedrawLayerCount], a
    ld a, [de] ; Scroll ratio
    inc e ; inc de
    ld c, a
    inc e ; inc de ; Skip scroll
    inc e ; inc de ; (2 bytes)
    ld a, [de] ; Height (in tiles)
    inc e ; inc de
    ld b, a
    ld a, [de] ; Data bank
    inc e ; inc de
    rst bankswitch ; OK because reading from RAM
    ld a, [de] ; Data ptr
    inc e ; inc de
    ld l, a
    ld a, [de]
    inc e ; inc de
    ld h, a
    push de
    inc c ; Increase for following loop, and detect static layers
    jr z, .staticLayer
    ; Get camera X pos to shift it
    inc c ; Do three left shifts to divide by 8, minus one to multiply by 2
    ld a, [wCameraXPos+1]
    ld d, a
    ld a, [wCameraXPos]
.shiftScroll
    srl d
    rra
    dec c
    jr nz, .shiftScroll
.gotScroll
    ; Get pointer to row
    and $FE
    rr d ; Get bit 0 of d in carry (must be done before second `inc a`)
    inc a ; Compensate for camera being 8 pixels behind; `inc a` required to preserve carry
    inc a ; If there's an overflow it's here
    jr nz, .noCameraOverflow
    ccf
.noCameraOverflow
    ld d, 0 ; Delet all other bits of d
    rl d ; Retrieve bit 0
    add a, l
    ld l, a
    ld a, d
    add a, h
    ld h, a
    ; Now draw as many rows as needed, making sure to also load their tiles
    ld a, SCRN_X_B + 1
.redrawColumn
    ldh [hRedrawRowCount], a
    ld a, [hli]
    push hl
    ld h, [hl]
    ld l, a
    ldh a, [hRedrawTilemapAddr]
    ld e, a
    inc a
    xor e
    and SCRN_VX_B - 1
    xor e
    ldh [hRedrawTilemapAddr], a
    ldh a, [hRedrawTilemapAddr+1]
    ld d, a
    ld c, b ; Height stayed in b the whole time!!1
.drawColumn
    ld a, [hli]
    ld [de], a
    ld a, e
    add a, SCRN_VX_B
    ld e, a
    adc a, d
    sub e
    ld d, a
    dec c
    jr nz, .drawColumn
    ; hl now points at how many tiles need to be transferred
    ld a, [hli]
    and a
    jr z, .tilelessColumn
    push bc ; Save height
    ld c, a
    ld a, [hli] ; Which tile ID does this start at? (Note: bit 7 flipped for ease of calculations)
    ; Calc corresponding dest ptr
    swap a
    ld e, a
    and $0F
    add a, HIGH(vMapTiles)
    ld d, a
    ld a, e
    and $F0
    ; add a, LOW(vMapTiles)
    ld e, a
    call Tilecpy
    pop bc ; Retrieve height
.tilelessColumn
    pop hl
    inc hl
    ldh a, [hRedrawRowCount]
    dec a
    jr nz, .redrawColumn
    jr .drewLayer
.staticLayer
    ; For static layers, there's just a tilemap, nothing fancy at all
    ldh a, [hRedrawTilemapAddr]
    and -SCRN_VX_B ; Static layers are always redrawn at column 0, though
    ld e, a
    ldh a, [hRedrawTilemapAddr+1]
    ld d, a
    ; Although the regs are inverted.
.copyStaticLayer
    ld c, SCRN_X_B
.copyStaticLayerRow
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    dec c
    jr nz, .copyStaticLayerRow
    ld a, e
    add a, SCRN_VX_B - SCRN_X_B
    ld e, a
    adc a, d
    sub e
    ld d, a
    dec b
    jr nz, .copyStaticLayer
    ldh [hRedrawTilemapAddr+1], a
    ; We need to put back the lower bits
    ldh a, [hRedrawTilemapAddr]
    and SCRN_VX_B - 1
    or e ; This is guaranteed to have the lower bits reset anyways
    ldh [hRedrawTilemapAddr], a
.drewLayer
    pop de
    inc e ; inc de ; Point to next layer
    ldh a, [hRedrawLayerCount]
    dec a
    jp nz, .drawParallaxLayer

    ; Turn screen back on to allow music to play at least once
    ldh a, [hLCDC]
    ldh [rLCDC], a

    ; Write initial scrolling amounts
    call GetFreeScanlineBuf
    ld hl, wParallaxLayers
    ld a, [wNbParallaxLayers]
    ld b, a
.writeLayerScroll
    ld a, [wCameraXPos]
    add a, 8
    ld e, a
    ld a, [wCameraXPos+1]
    adc a, 0
    ld d, a
    ld a, [hli] ; Get scroll ratio
    ld c, a
    and a
    ld a, e
    jr z, .gotLayerScroll
.shiftLayerScroll
    srl d
    rra
    dec c
    jr nz, .shiftLayerScroll
.gotLayerScroll
    ld [hli], a
    ld [hl], d
    ld a, l
    add a, 8 - 2
    ld l, a
    dec b
    jr nz, .writeLayerScroll

    ; Copy layer scrolling amounts to second buffer
    ld de, wParallaxLayers + 1
    ld hl, wParallaxLayersScroll
    ld a, [wNbParallaxLayers]
    ld b, a
.copyLayersScroll
    ld a, [de]
    ld [hli], a
    ld a, e
    add a, 8
    ld e, a
    dec b
    jr nz, .copyLayersScroll
    pop hl
    ; Shut screen down for tile copy
    rst wait_vblank
    xor a
    ldh [rLCDC], a
    jp .scrollTypeDone

.scrolling4Way
    ; We'll also need to redraw the tilemap
    ; We need the Y position (in tiles) to compute the vertical offset
    ; And the base pointer for obvious reasons
    ; FIXME: code is only equipped for maps as large as 256 tiles x 256 tiles
    ; If increasing this size, modify the code below appropriately (Mult8x16, etc.)
    ld bc, wYScroll
    ld a, [wCameraYPos]
    ld [bc], a
    and $F8
    add a, $10 ; Offset to get BG position
    ld e, a
    inc bc
    ld a, [wCameraYPos+1]
    ld [bc], a
    adc a, 0
    and $07
    or e
    rrca
    rrca
    rrca
    ld e, a ; Y position divided by 8 (size of a tile)
    inc bc
    ld a, [wCameraXPos]
    ld [bc], a
    and $F8
    add a, 8 ; Offset to get BG position
    ld d, a
    inc bc
    ld a, [wCameraXPos+1]
    ld [bc], a
    adc a, 0
    and $07
    or d
    rrca
    rrca
    rrca
    ld d, a ; X position divided by 8 (size of a tile)
    ; Copy tilemap ptr
    inc bc
    ld a, [hli]
    ld [bc], a
    inc bc
    ld a, [hli]
    ld [bc], a
    inc bc
    ld a, [hli]
    ld [bc], a
    ld a, [wTilemapBank]
    rst bankswitch ; Switch to tilemap's ROM bank
    push hl
    ld c, d ; Transfer X position to a reg preserved by the mult routine
    ld a, [wMapWidth]
    and $F8
    ld h, a
    ld a, [wMapWidth+1]
    and $07
    or h
    rrca
    rrca
    rrca
    ld h, a ; Map width divided by 8 (tile size)
    ldh [hRedrawTileWidth], a
    call Mult8x8 ; Get vertical offset in tilemap
    ld d, c ; Save X position for below
    ld a, [wTilemapPtr]
    add a, c ; Add horizontal offset to base ptr directly
    ld c, a ; Since it's going through `a` anyways, that's good
    ld a, [wTilemapPtr+1]
    adc a, b ; adc a, 0
    ld b, a
    add hl, bc ; Add vertical offset to get src ptr
    ; Now calc dest ptr
    ld a, e ; Y pos
    swap a
    rlca
    ld b, a
    xor d ; Add X pos for low byte
    and $E0
    xor d
    ld e, a
    ldh [hRedrawRowStart], a
    ld a, b
    and $1F
    add a, HIGH(_SCRN0)
    ld d, a ; Dest ptr
    ; Shut screen down
    rst wait_vblank
    xor a
    ldh [rLCDC], a
    ; Now, perform retrace
    ld b, SCRN_Y_B + 1
.nextRow
    ld c, SCRN_X_B + 1
    push hl
.nextTile
    ld a, [hli]
    ld [de], a
    inc e
    ld a, e
    and SCRN_VX_B - 1
    jr nz, .noWrap
    ld a, e
    sub SCRN_VX_B
    ld e, a
.noWrap
    dec c
    jr nz, .nextTile
    ; Compute where in the next line we should land
    ldh a, [hRedrawRowStart]
    add a, SCRN_VX_B
    ldh [hRedrawRowStart], a
    ld e, a
    adc a, d
    sub e
    and $9B ; Wrap around
    ld d, a
    pop hl
    ldh a, [hRedrawTileWidth]
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a
    dec b
    jr nz, .nextRow
    pop hl

.scrollTypeDone
    pop af
    rst bankswitch
    ; Just after the map header lie the "common tiles"
    ld a, [hli]
    ld b, a
    ld d, h ; The decompressor uses de as its source, not hl.
    ld e, l
    ld hl, vMapTiles
    call pb16_unpack_block


    ;;; Done applying map loading.


    ldh a, [hLCDC]
    ldh [rLCDC], a

    ld a, [wTargetMap]
    ld [wLoadedMap], a
    ld a, 1
    ld [wDoOverworldUpdates], a

    ld a, OVERWORLD_FADE_IN
    ld [wNextState], a
    ld a, OVERWORLD_NORMAL
    ld [wFollowingState], a
    ret
