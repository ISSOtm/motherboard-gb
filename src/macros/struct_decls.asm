
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
