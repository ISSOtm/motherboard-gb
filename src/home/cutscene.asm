
; read_bytecode_byte temp_reg (default c)
read_bytecode_byte: macro
    IF _NARG < 1
TMP_REG equs "c"
    ELSE
TMP_REG equ "\1"
    ENDC

    ld hl, wCutscenePtr
    ld a, [hl]
    inc [hl]
    inc hl
    ld TMP_REG, [hl]
    jr nz, .noCarry\@
    inc [hl]
.noCarry\@
    ld h, TMP_REG
    ld l, a
    ld a, [hl]

    PURGE TMP_REG
endm

SECTION "Cutscene functions", ROM0,ALIGN[8]

CutsceneFuncTable:
    dw EndCutscene
    dw SetPlayerButtonMask
    dw StartDrawingText
    dw SyncWithText
    dw UnhaltText
    dw CutsceneLoadMap
    dw CutsceneJump
    dw CutsceneCall
    dw CutsceneEI
    dw CutsceneDI
.end
REPT $80 - (.end - CutsceneFuncTable) / 2
    dw CutsceneCommandError
ENDR

; Process the active cutscene
; Must preserve hl as per its caller
; @param a The bank of the active cutscene
ProcessCutscene::
    push hl
    rst bankswitch

    ; BEGIN BYTECODE INTERPRETER

.again
    read_bytecode_byte
    ldh [hCutsceneCurrentCommand], a
    add a, a
    ld l, a
    ld h, HIGH(CutsceneFuncTable)
    call JumpToPtr
    ldh a, [hCutsceneCurrentCommand]
    add a, a
    jr c, .again

    ; Restore state for the caller
    pop hl
    ld a, BANK(OverworldStatePtrs)
    rst bankswitch
    ret


EndCutscene:
    ld a, [wCutsceneStackPtr]
    and a
    jr nz, .return
    ; Stack empty
    ; xor a
    ld [wCutsceneBank], a
    ret

.return
    ld l, a
    ld h, HIGH(wCutsceneStackPtr)
    ld de, wCutsceneBank
    ld a, [hld]
    ld [de], a
    dec e ; dec de
    ld a, [hld]
    ld [de], a
    dec e ; dec de
    ld a, [hld]
    ld [de], a
    ld a, l
    ld [wCutsceneStackPtr], a
    ret

SetPlayerButtonMask:
    read_bytecode_byte
    ld [wPlayerInputsMask], a
    ret

StartDrawingText:
    ld a, (vVWFTiles - _VRAM) / 16
    ld [wWrapTileID], a
    ld [wTextCurTile], a ; Force current text tile to be in range
    ld a, (SCRN_X_B - 4) * 8
    ld [wTextLineLength], a
    ld a, 2
    ld [wTextNbLines], a
    ld [wTextRemainingLines], a

    read_bytecode_byte
    ld [wTextSrcPtr], a
    ld e, a
    read_bytecode_byte
    ld [wTextSrcPtr+1], a
    ld d, a
    read_bytecode_byte
    ld [wTextSrcBank], a
    ld b, a
    ld h, d
    ld l, e
    xor a
    ld [wTextStackSize], a
    inc a ; ld a, 1
    ld [wTextLetterDelay], a
    ; ld a, 1 ; Flush the string
    call PrintVWFText
    ldcoord hl, 1, 2, vTextboxTilemap
    call SetPenPosition
    ld a, BANK(OpenTextbox)
    rst bankswitch
    jp OpenTextbox


SyncWithText:
    ld a, [wTextSrcPtr+1]
    inc a
    ret z
    ld a, [wTextPaused]
    add a, a
    ret c
DecrementCutscenePtr:
    ; Disable instantness because it would softlock
    xor a
    ldh [hCutsceneCurrentCommand], a
    ; Loop on this byte until sync is achieved
    ld hl, wCutscenePtr
    dec [hl]
    ld a, [hli]
    inc a
    ret nz
    dec [hl]
    ret


UnhaltText:
    ld hl, wTextPaused
    res 7, [hl]
    ret


CutsceneLoadMap:
    read_bytecode_byte
    ld [wTargetMap], a
    read_bytecode_byte
    ld [wTargetWarp], a
    read_bytecode_byte
    srl a
    ld [wFadeDelay], a
    sbc a, a
    ld [wFadeType], a
    ld a, OVERWORLD_LOAD_MAP
    ld [wFollowingState], a
    ld a, OVERWORLD_FADE_OUT
    ld [wNextState], a
    ret


pop_operand: macro
    dec b
    jp z, RPNExpressionError
    pop \1
endm

RPNlt:
    pop_operand hl
    ; Check if hl < de
    ld a, d
    cp h
    ld d, 0
    jr c, .gte  ; de < hl
    jr nz, .ok  ; de > hl
    ; h = d, so check if l < e
    ld a, l
    cp e
    jr nc, .gte  ; l >= e ==> hl >= de
.ok
    inc d
.gte
    ld e, d
    jr CutsceneJump.evalRPN

