
SECTION "Bike data", ROMX

BikeDrawPtrs::
    dw BikeLeftDraw
    dw BikeRightDraw

BikeLeftDraw:
    db 255
    db 255
    dw .frame0

.frame0
    db 5

    db -17
    db -9
    db 2
    db 0

    db -16
    db -1
    db 4
    db 0

    db -16
    db 7
    db 6
    db 0

    db -27
    db 15
    db 8
    db 0

    ; This one is last because its topmost row of pixels is blank, so it's okay if it isn't displayed
    db -16
    db -17
    db 0
    db 0

BikeRightDraw:
    db 255
    db 255


BikeTiles::
INCBIN "src/res/npc/bike/bike.chr"
BikeTilesEnd::
