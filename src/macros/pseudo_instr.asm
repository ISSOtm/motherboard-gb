
; Waits for \1 VBlanks
wait: MACRO
    IF \1 < 6
        REPT \1
            rst wait_vblank
        ENDR
    ELSE
        ld c, \1
.delay\@
        rst wait_vblank
        dec c
        jr nz, .delay\@
    ENDC
ENDM


; Waits until VRAM can be accessed
; @destroy a
wait_vram: MACRO
.waitVRAM\@
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .waitVRAM\@
ENDM
