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

; DO NOT REMOVE THE COMMENT LINES AROUND THIS, they are essential to gen_map_enum.py

;#BEGIN MAP DEFS
INCLUDE "maps/village.asm"
INCLUDE "maps/white_house.asm"
;#END MAP DEFS

INCLUDE "maps/headers.asm" ; IMPORTANT: this MUST come after all `map_header` decls
