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

---@class AllianceAchievementLeaderTaskComp : BaseTableViewProCell
local AllianceAchievementLeaderTaskComp = class('AllianceAchievementLeaderTaskComp', BaseTableViewProCell)

function AllianceAchievementLeaderTaskComp:OnCreate()
    self.p_text_detail = self:Text('p_text_detail')
    self.p_progress = self:Slider('p_progress')
    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_btn_claim = self:Button("p_btn_claim", Delegate.GetOrCreate(self, self.OnClickClaim))
    self.p_text_goto = self:Text('p_text_goto')
    self.p_text_goto = self:Text('p_text_goto', 'world_qianwang')
    self.p_text_claim = self:Text('p_text_claim', 'worldstage_lingqu')
    self.p_received = self:GameObject('p_received')
    self.p_lock = self:GameObject('p_lock')
end

function AllianceAchievementLeaderTaskComp:OnShow()
end

function AllianceAchievementLeaderTaskComp:OnHide()
end

---@field provider TaskItemDataProvider
function AllianceAchievementLeaderTaskComp:OnFeedData(param)
    self.param = param
    self.provider = param.provider
    self.isLock = self.param.index ~= 1 and not ModuleRefer.AllianceJourneyModule:IsLeaderTaskChapterUnlock(self.param.index - 1) or false
    self.provider:SetClaimCallback(function()
        self:RefreshContent()
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_LEADER_TASK_CLAIMED, param.index)
    end)

    self.p_table_reward:Clear()
    for _, reward in ipairs(self.provider:GetTaskRewards()) do
        self.p_table_reward:AppendData(reward)
    end
    self:RefreshContent()
end

function AllianceAchievementLeaderTaskComp:RefreshContent()
    self.p_text_detail.text = self.provider:GetTaskStr()

    if self.isLock then
        self.p_btn_claim:SetVisible(false)
        self.p_btn_goto:SetVisible(false)
        self.p_received:SetVisible(false)
        self.p_lock:SetVisible(true)
        return
    end
    self.p_lock:SetVisible(false)
    self.p_btn_claim:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish)
    self.p_btn_goto:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateReceived)
    self.p_received:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateFinished)
end

function AllianceAchievementLeaderTaskComp:OnClickGoto()
    self.provider:OnGoto()
end

function AllianceAchievementLeaderTaskComp:OnClickClaim()
    if self.isLock then
        ModuleRefer.ToastModule:AddSimpleToast("bw_info_circle_unlock")
        return
    end
    self.provider.onClaim()
end

return AllianceAchievementLeaderTaskComp
