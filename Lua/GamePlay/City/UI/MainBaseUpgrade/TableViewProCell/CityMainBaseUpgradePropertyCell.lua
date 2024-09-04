local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityMainBaseUpgradePropertyCell:BaseTableViewProCell
local CityMainBaseUpgradePropertyCell = class('CityMainBaseUpgradePropertyCell', BaseTableViewProCell)

function CityMainBaseUpgradePropertyCell:OnCreate()
    self._p_text_attribute = self:Text("p_text_attribute")
    self._p_text_attribute_old = self:Text("p_text_attribute_old")
    self._p_text_attribute_new = self:Text("p_text_attribute_new")
    self._trigger = self:AnimTrigger("")
end

---@param data {name:string, from:string, to:string}
function CityMainBaseUpgradePropertyCell:OnFeedData(data)
    self._p_text_attribute.text = data.name
    self._p_text_attribute_old.text = data.from
    self._p_text_attribute_new.text = data.to
    -- self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

return CityMainBaseUpgradePropertyCell