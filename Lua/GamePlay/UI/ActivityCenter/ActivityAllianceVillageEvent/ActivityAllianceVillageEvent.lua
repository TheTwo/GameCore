local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local DBEntityPath = require("DBEntityPath")
local TaskItemDataProvider = require("TaskItemDataProvider")
local ItemTableMergeHelper = require("ItemTableMergeHelper")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local GuideUtils = require("GuideUtils")
---@class ActivityAllianceVillageEvent : BaseUIComponent
local ActivityAllianceVillageEvent = class("ActivityAllianceVillageEvent", BaseUIComponent)

function ActivityAllianceVillageEvent:ctor()
    self.curStatus = 0
    self.taskIds = {}
    ---@type TaskItemDataProvider[]
    self.taskProviders = {}
end

function ActivityAllianceVillageEvent:OnCreate()
    self.textActivityTime = self:Text("p_text_time")
    self.textLabelInfo = self:Text("p_text_info", "bw_village_breakingice_rule")
    self.btnDetail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnBtnDetailClick))

    self.textTitle = self:Text("p_text_title", "bw_name_village_breakingIce")
    self.textTimerDay = self:Text("p_text_count_down")
    self.textTimerHour = self:Text("p_text_count_down_1")
    self.textTimerMinute = self:Text("p_text_count_down_3")
    self.textTimerSecond = self:Text("p_text_count_down_5")

    self.textHintRequire = self:Text("p_text_hint_require", "bw_village_breakingice_join")
    self.statusCtrlerStep1 = self:StatusRecordParent("p_group_require_1")
    self.textStep1 = self:Text("p_text_require_1", "bw_village_breakingice_joinalliance")
    self.textStepNum1 = self:Text("p_text_require_num_1", "1")
    self.statusCtrlerStep2 = self:StatusRecordParent("p_group_require_2")
    self.textStep2 = self:Text("p_text_require_2", "bw_village_breakingice_declare")
    self.textStepNum2 = self:Text("p_text_require_num_2", "2")
    self.statusCtrlerStep3 = self:StatusRecordParent("p_group_require_3")
    self.textStep3 = self:Text("p_text_require_3", "bw_village_breakingice_occupy")
    self.textStepNum3 = self:Text("p_text_require_num_3", "3")

    self.textHintReward = self:Text("p_text_hint_reward", "bw_village_breakingice_reward_2")
    self.tableReward = self:TableViewPro("p_table_award")

    self.textBtnLabelComplete = self:Text("p_text_completed", "bw_village_breakingice_btn_5")
    self.btnJoinAlliance = self:Button("p_btn_join_alliance", Delegate.GetOrCreate(self, self.OnBtnJoinAllianceClick))
    self.textBtnJoinAlliance = self:Text("p_text_join_alliance", "bw_village_breakingice_btn_1")
    self.btnViewVillage = self:Button("p_btn_view_village", Delegate.GetOrCreate(self, self.OnBtnViewVillageClick))
    self.textBtnViewVillage = self:Text("p_text_view_village", "bw_village_breakingice_btn_2")
    self.btnJoinWar = self:Button("p_btn_join_war", Delegate.GetOrCreate(self, self.OnBtnJoinWarClick))
    self.textBtnJoinWar = self:Text("p_text_join_war", "bw_village_breakingice_btn_3")
    self.btnClaimReward = self:Button("p_btn_claim_reward", Delegate.GetOrCreate(self, self.OnBtnClaimRewardClick))
    self.textBtnClaimReward = self:Text("p_text_claim_reward", "bw_village_breakingice_btn_4")

    self.textRewardTimes = self:Text("p_text_hint_start")

    self.statusCtrl = {
        {
            ctrler = self.statusCtrlerStep1,
            btn = self.btnJoinAlliance,
            checker = self.CheckInAlliance
        },
        {
            ctrler = self.statusCtrlerStep2,
            btn = self.btnViewVillage,
            checker = self.CheckDeclareVillageWar
        },
        {
            ctrler = self.statusCtrlerStep3,
            btn = self.btnJoinWar,
            checker = self.CheckJoinVillageWar
        }
    }

    self.isFirstOpen = true
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function ActivityAllianceVillageEvent:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.LastJoinAllianceTime.MsgPath, Delegate.GetOrCreate(self, self.UpdateStatus))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.UpdateStatus))
end

function ActivityAllianceVillageEvent:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.LastJoinAllianceTime.MsgPath, Delegate.GetOrCreate(self, self.UpdateStatus))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.UpdateStatus))
end

function ActivityAllianceVillageEvent:OnFeedData(param)
    self.tabId = param.tabId
    self.actId = ConfigRefer.ActivityCenterTabs:Find(self.tabId):RefActivityReward()
    self.actCfg = ConfigRefer.ActivityRewardTable:Find(self.actId)
    local actTempId = self.actCfg:OpenActivity()
    self.configId = self.actCfg:RefConfig()
    self.cfg = ConfigRefer.ActivityTaskGuide:Find(self.configId)
    table.clear(self.taskProviders)
    for i = 1, self.cfg:RelatedTasksLength() do
        local taskId = self.cfg:RelatedTasks(i)
        local provider = TaskItemDataProvider.new(taskId)
        table.insert(self.taskProviders, provider)
    end
    self.textActivityTime.text = ModuleRefer.ActivityCenterModule:GetActivityDurationStr(actTempId)
    self:UpdateStatus()
    self:UpdateRewardTable()
    self:OnSecondTicker()
