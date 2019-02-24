
instant: macro
MACRO_STRING equs "\1"
    REPT _NARG + (-1)
TMP equs "{MACRO_STRING}"
        SHIFT
        PURGE MACRO_STRING
MACRO_STRING equs "{TMP}, \1"
        PURGE TMP
    ENDR

CUTSCENE_INSTANT equ 0
    MACRO_STRING
    PURGE MACRO_STRING
endm

cutscene_db: macro
    IF DEF(CUTSCENE_INSTANT)
        PURGE CUTSCENE_INSTANT
        db \1 | $80
    ELSE
        db \1
    ENDC
endm


    enum_start

    enum_elem CUTSCENE_END
end_cutscene: macro
    cutscene_db CUTSCENE_END
endm

    enum_elem CUTSCENE_SET_BTN_MASK
; set_btn_mask button_mask
; Bits reset are ignored buttons
set_btn_mask: macro
    cutscene_db CUTSCENE_SET_BTN_MASK
    db \1
endm

    enum_elem CUTSCENE_START_TEXT
; cutscene_text TextLabel
cutscene_text: macro
    cutscene_db CUTSCENE_START_TEXT
    dw \1
    db BANK(\1)
endm

    enum_elem CUTSCENE_SYNC_TEXT
; Sync with text engine: wait until it's halted or finished
cutscene_text_sync: macro
    cutscene_db CUTSCENE_SYNC_TEXT
endm

    enum_elem CUTSCENE_UNHALT_TEXT
; Unhalt text engine
; You should probably wait until it's halted using `cutscene_text_sync`
cutscene_unhalt_text: macro
    cutscene_db CUTSCENE_UNHALT_TEXT
endm

    enum_elem CUTSCENE_LOAD_MAP
; load_map map_id, warp_id, fade_delay, to_black?
; Load a new map
; to_black must be 0 (white) or **exactly** 1 (black)
load_map: macro
    cutscene_db CUTSCENE_LOAD_MAP
    db \1, \2
    db \3 << 1 | \4
endm

    enum_elem CUTSCENE_JUMP
; cutscene_jump dest [, expr]
; Jump to the destination always, or when the expression evaluates to non-zero
; TODO: implement RPN evaluator
cutscene_jump: macro
    db CUTSCENE_JUMP
    IF _NARG > 1
RPN_STRING equs \2
        trim_str RPN_STRING
        ; RGBDS doesn't have a `while`-like structure
        ; Thus, we need to compute the number of tokens and REPT that
        count_tokens RPN_STRING
        REPT NB_TOKENS
            pop_token RPN_STRING
            ; The single quotes serve as separators and padding
RPN_OPER = STRIN("+'''-'''!'''&'''|'''^'''<'''<=''==''&&''||''<<''>>''['''", "{TOKEN}'") + 3
            IF RPN_OPER != 3
                ; Operator
                db RPN_OPER / 4
            ELSE
                ; Immediate
                db $81
                dw TOKEN
            ENDC
        ENDR
        PURGE RPN_STRING
        PURGE RPN_OPER
        PURGE TOKEN
        PURGE NB_TOKENS
    ELSE
        db $81
        dw 1
    ENDC
    db 0
    db LOW(\1)
    db BANK(\1)
    db HIGH(\1)
endm