RPNlte:
    pop_operand hl
    ; Check if hl <= de
    ld a, d
    cp h
    ld d, 0
    jr c, .gt   ; de < hl
    jr nz, .ok  ; de > hl
    ; h = d, so check if l <= e
    ld a, l
    scf
    sbc e
    jr nc, .gt  ; l >= e+1 ==> l > e ==> hl > de
.ok
    inc d
.gt
    ld e, d
    jr CutsceneJump.evalRPN

RPNsub:
    pop_operand hl
    ld a, l
    sub e
    ld e, a
    ld a, h
    sbc d
    ld d, a
    jr CutsceneJump.evalRPN

RPNeq:
    pop_operand hl
    ld a, h
    cp d
    ld d, 0
    jr nz, .ne
    ld a, l
    cp e
    jr nz, .ne
    inc d
.ne
    ld e, d
    jr CutsceneJump.evalRPN

RPNbAnd:
    pop_operand hl
    ld a, e
    and l
    ld e, a
    ld a, d
    and h
    ld d, a
    jr CutsceneJump.evalRPN

RPNbOr:
    pop_operand hl
    ld a, e
    or l
    ld e, a
    ld a, d
    or h
    ld d, a
    jr CutsceneJump.evalRPN

RPNbXor:
    pop_operand hl
    ld a, e
    xor l
    ld e, a
    ld a, d
    xor h
    ld d, a
    jr CutsceneJump.evalRPN

RPNrsh:
    pop_operand hl
.shiftRight
    rrc d
    rr h
    rr l
    dec e
    jr nz, .shiftRight
    ld d, h
    ld e, l
    jr CutsceneJump.evalRPN

CutsceneJump:
    ld b, 1 ; Number of entries on the stack, plus one
.evalRPN
    read_bytecode_byte
    add a, a
    jr z, .done
    jr nc, .operator
    push de
    inc b
    ld hl, wCutscenePtr
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    ld a, l
    ld [wCutscenePtr], a
    ld a, h
    ld [wCutscenePtr+1], a
    jr .evalRPN

.add
    pop_operand hl
    add hl, de
    ld d, h
    ld e, l
    jr CutsceneJump.evalRPN

.not
    ld a, e
    or d
    ld e, 1
    jr z, .zero
    dec e
.zero
    ld d, e
    jr CutsceneJump.evalRPN

.lAnd
    pop_operand hl
    ld a, d
    or e
    jr z, .evalRPN
    ld a, h
    or l
    jr nz, .evalRPN ; de non-zero already
    ld de, 0
    jr .evalRPN

.lOr
    pop_operand hl
    ld a, d
    or e
    jr nz, .evalRPN
    ld a, h
    or l
    jr z, .evalRPN ; de zero already
    inc e ; ld de, 1
    jr .evalRPN

.lsh
    pop_operand hl
.shiftLeft
    rlc d
    rl l
    rl h
    dec e
    jr nz, .shiftLeft
    ld d, h
    ld e, l
    jr .evalRPN

.deref
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld d, a
    ld e, l
    jr .evalRPN

.operator
    dec a
    dec a
    and $0F << 1
    add a, LOW(.opTable)
    ld l, a
    adc a, HIGH(.opTable)
    sub l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jp hl ; Safe because the entire table is controlled

.done
    dec b
    pop hl
    dec b
    jp nz, RPNExpressionError
    ld a, d
    or e
    ld hl, wCutscenePtr
    jr z, .jumpNotTaken
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, [hl]
    ld hl, wCutsceneBank
    ld [hld], a
    ld a, d
    ld [hld], a
    ld [hl], e
    ret
.jumpNotTaken
    ld a, [hl]
    add a, 3
    ld [hli], a
    ret nc
    inc [hl]
    ret

.opTable
    dw .add
    dw RPNsub
    dw .not
    dw RPNbAnd
    dw RPNbOr
    dw RPNbXor
    dw RPNlt
    dw RPNlte               ; 8
    dw RPNeq
    dw .lAnd
    dw .lOr
    dw .lsh
    dw RPNrsh
    dw .deref
    dw RPNExpressionError
    dw RPNExpressionError ; 16


CutsceneCall:
    ; Pointer reading is done below (from `de`), so advance the pointer instead
    ld hl, wCutscenePtr+1
    ld a, [hld]
    ld c, [hl]
    ld b, a
    ld a, c
    add a, 3
    ld [hli], a
    jr nc, .noCarry
    inc [hl]
.noCarry

; Start a cutscene, or at least attempt to
; @param bc A pointer to a far pointer to the cutscene to be started
StartCutscene::
    ld a, [wCutsceneBank]
    and a
    jr z, .starting
    ld hl, wCutsceneStackPtr
    ld l, [hl]
    inc l ; inc hl
    ld de, wCutscenePtr
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hl], a
    ld a, l
    ld [wCutsceneStackPtr], a

.starting
    ld hl, wCutscenePtr
    ld a, [bc]
    ld [hld], a
    inc bc
    ld a, [bc]
    ld [hld], a
    inc bc
    ld a, [bc]
    ld [hl], a
    ret

CutsceneEI:
    ld a, 1
    db $06 ; ld b, imm8
CutsceneDI:
    xor a
    ld [wCutsceneIME], a
    ret


PURGE read_bytecode_byte
