local ColorConsts = require("ColorConsts")

local BistateButtonDefine = {}

BistateButtonDefine.BUTTON_TYPE = {
    BROWN = 1,
    PINK = 2,
    RED = 3,
}

BistateButtonDefine.BTN_INFO  = {
    {baseIcon = "sp_btn_brown_nml_l_u2",
    textColor = ColorConsts.off_white,
    lackTextColor = ColorConsts.army_red,},
    {baseIcon = "sp_btn_green_nml_l_u2",
    textColor = ColorConsts.white,
    lackTextColor = ColorConsts.warning,},
    {baseIcon = "sp_btn_c_nml_l_u2",
    textColor = ColorConsts.off_white,
    lackTextColor = ColorConsts.army_red,},
}

return BistateButtonDefine