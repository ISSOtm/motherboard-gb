
SECTION "Village map header", ROMX

 map_header Village
INCLUDE "res/maps/village/village.asm"

VillageMapScript:
    ld a, [wPlayer_XPos+1]
    cp 2
    ret nz
    ld a, [wPlayer_XPos]
    cp $24
    ccf
    rra
    and $80
    ld [wPlayer_BaseAttr], a
    ret
