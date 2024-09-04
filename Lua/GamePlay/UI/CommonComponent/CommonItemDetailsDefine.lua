---@class CommonItemDetailsDefine
local ColorConsts = require("ColorConsts")
local CommonItemDetailsDefine = {}

---@class CommonItemDetailsDefine.ITEM_TYPE:number
CommonItemDetailsDefine.ITEM_TYPE = {
    ITEM = 1,
    EQUIP = 2,
    BUILDING = 3,
    FURNITURE = 4,
    DRAWING = 5
}

---@class CommonItemDetailsDefine.SHOW_TYPE:number
CommonItemDetailsDefine.SHOW_TYPE = {
    HORIZONTAL = 1,
    VERTICAL = 2,
}

---@class CommonItemDetailsDefine.COMPARE_TYPE:number
CommonItemDetailsDefine.COMPARE_TYPE = {
    LEFT_OWN_RIGHT_COST = 1,
    OVERFLOW = 2,
    LEFT_COST_RIGHT_OWN = 3,
}

---@class CommonItemDetailsDefine.TEXT_COLOR:string
CommonItemDetailsDefine.TEXT_COLOR = {
    WHITE = '#F1E6E0',
    GREEN = '#9AE750',
    RED = '#FF3F2B',
    GREEN_2 = '#488A02',
    BLACK = '#000000',
    RED_2 = '#B8120E',
}

CommonItemDetailsDefine.TEXT_COLOR_1 = {
    GREEN = "#6d9d3a",
    RED = "#b8120e",
    WHITE = "#242630",
}

CommonItemDetailsDefine.TEXT_COLOR_2 = {
    GREEN = ColorConsts.quality_green,
    RED = ColorConsts.warning,
    WHITE = ColorConsts.black,
}

return CommonItemDetailsDefine