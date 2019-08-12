

SECTION "General-purpose vars", WRAM0,ALIGN[8]

; Queue of fast VRAM copy requests
; Format:
;  Byte - bank
;  Ptr  - source
;  Ptr  - dest
;  Byte - low byte of ptr to which 1 is written upon transfer
;  Byte - first impossible scanline
;  Byte - len
wFastCopyQueue::
    ds NB_FAST_COPY_REQS * 8
wFastCopyQueueEnd::

; ACK flags for fast copy completions
wFastCopyACKs::
wDummyFastCopyACK::
    db
wPlayerFastCopyACK::
    db
    ds 3 ; Alignment, I guess
wPlayerReqPtrLow::
    db

; Temporary storage for SP while doing a VBlank fast VRAM transfer
wSPBuffer::
    dw

; This is ALIGN[3]


wLanguage::
    db


SECTION "Title screen vars", WRAM0

; Which of the 4 frames of animation is currently being displayed
wTitleScreenAnimCounter::
    db
; Counts upwards, when it reaches a certain value, the frame is animated
wTitleScreenAnimDelay::
    db


SECTION "Shadow OAM", WRAM0,ALIGN[8]

wShadowOAM::
    ds $A0


SECTION "Map properties", WRAM0,ALIGN[8]
; The current map's properties
wMapProperties::

; The NPC array must be in a single 256-byte page
UNION
    dstruct NPC, wPlayer
NEXTU
    dstructs NB_NPCS, NPC, wNPC
ENDU
wNPCArrayEnd::

wNPCSpeeds::
    ds 4 * NB_NPCS


; $XX40


; Current map's gravity
; Yes, there is "sideways" gravity, which may be used for wind effects
wGravity::
    dw
    dw

; Currently loaded map's ID
wLoadedMap::
    db

; The current map's height, in pixels
wMapHeight::
    dw
; The current map's width, in pixels
wMapWidth::
    dw


; Current map's map script
wMapScriptPtr::
    db
    dw

wMapCollisionMappingsPtr::
    db
; Current map's collision table ptr
wMapCollisionPtr::
    db
    dw


; Which SGB palette-related action to take on the next frame
; Required because packets tend to take effect one frame earlier than the thing they're synced to (eg. textbox)
wPalettePacketAction::
    db
; The packet to be sent to restore the map's SGB layout
; The first byte is fixed (command byte), the second is the map's ATF number
wRestoreSGBLayoutPacket::
    db ; Command byte
; The current map's SGB ATF number, for reloading after textbox
; Part of a SGB command packet, so encoded in ATTR_SET format directly
wCurMapATFNum::
    db


; Scroll amount for each parallax layer
; Redundant with each layer's own value below, but actually useful for comparison and easier to iterate on
wParallaxLayersScroll::
    ds NB_PARALLAX_LAYERS*2

    pad_align wMapProperties, 8, 1
wNbParallaxLayers::
    db
UNION
; Data of each parallax layer
wParallaxLayers::
REPT NB_PARALLAX_LAYERS
    db ; Scrolling ratio (how much the scroll amount must be shifted right)
    dw ; Scroll amount
    db ; Height
    db ; Bank
    dw ; Pointer to row data
    db  ; Padding
ENDR

NEXTU

wYScroll::
    dw
wXScroll::
    dw
wTilemapBank::
    db
wTilemapPtr::
    dw

ENDU


SECTION "Cutscene memory", WRAM0,ALIGN[8]

wCutsceneStackPtr::
    db
wCutsceneStack::
    ds 3 * CUTSCENE_STACK_NB_ENTRIES

wCutscenePtr::
    dw
wCutsceneBank::
    db

wCutsceneIME::
    db


SECTION "Overworld memory", WRAM0,ALIGN[8] ; We need to align wPlayerTiles

wPlayerTiles::
    ds 16 * NB_PLAYER_TILES

; Buffer used to write SGB packets
; WARNING: this buffer is especially non-persistent across frames due to potentially being a scratch buffer
wSGBPacket::
    ds 16
; Placed there because 10 bytes might spill out of wPlayerShiftedTiles if an interrupt fires at a specific moment
; wSGBPacket was chosen because its value doesn't matter while we're copying the shifted tiles to VRAM
; It's a temporary buffer, after all

wPlayerShiftedTiles::
    ds 16 * 6 + 12 * 4


; $40 past last 256 boundary


; The camera's position
wCameraYPos::    dw
wCameraXPos::    dw

; Map to be loaded
wTargetMap::
    db
; Target warp within the target map
; A value of $FF will cause warp operations to be bypassed
; Useful for save loading, for example, where all properties are already known
; Maybe also map reloading?
wTargetWarp::
    db

; Scanline at which the textbox should be displayed
; If zero, the textbox is simply not displayed
wTextboxScanline::
    db
; Number of scanlines between the top of the textbox and its split
; If zero, no split is made
wTextboxSplitScanline::
    db

; Are the player's tiles shifted?
wPlayerTilesShifted::
    db

; How the camera is allowed to scroll
wScrollingType::
    db

; The ID of the NPC the camera focuses on
wCameramanID::
    db

; The current state the overworld is in
wOverworldState::
    db
; The previous state the overworld was in (useful for "returning")
wPreviousState::
    db
; The next state the overworld should transition to
; A non-zero value will cause the overworld to change states
wNextState::
    db
; The state that the next state should transition to
; Some states are only transition states (eg. FADE_IN), this tells them where to go next
wFollowingState::
    db
; Set to 1 on the first frame of the current state
wCurStateFirstFrame::
    db


