local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceMemberAppliesCell:BaseTableViewProCell
---@field new fun():AllianceMemberAppliesCell
---@field super BaseTableViewProCell
local AllianceMemberAppliesCell = class('AllianceMemberAppliesCell', BaseTableViewProCell)

function AllianceMemberAppliesCell:OnCreate(param)
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_text_name_player = self:Text("p_text_name_player")
    self._p_text_power_player = self:Text("p_text_power_player")
    self._p_btn_reject = self:Button("p_btn_reject", Delegate.GetOrCreate(self, self.OnClickBtnReject))
    self._p_btn_pass = self:Button("p_btn_pass", Delegate.GetOrCreate(self, self.OnClickBtnAccept))
end

---@param cellData AllianceMemberAppliesCellListData
function AllianceMemberAppliesCell:OnFeedData(cellData)
    local data = cellData.Data
    self._child_ui_head_player:FeedData(data.PortraitInfo)
    self._playerFacebookId = data.FacebookID
    self._p_text_name_player.text = data.Name
    self._p_text_power_player.text = tostring(data.Power)
end

function AllianceMemberAppliesCell:OnClickBtnReject()
    ModuleRefer.AllianceModule:VerifyAllianceApplication(self._playerFacebookId, false)
end

function AllianceMemberAppliesCell:OnClickBtnAccept()
    ModuleRefer.AllianceModule:VerifyAllianceApplication(self._playerFacebookId, true)
end

return AllianceMemberAppliesCell