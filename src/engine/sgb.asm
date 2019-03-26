
SECTION "SGB setup", ROMX

TwoPlayersPacket:
    sgb_packet MLT_REQ, 1, 1
OnePlayerPacket:
    sgb_packet MLT_REQ, 1, 0

DisablePalettesPacket:
    sgb_packet ICON_EN, 1, %001 ; Disable palettes, keep other two

NB_BORDER_TILES = 1
CompressedBorderTiles:
;INCBIN "res/sgb/borders/tetbits.borderchr.pb16"
TransferBorderTilesPacket:
    sgb_packet CHR_TRN, 1, %00 ; BG tiles, $00-7F
    ; A second packet might be needed if more than $80 tiles are transferred

BORDER_ATTRIBUTE_SIZE = $880
CompressedBorderAttributes:
;INCBIN "res/sgb/borders/tetbits.borderattr.pb16"
TransferBorderAttributesPacket:
    sgb_packet PCT_TRN, 1

NB_ATTRIBUTE_FILES = 3
CompressedAttributeFiles:
INCBIN "res/sgb/attr_files.bin.pb16"
TransferAttributeFilesPacket:
    sgb_packet ATTR_TRN, 1

NB_PALETTE_FILES = 10
CompressedPaletteFiles:
INCBIN "res/sgb/palettes.bin.pb16"
TransferPaletteFilesPacket:
    sgb_packet PAL_TRN, 1

UnfreezeScreenPacket:
    sgb_packet MASK_EN, 1, 0


; Sets up a ton of SGB-related stuff
; The stuff in question takes a bunch of time, but we need to do it ASAP, basically
; Of course on a non-SGB system basically nothing will happen :D
DoSGBSetup::
    ; Request multiplayer mode, which a non-SGB device will ignore
    ld hl, TwoPlayersPacket
    call SendPackets
    lb bc, 2, LOW(rP1)
.tryAgain
    ; Now poll input...
    ld a, $10
    ld [$ff00+c], a
    ; Apparently polling only $10 is enough..?
;    ld a, $20
;    ld [$ff00+c], a
    ; ...and say we're over.
    ld a, $30
    ld [$ff00+c], a
    ; A non-SGB won't have cared the slightest about our little ballet here
    ; But a SGB will know that we have polled one joypad, and will switch to the next one
    ; And we can read that out!
    ld a, [$ff00+c]
    and $03
    cp $03 ; Value returned when Player 1 is in effect ($XF)
    jr nz, .isSGB
    ; Okay, but maybe we just genuinely polled Player 1. Let's try again.
    dec b
    jr nz, .tryAgain
    ret


.isSGB
    ; Freeze the screen for the upcoming transfers
    call FreezeSGBScreen
    rst wait_vblank ; Wait an extra frame to make up for the SGB delay (can be removed if decompression takes long enough)
    ; Shut the LCD down to decompress directly to VRAM
    xor a
    ldh [hLCDC], a
    inc a ; ld a, 1
    ldh [hIsSGB], a
    rst wait_vblank
    call SGBDelay ; FIXME: remove this once what's below is finished

IF 0
    ; Now, send the border while the static screen is being shown
    ld de, CompressedBorderTiles
    ld hl, vSGBTransferArea
    ld b, NB_BORDER_TILES * 16 / 16
    call pb16_unpack_block
    call FillScreenWithSGBMap ; Also re-enables display and sets up render params
    rst wait_vblank ; Wait for the first blank frame to display; the transfer will start at the end of the following frame
    ld hl, TransferBorderTilesPacket
    call SendPackets
    xor a
    ldh [hLCDC], a
    rst wait_vblank
    ld de, CompressedBorderAttributes
    ld hl, vSGBTransferArea
    ld b, BORDER_ATTRIBUTE_SIZE / 16
    call pb16_unpack_block
    call SetupSGBLCDC
    rst wait_vblank
    ld hl, TransferBorderAttributesPacket
    call SendPackets

    ; Now send the attribute files...
    xor a
    ldh [hLCDC], a
    rst wait_vblank
ENDC
    ; Same thing!
    ld de, CompressedAttributeFiles
    ld hl, vSGBTransferArea
    ld b, (90 * NB_ATTRIBUTE_FILES + 89) / 16 ; + (90 - 1) to round up
    call pb16_unpack_block
    call FillScreenWithSGBMap ; FIXME: restore to SetupSGBLCDC once above is complete
    rst wait_vblank
    ld hl, TransferAttributeFilesPacket
    call SendPackets

    ; Palette files now...
    xor a
    ldh [hLCDC], a
    rst wait_vblank
    ; Same thing!
    ld de, CompressedPaletteFiles
    ld hl, vSGBTransferArea
    ld b, (2 * 4 * NB_PALETTE_FILES) / 16
    call pb16_unpack_block
    call SetupSGBLCDC
    rst wait_vblank
    ld hl, TransferPaletteFilesPacket
    call SendPackets ; Perform delay, because the transfer takes a while

    ; Clear the garbage we transmitted by blanking the palette
    ; Thought of disabling the LCD, but it appears this doesn't blank the screen on SGB!
    xor a
    ldh [hBGP], a
    ; Disable manual paletting
    ld hl, DisablePalettesPacket
    call SendPackets

    ; We don't unfreeze the screen, this will be done by the next PAL_SET packet

    ld hl, OnePlayerPacket ; We're not gonna use multiplayer capabilities, though.
    jp SendPacketNoDelay ; Tail call
