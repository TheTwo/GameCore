local CommonGotoDetailDefine = {}

CommonGotoDetailDefine.DISPLAY_MASK = {
    BTN_GOTO = 1 << 0,
    BTN_VIDEO = 1 << 1,
    BTN_REPLAY = 1 << 2,
    ALL = 0xFFFFFFFF,
}

CommonGotoDetailDefine.TYPE = {
    HERO = 1,
    PET = 2,
    GUIDE = 3,
}

return CommonGotoDetailDefine