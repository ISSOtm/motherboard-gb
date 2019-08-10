
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
; @return a 0
; @return hl wTextCharset
; @return f NC and Z
; @destroy bc de
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
    ; TODO: decrease remaining amount of pixels
.dontFlush

    ; Force buffer refill
    ld a, LOW(wTextCharBufferEnd)
    ld [wTextReadPtrLow], a
    ; Initialize auto line-wrapper
    ld a, [wTextLineLength]
    inc a ; Last pixel of all chars is blank, so we can actually fit 1 extra
    ld [wLineRemainingPixels], a

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

; Prints a VWF char (or more), applying delay if necessary
; Might print more than 1 char, eg. if wTextLetterDelay is zero
; Sets the high byte of the source pointer to $FF when finished
; **DO NOT CALL WITH SOURCE DATA IN FF00-FFFF, THIS WILL CAUSE AN EARLY RETURN!!
; Number of tiles to write to the tilemap is written in wFlushedTiles
PrintVWFChar::
    ld hl, wTextNextLetterDelay
    ld a, [hl]
    and a
    jr nz, .delay
    ; xor a
    ld [wFlushedTiles], a

    ; Save current ROM bank
    ldh a, [hCurROMBank]
    push af

    ld a, BANK(_PrintVWFChar)
    rst bankswitch
    call _PrintVWFChar

    pop af
    rst bankswitch
    ret

.delay
    dec a
    ld [hl], a
    ret


RefillerOnlyControlChar:
    ld bc, _RefillCharBuffer
    push bc

    push hl
    add a, LOW(RefillerOnlyControlChars)
    ld l, a
    ld a, $FF ; If we're here, the value in A is negative
    adc a, HIGH(RefillerOnlyControlChars)
    ld h, a
    ld a, [hli]
    ld b, [hl]
    ld c, a
    pop hl
    push bc
    ret

RefillerControlChar:
    ld bc, _RefillCharBuffer.afterControlChar
    push bc
    inc e ; Otherwise the char isn't counted to be written!
    push hl
    add a, " "
    add a, a ; Can't be zero because we handle that earlier
    add a, LOW(RefillerControlChars - 2)
    ld l, a
    adc a, HIGH(RefillerControlChars - 2)
    sub l
    ld h, a
    ld a, [hli]
    ld b, [hl]
    ld c, a
    pop hl
    push bc
    ret

; Refills the char buffer, assuming at least half of it has been read
; Newlines are injected into the buffer to implement auto line-wrapping
; @param hl The current read ptr into the buffer
RefillCharBuffer:
    ld de, wTextCharBuffer
    ; First, copy remaining chars into the buffer
    ld a, LOW(wTextCharBufferEnd)
    sub l
    ld c, a
    jr z, .charBufferEmpty
.copyLeftovers
    ld a, [hli]
    ld [de], a
    inc e
    dec c
    jr nz, .copyLeftovers
.charBufferEmpty

    ; Cache charset ptr to speed up calculations
    ld a, [wTextCharset]
    ld [wRefillerCharset], a
    add a, a
    add a, LOW(CharsetPtrs)
    ld l, a
    adc a, HIGH(CharsetPtrs)
    sub l
    ld h, a
    ld a, [hli]
    add a, 8 ; Code later on will want a +8 offset
    ld [wCurCharsetPtr], a
    ld a, 0 ; If you try to optimize this to `xor a` I will kick you in the nuts
    adc a, [hl]
    ld [wCurCharsetPtr+1], a

    ; Get ready to read chars into the buffer
    ld hl, wTextSrcBank
    ld a, [hli]
    rst bankswitch
    ld a, [hli]
    ld h, [hl]
    ld l, a

_RefillCharBuffer:
.refillBuffer
    ld a, [hli]
    add a, a ; Test bit 7 and prepare for control char handling
    jr z, .tryReturning
    jr c, RefillerOnlyControlChar
    rra ; Restore A
    ld [de], a
    sub " "
    jr c, RefillerControlChar ; The refiller needs to be aware of some control chars

    ; Add char length to accumulated one
    push hl
    ld hl, wCurCharsetPtr
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, bc ; Char * 8 + base + 8
    ld c, a ; Stash this for later
    ld b, 0
    add hl, bc ; Char * 9 + base + 8
    ld a, [wLineRemainingPixels]
    sub a, [hl]
.insertCustomSize
    jr nc, .noNewline
    ld b, a ; Stash this for later
    ; Line length was overflowed, inject newline into buffer
    ; Get ptr to newline injection point
    ld h, d ; ld h, HIGH(wTextCharBuffer)
    ld a, [wNewlinePtrLow]
    ld l, a
    ; Dashes aren't overwritten on newlines, instead the newline is inserted right after
    ld a, [hl]
    cp " "
    ld d, "\n"
    jr z, .overwritingNewline
    ld a, e
    cp LOW(wTextCharBufferEnd - 1)
    jr z, .bufferFull
    inc e ; We're going to insert an extra char unless that would overflow the buffer
