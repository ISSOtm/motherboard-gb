
; dbr value, nb_times
; Writes nb_times consecutive bytes with value.
dbr: MACRO
    REPT \2
        db \1
    ENDR
ENDM

; dwr value, nb_times
; Writes nb_times consecutive words with value.
dwr: MACRO
    REPT \2
        dw \1
    ENDR
ENDM

; dwbe value
; Writes the given word, but big-endian
dwbe: MACRO
    db HIGH(\1), LOW(\1)
ENDM

; dbankw label
; Writes the label's bank then address
dbankw: MACRO
    IF "\1" == "NULL"
        db 1 ; The bank doesn't matter, but 1 guarantees no BGB exception
        dw 0
    ELSE
        db BANK(\1)
        dw \1
    ENDC
ENDM

; db's everything given to it, and terminates with a NUL
; For strings, obviously.
dstr: MACRO
    REPT _NARG
        db \1
        shift
    ENDR
    db 0
ENDM

; Places a sprite's data, but with screen coords instead of OAM coords
dspr: MACRO
    db LOW(\1 + 16)
    db LOW(\2 + 8)
    db \3
    db \4
ENDM

; dwcoord y, x, base
dwcoord: MACRO
    dw (\1) * SCRN_VX_B + (\2) + (\3)
ENDM

; dptr symbol
; Places a symbol's bank and ptr
;
; dptr symbol_b, symbol_p
; Places a symbol's bank and another's ptr
; Useful for expressions: `dptr Label, Label+1`
dptr: MACRO
    db BANK(\1)
    IF _NARG < 2
        dw \1
    ELSE
        dw \2
    ENDC
ENDM


lda: MACRO
    IF \1 == 0
        xor a
    ELSE
        ld a, \1
    ENDC
ENDM

lb: MACRO
    ld \1, ((\2) << 8) | (\3)
ENDM

ln: MACRO
REGISTER\@ = \1
VALUE\@ = 0
INDEX\@ = 1
    REPT _NARG
        shift
INDEX\@ = INDEX\@ + 1
        IF \1 > $0F
            FAIL "Argument {INDEX} to `ln` must be a 4-bit value!"
        ENDC
VALUE\@ = VALUE\@ << 8 | \1
    ENDR

    ld REGISTER\@, VALUE\@

PURGE REGISTER\@
PURGE VALUE\@
PURGE INDEX\@
ENDM

; ldcoord reg16, y, x, base
ldcoord: MACRO
    IF "\1" == "bc"
        db $01
    ELIF "\1" == "de"
        db $11
    ELIF "\1" == "hl"
        db $21
    ELIF "\1" == "sp"
        db $31
    ELSE
        FAIL "Invalid 1st operand to ldcoord, \1 is not a 16-bit register"
    ENDC
    dwcoord \2, \3, \4
ENDM


; sgb_packet packet_type, nb_packets, packet_data...
sgb_packet: MACRO
    db (\1 << 3) | (\2)
NB_REPT = _NARG + (-2)

    REPT NB_REPT
        SHIFT
        db \2
    ENDR
    PURGE NB_REPT
ENDM

; sgb_packet_padded packet_type, nb_packets, packet_data...
sgb_packet_padded: MACRO
SGBPacket:
    db (\1 << 3) | (\2)
NB_REPT = _NARG + (-2)

    REPT NB_REPT
        SHIFT
        db \2
    ENDR
    PURGE NB_REPT
.end
PACKET_SIZE = .end - SGBPacket
    IF PACKET_SIZE % SGB_PACKET_SIZE != 0
        dbr 0, SGB_PACKET_SIZE - PACKET_SIZE
    ENDC

    PURGE .end
    PURGE SGBPacket
    PURGE PACKET_SIZE
ENDM


; pad_align baseLabel, alignment (nbBytes), offset
pad_align: MACRO
Padding\@:
PADDING_AMOUNT = (Padding\@ - \1 + \3) % \2
IF PADDING_AMOUNT
    ds \2 - PADDING_AMOUNT ; Padding to get alignment below
ELSE
    PURGE Padding\@
ENDC
    PURGE PADDING_AMOUNT
ENDM


trim_str: macro
    IF STRSUB("{\1}", 1, 1) == " "
TMP_STR\@ equs STRSUB("{\1}", 2, STRLEN("{\1}") - 1)
        PURGE \1
\1 equs "{TMP_STR\@}"
        PURGE TMP_STR\@
        trim_str \1
    ELIF STRSUB("{\1}", STRLEN("{\1}"), 1) == " "
TMP_STR\@ equs STRSUB("{\1}", 1, STRLEN("{\1}") - 1)
        PURGE \1
\1 equs "{TMP_STR\@}"
        PURGE TMP_STR\@
        trim_str \1
    ENDC
endm

pop_token: macro
    IF DEF(TOKEN)
        PURGE TOKEN
    ENDC

SPACE_POS equ STRIN("{\1}", " ")
    IF SPACE_POS == 0
TOKEN equs "{\1}"
        PURGE \1
\1 equs ""
    ELSE
TOKEN equs STRSUB("{\1}", 1, SPACE_POS + (-1))
TMP\@ equs STRSUB("{\1}", SPACE_POS + 1, STRLEN("{\1}") - SPACE_POS)
        PURGE \1
\1 equs "{TMP\@}"
        PURGE TMP\@
        trim_str \1
    ENDC
    PURGE SPACE_POS
endm

count_tokens: macro
NB_TOKENS = 0
    IF "{\1}" != ""
\1_copy\@ equs "{\1}"
        trim_str \1_copy\@
        count_tokens_internal \1_copy\@
    ENDC
endm

count_tokens_internal: macro
    IF "{\1}" != ""
NB_TOKENS = NB_TOKENS + 1
        pop_token \1
        count_tokens_internal \1
    ENDC
endm
