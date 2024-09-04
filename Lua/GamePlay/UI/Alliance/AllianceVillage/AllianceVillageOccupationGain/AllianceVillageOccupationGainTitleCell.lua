
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationGainTitleCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationGainTitleCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationGainTitleCell = class('AllianceVillageOccupationGainTitleCell', BaseTableViewProCell)

function AllianceVillageOccupationGainTitleCell:OnCreate(param)
    self._p_text_gain = self:Text("p_text_gain")
end

---@param data string
function AllianceVillageOccupationGainTitleCell:OnFeedData(data)
    self._p_text_gain.text = data
end

return AllianceVillageOccupationGainTitleCell