; $50 past 256 boundary


; Whether to update sprites, scrolling regs, etc.
; Not part of the state data to be able to freeze the overworld dynamically
wDoOverworldUpdates::
    db


; Top camera lock position (pixels, inclusive) - position of the top edge
wTopCamLock::
    dw
; Bottom camera lock position (pixels, inclusive) - position of the bottom edge
wBottomCamLock::
    dw
; Left camera lock position (pixels, inclusive) - position of the left edge
wLeftCamLock::
    dw
; Right camera lock position (pixels, inclusive) - position of the right edge
wRightCamLock::
    dw


; Type of fadeouts (0 = to/from white, NZ = to/from black)
wFadeType::
    db
; Frames between each fade step
wFadeDelay::
    db
; Frames until next fade step
wFadeFrames::
    db
; Step for fade-in (not used for fade-out)
wFadeStep::
    db
; Palettes before fadeout / target palettes for fadein
wFadePalettes::
    ds 3


; $60 past 256 boundary


wTriggerArgPool::
    ds 5 * NB_TRIGGERS ; $A0


; This is ALIGN[8]


wTriggerPool::
    dstructs NB_TRIGGERS, Trigger, wTrigger


; This is ALIGN[8]


wMovementVector:: ; Requires same high byte
    dw
    dw

wPlayerStateChange::
    db
wPlayerLoadedTiles::
    dw


; Indicates which buttons should be taken into account by the overworld engine
wPlayerInputsMask::
    db


SECTION "Menu system vars", WRAM0

wNbMenus::
    db

MENU_ID = 0
REPT MENU_STACK_CAPACITY
MENU_ID_STR equs STRSUB("{MENU_ID}", 2, STRLEN("{MENU_ID}") - 1)
    dstruct Menu, wMenu{MENU_ID_STR}
MENU_ID = MENU_ID + 1
    PURGE MENU_ID_STR
ENDR
PURGE MENU_ID

; What action to take after processing the menu
wMenuAction::
    db ; Action type
    ds 3 ; Action args

; The reason why this menu should be closed
wMenuClosingReason::
    db
; The reason why the last menu was closed
wPreviousMenuClosingReason::
    db
; The item selected on the last menu that was closed
; Updated when the menu is validated through the `VALIDATE` action
wPreviousMenuItem::
    db


SECTION "VWF engine memory", WRAM0,ALIGN[7]

wTextCharBuffer::
    ds 64
wTextCharBufferEnd:: ; We need this not to be on a 256-byte boundary

; This is ALIGN[6]
wTextTileBuffer::
    ds $10 * 2

; This is ALIGN[5]
; Format of entries: ptr(16bit LE), bank(8bit)
wTextStack::
    ds TEXT_STACK_CAPACITY * 3
; Number of entries in the stack
wTextStackSize::
    db

; Tells which tile to wrap to after $7F
wWrapTileID::
    db

; Tells which color to use in the palette for the text (in range 0-3)
wTextColorID::
    db

; Defines which character table to use
; Upper nibble is language-defined, lower nibble is decoration
wTextCharset::
    db

wPreviousLanguage::
    db
wPreviousDecoration::
    db

wTextSrcBank::
    db
wTextSrcPtr::
    dw

wTextCurTile::
    db
wTextCurPixel::
    db

; Number of frames between each character
wTextLetterDelay::
    db
; Number of frames till next character
wTextNextLetterDelay::
    db

; Bit 6 - Whether the text engine is currently waiting for a button press
; Bit 7 - Whether the text engine is halted, for syncing (can be reset)
wTextPaused::
    db

; Number of tiles flushed, used to know how many tiles should be written to the tilemap
wFlushedTiles::
    db

; Number of newlines that occurred during this print
wNbNewlines::
    db
; ID of the tiles during which newlines occurred (NOTE: there can be duplicates due to empty lines!!)
wNewlineTiles::
    ds TEXT_NEWLINE_CAPACITY

wPenStartingPosition::
    dw
wPenPosition::
    dw
wPenCurTile::
    db

; Low byte of the read ptr into wTextCharBuffer
wTextReadPtrLow::
    db
; Where the refiller ended, ie. where the printer needs to stop
wTextReadPtrEnd::
    db

; Length, in pixels, of the current text line
wTextLineLength::
    db
wLineRemainingPixels::
    db
; Ptr to last newlineable location
wNewlinePtrLow::
    db
; wLineRemainingPixels at the time wNewlinePtrLow is updated
wNewlineRemainingPixels::
    db
; Charset ptr is cached by refiller to speed up reads
wCurCharsetPtr::
    dw
wRefillerCharset::
    db
wRefillerPrevLanguage::
    db
wRefillerPrevDecoration::
    db


SECTION "Stack", WRAM0[$E000 - STACK_SIZE]

wStackTop::
    ds STACK_SIZE
wStackBottom::


SECTION "Error handler memory", WRAM0

; ID of the error that occurred
wErrorType::
; Once the ID has been used, this is re-used as a status, to route calls because stack space is available
wErrorDrawStatus::
; The status is also used to determine which dump to print
wErrorWhichDump::
    db

wErrorRegs::
; Value of A when the handler is called
; Re-used as part of the reg dump
wErrorA::
; Re-used to hold last frame's keys
wErrorHeldButtons::
    db ; a
; Re-used to hold the number of frames till the debugger is unlocked
wErrorFramesTillUnlock::
    db ; f
    dw ; bc
    dw ; de
wErrorHL::
    dw
wErrorSP::
    dw
