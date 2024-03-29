
TEXT_CONT_STR equ 0
TEXT_NEW_STR  equ 1


; Number of elements the text stack has room for
; Having more will cause a soft crash
; This must not exceeed $7F, as the return logic discards bit 7 when checking for zero
TEXT_STACK_CAPACITY = 8

; IMPORTANT NOTE REGARDING NEWLINES!!!
; DO NOT PRINT MORE THAN THIS NEWLINES AT ONCE
; THIS **WILL** CAUSE A BUFFER OVERFLOW
TEXT_NEWLINE_CAPACITY = 10


    enum_start
    enum_elem TEXT_NUL ; Terminator
    enum_elem TEXT_SET_LANG
    enum_elem TEXT_RESTORE_LANG
    enum_elem TEXT_SET_DECORATION
    enum_elem TEXT_RESTORE_DECORATION
    enum_elem TEXT_SET_COLOR
    enum_elem TEXT_BLANKS
    enum_elem TEXT_DELAY
    enum_elem TEXT_WAITBUTTON
    enum_elem TEXT_CLEAR
    enum_elem TEXT_NEWLINE ; '\n'
    enum_elem TEXT_HALT
    enum_elem TEXT_SCROLL
    enum_elem TEXT_WAITBUTTON_SCROLL
    enum_elem TEXT_BAD_CTRL_CHAR

    ; Reader-only control chars
    enum_elem SOFT_HYPHEN, $FD ; Ideally $AD because that's the Unicode code point
    enum_elem TEXT_JUMP, $FE
    enum_elem TEXT_CALL, $FF


    enum_start
    enum_elem LANGUAGE_ASCII
    enum_elem LANGUAGE_KATAKANA ; NYI
    enum_elem LANGUAGE_HIRAGANA ; NYI
    enum_elem LANGUAGE_KANJI ; NYI

    enum_start
    enum_elem DECORATION_NONE
    enum_elem DECORATION_BOLD
