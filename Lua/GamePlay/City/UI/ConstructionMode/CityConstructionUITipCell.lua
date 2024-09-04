local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require("I18N")

---@class CityConstructionUITipCell:BaseTableViewProCell
local CityConstructionUITipCell = class('CityConstructionUITipCell', BaseTableViewProCell)

function CityConstructionUITipCell:OnCreate()
    self._p_icon_addition = self:Image("p_icon_addition")
    self._p_text_addition = self:Text("p_text_addition")
    self._p_text_addition_add = self:Text("p_text_addition_add")
end

---@param data AttrTypeAndValue
function CityConstructionUITipCell:OnFeedData(data)
    local element = ConfigRefer.AttrElement:Find(data:TypeId())
    g_Game.SpriteManager:LoadSprite(element:Icon(), self._p_icon_addition)
    self._p_text_addition.text = I18N.Get(element:Name())
    self._p_text_addition_add.text = "+" .. ModuleRefer.AttrModule:GetAttrValueShowTextByType(element, data:Value())
end

function CityConstructionUITipCell:OnRecycle()

end

return CityConstructionUITipCell