local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class LandformTaskCellParameter
---@field activityInfo wds.LandActivityInfo
---@field landformConfigID number
---@field taskID number

---@class LandformTaskCell : BaseUIComponent
---@field param LandformTaskCellParameter
local LandformTaskCell = class("LandformTaskCell", BaseUIComponent)

function LandformTaskCell:OnCreate(param)
    self.p_text_progress = self:Text("p_text_progress")
    self.p_text_reward = self:Text("p_text_reward")
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClicked))
    self.p_text = self:Text("p_text", I18N.Get("world_qianwang"))
    self.p_img_received = self:GameObject("p_img_received")
end

---@param param LandformTaskCellParameter
function LandformTaskCell:OnFeedData(param)
    self.param = param

    local desc = ModuleRefer.LandformTaskModule:GetTaskDesc(self.param.activityInfo, self.param.taskID)
    self.p_text_progress.text = desc
    
    local finished = ModuleRefer.LandformTaskModule:CheckTaskFinished(self.param.activityInfo, self.param.taskID)
    self.p_btn_goto:SetVisible(not finished)
    self.p_img_received:SetVisible(finished)
    
    local rewardDesc = ModuleRefer.LandformTaskModule:GetTaskRewardDesc(self.param.taskID)
    rewardDesc = rewardDesc .. "[000]"
    self.p_text_reward.text = rewardDesc
end

function LandformTaskCell:OnGotoClicked()
    local taskConfig = ConfigRefer.LandTask:Find(self.param.taskID)
    ModuleRefer.LandformTaskModule:GotoTask(taskConfig:TaskType(), self.param.landformConfigID)
end

return LandformTaskCell