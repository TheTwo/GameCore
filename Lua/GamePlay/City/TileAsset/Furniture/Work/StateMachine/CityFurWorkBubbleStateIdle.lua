local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateIdle:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateIdle
local CityFurWorkBubbleStateIdle = class("CityFurWorkBubbleStateIdle", CityFurWorkBubbleStateBase)

function CityFurWorkBubbleStateIdle:GetName()
    return CityFurWorkBubbleStateBase.Names.Idle
end

function CityFurWorkBubbleStateIdle:GetPrefabName()
    return string.Empty
end

return CityFurWorkBubbleStateIdle