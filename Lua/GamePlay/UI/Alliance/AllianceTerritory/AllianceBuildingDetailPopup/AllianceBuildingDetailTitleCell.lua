
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBuildingDetailTitleCell:BaseTableViewProCell
---@field new fun():AllianceBuildingDetailTitleCell
---@field super BaseTableViewProCell
local AllianceBuildingDetailTitleCell = class('AllianceBuildingDetailTitleCell', BaseTableViewProCell)

function AllianceBuildingDetailTitleCell:OnCreate(param)
    self._p_text_title = self:Text("p_text_title")
end

---@param data string
function AllianceBuildingDetailTitleCell:OnFeedData(data)
    self._p_text_title.text = data
end

return AllianceBuildingDetailTitleCell