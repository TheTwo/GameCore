local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationHistoryListTitleCellData
---@field column string[]

---@class AllianceVillageOccupationHistoryListTitleCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationHistoryListTitleCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationHistoryListTitleCell = class('AllianceVillageOccupationHistoryListTitleCell', BaseTableViewProCell)

function AllianceVillageOccupationHistoryListTitleCell:OnCreate(param)
    ---@type CS.UnityEngine.UI.Text[]
    self._p_text_colum = {}
    self._p_text_colum[1] = self:Text("p_text_a")
    self._p_text_colum[2] = self:Text("p_text_b")
end

---@param data AllianceVillageOccupationHistoryListTitleCellData
function AllianceVillageOccupationHistoryListTitleCell:OnFeedData(data)
    for i = 1, #self._p_text_colum do
        self._p_text_colum[i].text = data.column[i] or string.Empty
    end
end

return AllianceVillageOccupationHistoryListTitleCell