.bufferFull
.copyNewlinedChars
    ld a, d
    ld d, [hl]
    ld [hli], a
    ld a, e ; Stop when we're about to write the last char
    cp l
    jr nz, .copyNewlinedChars
    ; But write it, of course!
.overwritingNewline
    ld [hl], d
    ; Restore dest ptr high byte
    ld d, h ; ld d, HIGH(wTextCharBuffer)
    ; Get amount of pixels remaining on next line after we move a word to it
    ld a, [wNewlineRemainingPixels]
    sub b ; Get pixels that word has
    ld b, a
    ld a, [wTextLineLength]
    sub b ; Subtract that amount from a whole line's length
.noNewline
    ld [wLineRemainingPixels], a
    pop hl

    ld a, c
    ; If the character is a dash or a space, a newline can be inserted
    and a ; cp " " - " "
    jr z, .canNewline
    inc e ; This increment is also shared by the main loop
    cp "-" - " " ; Dashes aren't *overwritten* by the newline, instead it's inserted after
    ld a, e ; The increment has to be placed in an awkward way because it alters flags
    jr z, .canNewlineAfter

.afterControlChar
    ld a, e
    cp LOW(wTextCharBufferEnd)
    jr nz, .refillBuffer

.done
    ; Write src ptr for later
    ld a, l
    ld [wTextSrcPtr], a
    ld a, h
    ld [wTextSrcPtr+1], a
    ldh a, [hCurROMBank]
    ld [wTextSrcBank], a

    ld a, BANK(_PrintVWFChar)
    rst bankswitch
    ; Restart printer's reading
    ld hl, wTextCharBuffer
    ret


.tryReturning
    ld hl, wTextStackSize
    ld a, [hl]
    ld b, a
    add a, a
    ld [de], a ; If we're returning, we will need to write that $00; otherwise it'll be overwritten
    jr z, .done
    dec b
    ld [hl], b
    add a, b ; a = stack size * 3 + 2
    add a, LOW(wTextStack)
    ld l, a
    adc a, HIGH(wTextStack)
    sub l
    ld h, a
    ld a, [hld]
    rst bankswitch
    ld a, [hld]
    ld l, [hl]
    ld h, a
    jp .refillBuffer ; Too far to `jr`


.canNewline
    ld a, e
    inc e
.canNewlineAfter
    ld [wNewlinePtrLow], a
    ld a, [wLineRemainingPixels]
    ld [wNewlineRemainingPixels], a
    jr .afterControlChar


RefillerControlChars:
    dw ReaderSetLanguage
    dw ReaderRestoreLanguage
    dw ReaderSetDecoration
    dw ReaderRestoreDecoration
    dw Reader2ByteNop
    dw ReaderPrintBlank
    dw Reader2ByteNop
    dw Reader1ByteNop
    dw ReaderClear
    dw ReaderNewline
    dw Reader1ByteNop

    ; The base of the table is located at its end
    ; Unusual, I know, but it works better!
    dw ReaderJumpTo
    dw ReaderCall
RefillerOnlyControlChars:

Reader2ByteNop:
    ld a, [hli]
    ld [de], a
    inc e
Reader1ByteNop:
    ret

ReaderSetLanguage:
    ld a, [wRefillerCharset]
    ld c, a
    ld [wRefillerPrevLanguage], a
    ld a, [hli]
    ld [de], a
    inc e
    swap a
    xor c
    and $F0
    jr ReaderUpdateCharset

ReaderRestoreLanguage:
    ld a, [wRefillerCharset]
    and $0F
    ld c, a
    ld a, [wRefillerPrevLanguage]
    and $F0
    jr ReaderUpdateCharset

ReaderSetDecoration:
    ld a, [wRefillerCharset]
    ld c, a
    ld [wRefillerPrevDecoration], a
    ld a, [hli]
    ld [de], a
    inc e
    xor c
    and $0F
    jr ReaderUpdateCharset

ReaderRestoreDecoration:
    ld a, [wRefillerCharset]
    and $F0
    ld c, a
    ld a, [wRefillerPrevDecoration]
    and $0F
    ; Fall through
ReaderUpdateCharset:
    xor c
    ld [wRefillerCharset], a
    add a, a
    add a, LOW(CharsetPtrs)
    ld c, a
    adc a, HIGH(CharsetPtrs)
    sub c
    ld b, a
    ld a, [bc]
    ld [wCurCharsetPtr], a
    inc bc
    ld a, [bc]
    ld [wCurCharsetPtr+1], a
    ret

ReaderPrintBlank:
    pop bc ; We're not gonna return because we're gonna insert a custom size instead
    ld a, [hli] ; Read number of blanks
    ld [de], a
    ; inc e ; Don't increment dest ptr because the code path we'll jump into will do it
    ld c, a
    ld a, [wLineRemainingPixels]
    sub c
    ; We'll be jumping straight in the middle of some code path, make sure not to break it
    push hl
    ld c, "A" ; Make sure we won't get a newline
    jp _RefillCharBuffer.insertCustomSize ; Too far to `jr`

ReaderClear:
    ; For the purpose of line length counting, newline and clearing are the same
