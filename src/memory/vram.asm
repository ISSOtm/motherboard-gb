
SECTION "VRAM", VRAM[$8000]

UNION

vSGBTransferArea::
    ds $1000

NEXTU

; Layout:
; 2 hat overlap tiles
; 2 body overlap tiles
; 6 hat tiles
; 4 body tiles
vPlayerTiles::
    ds 16 * (NB_PLAYER_TILES + 2*2)
vNPCTiles::
    ds $580 - 16 * (NB_PLAYER_TILES + 2*2)

vTextboxBorderTiles::
    ds $80
vVWFTiles::
    ds $200

; $8800
; Tiles for overworld maps
vMapTiles::
    ds $1000

NEXTU

    ds $1000

; $9000
vBlankTile::
    ds $10

ENDU

; $9800

vOverworldTilemap::
    ds SCRN_VX_B * SCRN_VY_B ; $400

; $9C00

vWindowTilemap::
    ds SCRN_VX_B * SCRN_Y_B ; $240
vTextboxTilemap::
    ds SCRN_VX_B * 4 ; $80
vTextboxScrollTilemap::
    ds SCRN_VX_B * 3 ; $60
