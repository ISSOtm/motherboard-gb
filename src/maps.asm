INCLUDE "constants.asm"
INCLUDE "macros.asm"

HEADER_LIST equs ""
map_header: MACRO
\1Header::

TMP equs "{HEADER_LIST}\1;"
    PURGE HEADER_LIST
HEADER_LIST equs "{TMP}"
    PURGE TMP
ENDM

INCLUDE "maps/village.asm"
INCLUDE "maps/white_house.asm"

INCLUDE "maps/headers.asm" ; IMPORTANT: this MUST come after all `map_header` decls