ReaderNewline:
    ; Reset line length, since we're forcing a newline
    ld a, [wTextLineLength]
    ld [wLineRemainingPixels], a
    ret

; Sets text ptr to given location
ReaderJumpTo:
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, b
    rst bankswitch
    ret

; Start printing a new string, then keep writing this one
; NOTE: avoids corruption by preventing too much recursion, but this shouldn't happen at all
ReaderCall:
    ld a, [wTextStackSize]
    cp TEXT_STACK_CAPACITY
    call nc, TextStackOverflowError

    ; Read target ptr
    inc a ; Increase stack size
    ld [wTextStackSize], a

    ; Get ptr to end of 1st empty entry
    ld b, a
    add a, a
    add a, b
    add a, LOW(wTextStack - 1)
    ld c, a
    adc a, HIGH(wTextStack - 1)
    sub c
    ld b, a
    ; Save ROM bank immediately, as we're gonna bankswitch
    ldh a, [hCurROMBank]
    ld [bc], a
    dec bc

    ; Swap src ptrs
    ld a, [hli]
    ld [de], a ; Use current byte in char buffer as scratch
    ; Save src ptr now (will require incrementing twice when returning but eh)
    ld a, h
    ld [bc], a
    dec bc
    ld a, l
    ld [bc], a
    ; Read new src ptr
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ; Perform bankswitch now that all bytecode has been read
    ld a, [de]
    rst bankswitch
    ret


SECTION "VWF ROMX functions + data", ROMX

_PrintVWFChar:
    ld h, HIGH(wTextCharBuffer)
    ld a, [wTextReadPtrLow]
    ld l, a

.setDelayAndNextChar
    ; Reload delay
    ld a, [wTextLetterDelay]
    ld [wTextNextLetterDelay], a

.nextChar
    ; First, check if the buffer is sufficiently full
    ; Making the buffer wrap would be costly, so we're keeping a safety margin
    ; Especially since control codes are multi-byte
    ld a, l
    cp LOW(wTextCharBufferEnd - 8)
    call nc, RefillCharBuffer

    ; Read byte from string stream
    ld a, [hli]
    and a ; Check for terminator
    jp z, .return
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

    ld a, 8
.printOneLine
    ldh [hVWFRowCount], a

    ld a, [wTextCurPixel]
    ld b, a
    and a ; Check now if shifting needs to happen

    ld a, [de]
    inc de

    ld c, 0
    jr z, .doneShifting
.shiftRight
    rra ; Actually `srl a`, since a 0 bit is always shifted in
    rr c
    dec b
    jr nz, .shiftRight
.doneShifting
    ld b, a

    ld a, [wTextColorID]
    rra
    jr nc, .noLSB
    ld a, b
    or [hl]
    ld [hl], a

    set 4, l
    ld a, c
    or [hl]
    ld [hl], a
    res 4, l

    ld a, [wTextColorID]
    rra
.noLSB
    inc l

    rra
    jr nc, .noMSB
    ld a, b
    or [hl]
    ld [hl], a

    set 4, l
    ld a, c
    or [hl]
    ld [hl], a
    res 4, l
.noMSB
    inc l

    ldh a, [hVWFRowCount]
    dec a
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
    ; Write back new read ptr into buffer for next iteration
    ld a, l
    ld [wTextReadPtrLow], a

.flushAndFinish
    ; Check if flushing is necessary
    ld a, [wTextCurPixel]
    cp 2
    ret c

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
    jp LCDMemcpySmall ; Tail call


.return
    ; Tell caller we're done (if we're not, this'll be overwritten)
    ld a, $FF
    ld [wTextSrcPtr + 1], a
    jr .flushAndFinish


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
    dw TextDelay
    dw TextWaitButton
    dw TextClear
    dw TextNewline
    dw TextHalt


TextDelay:
    ld a, [hli]
    ld [wTextNextLetterDelay], a
    ret


TextRestoreLanguage:
    ld de, wTextCharset
    ld a, [de]
    and $0F
    ld b, a
    ld a, [wPreviousLanguage]
    and $F0
    jr _TextSetCharset

TextRestoreDecoration:
    ld de, wTextCharset
    ld a, [de]
    and $F0
    ld b, a
    ld a, [wPreviousDecoration]
    and $0F
    jr _TextSetCharset

TextSetDecoration:
    ld de, wTextCharset
    ld a, [de]
    ld [wPreviousDecoration], a
    and $F0
    ld b, a
    ld a, [hli]
    and $0F
    jr _TextSetCharset

TextSetLanguage:
    ld de, wTextCharset
    ld a, [de]
    ld [wPreviousLanguage], a
    and $0F
    ld b, a
    ld a, [hli]
    swap a
    and $F0
_TextSetCharset:
    or b
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
    ; We know that text is running, so it's fine to overwrite bit 7
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



SECTION "Charset data", ROM0

CharsetPtrs::
    dw LatinCharsetBasic
    ; TODO: add more charsets (bold, JP, etc.)


LatinCharsetBasic::
INCBIN "res/textbox/latin.font"
