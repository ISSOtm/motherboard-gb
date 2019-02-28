
SECTION "Overworld engine ROM0", ROM0

BeginOverworld::
    ; Do minimal init here, rest is done by "BEGIN" state
    ld a, OVERWORLD_BEGIN
    ld [wFollowingState], a
    ld a, OVERWORLD_FADE_OUT
    ld [wNextState], a

    xor a
    ld [wPlayerInputsMask], a ; Consider no player input until init has been performed
    ; xor a
    ld [wDoOverworldUpdates], a ; Don't update the overworld until the map is loaded
    ; xor a
    ld [wCutsceneBank], a ; Don't process cutscenes that don't exist, either
    ; xor a
    ld [wPlayerTilesShifted], a
    ; xor a
IF DEF(PedanticMemInit)
    ld [wMapScriptPtr], a
ENDC
    ld [wMapScriptPtr+1], a
    ld [wMapScriptPtr+2], a
    inc a ; ld a, 1 ; Fade to black
    ld [wFadeType], a
    ld a, 10 frames
    ld [wFadeDelay], a

OverworldLoop:
    rst wait_vblank

    ; Do this now instead of later, because the player sprite may glitch out the later we do this
    ld a, BANK(CopyShiftedPlayerTiles)
    rst bankswitch
    ld a, [wPlayerTilesShifted]
    and a
    call nz, CopyShiftedPlayerTiles

    ; Reset "single-frame" vars
    xor a
    ld [wCurStateFirstFrame], a
    ld [wPlayerStateChange], a

    ; Change state if needed
    ld a, [wNextState]
    and a
    jr z, .keepCurrentState
    ld a, [wOverworldState]
    ld [wPreviousState], a
    ld a, [wNextState]
    ld [wOverworldState], a
    xor a
    ld [wNextState], a
    inc a ; ld a, 1
    ld [wCurStateFirstFrame], a
.keepCurrentState

    ld hl, wMapScriptPtr
    ld a, [hli]
    rst bankswitch
    ld a, [hli]
    ld h, [hl]
    ld l, a
    or h
    jr z, .noMapScript
    rst call_hl
.noMapScript

    ; Begin by retrieving info from the current state
    ld a, BANK(OverworldStatePtrs)
    rst bankswitch
    ld a, [wOverworldState]
    add a, a
    add a, LOW(OverworldStatePtrs)
    ld l, a
    adc a, HIGH(OverworldStatePtrs)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ; hl points to current state struct

    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    or e
    jr z, .noFunction
    push hl
    call CallDE
    pop hl
.noFunction

    ld a, [wCutsceneBank]
    and a
    call nz, ProcessCutscene

    ; BUTTON PROCESSING

    ld a, [wNextState]
    and a
    jr nz, .skipButtons ; Skip any button operations if we need to change states
    ld a, [hli] ; Get button mask
    ld c, a
    ldh a, [hHeldButtons]
    and c
    ld c, a
    ldh a, [hPressedButtons]
    or c
    ld c, a
    ld a, [wPlayerInputsMask]
    and c
    ld c, a
    ld b, 8
.checkButton
    rl c
    ld a, [hli]
    ld e, a
    ld a, [hli]
    jr nc, .skipButton ; Skip button if not selected
    ld d, a
    or e
    jr z, .skipButton
    push hl
    push bc
    call CallDE
    pop bc
    pop hl
.skipButton
    dec b
    jr nz, .checkButton
.skipButtons


    ; Processing is done, now to render it


OverworldUpdate:
    ; Updating might not be a good idea, for example if the overworld hasn't been loaded yet
    ld a, [wDoOverworldUpdates]
    and a
    jp z, OverworldLoop

    
    ; Perform text updates here
    ; They can actually be considered updates, since they're async
    ld a, [wTextSrcPtr+1]
    inc a
    call nz, ProcessText


    ; Calculate camera movement vector
    xor a
    ldh [hCameraRelativePosition], a
    ldh [hCameraRelativePosition+2], a
    ld a, [wCameramanID]
    cp NB_NPCS + 1 ; Plus player!
    jr nc, .fixedCamera
    ld a, [wScrollingType]
    add a, a
    add a, LOW(CameraDeltaFuncs)
    ld l, a
    adc a, HIGH(CameraDeltaFuncs)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    rst call_hl

    ; Apply lerping, and calculate the direction the camera moved in
    ; Using a fixed division of 16
    ; This causes the camera to not move if the target is less than 16 pixels away, which is intended as well.
    ld hl, hCameraRelativePosition + 3
    ; Only process low bytes, since the camera shouldn't move by more than 8 pixels in a frame
    ld a, [hl]
    add a, a ; Perform sign extension
    sbc a, a
    ldh [hCameraXMovementDirection], a
    ld [hld], a
    and $0F
    ld c, a
    ld a, [hl]
    and $F0
    or c
    swap a
    ld [hld], a
    ld a, [hl]
    add a, a ; Perform sign extension
    sbc a, a
    ldh [hCameraYMovementDirection], a
    ld [hld], a
    and $0F
    ld c, a
    ld a, [hl]
    and $F0
    or c
    swap a
    ld [hl], a
.fixedCamera

    ; Update camera position, also applying camera locking
    ldh a, [hCameraRelativePosition]
    and a
    jr z, .camMovedVert ; Skip all calculations if the camera isn't supposed to move
    ldh a, [hCameraYMovementDirection]
    and a
    jr z, .camMovedDown
    ; Get top cam lock pos, in screen coords
    ld hl, wTopCamLock
    ld a, [hli]
    sub a, 16
    ld e, a
    sbc [hl]
    sub e
    ld d, a
    ; Move camera (by subtracting to get proper carry below)
    ld hl, wCameraYPos
    ldh a, [hCameraRelativePosition]
    cpl
    inc a
    ld c, a
    ld a, [hli]
    sub a, c
    ld c, a
    ld a, [hl]
    sbc a, 0
    ld b, a
    ; Check if higher than top boundary
    ; Must perform a signed comparison, since the dest position may overflow
    ; Comparison done by calculating the diff then checking sign (negative means to the top = lock must be applied)
    ld a, c
    sub e
    ld a, b
    sbc d
    add a, a ; Shift sign into carry...
    jr nc, .noVertLock
    ld a, d
    ld [hld], a
    ld [hl], e
    jr .camMovedVert

