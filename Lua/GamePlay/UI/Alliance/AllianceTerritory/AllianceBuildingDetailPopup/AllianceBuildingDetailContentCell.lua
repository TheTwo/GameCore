
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBuildingDetailContentCell:BaseTableViewProCell
---@field new fun():AllianceBuildingDetailContentCell
---@field super BaseTableViewProCell
local AllianceBuildingDetailContentCell = class('AllianceBuildingDetailContentCell', BaseTableViewProCell)

function AllianceBuildingDetailContentCell:OnCreate(param)
    self._selfText = self:Text("")
end

---@param data string
function AllianceBuildingDetailContentCell:OnFeedData(data)
    self._selfText.text = data
end

return AllianceBuildingDetailContentCell