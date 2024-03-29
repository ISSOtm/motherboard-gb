
SECTION "HRAM", HRAM

; The OAM DMA routine
hOAMDMA::
    ds 8 ; OAMDMAEnd - OAMDMA


; Currently-loaded ROM bank, useful to save back (eg. during ints)
hCurROMBank::
    db


; Used by the PB16 decompressor
pb16_byte0::
    db


; Low byte of the current scanline buffer
; Permits double-buffering
hWhichScanlineBuffer::
    db
; Low byte of byte read by STAT handler
; NO TOUCHY
hScanlineFXIndex::
    db

; Scanline FX buffers (scanline, addr, value)
; Double-buffering used to prevent race conditions
hScanlineFXBuffer1::
    ds 3 * 5 + 1
hScanlineFXBuffer2::
    ds 3 * 5 + 1

; Addr/value pair to allow writing to 2 regs in the same scanline
hSecondFXAddr::
    db
hSecondFXValue::
    db


; Temporary variables

UNION

; Title screen

; Index in the table below, fade stops if
hTitleScreenFadeIndex::
    db
hTitleScreenFadeTable::
    ds 7

NEXTU

; Main menu

; Non-zero if a save file is present
hSaveFilePresent::
    db

NEXTU

; Redrawing vars

; The direction in which the camera moved on this frame
; -1 = left
;  0 = right
; Anything else is invalid
; NEITHER value guarantees the camera moved at all (due to locking, for example)
hCameraYMovementDirection::
    db
; See hCameraYMovementDirection
hCameraXMovementDirection::
    db

    UNION

; Redraw destination ptr
hRedrawTilemapAddr::
    dw

    NEXTU

; Accumulated height, in tiles
hRedrawAccumulatedHeight::
    db

; Index of the col to be redrawn
hRedrawTargetColID::
    db

    NEXTU

; First tile of the current row
hRedrawRowStart::
    db

; Map's width divided by 8
hRedrawTileWidth::
    db

    ENDU

; Number of layers remaining to redraw
hRedrawLayerCount::
    db

; How many rows need to be redrawn
hRedrawRowCount::
    db

NEXTU

; NPC draw vars

; Remaining OAM entries to write in the current NPC
hNPCRemainingEntries::
    db

; Current tile ID
hNPCTileID::
    db

; Current attr
hNPCAttr::
    db

NEXTU

; Map loading

; Number of NPCs remaining to load
hLoadingRemainingNPCs::
    db

; Number of NPC tiles to load
hLoadingNPCCount::
    db

; Current NPC base tile ID
hLoadingNPCBaseTileID::
    db

NEXTU

; Player overlap fix buffer

hPlayerShiftBytes::
    ds 16

NEXTU

; Cutscene engine

; Currently executed cutscene command
; Only bit 7 is considered, to check if the command should be made instant
; Commands can forcibly reset that bit if they want
hCutsceneCurrentCommand::
    db

NEXTU

; Trigger processing

; Point at which to search for a trigger (SearchTrigger)
hTriggerSearchPoint::
    dw ; Y pos
    dw ; X pos

; Temporary for SearchTrigger. Make sure to reset before calling.
hTriggerSearchPtr::
    db

; Mask of the types SearchTrigger should consider
hTriggerSearchedTypes::
    db

; Which trigger type(s) matched
hTriggerFoundTypes::
    db

NEXTU

; Language selection menu

; Offset of the cursor in the language selection menu
hLangSelMenuCursorPos::
    db

hLangSelMenuTimer1::
    db
hLangSelMenuTimer2::
    db

hLangSelMenuPalette::
    db

NEXTU

; Collision'd movement

; Position of the hitbox that's being moved
hMovementPosition::
    ds 3
    ds 3

; Size of the hitbox that's being moved
hMovementHitbox::
    db
    db

; Bottom-right point of the hitbox that's being moved
hMovementSecondPoint::
    ds 2 ; ds 3
    ds 3

; Which of an entity's 4 colliders are active at a given time:
; ABCD being clockwise-ordered vertices, the mapping is:
; AC00 00BD
hActiveColliders::
    db

ENDU

; Map height, in tiles
; (Cached for collision detection)
hMapHeight::
    db


; How many rows are left to be drawn in the current tile
hVWFRowCount::
    db


; When non-zero, we're running on a SGB
hIsSGB::
    db


; Value written to BGP for the textbox
; Differs on SGB because colors are post-processed through SGBP3, and we also need to not use color #0
hTextboxBGP::
    db


; Low byte of the first free slot in the queue
hFastCopyLowByte::
    db
; Low byte of the first used slot in the queue
; DO NOT TOUCH
hFastCopyCurLowByte::
    db


; Output buffer of GetCameraRelativePosition
hCameraRelativePosition::
    ds 4


; Place variables that need to be zero-cleared on init (and soft-reset) below
hClearStart::


; When zero, lets VBlank know it needs to ACK
; NOTE: VBlank doesn't preserve AF **on purpose** when this is set
; Thus, make sure to wait for Z to be set before continuing
hVBlankFlag::
    db


; Values transferred to hw regs on VBlank
hLCDC::
    db
hSCY::
    db
hSCX::
    db
hWY::
    db
hWX::
    db
hBGP::
    db
hOBP0::
    db
hOBP1::
    db

; Number of "fast copy" requests that need to be serviced
; Served on next VBlank
hFastCopyNbReq::
    db

; Joypad regs
; Get updated by the VBlank handler on non-lag frames
hHeldButtons::
    db
hPressedButtons::
    db

; If non-zero, soft-resetting is permitted
hSoftResettingPermitted::
    db

; High byte of the shadow OAM buffer to be transferred
; Reset by the VBlank handler to signal transfer completion
hOAMBufferHigh::
    db
