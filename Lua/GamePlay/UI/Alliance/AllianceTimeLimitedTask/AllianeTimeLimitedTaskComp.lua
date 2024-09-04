local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceTaskOperationParameter = require('AllianceTaskOperationParameter')
local TimeFormatter = require('TimeFormatter')
local EventConst = require('EventConst')

---@class AllianeTimeLimitedTaskComp : BaseTableViewProCell
local AllianeTimeLimitedTaskComp = class('AllianeTimeLimitedTaskComp', BaseTableViewProCell)

function AllianeTimeLimitedTaskComp:OnCreate()
    self.statusRecordParent = self:StatusRecordParent("")
    self.p_text_task_content = self:Text('p_text_task_content')
    self.p_text_open = self:Text('p_text_open', "alliance_target_46")

    self.p_table_reward = self:TableViewPro("p_table_reward")
    self.p_btn_share = self:Button("p_btn_share", Delegate.GetOrCreate(self, self.OnBtnShareClick))
    self.p_btn_claim = self:Button("p_btn_claim", Delegate.GetOrCreate(self, self.OnBtnClaimClick))
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnBtnGotoClick))
    ---@type CommonTimer
    self.child_time = self:LuaObject("child_time")
    self.p_text_goto = self:Text('p_text_goto', 'world_qianwang')
    self.p_text = self:Text('p_text', "worldstage_lingqu")

    self.timeComp = self:GameObject('time')
    self.p_text_completed = self:Text('p_text_completed', "alliance_target_58")
    self.p_text_completed_time = self:Text('p_text_completed_time')
    self.p_text_uncompleted = self:Text('p_text_uncompleted', "alliance_target_59")
    self.p_text_uncompleted_time = self:Text('p_text_uncompleted_time')
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClick))
end

function AllianeTimeLimitedTaskComp:OnShow()
end

function AllianeTimeLimitedTaskComp:OnHide()

end

function AllianeTimeLimitedTaskComp:OnFeedData(param)
    self.param = param
    self.provider = param.provider
    self:RefreshData()
end

function AllianeTimeLimitedTaskComp:RefreshData()
    self.provider:SetClaimCallback(function()
        self:RefreshContent()
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_LIMITED_TIME_TASK_CLAIMED)
    end)

    self.p_table_reward:Clear()
    -- 奖励
    for _, reward in ipairs(self.provider:GetTaskRewards()) do
        self.p_table_reward:AppendData(reward)
    end
    self:RefreshContent()
end

function AllianeTimeLimitedTaskComp:RefreshContent()
    local param = self.param
    self.p_text_task_content.text = self.provider:GetTaskStr()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local state = self.provider:GetTaskState()
    if state == wds.TaskState.TaskStateReceived then
        if param.UnlockTimeStamp ~= 0 then
            if curTime >= param.UnlockTimeStamp then
                -- 已解锁\前往
                self.statusRecordParent:SetState(0)
            else
                -- 未解锁
                self.statusRecordParent:SetState(4)
            end
        else
            -- 前往
            self.statusRecordParent:SetState(0)
        end

        -- 这是可领接取任务的状态
        -- elseif state == wds.TaskState.TaskStateCanReceive then
        --     self.statusRecordParent:SetState(2)

    elseif state == wds.TaskState.TaskStateFinished then
        -- 已领取
        self.statusRecordParent:SetState(3)
        local timeStr = TimeFormatter.TimeToDateTimeStringUseFormat(self.param.FinishTimeStamp, "MM/dd/yyyy")
        self.p_text_completed_time.text = timeStr
    elseif state == wds.TaskState.TaskStateExpired then
        -- 过期
        self.statusRecordParent:SetState(1)
        local timeStr = TimeFormatter.TimeToDateTimeStringUseFormat(self.param.ExpireTimeStamp, "MM/dd/yyyy")
        self.p_text_uncompleted_time.text = timeStr
    elseif state == wds.TaskState.TaskStateCanFinish then
        -- 可领取
        self.statusRecordParent:SetState(2)
    end
    self:SetCountDown()

end

function AllianeTimeLimitedTaskComp:SetCountDown()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()

    -- 解锁倒计时
    local isWaitUnlock = curTime < self.param.UnlockTimeStamp
    -- 过期倒计时
    local isWaitExpire = curTime >= self.param.UnlockTimeStamp and curTime < self.param.ExpireTimeStamp

    local endT
    if isWaitUnlock then
        endT = self.param.UnlockTimeStamp
    elseif isWaitExpire then
        endT = self.param.ExpireTimeStamp
    else
        self.timeComp:SetVisible(false)
        return
    end

    local timerData = {}
    timerData.endTime = endT
    timerData.needTimer = true
    timerData.callBack = Delegate.GetOrCreate(self, self.RefreshContent)
    self.child_time:FeedData(timerData)
    self.timeComp:SetVisible(true)
end

function AllianeTimeLimitedTaskComp:OnBtnClaimClick()
    self.provider.onClaim()
end

function AllianeTimeLimitedTaskComp:OnBtnShareClick()
    ---@type ShareChannelChooseParam
    local param = {type = ChatShareType.AllianceTask, configID = self.param.TID, blockWorldChannel = true}
    g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
end

function AllianeTimeLimitedTaskComp:OnBtnGotoClick()
    self.provider:OnGoto()
end

function AllianeTimeLimitedTaskComp:OnBtnDetailClick()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform = self.p_btn_detail.transform
    toastParameter.content = I18N.Get("#asdfasdf")
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

return AllianeTimeLimitedTaskComp
