
SECTION "VWF engine", ROM0

; Sets the pen's position somewhere in memory
; The code is designed for a pen in VRAM, but it can be anywhere
; Please call this after PrintVWFText, so wTextCurTile is properly updated
; @param hl The address to print to (usually in the tilemap)
SetPenPosition::
; Note: relied upon preserving HL
    ld a, l
    ld [wPenPosition], a
    ld [wPenStartingPosition], a
    ld a, h
    ld [wPenPosition + 1], a
    ld [wPenStartingPosition + 1], a

    ld a, [wTextCurTile]
    ld [wPenCurTile], a
    ret

DrawVWFChars::
    ld hl, wPenPosition
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    ; ld hl, wPenCurTile
    ld c, [hl]

    ld hl, wNewlineTiles
    ld a, [wFlushedTiles]
    and a
    jr z, .noNewTiles
    ld b, a
    xor a
    ld [wFlushedTiles], a
.writeNewTile
    ; Check if current tile is subject to a newline
    ld a, [wNbNewlines]
    and a
    jr z, .noNewline
    ld a, c
    cp [hl]
    jr z, .newline
.noNewline
    wait_vram
    ld a, c
    ld [de], a
    cp $7F
    jr nz, .nowrap
    ld a, [wWrapTileID]
    ld c, a
    db $3E ; ld a, imm8
.nowrap
    inc c
    inc de
    dec b
    jr nz, .writeNewTile
.noNewTiles

.tryAgain
    ld a, [wNbNewlines]
    and a
    jr z, .noFinalNewline
    ld a, c
    cp [hl]
    jr z, .finalNewline
.noFinalNewline
    xor a
    ld [wNbNewlines], a

    ld hl, wPenCurTile
    ld a, c
    ld [hld], a
    ld a, d
    ld [hld], a
    ld [hl], e

    ; If the current tile is empty (1 px == 1 space)
    ld a, [wTextCurPixel]
    cp 2
    ret c
    wait_vram
    ld a, c
    ld [de], a
    ret

.newline
    ld a, [wNbNewlines]
    dec a
    ld [wNbNewlines], a
    ld a, [wPenStartingPosition]
    and SCRN_VX_B - 1
    ld c, a ; Get offset from column 0
    ld a, e
    and -SCRN_VX_B ; Get to column 0
    add a, c ; Get to starting column
    add a, SCRN_VX_B ; Go to next row (this might overflow)
    ld e, a
    jr nc, .nocarry
    inc d
.nocarry
    ld c, [hl] ; Get back tile ID
    xor a ; Clear this newline tile
    ld [hli], a ; Go to the next newline (if any)
    jr .writeNewTile

.finalNewline
    ld a, [wNbNewlines]
    dec a
    ld [wNbNewlines], a
    xor a
    ld [hli], a ; Clear that
    ld a, [wPenStartingPosition]
    and SCRN_VX_B - 1
    ld b, a
    ld a, e
    and -SCRN_VX_B
    add a, b
    add a, SCRN_VX_B
    ld e, a
    jr nc, .tryAgain ; noCarry
    inc d
    jr .tryAgain



; Sets up the VWF engine to start printing text
; @param hl Pointer to the string to be displayed
; @param b  Bank containing the string
; @param a  Non-zero to flush the current string (use zero if you want to keep printing the same string)
PrintVWFText::
    and a ; Set Z flag for test below

    ; Write src ptr
    ld a, b
    ld [wTextSrcBank], a
    ld a, l
    ld [wTextSrcPtr], a
    ld a, h
    ld [wTextSrcPtr + 1], a

    ; Flag preserved from `and a`
    jr z, .dontFlush
    ; Don't flush if current tile is empty
    ld a, [wTextCurPixel]
    cp 2
    ; Flush buffer to VRAM
    call nc, FlushVWFBuffer
    ; Reset position always, though
    xor a
    ld [wTextCurPixel], a
