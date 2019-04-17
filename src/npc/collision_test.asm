
SECTION "Collision test NPC data", ROMX

CollisionTestDrawPtrs::
    dw CollisionTestDraw

CollisionTestDraw:
    db 255
    db 255
    dw .frame0

.frame0
    db 2
    db -18, -8, 0, 0
    db -18,  0, 2, 0


CollisionTestTiles::
INCBIN "src/res/npc/collision_test/collision_test.chr"
CollisionTestTilesEnd::
