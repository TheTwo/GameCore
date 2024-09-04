local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainCityCategoryCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainCityCategoryCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainCityCategoryCell = class('AllianceTerritoryMainCityCategoryCell', BaseTableViewProCell)

function AllianceTerritoryMainCityCategoryCell:OnCreate(param)
    self._p_text_city = self:Text("p_text_city")
    self._p_btn_city = self:Button("p_btn_city", Delegate.GetOrCreate(self, self.OnClickFold))
    self._p_icon_arrow_a_city = self:GameObject("p_icon_arrow_a_city")
    self._p_icon_arrow_b_city = self:GameObject("p_icon_arrow_b_city")
    self._p_btn_detail = self:Button("p_btn_detail")
    if self._p_btn_detail then
        self._p_btn_detail:SetVisible(false)
    end
end

---@param data AllianceTerritoryMainCityCategoryCellData
function AllianceTerritoryMainCityCategoryCell:OnFeedData(data)
    self._data = data
    self._p_text_city.text = data.titleContent
    self._p_icon_arrow_a_city:SetVisible(not self._data:IsExpanded())
    self._p_icon_arrow_b_city:SetVisible(self._data:IsExpanded())
end

function AllianceTerritoryMainCityCategoryCell:OnClickFold()
    self._data:SetExpanded(not self._data:IsExpanded())
    self:GetTableViewPro():UpdateData(self._data)
end

return AllianceTerritoryMainCityCategoryCell