.dontFlush

    ; Use black color by default (which is normally loaded into color #3)
    ld a, 3
    ld [wTextColorID], a

    ; Preserve the language but reset the decoration
    ld hl, wTextCharset
    ld a, [hl]
    and $F0
    ld [hl], a

    ; Set initial letter delay to 0, to start printing directly
    xor a
    ld [wTextNextLetterDelay], a
    ret

; Prints a VWF char (or more), applying delay if necessary
; Might print more than 1 char, eg. if wTextLetterDelay is zero
; Sets the high byte of the source pointer to $FF when finished
; **DO NOT CALL WITH SOURCE DATA IN FF00-FFFF, THIS WILL CAUSE AN EARLY RETURN!!
; Number of tiles to write to the tilemap is written in wFlushedTiles
PrintVWFChar::
    ld hl, wTextNextLetterDelay
    ld a, [hl]
    and a
    jr z, .delayFinished
    dec a
    ld [hl], a
    ret

.delayFinished
    ; xor a
    ld [wFlushedTiles], a

    ; Save current ROM bank
    ldh a, [hCurROMBank]
    push af

    ; Get ready to read char
    ld hl, wTextSrcBank
    ld a, [hli]
    rst bankswitch
    ld a, [hli]
    ld h, [hl]
    ld l, a

.setDelayAndNextChar
    ; Reload delay
    ld a, [wTextLetterDelay]
    ld [wTextNextLetterDelay], a

.nextChar
    ; Read byte from string stream
    ld a, [hli]
    and a ; Check for terminator
    jp z, .checkForReturn
    cp " "
    jp c, .controlChar

; Print char

    ; Save src ptr & letter ID
    push hl

    sub " "
    ld e, a

    ; Get ptr to charset table
    ld a, [wTextCharset]
    add a, a
    add a, LOW(CharsetPtrs)
    ld l, a
    adc a, HIGH(CharsetPtrs)
    sub l
    ld h, a
    ld a, [hli]
    ld b, [hl]
    ld c, a

    ; Get ptr to letter
    ld d, 0
    ld l, e
    ld h, d ; ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de ; * 9
    add hl, bc
    ld d, h
    ld e, l

    ; Get dest buffer ptr
    ld hl, wTextTileBuffer

    ld c, 8
.printOneLine
    ld a, [wTextCurPixel]
    ld b, a
    and a

    ld a, [de]
    inc de
    push de

    ld e, 0
    jr z, .doneShifting
.shiftRight
    rra ; Actually `srl a`, since a 0 bit is always shifted in
    rr e
    dec b
    jr nz, .shiftRight
.doneShifting
    ld d, a

    ld a, [wTextColorID]
    rra
    jr nc, .noLSB
    ld a, d
    or [hl]
    ld [hl], a

    ld a, l
    add a, $10
    ld l, a
    ld a, e
    or [hl]
    ld [hl], a
    ld a, l
    sub $10
    ld l, a
.noLSB
    inc hl

    ld a, [wTextColorID]
    and 2
    jr z, .noMSB
    ld a, d
    or [hl]
    ld [hl], a

    ld a, l
    add a, $10
    ld l, a
    ld a, e
    or [hl]
    ld [hl], a
    ld a, l
    sub $10
    ld l, a
.noMSB
    inc hl

    pop de
    dec c
    jr nz, .printOneLine

    ; Advance read by size
    ld hl, wTextCurPixel
    ld a, [de]
    add a, [hl]
    ld [hl], a

    ; Restore src ptr
    pop hl

.charPrinted
    ; Save src ptr
    ld a, l
    ld [wTextSrcPtr], a
    ld a, h
    ld [wTextSrcPtr + 1], a

    ; Check if flushing needs to be done
    ld a, [wTextCurPixel]
    sub 8
    jr c, .noTilesToFlush

    ; Move back by 8 pixels
    ld [wTextCurPixel], a
    ; Flush them to VRAM
    call FlushVWFBuffer
    ; Check if the second tile needs to be flushed as well (happens with characters 9 pixels wide)
    ; We might never use 9-px chars, but if we do, there'll be support for them ^^
    ld a, [wTextCurPixel]
    sub 8
    jr c, .flushed
    ld [wTextCurPixel], a
    call FlushVWFBuffer
.flushed

.noTilesToFlush
    ; If not printing next char immediately, force to flush
    ld a, [wTextNextLetterDelay]
    and a
    jp z, .setDelayAndNextChar
    dec a
    ld [wTextNextLetterDelay], a

.flushAndFinish
    ; Check if flushing is necessary
    ld a, [wTextCurPixel]
    cp 2
    jr c, .flushingNotNeeded

    ld a, [wTextCurTile]
    swap a
    ld h, a
    and $F0
    ld l, a
    ld a, h
    and $0F
    add a, $80
    ld h, a
    ld de, wTextTileBuffer
    ld c, $10
    call LCDMemcpySmall

.flushingNotNeeded
    ; Restore ROM bank
    pop af
    rst bankswitch
    ret


.checkForReturn
    ; Tell caller we're done (if we're not, this'll be overwritten)
    ld a, $FF
    ld [wTextSrcPtr + 1], a

    ; Check if stack is empty
    ld hl, wTextStackSize ; Ok to trash hl, it doesn't matter anyways
    ld a, [hl]
    add a, a ; Assuming this can't be > $7F (shouldn't be > 8 anyways)
    jr z, .flushAndFinish

    add a, [hl] ; *3
    dec [hl] ; Decrement entry count
    add a, LOW(wTextStack)
    ld l, a
    adc a, HIGH(wTextStack)
    sub l
    ld h, a
    ; hl points to first byte of free entry, so decrement
    dec hl

    ; Restore ROM bank
    ld a, [hld]
    rst bankswitch
    
    ; Read new src ptr
    ld a, [hld]
    ld l, [hl]
    ld h, a
    jp .nextChar


