
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationGainDetailCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationGainDetailCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationGainDetailCell = class('AllianceVillageOccupationGainDetailCell', BaseTableViewProCell)

function AllianceVillageOccupationGainDetailCell:OnCreate(param)
    self._p_text_detail = self:Text("p_text_detail")
end

---@param data string
function AllianceVillageOccupationGainDetailCell:OnFeedData(data)
    self._p_text_detail.text = data
end

return AllianceVillageOccupationGainDetailCell