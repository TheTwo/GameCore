local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require("I18N")

---@class CityMainBaseUpgradeUILvCell:BaseTableViewProCell
local CityMainBaseUpgradeUILvCell = class('CityMainBaseUpgradeUILvCell', BaseTableViewProCell)

function CityMainBaseUpgradeUILvCell:OnCreate()
    self._p_text_content_1 = self:Text("p_text_content_1")
    self._trigger = self:AnimTrigger("")
end

---@param param {content:string}
function CityMainBaseUpgradeUILvCell:OnFeedData(param)
    self._p_text_content_1.text = param.content
    -- self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

return CityMainBaseUpgradeUILvCell