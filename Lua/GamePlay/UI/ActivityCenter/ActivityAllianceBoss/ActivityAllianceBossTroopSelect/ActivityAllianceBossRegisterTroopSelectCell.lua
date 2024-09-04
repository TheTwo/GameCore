local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
---@class ActivityAllianceBossRegisterTroopSelectCell : BaseTableViewProCell
local ActivityAllianceBossRegisterTroopSelectCell = class("ActivityAllianceBossRegisterTroopSelectCell", BaseTableViewProCell)

---@class ActivityAllianceBossRegisterTroopSelectCellParam

function ActivityAllianceBossRegisterTroopSelectCell:OnCreate()
    self.btnAdd = self:Button('p_btn_empty', Delegate.GetOrCreate(self, self.OnBtnAddClick))
end

---@param param ActivityAllianceBossRegisterTroopSelectCellParam
function ActivityAllianceBossRegisterTroopSelectCell:OnFeedData(param)
end

return ActivityAllianceBossRegisterTroopSelectCell