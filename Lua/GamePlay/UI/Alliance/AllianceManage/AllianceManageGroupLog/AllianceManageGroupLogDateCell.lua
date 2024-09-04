local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceManageGroupLogDateCellData
---@field dateTime CS.System.DateTime

---@class AllianceManageGroupLogDateCell:BaseTableViewProCell
---@field new fun():AllianceManageGroupLogDateCell
---@field super BaseTableViewProCell
local AllianceManageGroupLogDateCell = class('AllianceManageGroupLogDateCell', BaseTableViewProCell)

function AllianceManageGroupLogDateCell:OnCreate(param)
    self._p_text_date = self:Text("p_text_date")
end

---@param data AllianceManageGroupLogDateCellData
function AllianceManageGroupLogDateCell:OnFeedData(data)
    self._p_text_date.text = data.dateTime:ToString("yyyy/MM/dd")
end

return AllianceManageGroupLogDateCell