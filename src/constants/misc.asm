

; Define this to init memory that doesn't need to be init'd
; Keeps BGB from complaining
PedanticMemInit equ 1


; RST labels
null_exec    equ $00
memcpy_small equ $08
memset_small equ $10
memset       equ $18
bankswitch   equ $20
call_hl      equ $28
wait_vblank  equ $30
rst38_err    equ $38


; Seconds-to-frames converter
; "wait 30 seconds" is nice RGBDS magic :D
second  EQUS "* 60"
seconds EQUS "* 60"
frames  EQUS "" ; lol


SGB_PACKET_SIZE equ 16 ; A packet is 16 bytes



STACK_SIZE equ $40


NB_PARALLAX_LAYERS equ 4


NB_PLAYER_TILES equ 3 * 2 + 2 * 2 ; First row is 3 sprites, second is 2 sprites


NB_NPCS equ 15 + 1


NB_FAST_COPY_REQS equ 16 ; Needs to be greater than the number of NPCs for map loading to go smoothly


TRIGGER_BIT = 7
trigger_type: MACRO
\1_B equ TRIGGER_BIT
\1   equ 1 << TRIGGER_BIT
TRIGGER_BIT = TRIGGER_BIT + (-1)
ENDM
    trigger_type TRIGGER_BTNTRIGGER
    trigger_type TRIGGER_COORDSCRIPT

    enum_start
    enum_elem TRIGTYPE_CUTSCENE
    enum_elem TRIGTYPE_WARP
    enum_elem TRIGTYPE_ASM

NB_TRIGGERS equ $20 ; $100 / sizeof_Trigger


CUTSCENE_STACK_NB_ENTRIES equ 10


MENU_STACK_CAPACITY equ 10
