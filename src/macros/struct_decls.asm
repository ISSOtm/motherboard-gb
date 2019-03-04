
    struct Menu
    bytes 1, Bank ; ROM bank where everything is located
    words 1, InitFunc
    bytes 1, ButtonMask ; Mask applied to hPressedButtons and hHeldButtons
    bytes 1, EnableRepeatPress ; Set to non-zero to make direction buttons auto-repeat (hold for more than half a second to press every other frame)
    words 8, ButtonHooks ; Pointers to functions to be run each time a button is pressed
    bytes 1, PrevSelectedItem ; Item selected on previous frame
    bytes 1, AllowWrapping ; Bit 0 non-zero to allow wrapping. NOTE: could be used for other flags, too
    bytes 1, SelectedItem ; Holds the default selected item in ROM, then is modified in RAM
    bytes 1, Size ; Number of items in the menu
    words 1, RedrawFunc ; Function called on every frame after buttons have been processed
    words 1, ItemsPtr ; Pointer where the menu's items are located (might be anything, that's left for the redraw function to decide)
    words 1, ClosingFunc ; Function to be called when the menu is closed

    bytes 0, ROMSize ; MenuROMSize = number of bytes to copy
    ; Work memory, not stored in ROM
    bytes 1, RepeatPressCounter ; Tracks for how many frames RepeatPress has been in effect (loops between 30 and 31, though) Every time the counter hits 32, it's reset to 31 and the button is "pressed"
    bytes 2, MiscState ; The struct is allowed to do anything with this (frame counter, state, etc.)
    end_struct


    struct NPC
    bytes 1, YSubPos
    words 1, YPos
    bytes 1, XSubPos
    words 1, XPos
    bytes 1, DisplayType
    bytes 1, DisplayCounter
    bytes 1, BaseTileID
    bytes 1, BaseAttr
    bytes 1, DisplayStructBank
    words 1, DisplayStructPtr
    bytes 1, Status
    words 1, ProcessingPtr
    end_struct


    struct Trigger
    bytes 1, Type
    words 1, YPos
    bytes 1, YSize
    words 1, XPos
    bytes 1, XSize
    bytes 1, ArgPtr
    end_struct


    struct CutsceneStackEntry
    bytes 1, Instruction
    bytes 1, Bank
    words 1, Ptr
    end_struct