.camMovedDown
    ld hl, wCameraYPos
    ld a, [hli]
    ld c, a
    ; Calc dest camera pos
    ldh a, [hCameraRelativePosition]
    add a, c
    ld c, a
    ld a, [hl]
    adc a, 0
    ld b, a
    ; Add offset to get position of bottom screen edge
    ld a, SCRN_Y - 1 + 16
    add a, c
    ld e, a
    adc a, b
    sub e
    ld d, a
    ; Check if camera up
    ld a, [wBottomCamLock+1]
    cp d
    jr c, .downLock
    jr nz, .noVertLock
    ld a, [wBottomCamLock]
    ld d, a
    ld a, e
    cp d
    jr c, .noVertLock
.downLock
    ; Force camera at screen lock position
    ld a, [wBottomCamLock]
    sub SCRN_Y + 16
    ld c, a
    ld a, [wBottomCamLock+1]
    sbc a, 0
    db $06 ; ld b, imm8
.noVertLock
    ld a, b
.camLockedVert
    ld [hld], a
    ld [hl], c
.camMovedVert

    ldh a, [hCameraRelativePosition+2]
    and a
    jr z, .camMovedHoriz ; Skip all calculations if the camera isn't supposed to move
    ldh a, [hCameraXMovementDirection]
    and a
    jr z, .camMovedRight
    ; Get left cam lock pos, in screen coords
    ld hl, wLeftCamLock
    ld a, [hli]
    sub a, 8
    ld e, a
    sbc [hl]
    sub e
    ld d, a
    ; Move camera (by subtracting to get proper carry below)
    ld hl, wCameraXPos
    ldh a, [hCameraRelativePosition+2]
    cpl
    inc a
    ld c, a
    ld a, [hli]
    sub a, c
    ld c, a
    ld a, [hl]
    sbc a, 0
    ld b, a
    ; Check if higher than left boundary
    ; Must perform a signed comparison, since the dest position may overflow
    ; Comparison done by calculating the diff then checking sign (negative means to the left = lock must be applied)
    ld a, c
    sub e
    ld a, b
    sbc d
    add a, a ; Shift sign into carry...
    jr nc, .noHorizLock
    ld a, d
    ld [hld], a
    ld [hl], e
    jr .camMovedHoriz

.camMovedRight
    ld hl, wCameraXPos
    ld a, [hli]
    ld c, a
    ; Calc dest camera pos
    ldh a, [hCameraRelativePosition+2]
    add a, c
    ld c, a
    ld a, [hl]
    adc a, 0
    ld b, a
    ; Add offset to get position of right screen edge
    ld a, SCRN_X - 1 + 8
    add a, c
    ld e, a
    adc a, b
    sub e
    ld d, a
    ; Check if camera to the left
    ld a, [wRightCamLock+1]
    cp d
    jr c, .rightLock
    jr nz, .noHorizLock
    ld a, [wRightCamLock]
    ld d, a
    ld a, e
    cp d
    jr c, .noHorizLock
.rightLock
    ; Force camera at screen lock position
    ld a, [wRightCamLock]
    sub SCRN_X + 8
    ld c, a
    ld a, [wRightCamLock+1]
    sbc a, 0
    db $06 ; ld b, imm8
.noHorizLock
    ld a, b
.camLockedHoriz
    ld [hld], a
    ld [hl], c
.camMovedHoriz

    ; Update BG position(s) based on updated camera position
    ld a, [wScrollingType]
    add a, a
    add a, LOW(.scrollingFuncs)
    ld l, a
    adc a, HIGH(.scrollingFuncs)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    rst call_hl


    ; Perform textbox ops, if there's a need to
    ld a, [wTextboxScanline]
    and a
    jr z, .noTextbox
    ld b, a
    ; Add textbox raster FX to the list
    call GetFreeScanlineBuf
    ; Scan free scanline buf to find first effect past target scanline
    ; Always succeeds since terminator is $FF
.seekTextboxRaster
    ld a, [$FF00+c]
    cp b
    jr nc, .foundTextboxSlot
    inc c
    inc c
    inc c
    jr .seekTextboxRaster

.foundTextboxSlot
    ; Write scanline
    ld a, b
    ld [$FF00+c], a
    inc c
    ; Write FX (textbox is hardcoded to 0)
    xor a
    ld [$FF00+c], a
    inc c
    ; Write value (SCY value)
    xor a
    sub b
    ld [$FF00+c], a
    inc c
    ; Write terminator, since textbox overwrites all other FX
    ld a, $FF
    ld [$FF00+c], a
.noTextbox


    ; All raster FX operations are done, so, switch FX buffers
    call SwitchScanlineBuf


    ; Perform textbox SGB packet operations
    ld hl, wPalettePacketAction
    ld a, [hli]
    and a
    jr z, .noPalPacketAction
    dec a
    jr z, .restoreSGBLayout ; PAL_PACK_ACTION_RESTORE
    ld a, BANK(TextboxSGBLayoutPacket)
    rst bankswitch
    ld hl, TextboxSGBLayoutPacket
.restoreSGBLayout
    call SendPacketNoDelay
    xor a ; PAL_PACK_ACTION_NONE
    ld [wPalettePacketAction], a
.noPalPacketAction


    ; Compute next player state
    ld a, BANK(PlayerStateMachineFuncs)
    rst bankswitch
    ld a, [wPlayer_DisplayType]
    add a, a
    add a, LOW(PlayerStateMachineFuncs)
    ld l, a
    adc a, HIGH(PlayerStateMachineFuncs)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    and a ; Reset carry because a lot of callees simply `ret (n)z` without changing the C flag
    rst call_hl
    jr nc, .noStateChange
    ld hl, wPlayer_DisplayCounter
    xor a
    ld [hld], a ; Reset counter
    ld [hl], e ; Change state
