---@class CityLegoBuildingUIBuffData
---@field new fun(elementId, value, originValue, icon, prefix):CityLegoBuildingUIBuffData
local CityLegoBuildingUIBuffData = class("CityLegoBuildingUIBuffData")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

function CityLegoBuildingUIBuffData:ctor(elementId, value, originValue, icon, prefix)
    self.elementId = elementId
    self.value = value
    self.originValue = originValue
    self.icon = icon
    self.prefix = prefix
    self.elementCfg = ConfigRefer.AttrElement:Find(elementId)
end

function CityLegoBuildingUIBuffData:GetName()
    if self.prefix == nil then
        return I18N.Get(self.elementCfg:Name())
    else
        return I18N.GetWithParams(self.prefix, I18N.Get(self.elementCfg:Name()))
    end
end

return CityLegoBuildingUIBuffData