.controlChar
    ; Check if ctrl char is valid
    cp TEXT_BAD_CTRL_CHAR
    call nc, TextCtrlCharError

    ; Control char, run the associated function
    ld de, .charPrinted
    push de

    ; Push the func's addr (so we can preserve hl when calling)
    add a, a
    add a, LOW(.controlCharFuncs - 2)
    ld e, a
    adc a, HIGH(.controlCharFuncs - 2)
    sub e
    ld d, a
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    ld b, a
    push bc
    ret ; Actually jump to the function, passing `hl` as a parameter for it to read (and advance)


.controlCharFuncs
    dw TextSetLanguage
    dw TextRestoreLanguage
    dw TextSetDecoration
    dw TextRestoreDecoration
    dw TextSetColor
    dw TextPrintBlank
    dw TextJumpTo
    dw TextCall
    dw TextDelay
    dw TextNewline
    dw TextWaitButton
    dw TextClear
    dw TextHalt


TextDelay:
    ld a, [hli]
    ld [wTextNextLetterDelay], a
    ret


TextSetLanguage:
    ld de, wTextCharset
    ld a, [de]
    ld b, a
    ld [wPreviousLanguage], a
    ld a, b
    and $0F
    ld b, a
    ld a, [hli]
    swap a
    and $F0
    or b
    jr _TextSetCharset

TextRestoreLanguage:
    ld de, wTextCharset
    ld a, [de]
    and $0F
    ld b, a
    ld a, [wPreviousLanguage]
    and $F0
    or b
    jr _TextSetCharset

TextSetDecoration:
    ld de, wTextCharset
    ld a, [de]
    ld b, a
    ld [wPreviousDecoration], a
    ld a, b
    and $F0
    ld b, a
    ld a, [hli]
    and $0F
    or b
    jr _TextSetCharset

TextRestoreDecoration:
    ld de, wTextCharset
    ld a, [de]
    and $F0
    ld b, a
    ld a, [wPreviousDecoration]
    and $0F
    or b

_TextSetCharset:
    ld [de], a
    jr PrintNextCharInstant


TextSetColor:
    ld a, [hli]
    and 3
    ld [wTextColorID], a
    jr PrintNextCharInstant


TextPrintBlank:
    ld a, [hli]
    ld c, a
    ld a, [wTextCurPixel]
    add a, c
    ld c, a
    and $F8
    jr z, .noNewTiles
    rrca
    rrca
    rrca
    ld b, a
.printNewTile
    push bc
    call FlushVWFBuffer ; Preserves HL
    pop bc
    dec b
    jr nz, .printNewTile
.noNewTiles
    ld a, c
    and 7
    ld [wTextCurPixel], a
    jr PrintNextCharInstant


; Sets text ptr to given location (must be within same bank!)
TextJumpTo:
    ld a, [hli]
    rst bankswitch
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jr PrintNextCharInstant

