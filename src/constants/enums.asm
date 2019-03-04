
set_enum_value: MACRO
enum_value = \1
ENDM

enum_start: MACRO
    IF _NARG == 0
        set_enum_value 0
    ELSE
        set_enum_value \1
    ENDC
ENDM

enum_elem: MACRO
    IF _NARG >= 2
        set_enum_value \2
    ENDC

\1 = enum_value
    set_enum_value enum_value+1
ENDM


; SGB packet types
    enum_start
    enum_elem PAL01
    enum_elem PAL23
    enum_elem PAL12
    enum_elem PAL03
    enum_elem ATTR_BLK
    enum_elem ATTR_LIN
    enum_elem ATTR_DIV
    enum_elem ATTR_CHR
    enum_elem SOUND    ; $08
    enum_elem SOU_TRN
    enum_elem PAL_SET
    enum_elem PAL_TRN
    enum_elem ATRC_EN
    enum_elem TEST_EN
    enum_elem ICON_EN
    enum_elem DATA_SND
    enum_elem DATA_TRN ; $10
    enum_elem MLT_REQ
    enum_elem JUMP
    enum_elem CHR_TRN
    enum_elem PCT_TRN
    enum_elem ATTR_TRN
    enum_elem ATTR_SET
    enum_elem MASK_EN
    enum_elem OBJ_TRN  ; $18


; Error IDs
    enum_start
    enum_elem ERROR_JUMP_HL
    enum_elem ERROR_JUMP_DE
    enum_elem ERROR_NULL_EXEC
    enum_elem ERROR_RST38
    enum_elem ERROR_CUTSCENE_COMMAND
    enum_elem ERROR_TEXT_STACK_OVERFLOW
    enum_elem ERROR_BAD_CTRL_CHAR
    enum_elem ERROR_RPN_EXPRESSION
    enum_elem ERROR_MENU_STACK_OVERFLOW
    enum_elem ERROR_MENU_STACK_EMPTY
    enum_elem ERROR_UNKNOWN


; Directions
    enum_start
    enum_elem DIR_UP
    enum_elem DIR_DOWN
    enum_elem DIR_LEFT
    enum_elem DIR_RIGHT


; Overworld states
    enum_start
    enum_elem OVERWORLD_IMPOSSIBLE
    enum_elem OVERWORLD_BEGIN
    enum_elem OVERWORLD_FADE_IN
    enum_elem OVERWORLD_FADE_OUT
    enum_elem OVERWORLD_LOAD_MAP
    enum_elem OVERWORLD_NORMAL


; Camera scrolling types
    enum_start
    enum_elem SCROLLING_4_WAY ; Required to be 0
    enum_elem SCROLLING_HORIZ ; Required to be 1
    enum_elem SCROLLING_VERT  ; Required to be 2


; Palette packet actions
    enum_start
    enum_elem PAL_PACK_ACTION_NONE
    enum_elem PAL_PACK_ACTION_RESTORE
    enum_elem PAL_PACK_ACTION_TEXTBOX_LAYOUT


; wPlayerStateChange bits
    enum_start 4
    ; These bits MUST be the upper 4!
    enum_elem RIGHT_HELD
    enum_elem LEFT_HELD
    enum_elem UP_HELD
    enum_elem DOWN_HELD

; Player states
    enum_start
    enum_elem PLAYER_STATE_STANDING_DOWN
    enum_elem PLAYER_STATE_STANDING_UP
    enum_elem PLAYER_STATE_STANDING_LEFT
    enum_elem PLAYER_STATE_STANDING_RIGHT
    enum_elem PLAYER_STATE_WALKING_DOWN
    enum_elem PLAYER_STATE_WALKING_UP
    enum_elem PLAYER_STATE_WALKING_LEFT
    enum_elem PLAYER_STATE_WALKING_RIGHT


; Menu actions
    enum_start
    enum_elem MENU_ACTION_NONE
    ; These are each button's default action
    enum_elem MENU_ACTION_MOVE_DOWN
    enum_elem MENU_ACTION_MOVE_UP
    enum_elem MENU_ACTION_MOVE_LEFT
    enum_elem MENU_ACTION_MOVE_RIGHT
    enum_elem MENU_ACTION_NONE_START ; Placeholder since START shouldn't do anything
    enum_elem MENU_ACTION_NONE_SELECT
    enum_elem MENU_ACTION_CANCEL
    enum_elem MENU_ACTION_VALIDATE
    ; These can only be triggered manually
    enum_elem MENU_ACTION_NEW_MENU ; Followed by a 3-byte pointer to the menu
    enum_elem MENU_ACTION_INVALID ; Any action greater than this is invalid, and does nothing

; Menu closing reasons
    enum_start
    enum_elem MENU_NOT_CLOSED
    enum_elem MENU_CANCELLED
    enum_elem MENU_VALIDATED
