local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local NumberFormatter = require('NumberFormatter')

local I18N = require("I18N")

---@class CityLegoBuildingUIBuffDesc:BaseUIComponent
local CityLegoBuildingUIBuffDesc = class('CityLegoBuildingUIBuffDesc', BaseUIComponent)

function CityLegoBuildingUIBuffDesc:OnCreate()
    self._p_icon = self:Image("p_icon")
    self._p_text_buff_name = self:Text("p_text_buff_name")
    self._p_text_buff_value = self:Text("p_text_buff_value")
end

---@param data CityLegoBuildingUIBuffData
function CityLegoBuildingUIBuffDesc:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon)

    self._p_text_buff_name.text = data:GetName()
    self._p_text_buff_value.text = ModuleRefer.AttrModule:GetAttrValueShowTextByTypeWithSign(data.elementId, data.originValue, 2)
end

return CityLegoBuildingUIBuffDesc