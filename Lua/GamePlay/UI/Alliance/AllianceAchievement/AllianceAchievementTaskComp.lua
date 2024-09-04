local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')
local EventConst = require('EventConst')

---@class AllianceAchievementTaskComp : BaseTableViewProCell
local AllianceAchievementTaskComp = class('AllianceAchievementTaskComp', BaseTableViewProCell)

function AllianceAchievementTaskComp:OnCreate()
    self.p_text_detail = self:Text('p_text_detail')
    self.p_text_progress = self:Text('p_text_progress')
    self.p_progress = self:Slider('p_progress')
    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_btn_claim = self:Button("p_btn_claim", Delegate.GetOrCreate(self, self.OnClickClaim))
    self.p_text_goto = self:Text('p_text_goto')
    self.p_text_goto = self:Text('p_text_goto', 'world_qianwang')
    self.p_text_claim = self:Text('p_text_claim', 'worldstage_lingqu')
    self.p_received = self:GameObject('p_received')
    self.p_text_score = self:Text('p_text_score')
end

function AllianceAchievementTaskComp:OnShow()
end

function AllianceAchievementTaskComp:OnHide()
end

---@field provider TaskItemDataProvider
function AllianceAchievementTaskComp:OnFeedData(param)
    self.param = param
    self.provider = param.provider
    self.provider:SetClaimCallback(function()
        self:RefreshContent()
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TASK_CLAIMED, param.index)
    end)

    self.p_table_reward:Clear()
    for _, reward in ipairs(self.provider:GetTaskRewards()) do
        self.p_table_reward:AppendData(reward)
    end
    self:RefreshContent()
end

function AllianceAchievementTaskComp:RefreshContent()
    self.p_btn_claim:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish)
    self.p_btn_goto:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateReceived)
    self.p_received:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateFinished)
    self.p_text_detail.text = self.provider:GetTaskStr(true)
    self.p_text_progress.text = self.provider:GetTaskProgressStr()
    self.p_text_score.text = self.param.RewardAlliancePoint
    local numCurrent, numNeeded = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(self.provider.taskCfgId)
    self.p_progress.value = numCurrent / numNeeded
end

function AllianceAchievementTaskComp:OnClickGoto()
    self.provider:OnGoto()
end

function AllianceAchievementTaskComp:OnClickClaim()
    self.provider.onClaim()
end

return AllianceAchievementTaskComp
