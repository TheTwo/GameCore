local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceActivityWarTroopListPopupCellData:BaseTableViewProExpendData
---@field new fun(memberData):AllianceActivityWarTroopListPopupCellData
---@field super BaseTableViewProExpendData
local AllianceActivityWarTroopListPopupCellData = class('AllianceActivityWarTroopListPopupCellData', BaseTableViewProExpendData)

---@param memberData wds.AllianceBattleMemberInfo
function AllianceActivityWarTroopListPopupCellData:ctor(memberData)
    BaseTableViewProExpendData.ctor(self)
    ---@type wds.AllianceBattleMemberInfo
    self._memberData = memberData
    self:RefreshChildCells(nil, memberData.Troops and {memberData.Troops} or {})
    self._battleId = nil
    self._isSelf = false
    self._adminMode = false
    ---@type wds.AllianceMember
    self._memberInfo = nil
end

---@param tableView CS.TableViewPro
---@param memberData wds.AllianceBattleMemberInfo
function AllianceActivityWarTroopListPopupCellData:UpdateData(tableView, memberData)
    ---@type wds.AllianceBattleMemberInfo
    self._memberData = memberData
    self:RefreshChildCells(tableView, memberData.Troops and {memberData.Troops} or {})
end

return AllianceActivityWarTroopListPopupCellData