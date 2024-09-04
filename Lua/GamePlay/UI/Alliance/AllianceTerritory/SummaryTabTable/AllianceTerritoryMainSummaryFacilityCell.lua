local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryFacilityCellData
---@field defenceTowerCount number
---@field defenceTowerCountMax number
---@field crystalTowerCount number
---@field crystalTowerCountMax number

---@class AllianceTerritoryMainSummaryFacilityCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryFacilityCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryFacilityCell = class('AllianceTerritoryMainSummaryFacilityCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryFacilityCell:OnCreate(param)
    self._p_text_name_1 = self:Text("p_text_name_1", "alliance_territory_9")
    self._p_text_name_2 = self:Text("p_text_name_2", "alliance_territory_10")
    self._p_text_num_1 = self:Text("p_text_num_1")
    self._p_text_num_2 = self:Text("p_text_num_2")
end

---@param data AllianceTerritoryMainSummaryFacilityCellData
function AllianceTerritoryMainSummaryFacilityCell:OnFeedData(data)
    self._p_text_num_1.text = string.format("%s/%s", data.defenceTowerCount, data.defenceTowerCountMax)
    self._p_text_num_2.text = string.format("%s/%s", data.crystalTowerCount, data.crystalTowerCountMax)
end

return AllianceTerritoryMainSummaryFacilityCell