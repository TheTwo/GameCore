local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainFacilityCategoryCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainFacilityCategoryCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainFacilityCategoryCell = class('AllianceTerritoryMainFacilityCategoryCell', BaseTableViewProCell)

function AllianceTerritoryMainFacilityCategoryCell:OnCreate(param)
    self._p_text_facility = self:Text("p_text_facility")
    self._p_btn_facility = self:Button("p_btn_facility", Delegate.GetOrCreate(self, self.OnClickFold))
    self._p_icon_arrow_a_facility = self:GameObject("p_icon_arrow_a_facility")
    self._p_icon_arrow_b_facility = self:GameObject("p_icon_arrow_b_facility")
end

---@param data AllianceTerritoryMainFacilityCategoryCellData
function AllianceTerritoryMainFacilityCategoryCell:OnFeedData(data)
    self._data = data
    self._p_text_facility.text = data.titleContent
    self._p_icon_arrow_a_facility:SetVisible(not self._data:IsExpanded())
    self._p_icon_arrow_b_facility:SetVisible(self._data:IsExpanded())
end

function AllianceTerritoryMainFacilityCategoryCell:OnClickFold()
    self._data:SetExpanded(not self._data:IsExpanded())
    self:GetTableViewPro():UpdateData(self._data)
end

return AllianceTerritoryMainFacilityCategoryCell