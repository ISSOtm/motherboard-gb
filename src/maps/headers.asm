
SECTION "Map headers", ROMX


MapHeaders::

CHAR_ID = 0
STARTING_CHAR = 1
NAME_LEN = 0
REPT STRLEN("{HEADER_LIST}")
CHAR_ID = CHAR_ID + 1
    IF STRCMP(STRSUB("{HEADER_LIST}", CHAR_ID, 1), ";")
        ; Append char to header name
NAME_LEN = NAME_LEN + 1
    ELSE
        ; Yield pointer to header
HEADER_NAME equs STRCAT(STRSUB("{HEADER_LIST}", STARTING_CHAR, NAME_LEN), "Header")
        db BANK(HEADER_NAME)
        dw HEADER_NAME
        PURGE HEADER_NAME
STARTING_CHAR = CHAR_ID + 1
NAME_LEN = 0
    ENDC
ENDR
PURGE CHAR_ID
