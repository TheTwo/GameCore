local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationHistoryTitleCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationHistoryTitleCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationHistoryTitleCell = class('AllianceVillageOccupationHistoryTitleCell', BaseTableViewProCell)

function AllianceVillageOccupationHistoryTitleCell:OnCreate(param)
    self._p_text_first = self:Text("p_text_first")
end

---@param data string
function AllianceVillageOccupationHistoryTitleCell:OnFeedData(data)
    self._p_text_first.text = data
end

return AllianceVillageOccupationHistoryTitleCell