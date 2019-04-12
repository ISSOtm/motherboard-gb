
SECTION "Bike data", ROMX

BikeDrawPtrs::
    dw BikeLeftDraw

BikeLeftDraw:
    db 255
    db 255
    dw .frame0

.frame0
    db 5
    db -16, -9, 2, 0
    db -15, -1, 4, 0
    db -15, 7, 6, 0
    db -26, 15, 8, 0
    ; This one is last because its topmost row of pixels is blank, so it's okay if it isn't displayed
    db -15, -17, 0, 0


BikeTiles::
INCBIN "src/res/npc/bike/bike.chr"
BikeTilesEnd::
