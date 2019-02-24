
; Be careful with effects on consecutive lines!
; A "double" effect will end a handful of cycles too late if the preceding scanline was really busy
; (approx. 25 M-cycles, HBlank can be as short as 22 cycles plus 1~2 cycles of latency explained below)
; The textbox appears to last up to 22 M-cycles so it should be fine
; The LY=LYC interrupt appears to be unable to trigger in the first (first two?) cycles of a scanline, giving extra leeway
; Anyways, using an effect just after either of the previous conditions may slightly delay it, and repeating the condition will accumulate the delays
; Mode 2 being 20 cycles long, it should be possible to stack the delays somewhat before visible breakage happens, but it's better to avoid it at all


SECTION "Raster fx helper functions", ROM0

; Get a pointer to the currently free scanline buffer
; @return a The pointer
; @return c The pointer
GetFreeScanlineBuf::
    ldh a, [hWhichScanlineBuffer]
    xor LOW(hScanlineFXBuffer2) ^ LOW(hScanlineFXBuffer1)
    ld c, a
    ret

; Switches to the currently free scanline buffer
; @return b A pointer to the newly used buffer
; @return c A pointer to the newly freed buffer
; @return a A pointer to the newly freed buffer
SwitchScanlineBuf::
    call GetFreeScanlineBuf
    ldh [hWhichScanlineBuffer], a
    ld b, a
    xor LOW(hScanlineFXBuffer2) ^ LOW(hScanlineFXBuffer1)
    ld c, a
    ret

; Switches to the currently free scanline buffer, and copies it over to the other buffer
; @return hl A pointer just past the source buffer
; @return c A pointer to just past the destination buffer
; @return a 0
SwitchAndCopyScanlineBuf::
    call SwitchScanlineBuf
    ld l, b
    ld h, HIGH(hScanlineFXBuffer1)
.loop
    ld a, [hli]
    ld [$ff00+c], a
    inc c
    inc a
    jr nz, .loop
    ret
