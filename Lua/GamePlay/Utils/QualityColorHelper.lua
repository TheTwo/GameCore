local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local QualityColorHelper = {}

local Type = {
    Hero = 1,
    Equip = 2,
    Pet = 3,
    Radar = 4,
    Item = 5,
    Furniture = 6,
    Adornment = 7
}

QualityColorHelper.Type = Type

local Offset = {
    [Type.Hero] = 2,
    [Type.Equip] = 0,
    [Type.Pet] = 2,
    [Type.Radar] = 2,
    [Type.Item] = 0,
    [Type.Furniture] = 0,
    [Type.Adornment] = 2,
}

local QualityColor = {
    ColorConsts.quality_white,
    ColorConsts.quality_green,
    ColorConsts.quality_blue,
    ColorConsts.quality_purple,
    ColorConsts.quality_orange,
}

local QualityFrame = {
    [Type.Hero] = "sp_hero_frame_circle_%d",
    [Type.Item] = "sp_item_frame_circle_%d",
}

function QualityColorHelper.GetSpHeroFrameCircleImg(quality)
    quality = checknumber(quality)
    return ("sp_hero_frame_circle_%d"):format(math.clamp(quality, 1, 5))
end

function QualityColorHelper.GetOffsetQuality(quality, type)
    return math.clamp(quality + Offset[type], 1, 5)
end

---@param quality number @直接传入从配置中读到的品质数值，无需+-
---@param type number
---@return string
function QualityColorHelper.GetQualityColorStr(quality, type)
    return QualityColor[math.clamp(quality + Offset[type], 1, 5)]
end

---@param quality number @直接传入从配置中读到的品质数值，无需+-
---@param type number
---@return CS.UnityEngine.Color
function QualityColorHelper.GetQualityColor(quality, type)
    local colorStr = QualityColorHelper.GetQualityColorStr(quality, type)
    return UIHelper.TryParseHtmlString(colorStr)
end

---@param quality number @直接传入从配置中读到的品质数值，无需+-
---@param offsetType number
---@param iconType number | nil
---@return string
function QualityColorHelper.GetQualityCircleBaseIcon(quality, offsetType, iconType)
    quality = math.clamp(quality + Offset[offsetType], 1, 5)
    local str = QualityFrame[iconType or offsetType] or "sp_hero_frame_circle_%d"
    return (str):format(quality)
end

return QualityColorHelper