.noStateChange

    ; Load player tiles
    ld a, BANK(PlayerDrawPtrs)
    rst bankswitch
    ld a, [wPlayer_DisplayType]
    add a, a
    add a, LOW(PlayerDrawPtrs)
    ld l, a
    adc a, HIGH(PlayerDrawPtrs)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [wPlayer_DisplayCounter] ; We expect this to be in a valid state, which it should be
.seekFrame
    inc hl
    sub [hl]
    inc hl
    inc hl
    jr nc, .seekFrame
    ld a, [hld]
    ld l, [hl]
    ld h, a
    dec hl
    ld a, [hld]
    ld e, [hl]
    ld d, a
    ld hl, wPlayerLoadedTiles + 1
    cp [hl] ; Check if tiles are already loaded
    ld [hld], a
    ld a, e
    jr nz, .notAlreadyLoaded
    cp [hl]
    jr z, .playerTilesAlreadyLoaded
.notAlreadyLoaded
    ld [hld], a
    ld a, BANK(LoadPlayerGfx)
    rst bankswitch
    call LoadPlayerGfx
.playerTilesAlreadyLoaded


    ; Redraw NPCs
    ld hl, wPlayer
    ld de, wShadowOAM + 2 * 4 ; Reserve two objects for player shifting
.redrawNPC
    call GetCameraRelativePosition
    ldh a, [hCameraRelativePosition]
    add a, (256 - SCRN_Y) / 2
    ldh a, [hCameraRelativePosition+1]
    adc a, 0
    jr nz, .npcCulledOut
    ldh a, [hCameraRelativePosition+2]
    add a, (256 - SCRN_X) / 2
    ldh a, [hCameraRelativePosition+3]
    adc a, 0
    jr nz, .npcCulledOut
    ld a, [hli] ; Read display type
    add a, a ; Double for upcoming ptr computation
    ; (assuming that the object has no more than 128 different types)
    ld c, a
    push hl ; Save this pointer to do write-back later
    ld a, [hli] ; Read display counter
    ld b, a
    ld a, [hli]
    ldh [hNPCTileID], a
    ld a, [hli]
    ldh [hNPCAttr], a
    ld a, [hli] ; Read draw struct bank
    rst bankswitch
    ld a, [hli] ; Read draw struct ptr
    ld h, [hl]
    add a, c ; Add display type offset
    ld l, a
    adc a, h
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld c, [hl] ; Read anim length (don't inc to improve upcoming loop)
    ld a, b ; Get display counter
    inc a
    sub c
    jr nc, .wrapAnimCnt
    add a, c
.wrapAnimCnt
    ld c, a
    ; Use current value, because increment should only affect next frame
    ; Important for player tile loading to work correctly
    ld a, b
.seekAnimFrame
    inc hl ; Advance to length
    sub [hl]
    inc hl ; Skip anim counter
    inc hl ; Skip one byte of ptr (so we can still read efficiently below)
    jr nc, .seekAnimFrame
    ld a, [hld]
    ld l, [hl]
    ld h, a
    ; Now, write the OAM entries
    ld a, [hli] ; Read nb of OAM entries
.writeOAMEntry
    ldh [hNPCRemainingEntries], a
    ldh a, [hCameraRelativePosition]
    add a, [hl]
    inc hl
    dec a
    cp SCRN_Y + 16 - 1
    jr nc, .offscreen
    inc a
    ld [de], a
    inc e ; inc de
    ldh a, [hCameraRelativePosition+2]
    add a, [hl]
    inc hl
    dec a
    cp SCRN_X + 8 - 1
    jr nc, .offscreenCancel
    inc a
    ld [de], a
    inc e ; inc de
    ldh a, [hNPCTileID]
    add a, [hl]
    inc hl
    ld [de], a
    inc e ; inc de
    ldh a, [hNPCAttr]
    xor [hl]
    ld [de], a
    inc e ; inc de
    ld a, e
    cp $A0
    jr nc, .filledOAM
    ; Carry is set here
.skipOffscreen ; This gets jumped to with carry set
    inc hl ; Skip attr (this is common to all code paths)
    ldh a, [hNPCRemainingEntries]
    dec a
    jr nz, .writeOAMEntry
.filledOAM ; This gets jumped to on NC
    ; Here: NC <=> OAM is full
    pop hl
    ld [hl], c ; Write back new anim cnt
    jr nc, .OAMFull ; Prevent overflowing OAM
.npcCulledOut ; This gets jumped to on C if the NPC isn't drawn, which can't have overflowed OAM, therefore NC <=> OAM isn't full
    ; Advance to next NPC, if it exists
    ld a, l
    or sizeof_NPC - 1
    inc a
    ld l, a
    cp LOW(wNPCArrayEnd)
    jr nz, .redrawNPC

    ; If we're here, OAM can't be full!
    ; Otherwise we'd have jumped to `.OAMFull`
.clearOAM
    xor a
    ld [de], a
    ld a, e
    add a, 4
    ld e, a
    cp $A0
    jr c, .clearOAM
    jr .OAMFull ; Jump over the following bit of code


    ; Bit of code that's referenced below
.offscreen
    inc hl ; Skip X pos
    inc e ; we're already at first byte of entry
.offscreenCancel
    dec e ; dec de
    inc hl ; Skip tile ID
    ; Attr will be skipped after the jump
    scf ; Set carry to signify OAM can't be full
    jr .skipOffscreen


.OAMFull
    ld a, d ; ld a, HIGH(wShadowOAM)
    ldh [hOAMBufferHigh], a

    ; "hack" to apply priority to player obj
    ; Basically, DMG applies priority based on X position, and OAM position is used as a tie breaker
    ; When the player's sprites get overlapped, the overlap may occur in a weird way, which is what this code aims to fix
    ; For now, clear the two extra sprites
    xor a
    ld [wShadowOAM], a
    ld [wShadowOAM+4], a
    ; Get position of player's top-left sprite, and offset it
    ; This is because sprites located to the top/left of the player might be offenders
    ld a, [wShadowOAM+8]
    and a ; If player is off-screen, it ain't being overlapped
    jr z, .playerOffscreen
    sub 6
    ld b, a
    ld a, [wShadowOAM+8+1]
    sub 6
    ld c, a
    ; Iterate over OAM to perhaps find offending sprite
    ld a, BANK(PlayerOverlapFuncs)
    rst bankswitch
    ld hl, wShadowOAM+28 ; Obviously skip player's sprites
    ; FIXME: this uses hardcoded hitbox sizes, I'm sorry if you have to modify this
.checkOffenderSprite
    ld a, [hli]
    sub b
    cp 38 ; TODO: check if that's correct
    jr nc, .spriteOkay
    ld a, [hl]
    sub c
    cp 32 ; If there's overlap only with the *rightmost* sprite, then it's fine because we'll render over it
    jr c, ShiftPlayerSprites
.spriteOkay
    ld a, l
    add a, 3
    ld l, a
    cp $A0
    jr c, .checkOffenderSprite
.playerOffscreen

    ; Player sprite doesn't need to be shifted, check if they should be restored
    ld a, [wPlayerTilesShifted]
    and a
    jp z, OverworldLoop
    xor a
    ld [wPlayerTilesShifted], a
    ; Copy the original gfx back
    ld a, BANK(LoadCurrentPlayerGfx)
    rst bankswitch
    call LoadCurrentPlayerGfx
    jp OverworldLoop


.scrollingFuncs
    dw Update4WayScrolling
    dw UpdateHorizScrollLayers


ShiftPlayerSprites:
    ; Shift player gfx
    ; The problem is that the hat sprites and player sprites need to be shifted differently
    ; Luckily the difference is 4 pixels, which actually has a great perk (about the direction of the shifts)
    sub 6 ; Compensate for the subtraction that occurred above (it was a subtraction to a subtractor, therefore an addition to the final result)
    and 7
    add a, a
    ld l, a
    ld h, HIGH(PlayerOverlapFuncs)
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jp hl ; Safe because the index is controlled and the table length is known



Update4WayScrolling:
    ; Compare and redraw
    ld a, [wCameraYPos]
    and $F8
    ld l, a
    ld a, [wYScroll]
    and $F8
    cp l
    jr z, .noVertMovement
    ld a, [wCameraYPos+1]
    and $07
    or l
    rrca
    rrca
    rrca
    add a, 16 >> 3
    ld e, a ; Y pos / 8
    ld a, [hCameraYMovementDirection]
    inc a
    jr z, .movingUp
    ld a, e
    add a, SCRN_Y_B
    ld e, a
.movingUp
    ld a, [wMapWidth]
    and $F8
    ld l, a
    ld a, [wMapWidth+1]
    and $07
    or l
    rrca
    rrca
    rrca
    ld h, a
    call Mult8x8 ; FIXME: code is only equipped for $800x$800 maps
    ld a, [wXScroll]
    and $F8
    ld c, a
    ld a, [wXScroll+1]
    and $07
    or c
    rrca
    rrca
    rrca
    inc a ; add a, 8 >> 3
    ld c, a ; X pos / 8
    ld b, e ; Y pos / 8
    ld a, [wTilemapPtr]
    add a, c
    ld e, a
    ld a, [wTilemapPtr+1]
    adc a, 0
    ld d, a
    add hl, de ; Add X offset + base ptr to Y offset
    ld a, b
    swap a
    rlca
    ld b, a
    xor c
    and $E0
    xor c
    ld e, a
    ld a, b
    and $1F
    add a, HIGH(_SCRN0)
    ld d, a
    ld c, SCRN_X_B + 1
.nextTile
    wait_vram
    ld a, [hli]
    ld [de], a
    inc e
    ld a, e
    and SCRN_VX_B - 1
    jr nz, .noHorizWrap
    ld a, e
    sub SCRN_VX_B
    ld e, a
.noHorizWrap
    dec c
    jr nz, .nextTile
.noVertMovement

    ld a, [wCameraXPos]
    and $F8
    ld l, a
    ld a, [wXScroll]
    and $F8
    cp l
    jr z, .noHorizMovement
    ld a, [wCameraYPos]
    and $F8
    ld l, a
    ld a, [wCameraYPos+1]
    and $07
    or l
    rrca
    rrca
    rrca
    add a, 16 >> 3
    ld e, a ; Y pos / 8
    ld a, [wMapWidth]
    and $F8
    ld l, a
    ld a, [wMapWidth+1]
    and $07
    or l
    rrca
    rrca
    rrca
    ld h, a
    ldh [hRedrawAccumulatedHeight], a
    call Mult8x8 ; FIXME: code is only equipped for $800x$800 maps
    ld a, [wCameraXPos]
    and $F8
    ld c, a
    ld a, [wCameraXPos+1]
    and $07
    or c
    rrca
    rrca
    rrca
    inc a ; add a, 8 >> 3
    ld c, a ; X pos / 8
    ld a, [hCameraXMovementDirection]
    inc a
    jr z, .movingLeft
    ld a, c
    add a, SCRN_X_B
    ld c, a
.movingLeft
    ld b, e ; Y pos / 8
    ld a, [wTilemapPtr]
    add a, c
    ld e, a
    ld a, [wTilemapPtr+1]
    adc a, 0
    ld d, a
    add hl, de ; Add X offset + base ptr to Y offset
    ld a, b
    swap a
    rlca
    ld b, a
    xor c
    and $E0
    xor c
    ld e, a
    ld a, b
    and $1F
    add a, HIGH(_SCRN0)
    ld d, a
    ld c, SCRN_Y_B + 1
.nextRow
    wait_vram
    ld a, [hl]
    ld [de], a
    ld a, e
    add a, SCRN_VX_B
    ld e, a
    adc a, d
    sub e
    and $9B
    ld d, a
    ldh a, [hRedrawAccumulatedHeight]
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a
    dec c
    jr nz, .nextRow
.noHorizMovement

    ; Update memory
    ld a, [wCameraXPos]
    add a, 8
    ldh [hSCX], a
    ld a, [wCameraYPos]
    add a, 16
    ldh [hSCY], a
    ld c, a
    and $F8
    ld b, a
    call GetFreeScanlineBuf
    ld a, $FF
    ld [$FF00+c], a
    ld a, [wYScroll]
    ld de, wCameraYPos
    ld hl, wYScroll
    ld c, 4
    jp MemcpySmall


UpdateHorizScrollLayers:
    ; First, calculate new positions
    ld hl, wParallaxLayers
    ld a, [wNbParallaxLayers]
    ld b, a
.computeNewScroll
    ld a, [hli] ; Read scroll ratio
    inc a
    ld c, a
    jr z, .staticLayer ; If the layer's ratio is -1, the layer ain't scrolling (preserve the value instead of resetting it)
    ld a, [wCameraXPos]
    add a, 8
    ld e, a
    ld a, [wCameraXPos+1]
    adc a, 0
    ld d, a
    ld a, e
    dec c ; Check if the scroll ratio was zero
    jr z, .gotLayerScroll
.shiftCameraPos
    srl d
    rra
    dec c
    jr nz, .shiftCameraPos
.gotLayerScroll
    ld [hli], a
    ld [hl], d
.staticLayer
    ld a, l
    or 8 - 1
    inc a
    ld l, a
    dec b
    jr nz, .computeNewScroll
    ; Next, compare against comparison positions, to check if redraw should occur
    xor a
    ldh [hRedrawAccumulatedHeight], a
    ld de, wParallaxLayersScroll
    ld hl, wNbParallaxLayers
    ld a, [hli]
.compareLayerPositions
    ldh [hRedrawLayerCount], a
    inc l ; Skip ratio
    ld a, [hli]
    and $F8 ; Get coarse scroll (low byte)
    ld c, a
    ; Calc row index
    ld a, [hli] ; Get scroll high byte
    and 7
    or c ; Mix with low byte (%7654 3A98)
    rrca ; Put it right
    rrca ; again
    rrca ; FIXME: assumes maps are at most $800 pixels large
    ldh [hRedrawTargetColID], a ; Store col #
    ld a, [hli] ; Get height
    ld b, a
    ldh a, [hRedrawAccumulatedHeight]
    add a, b
    ldh [hRedrawAccumulatedHeight], a
    ; Compare against old coarse scroll
    ld a, [de]
    inc e ; inc de
    and $F8 ; Get old coarse scroll (comparing low bytes is enough)
    cp c
    jp z, .noLayerRedraw
    push de ; Save scroll comparison read ptr
    ldh a, [hCameraXMovementDirection]
    inc a ; cp a, -1 ; Check if moved left
    jr z, .cameraMovedLeft ; If the old scroll was greater than the current one, the target address is correct
    ; Otherwise, we need to point to the right edge!
    ldh a, [hRedrawTargetColID]
    add a, SCRN_X_B
    ldh [hRedrawTargetColID], a
.cameraMovedLeft
    ; Redraw one of the layer's columns
    ld a, [hli] ; Bank
    rst bankswitch
    ld a, [hli] ; Ptr low
    push hl ; Save layer data read ptr (stopping in the middle of the struct, so the later advancing is guaranteed to work)
    ld h, [hl] ; Ptr high
    ld l, a
    ; Add column offset
    ldh a, [hRedrawTargetColID]
    add a, a
    jr nc, .noCarry
    inc h
.noCarry
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a
    ; Get ptr to col data
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ; Calc tilemap dest addr
    ldh a, [hRedrawTargetColID]
    and SCRN_VX_B - 1
    ld c, a ; Horiz offset (depends on scrolling)
    ldh a, [hRedrawAccumulatedHeight]
    sub b ; Don't count our own height, though
    swap a ; Multiply
    rlca ; by $20
    ld e, a
    and SCRN_VX_B - 1
    add a, HIGH(_SCRN0)
    ld d, a
    ld a, e
    and -SCRN_VX_B
    add a, c
    ld e, a
    ; Write new tiles
.writeColumnTilemap
    wait_vram
    ld a, [hli]
    ld [de], a
    ld a, e
    add a, SCRN_VX_B
    ld e, a
    adc a, d
    sub e
    ld d, a
    dec b
    jr nz, .writeColumnTilemap
    ; Load new tiles; or, rather, ask VBlank to do it for us
    ld a, [hli]
    and a
    jr z, .noNewTiles
    ld b, a ; Save this for later
    ld a, [hli] ; Which tile ID this starts at; bit 7 is flipped to help calculations
    ld c, a ; Also save this for later
    ld d, h ; Save the current pointer, which is the source for the transfer below
    ld e, l
    ; Get ptr to queue
    ld h, HIGH(wFastCopyQueue)
    ldh a, [hFastCopyLowByte]
    ld l, a
    ldh a, [hCurROMBank]
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    swap c ; Mult by 16
    ld a, c
    and $F0
    ld [hli], a
    ld a, c
    and $0F
    add a, HIGH(vMapTiles)
    ld [hli], a
    ld a, LOW(wDummyFastCopyACK)
    ld [hli], a
    ld a, $99 ; FIXME:
    ld [hli], a
    ld a, b ; Finally, write length
    ld [hli], a
    ld a, l ; Get new low byte to update ptr
    ; Schedule transfer as early as possible
    ld hl, hFastCopyNbReq
    inc [hl] ; MUST use this instruction because we need atomicity
    and $7F ; Do wrapping
    ldh [hFastCopyLowByte], a
.noNewTiles
    pop hl ; Restore regs
    pop de
.noLayerRedraw
    ld a, l
    or 8 - 1
    inc a
    ld l, a
    ldh a, [hRedrawLayerCount]
    dec a
    jp nz, .compareLayerPositions

    ; Copy new positions to comparison buffer
    ld de, wParallaxLayersScroll
    ld hl, wNbParallaxLayers
    ld a, [hli]
    ld b, a
    inc l ; inc hl
.copyParallaxScrolls
    ld a, [hli]
    ld [de], a
    inc e ; inc de
    ld a, l
    add a, 8 - 1
    ld l, a
    dec b
    jr nz, .copyParallaxScrolls
    ; Finally, update raster FX
    ld hl, wNbParallaxLayers
    call GetFreeScanlineBuf
    ld a, [hli] ; Get number of layers
    ld b, a
    inc l ; inc hl
    ld a, [hli] ; Get first layer's scroll amount (low byte only)
    inc l ; inc hl ; Skip other byte
    ldh [hSCX], a ; First layer is handled in SCX
    ld a, [wCameraYPos] ; Handle vertical scroll now, so we can get the scanline #
    add a, 16
    ldh [hSCY], a
    dec b
    jr z, .onlyOneLayer
    inc b
    ; Prepare scanline number calculation
    cpl ; Negate
    inc a
    ld e, a
    jr .processOtherLayers
.setupOneLayer
    ld a, e
    ld [$FF00+c], a
    inc c
    ld a, LOW(rSCX) ; ...write addr...
    ld [$FF00+c], a
    inc c
    ld a, [hli] ; ...and write value
    ld [$FF00+c], a
    inc c
.processOtherLayers
    ld a, [hli] ; Read height
    add a, a ; Multiply
    add a, a ; by tile height
    add a, a ; (8 pixels)
    add a, e ; Add to current scanline
    ld e, a
    ld a, l ; Go to next layer
    and -8
    add a, 8 + 1
    ld l, a
    dec b
    jr nz, .setupOneLayer
.onlyOneLayer
    ld a, $FF ; Terminate raster FX list
    ld [$FF00+c], a
    ret


CameraDeltaFuncs:
    dw GetNPCCameraDelta
    dw GetHorizNPCCameraDelta
    dw GetVertNPCCameraDelta

GetNPCCameraDelta:
    ld a, [wCameramanID]
    swap a ; *16
    add a, LOW(wPlayer)
    ld l, a
    adc a, HIGH(wPlayer)
    sub l
    ld h, a
    call GetCameraRelativePosition
    ld hl, hCameraRelativePosition
    ld a, [hl]
    sub a, SCRN_Y / 2 + 16
    ld [hli], a
    jr nc, .noCarry
    dec [hl]
.noCarry
    inc l ; inc hl
    ld a, [hl]
    sub a, SCRN_X / 2 + 8
    ld [hli], a
    ret nc
    dec [hl]
    ret

GetHorizNPCCameraDelta:
    call GetNPCCameraDelta
    ld hl, hCameraRelativePosition
    xor a
    ld [hli], a
    ld [hl], a
    ret

GetVertNPCCameraDelta:
    call GetNPCCameraDelta
    ld hl, hCameraRelativePosition + 2
    xor a
    ld [hli], a
    ld [hl], a
    ret


SECTION "Overworld states ROMX", ROMX

OverworldStatePtrs::
    dw ; This state cannot be called!
    dw OverworldStateBegin
    dw OverworldStateFadeIn
    dw OverworldStateFadeOut
    dw OverworldStateLoadMap
    dw OverworldStateNormal


OverworldStateBegin:
    dw .initEngine ; Function to run before input
    db 0 ; Which buttons should be considered when held
    dw 0, 0, 0, 0, 0, 0, 0, 0 ; Functions to be ran when a button is triggered

.initEngine
    ld a, OVERWORLD_LOAD_MAP
    ld [wNextState], a

    ; Init extra player sprites's tiles
    ; These should never have to change
    ld a, 2
    ld [wShadowOAM + 6], a
    xor a
    ld [wShadowOAM + 2], a

    ; Player tiles will be loaded normally on first frame
    ; xor a
    ld [wPlayerTilesShifted], a

    ld hl, wPlayerTiles
    ld c, 16 * NB_PLAYER_TILES
    ; xor a
    rst memset_small

    ld hl, wPlayerShiftedTiles
    ld c, 16 * 6 + 12 * 4
    ; xor a
    rst memset_small

    ld hl, vPlayerTiles
    ld c, 16 * 2
    ; xor a
    call LCDMemsetSmall
    ld l, LOW(vPlayerTiles + 8 * 16)
    ld c, 16 * 2
    ; xor a
    call LCDMemsetSmall

    ; xor a
    ld [wTextboxScanline], a
    ; ld a, PAL_PACKT_ACTION_NONE
    ld [wPalettePacketAction], a

    ; xor a
    ld [wTextCurPixel], a
    ld [wTextCharset], a
    ld [wNbNewlines], a
    ld [wTextPaused], a
    ld hl, wTextTileBuffer
    ld c, $20
    ; xor a
    rst memset_small
    dec a ; ld a, $FF
    ld [wTextSrcPtr+1], a

    ; ld a, $FF
    ldh [hScanlineFXBuffer1], a
    ldh [hScanlineFXBuffer2], a

    ; ld a, $FF
    ld [wPlayerInputsMask], a

    ; Prevent warp behavior on file loading
    ; ld a, $FF
    ld [wTargetWarp], a

    ; Non-zero
    ld [wPlayerFastCopyACK], a

    ld a, %00011110
    ldh [hTextboxBGP], a

    ld a, (vVWFTiles - $8000) / 16
    ld [wTextCurTile], a

    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
    ldh [hLCDC], a

    ; FIXME: this is all temporary init, load from save file instead
    xor a
    ld [wTargetMap], a

    ; xor a
    ld [wCameramanID], a

    ld hl, wPlayer
    ld de, .player
    ld c, sizeof_NPC
    rst memcpy_small
    
    ld hl, wCameraXPos+1
    dec a ; ld a, $FF
    ld [hld], a
    ld a, $F8
    ld [hld], a
    xor a
    ld [hld], a
    ld [hl], a

    ld a, LOW(PlayerSideStandingTiles)
    ld [wPlayerLoadedTiles], a
    ld a, HIGH(PlayerSideStandingTiles)
    ld [wPlayerLoadedTiles+1], a
    ; LoadPlayerGfx is in another ROM bank, we can't just jump to it: ROP time!
    ld de, LoadPlayerGfx
    push de
    ld de, PlayerSideStandingTiles ; Passed as argument to LoadPlayerGfx because ROMBankswitch preserves DE
    ld a, BANK(LoadPlayerGfx)
    jp ROMbankswitch

; .player
    dstruct NPC, .player, 0, $80, 0, $F1, PLAYER_STATE_STANDING_RIGHT, 0, 4, 0, BANK(PlayerDrawPtrs), PlayerDrawPtrs, 0, EmptyFunc


OverworldStateFadeIn:
    dw .fadeIn ; Function to run before input
    db 0 ; Which buttons should be considered when held
    dw 0, 0, 0, 0, 0, 0, 0, 0 ; Functions to be ran when a button is triggered

.fadeIn
    ld a, [wCurStateFirstFrame]
    and a
    jr z, .notFirstFrame
    ; Assume palettes are properly set (ie. we're fading from the proper solid colors)
    ; Perform first fade immediately
    ld a, 1
    ld [wFadeFrames], a
    ; This is the value that will get added to each color
    ; It'll be decremented just below
    ld a, 4
    ld [wFadeStep], a
.notFirstFrame

    ld hl, wFadeFrames
    dec [hl]
    ret nz
    ld a, [wFadeDelay]
    ld [hli], a
    ; ld hl, wFadeStep
    ld a, [hl]
    dec a
    ld [hli], a
    ld e, a

    ; Unlike for fading in, we can't proceed incrementally
    ; Getting closer to the desired value and capping isn't symmetrical to the fade-in, which looks better (closer to actual alpha blending a solid color)
    ; Thus we will add a fixed value to the palette
    ld c, LOW(hBGP)
    ; ld hl, wFadePalettes
.fadePalette
    ld a, [hli] ; Target palette, which we'll modify
    push hl
    ld b, 4
.fadeColor
    ld d, a
    ld a, [wFadeType]
    and a
    ld a, d
    ; Modify current color
    jr nz, .fromBlack
    and 3
    sub e
    jr nc, .noCap
    xor a
    jr .noCap
.fromBlack
    and 3
    add a, e
    cp 4
    jr c, .noCap
    ld a, 3
.noCap
    ; Mix back the rest of the palette without an extra reg
    xor d ; Reversibly mix the two lower bits of the palette
    and 3 ; Trash all others
    xor d ; Get upper bits as normal, and cancel lower two bits
    ; Rotate the colors to get the next one
    rlca
    rlca
    dec b
    jr nz, .fadeColor
    ld [$ff00+c], a
    pop hl
    ld a, c
    inc c
    cp LOW(hOBP1)
    jr nz, .fadePalette

    ; Check if palettes have been faded out fully
    ld a, [wFadeStep]
    and a
    ret nz

    ld a, [wFollowingState]
    ld [wNextState], a
    ret


OverworldStateFadeOut:
    dw .fadeOut ; Function to run before input
    db 0 ; Which buttons should be considered when held
    dw 0, 0, 0, 0, 0, 0, 0, 0 ; Functions to be ran when a button is triggered

.fadeOut
    ld a, [wCurStateFirstFrame]
    and a
    jr z, .notFirstFrame
    ; Save palettes for corresponding fade-in
    ld hl, wFadePalettes
    lb bc, 3, LOW(hBGP)
.copyPalettes
    ld a, [$ff00+c]
    inc c
    ld [hli], a
    dec b
    jr nz, .copyPalettes
    ; Perform first fade immediately
    ld a, 1
    ld [wFadeFrames], a
.notFirstFrame

    ld hl, wFadeFrames
    dec [hl]
    ret nz
    ld a, [wFadeDelay]
    ld [hli], a

    ; When fading out, it's possible to proceed incrementally:
    ; We need to apply an "alpha" layer, that is, subtract (or add) to every color
    ; But we can do that incrementally!
    ld a, [wFadeType]
    and a
    jr z, .toWhite
    ld a, $FF
.toWhite
    ld l, a ; Value of a successfully faded palette
    lb bc, 3 + 1, LOW(hBGP) ; Number of palettes successfully faded, pointer to current palette
.fadeOnePalette
    ld a, [$ff00+c] ; Current palette
    ld h, 4 ; Number of colors that need fading
.fadeOneColor
    ld e, a
    and $FC
    ld d, a ; Other colors in the palette
    ld a, [wFadeType]
    and a
    ld a, e
    jr nz, .toBlack
    and $03
    jr z, .colorDone
    dec a
    jr .colorDone
.toBlack
    and $03
    cp 3
    jr z, .colorDone
    inc a
.colorDone
    or d
    rlca
    rlca
    dec h
    jr nz, .fadeOneColor
    ; a = Current palette value
    cp l
    jr nz, .paletteNotFinished
    dec b
.paletteNotFinished
    ld [$ff00+c], a
    ld a, c
    inc c
    cp LOW(hOBP1)
    jr nz, .fadeOnePalette
    dec b
    ret nz
    ld a, [wFollowingState]
    ld [wNextState], a
    ret


OverworldStateLoadMap:
    dw LoadMap
    db 0 ; Which buttons should be considered when held
    dw 0, 0, 0, 0, 0, 0, 0, 0 ; Functions to be ran when a button is triggered


OverworldStateNormal:
    dw CheckMapTriggers ; Function to run before input
    db PADF_DOWN | PADF_UP | PADF_LEFT | PADF_RIGHT ; Which buttons should be considered when held
    dw MovePlayerDown, MovePlayerUp, MovePlayerLeft, MovePlayerRight, 0, 0, 0, 0 ; Functions to be ran when a button is pressed

CheckMapTriggers:
    ; Check position-based triggers
    ; FIXME: button triggers should be triggered slightly ahead of the player, not at their feet (requires implementing directions, though)
    ld hl, hTriggerSearchPoint
    ld de, wPlayer_YPos
    ld a, [de]
    ld [hli], a
    inc e ; inc de
    ld a, [de]
    ld [hli], a
    inc e ; inc de
    inc e ; inc de
    ld a, [de]
    ld [hli], a
    inc e ; inc de
    ld a, [de]
    ld [hli], a
    xor a
    ld [hli], a ; hTriggerSearchPtr
    ld [hl], TRIGGER_COORDSCRIPT | TRIGGER_BTNTRIGGER ; hTriggerSearchedTypes
.search
    call SearchTrigger
    jr nz, .checkTrigger
.rejectTrigger
    ldh a, [hTriggerSearchPtr]
    and a
    jr nz, .search
    ret

.checkTrigger
    ldh a, [hTriggerFoundTypes]
    add a, a ; Test for button triggers
    jr nc, .doTrigger
    ; Button triggers depend on the button type
    ldh a, [hPressedButtons]
    and [hl]
    jr z, .rejectTrigger
    inc l ; inc hl
.doTrigger
    ld a, [hli] ; First byte tells how the rest should be dispatched
    add a, a
    add a, LOW(.dispatchTable)
    ld c, a
    adc a, HIGH(.dispatchTable)
    sub c
    ld b, a
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    jp CallDE

.dispatchTable
    dw .dispatchCutscene
    dw .dispatchWarp
    dw JumpToFarPtr

.dispatchCutscene
    ; TODO: stack
    ld a, [hli]
    ld [wCutsceneBank], a
    ld a, [hli]
    ld [wCutscenePtr], a
    ld a, [hli]
    ld [wCutscenePtr+1], a
    ret

.dispatchWarp
    ld a, [hli]
    ld [wTargetMap], a
    ld a, [hli]
    ld [wTargetWarp], a
    ld a, [hli]
    srl a
    ld [wFadeDelay], a
    sbc a, a
    ld [wFadeType], a
    ld a, OVERWORLD_LOAD_MAP
    ld [wFollowingState], a
    ld a, OVERWORLD_FADE_OUT
    ld [wNextState], a
    ret


MovePlayerDown:
    ld a, [wScrollingType]
    cp SCROLLING_HORIZ
    ret z

    ; TODO: collision

    ld hl, wPlayerStateChange
    set DOWN_HELD, [hl]

    ld hl, wPlayer_YPos
    inc [hl]
    ret nz
    inc hl
    inc [hl]
    ret

MovePlayerUp:
    ld a, [wScrollingType]
    cp SCROLLING_HORIZ
    ret z

    ; TODO: collision

    ld hl, wPlayerStateChange
    set UP_HELD, [hl]
    
    ld hl, wPlayer_YPos
    dec [hl]
    ld a, [hli]
    inc a
    ret nz
    dec [hl]
    ret

MovePlayerLeft:
    ; TODO: collision

    ld hl, wPlayerStateChange
    set LEFT_HELD, [hl]

    ld hl, wPlayer_XPos
    dec [hl]
    ld a, [hli]
    inc a
    ret nz
    dec [hl]
    ret

MovePlayerRight:
    ; TODO: collision

    ld hl, wPlayerStateChange
    set RIGHT_HELD, [hl]

    ld hl, wPlayer_XPos
    inc [hl]
    ret nz
    inc hl
    inc [hl]
    ret



; Looks for a trigger of a certain type at given coordinates
; **CAUTION:** make sure to reset hTriggerSearchPtr before starting to call this function
; @param hTriggerSearchedTypes A mask of the triggers to look for
; @param hTriggerSearchPoint The coordinates at which to look for a trigger (basically, look for triggers whose hitbox contain this trigger)
; @return Z Reset (`nz`) if a trigger was found
; @return hl A pointer to the trigger's arguments (in wTriggerArgPool) if one was found
; @return hTriggerSearchPtr Zero if the search has ended (do not keep calling the function, this will cause the logic to loop)
SearchTrigger::
    ld h, HIGH(wTriggerPool)
    ldh a, [hTriggerSearchPtr]
    ld l, a
    ldh a, [hTriggerSearchedTypes]
    ld b, a
.loop
    ld a, [hli]
    and b
    jr z, .reject
    ldh [hTriggerFoundTypes], a
    ldh a, [hTriggerSearchPoint]
    sub [hl]
    ld e, a
    inc l ; inc hl
    ldh a, [hTriggerSearchPoint+1]
    sbc [hl]
    jr nz, .reject
    inc l ; inc hl
    ld a, [hli] ; Y size
    cp e
    jr c, .reject
    ldh a, [hTriggerSearchPoint+2]
    sub [hl]
    ld d, a
    inc l ; inc hl
    ldh a, [hTriggerSearchPoint+3]
    sbc [hl]
    jr nz, .reject
    inc l ; inc hl
    ld a, [hli] ; X size
    cp d
    jr nc, .accept
.reject
    ld a, l
    and -sizeof_Trigger
    add sizeof_Trigger
    ld l, a
    jr nz, .loop
    ldh [hTriggerSearchPtr], a
    ret

.accept
    ld a, l
    inc a
    ldh [hTriggerSearchPtr], a
    ld l, [hl]
    dec h ; ld h, HIGH(wTriggerArgPool)
    ; NZ because `dec h`
    ret