end

function ActivityAllianceVillageEvent:UpdateStatus()
    local curStatus = 0
    for i = 1, #self.statusCtrl do
        local ctrl = self.statusCtrl[i]
        local isFinish = ctrl.checker(self)
        ctrl.btn.gameObject:SetActive(false)
        if isFinish then
            ctrl.ctrler:ApplyStatusRecord(1)
        else
            if curStatus == 0 then
                curStatus = i
            end
            ctrl.ctrler:ApplyStatusRecord(0)
        end
    end
    self.curStatus = curStatus
    for i = 1, #self.statusCtrl do
        local ctrl = self.statusCtrl[i]
        ctrl.btn.gameObject:SetActive(i == curStatus)
    end
    self.btnClaimReward.gameObject:SetActive(curStatus == 0 and not self:CheckRewardClaimed())
    UIHelper.SetGray(self.btnClaimReward.gameObject, self:GetCanRewardNum() == 0)
    self.textBtnLabelComplete.gameObject:SetActive(curStatus == 0 and self:CheckRewardClaimed())
    self.textRewardTimes.gameObject:SetActive(true)
    self.textRewardTimes.text = I18N.GetWithParams("bw_village_breakingice_reward", self:GetRewardedNum(), #self.taskProviders)
end

function ActivityAllianceVillageEvent:UpdateRewardTable()
    self.tableReward:Clear()
    local rewards = {}
    for _, v in ipairs(self.taskProviders) do
        local reward = v:GetTaskRewards()
        for _, r in ipairs(reward) do
            table.insert(rewards, r)
        end
    end
    local mergedRewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(rewards)
    for _, v in pairs(mergedRewards) do
        v.received = self:CheckRewardClaimed()
        v.showTips = true
        self.tableReward:AppendData(v)
    end
end

function ActivityAllianceVillageEvent:CheckInAlliance()
    return self:CheckDeclareVillageWar() or ModuleRefer.AllianceModule:IsInAlliance()
end

function ActivityAllianceVillageEvent:CheckDeclareVillageWar()
    return self:CheckJoinVillageWar() or ModuleRefer.VillageModule:HasAnyDeclareWarOnVillage()
end

function ActivityAllianceVillageEvent:CheckJoinVillageWar()
    for _, v in ipairs(self.taskProviders) do
        if v:GetTaskState() >= wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    return false
end

function ActivityAllianceVillageEvent:CheckRewardClaimed()
    for _, v in ipairs(self.taskProviders) do
        if v:GetTaskState() < wds.TaskState.TaskStateFinished then
            return false
        end
    end
    return true
end

function ActivityAllianceVillageEvent:OnSecondTicker()
    if Utils.IsNull(self.CSComponent) then return end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local actTempId = self.actCfg:OpenActivity()
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(actTempId)
    local remainTime = math.max(endTime.Seconds - curTime, 0)
    local time = TimeFormatter.GetTimeTableInDHMS(remainTime)
    self.textTimerDay.text = string.format("%dd", time.day)
    self.textTimerHour.text =  string.format("%02d", time.hour)
    self.textTimerMinute.text =  string.format("%02d", time.minute)
    self.textTimerSecond.text =  string.format("%02d", time.second)
end

function ActivityAllianceVillageEvent:OnBtnDetailClick()
    GuideUtils.GotoByGuide(5284)
end

function ActivityAllianceVillageEvent:OnBtnJoinAllianceClick()
    if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Global_alliance) then
        g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
    end
end

function ActivityAllianceVillageEvent:OnBtnViewVillageClick()
    ModuleRefer.VillageModule:GotoNeareastCanDeclareVillage()
    self:GetParentBaseUIMediator():CloseSelf()
end

function ActivityAllianceVillageEvent:OnBtnJoinWarClick()
    if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Global_alliance) then
        ---@type AllianceWarMediatorParameter
        local data = {}
        data.enterTabIndex = 2
        g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, data)
    end
end

function ActivityAllianceVillageEvent:OnBtnClaimRewardClick()
    if self:GetCanRewardNum() == 0 then return end
    for _, v in ipairs(self.taskProviders) do
        if v:GetTaskState() == wds.TaskState.TaskStateCanFinish then
            v:SetClaimCallback(function ()
                self:UpdateStatus()
                self:UpdateRewardTable()
                ModuleRefer.ActivityCenterModule:UpdateRedDotByTabId(self.tabId)
            end)
            v:OnClaim()
        end
    end
end

function ActivityAllianceVillageEvent:GetRewardedNum()
    local num = 0
    for _, v in ipairs(self.taskProviders) do
        if v:GetTaskState() == wds.TaskState.TaskStateFinished then
            num = num + 1
        end
    end
    return num
end

function ActivityAllianceVillageEvent:GetCanRewardNum()
    local num = 0
    for _, v in ipairs(self.taskProviders) do
        if v:GetTaskState() == wds.TaskState.TaskStateCanFinish then
            num = num + 1
        end
    end
    return num
end

return ActivityAllianceVillageEvent