local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceManageGroupLogDateDetailCellData : AllianceManageGroupLogDateCellData
---@field preBuildText string

---@class AllianceManageGroupLogDateDetailCell:BaseTableViewProCell
---@field new fun():AllianceManageGroupLogDateDetailCell
---@field super BaseTableViewProCell
local AllianceManageGroupLogDateDetailCell = class('AllianceManageGroupLogDateDetailCell', BaseTableViewProCell)

function AllianceManageGroupLogDateDetailCell:OnCreate(param)
    self._p_text_time = self:Text("p_text_time")
    self._p_text_detail = self:Text("p_text_detail")
end

---@param data AllianceManageGroupLogDateDetailCellData
function AllianceManageGroupLogDateDetailCell:OnFeedData(data)
    self._p_text_time.text = data.dateTime:ToString("HH:mm:ss")
    self._p_text_detail.text = data.preBuildText
end

return AllianceManageGroupLogDateDetailCell