; Start printing a new string, then keep writing this one
; NOTE: avoids corruption by preventing too much recursion, but this shouldn't happen at all
TextCall:
    ld a, [wTextStackSize]
    cp TEXT_STACK_CAPACITY
    call nc, TextStackOverflowError

    ; Read target ptr
    ld b, a ; Save current size for later (to get ptr to 1st free entry)
    inc a ; Increase stack size
    ld [wTextStackSize], a

    ; Get target ptr
    ld a, [hli]
    rst bankswitch
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a

    ; Get ptr to stack top (1st empty entry)
    ld a, b
    add a, a
    add a, b
    add a, LOW(wTextStack)
    ld c, a
    adc a, HIGH(wTextStack)
    sub c
    ld b, a
    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a
    inc bc
    ldh a, [hCurROMBank]
    ld [bc], a

    ; Get new src ptr
    ld h, d
    ld l, e
    jr PrintNextCharInstant


TextNewline:
    ; Flush the current tile if non-blank
    ld a, [wTextCurPixel]
    cp 2
    call nc, FlushVWFBuffer
    ; Reset position
    xor a
    ld [wTextCurPixel], a

    ld de, wNbNewlines
    ld a, [de]
    inc a
    ld [de], a
    dec a
    add a, LOW(wNewlineTiles)
    ld e, a
    adc a, HIGH(wNewlineTiles)
    sub e
    ld d, a
    ld a, [wTextCurTile]
    ld [de], a
    ; Fall through

PrintNextCharInstant:
    xor a
    ld [wTextNextLetterDelay], a
    ret


TextWaitButton:
    xor a ; FIXME: if other bits than 7 and 6 get used, this is gonna be problematic
    ld [wTextPaused], a
    ldh a, [hHeldButtons]
    and PADF_B
    jr nz, PrintNextCharInstant
    ldh a, [hPressedButtons]
    rra ; Get PADF_A
    jr c, PrintNextCharInstant
    ; If no button has been pressed, keep reading this char
    ; Ensure the engine reacts on the very next frame to allow swallowing buttons
    ld a, 1
    ld [wTextNextLetterDelay], a
    ; We know that text is running, so it's fine to overwrite this
    ld a, $40
    ld [wTextPaused], a
    ; Decrement src ptr so this char keeps getting read
    dec hl
    ret


TextHalt:
    ld a, [wTextPaused]
    set 7, a
    ld [wTextPaused], a
    ret


TextClear:
    push hl
    ldcoord hl, 1, 2, vTextboxTilemap
    ld bc, SCRN_X_B - 4
    call LCDMemsetSmallFromB
    ld l, LOW(SCRN_VX_B * 2 + 2)
    ld c, SCRN_X_B - 4
    call LCDMemsetSmallFromB

    ; Reset text printing
    ; Don't flush if current tile is empty
    ld a, [wTextCurPixel]
    cp 2
    ; Flush buffer to VRAM
    call nc, FlushVWFBuffer
    ; Reset position always, though
    xor a
    ld [wTextCurPixel], a
    ldcoord hl, 1, 2, vTextboxTilemap
    call SetPenPosition

    pop hl
    ret



FlushVWFBuffer::
    push hl

    ; Calculate ptr to next tile
    ld a, [wTextCurTile]
    swap a
    ld d, a
    and $F0
    ld e, a
    ld a, d
    and $0F
    add a, $80
    ld d, a

    ; Copy buffer 1 to VRAM, buffer 2 to buffer 1, and clear buffer 2
    ld hl, wTextTileBuffer
    ld bc, wTextTileBuffer + $10
.copyByte
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .copyByte
    ; Write tile buf to VRAM
    ld a, [hl]
    ld [de], a
    inc e ; Faster than inc de, guaranteed thanks to ALIGN[4]
    ; Copy second tile to first one
    ld a, [bc]
    ld [hli], a
    ; Clear second tile
    xor a
    ld [bc], a
    inc c

    ld a, l
    cp LOW(wTextTileBuffer + $10)
    jr nz, .copyByte

    ; Go to next tile
    ld hl, wTextCurTile
    ld a, [hl]
    inc a
    and $7F
    jr nz, .noWrap
    ld a, [wWrapTileID]
.noWrap
    ld [hl], a

    ld hl, wFlushedTiles
    inc [hl]
    pop hl
    ret



CharsetPtrs::
    dw LatinCharsetBasic
    ; TODO: add more charsets (bold, JP, etc.)


LatinCharsetBasic::
INCBIN "res/textbox/latin.font"
