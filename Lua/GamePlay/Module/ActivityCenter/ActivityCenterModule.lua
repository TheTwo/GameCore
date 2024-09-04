local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ActivityCenterConst = require("ActivityCenterConst")
local NotificationType = require("NotificationType")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ClientDataKeys = require("ClientDataKeys")
local EventConst = require("EventConst")
local UIManager = require("UIManager")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local UIMediatorNames = require("UIMediatorNames")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local GrowthFundConst = require("GrowthFundConst")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")
local ActivityCategory = require("ActivityCategory")
local TabOpenChecker = require("ActivityCenter_TabOpenChecker")
local ActivityClass = require("ActivityClass")
local ActivityRewardType = require("ActivityRewardType")
---@class ActivityCenterModule : BaseModule
local ActivityCenterModule = class("ActivityCenterModule", BaseModule)

function ActivityCenterModule:OnRegister()
    self.isDoOnceLogicFinished = false
    self.newlyUnlockStatus = {}
    self.gmOpenAllActivity = false
end

function ActivityCenterModule:SetUp()
    ---@type ActivityCenter_TabOpenChecker
    self.checker = TabOpenChecker.new()
    self:RegisterCheckers()
    self:UpdateNewlyUnlockStatus()
    self:SetupNotificationNodes()
    self:InitRedDot()

    g_Game.DatabaseManager:AddChanged(
        DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,
        Delegate.GetOrCreate(self, self.OnPlayerAutoRewardChanged)
    )
    g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnSystemEntryOpen))
end

function ActivityCenterModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,
        Delegate.GetOrCreate(self, self.OnPlayerAutoRewardChanged)
    )
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnSystemEntryOpen))
    self.checker:Release()
end

function ActivityCenterModule:OnPlayerAutoRewardChanged()
    self:InitRedDot()
end

function ActivityCenterModule:RegisterCheckers()
    ---@type number, ActivityCenterTabsConfigCell
    for _, tab in ConfigRefer.ActivityCenterTabs:pairs() do
        if tab:HideInRegularStage() then
            self.checker:AddChecker(tab:Id(), self.checker.CheckTypeRegular)
        end
    end
end

---@param a number
---@param b number
---@return boolean
function ActivityCenterModule.ActivitySorter(a, b)
    local priorityA = ConfigRefer.ActivityCenterTabs:Find(a):Priority()
    local priorityB = ConfigRefer.ActivityCenterTabs:Find(b):Priority()
    if priorityA == priorityB then
        return a < b
    else
        return priorityA < priorityB
    end
end

function ActivityCenterModule:OnSystemEntryOpen(systemEntryIds)
    -- todo: 和策划商量一下，等拍脸系统优化后，这部分应该放到LoginPopupModule中由配置控制, 现在写的过于丑陋了
    local providers = {}
    local signUpSysId = NewFunctionUnlockIdDefine.Activity_sign_in
    if table.ContainsValue(systemEntryIds, signUpSysId) then
        local provider = UIAsyncDataProvider.new()
        local mediatorName = UIMediatorNames.UISignInMediator
        local timing = UIAsyncDataProvider.PopupTimings.AnyTime
        local checkType = UIAsyncDataProvider.CheckTypes.CheckAll
        local StrategyOnCheckFailed = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
        local openParams = {
            popIds = {3},
        }
        provider:Init(mediatorName, timing, checkType, StrategyOnCheckFailed, false, openParams)
        provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
        provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
        provider:SetCustomChecker(function()
            return g_Game.SceneManager.current:IsInCity()
        end)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
        -- table.insert(providers, provider)
    end

    local growthFundSysId = NewFunctionUnlockIdDefine.GrowthFund
    if table.ContainsValue(systemEntryIds, growthFundSysId) then
        local provider = UIAsyncDataProvider.new()
        local mediatorName = UIMediatorNames.GrowthFundPopupMediator
        local timing = UIAsyncDataProvider.PopupTimings.AnyTime
        local checkType = UIAsyncDataProvider.CheckTypes.CheckAll
        local StrategyOnCheckFailed = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
        provider:Init(mediatorName, timing, checkType, StrategyOnCheckFailed, false)
        provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
        provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
        -- table.insert(providers, provider)
    end
    -- g_Game.UIAsyncManager:AddAsyncMediatorsList(providers, true)
end

--- 获取活动的开始和结束时间
---@param actRewardId number @ActivityRewardTable ConfigId
---@return google.protobuf.Timestamp, google.protobuf.Timestamp @startTime, endTime
function ActivityCenterModule:GetActivityStartEndTime(actRewardId)
    local defaultTimeStamp = google.protobuf.Timestamp.New()
    local cfg = ConfigRefer.ActivityRewardTable:Find(actRewardId)
    if not cfg then return defaultTimeStamp, defaultTimeStamp end
    local tempId = cfg:OpenActivity()
    return self:GetActivityStartEndTimeByActivityTemplateId(tempId)
end

--- 获取活动的开始和结束时间
---@param activityTemplateId number @ActivityTemplate ConfigId
---@return google.protobuf.Timestamp, google.protobuf.Timestamp @startTime, endTime
function ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
    ---@type google.protobuf.Timestamp
    local defaultTimeStamp = google.protobuf.Timestamp.New() --{Seconds = 0, Millisecond = 0, ServerSecond = 0, nanos = 0, timeSeconds = 0}
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdom then return defaultTimeStamp, defaultTimeStamp end
    local activityEntry = kingdom.ActivityInfo.Activities[activityTemplateId]
    if not activityEntry then return defaultTimeStamp, defaultTimeStamp end
    local startTime = activityEntry.StartTime
    local endTime = activityEntry.EndTime
    return startTime, endTime
end

---@param activityId number @ActivityTemplate ConfigId
---@return string
function ActivityCenterModule:GetActivityDurationStr(activityId)
    local startTime, endTime = self:GetActivityStartEndTimeByActivityTemplateId(activityId)
    local startTimeDate = TimeFormatter.ToDateTime(startTime.Seconds)
    local endTimeDate = TimeFormatter.ToDateTime(endTime.Seconds)
    local startTimeStr = startTimeDate:ToString("yyyy.MM.dd")
    local endTimeStr = endTimeDate:ToString("yyyy.MM.dd")
    return I18N.GetWithParams("alliance_worldevent_big_time", startTimeStr, endTimeStr)
end

---@param activityTemplateId number @ActivityTemplate ConfigId
---@return boolean
function ActivityCenterModule:IsActivityTemplateOpen(activityTemplateId)
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdom then return false end
    local activityEntry = kingdom.ActivityInfo.Activities[activityTemplateId]
    if not activityEntry then return false end
    return activityEntry.Open
end

function ActivityCenterModule:SetupNotificationNodes()
    local hudNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        ActivityCenterConst.NotificationNodeNames.ActivityCenterEntry, NotificationType.ACTIVITY_CENTER_HUD
    )
    for _, tab in ConfigRefer.ActivityCenterTabs:ipairs() do
        if self:GetActivityClass(tab:Id()) == ActivityClass.Commercial then
            local tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
                ActivityCenterConst.NotificationNodeNames.ActivityCenterTab .. tab:Id(), NotificationType.ACTIVITY_CENTER_TAB
            )
            ModuleRefer.NotificationModule:AddToParent(tabNode, hudNode)
        end
    end
    local earthRevivalNode = ModuleRefer.EarthRevivalModule.btnRedDot
    -- ModuleRefer.NotificationModule:AddToParent(hudNode, earthRevivalNode)
end

function ActivityCenterModule:InitRedDot()
    for _, tab in ConfigRefer.ActivityCenterTabs:ipairs() do
        self:UpdateRedDotByTabId(tab:Id())
    end
end

function ActivityCenterModule:UpdateRedDotByTabId(tabId)
    local tabNodeNotify = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        ActivityCenterConst.NotificationNodeNames.ActivityCenterTab .. tabId, NotificationType.ACTIVITY_CENTER_TAB
    )
    local tabNodeNew = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        ActivityCenterConst.NotificationNodeNames.ActivityCenterTabNew .. tabId, NotificationType.ACTIVITY_CENTER_TAB
    )
    local isNewlyUnlock = self:IsActivityTabNewlyUnlock(tabId)
    local hasNotify = self:HasActivityNotify(tabId)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(tabNodeNotify, hasNotify and 1 or 0)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(tabNodeNew, isNewlyUnlock and 1 or 0)
end

---@param tabId number
---@return boolean
function ActivityCenterModule:HasActivityNotify(tabId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then return false end
    
    local rewardType = self:GetActivityAutoRewardType(tabId)
    if tabId == ActivityCenterConst.SignupTabId then
        local signUpRewardId = ConfigRefer.ActivityCenterTabs:Find(ActivityCenterConst.SignupTabId):RefActivityReward()
        local isSignRewardCanClaim = player.PlayerWrapper2.PlayerAutoReward.Rewards[signUpRewardId].SevenDaySignInParam.CanReceiveRewardDays:Count() > 0
        return isSignRewardCanClaim
    elseif tabId == ActivityCenterConst.AccumulateTabId then
        local accRewardId = ConfigRefer.ActivityCenterTabs:Find(ActivityCenterConst.AccumulateTabId):RefActivityReward()
        local accNodeIndex = player.PlayerWrapper2.PlayerAutoReward.Rewards[accRewardId].AccRechargeParam.NodeIndex
        local accReceivedNum = #player.PlayerWrapper2.PlayerAutoReward.Rewards[accRewardId].AccRechargeParam.ReceivedIndex
        local isAccRewardCanClaim = accNodeIndex > accReceivedNum
        return isAccRewardCanClaim
    elseif tabId == ActivityCenterConst.GrowthFundTabId then
        local id = ModuleRefer.GrowthFundModule:GetCurOpeningGrowthFundCfgId()
        local isRewardCanClaim = ModuleRefer.GrowthFundModule:IsAnyRewardCanClaim(id)
        return isRewardCanClaim
    elseif tabId == ActivityCenterConst.BehemothNest then
        local claimable = ModuleRefer.ActivityBehemothModule:IsDeviceBuildRewardCanClaim()
        return claimable
    elseif tabId == ActivityCenterConst.WorldEvent3_1 or tabId == ActivityCenterConst.WorldEvent3_2 then
        return ModuleRefer.WorldEventModule:CheckWorldEventUseItem(tabId)
    elseif tabId == ActivityCenterConst.VillageEvent then
        local actId = ConfigRefer.ActivityCenterTabs:Find(tabId):RefActivityReward()
        local actCfg = ConfigRefer.ActivityRewardTable:Find(actId)
        local configId = actCfg:RefConfig()
        local cfg = ConfigRefer.ActivityTaskGuide:Find(configId)
        local taskId = cfg:RelatedTask()
        local provider = require("TaskItemDataProvider").new(taskId)
        local claimable = provider:GetTaskState() == wds.TaskState.TaskStateCanFinish
        return claimable
    elseif rewardType == ActivityRewardType.FirePlan then
        local actId = ConfigRefer.ActivityCenterTabs:Find(tabId):RefActivityReward()
        local actCfg = ConfigRefer.ActivityRewardTable:Find(actId)
        local configId = actCfg:RefConfig()
        local cfg = ConfigRefer.FirePlan:Find(configId)
        local tasks = {}
        for i = 1, cfg:RelatedTaskLength() do
            local taskLink = cfg:RelatedTask(i)
            local curTask = ModuleRefer.QuestModule:GetTaskLinkCurTask(taskLink)
            if not curTask or curTask == 0 then
                goto continue
            end
            table.insert(tasks, curTask)
            ::continue::
        end
        for _, taskId in ipairs(tasks) do
            local provider = require("TaskItemDataProvider").new(taskId)
            if provider:GetTaskState() == wds.TaskState.TaskStateCanFinish then
                return true
            end
        end
        return false
    elseif rewardType == ActivityRewardType.CityCompetition then
        local actId = ConfigRefer.ActivityCenterTabs:Find(tabId):RefActivityReward()
        local actCfg = ConfigRefer.ActivityRewardTable:Find(actId)
        local configId = actCfg:RefConfig()
        local cfg = ConfigRefer.CityCompetition:Find(configId)
        local taskId = cfg:RelatedTask()
        local provider = require("TaskItemDataProvider").new(taskId)
        return provider:GetTaskState() == wds.TaskState.TaskStateCanFinish
    elseif rewardType == ActivityRewardType.LandExplore then
        local actId = ConfigRefer.ActivityCenterTabs:Find(tabId):RefActivityReward()
        local actCfg = ConfigRefer.ActivityRewardTable:Find(actId)
        local configId = actCfg:RefConfig()
        return ModuleRefer.ActivityLandformModule:IsAnyRewardCanReceive(configId) or ModuleRefer.LandformTaskModule:GetGeneralNotifyState()
    elseif tabId == ActivityCenterConst.AllianceBossEventFirst or tabId == ActivityCenterConst.AllianceBossEventWeekly then
        return ModuleRefer.AllianceBossEventModule:HasCanClaimPlayerReward(tabId) or ModuleRefer.AllianceBossEventModule:HasCanClaimAllianceReward(tabId)
    else
        return false
    end
end

---@return boolean, boolean
function ActivityCenterModule:HasNotify()
    local gamePlayNotify = false
    local commercialNotify = false
    for _, tab in ConfigRefer.ActivityCenterTabs:ipairs() do
        if self:HasActivityNotify(tab:Id()) and self:IsActivityTabOpen(tab) then
            if self:GetActivityClass(tab:Id()) == ActivityClass.GamePlay then
                gamePlayNotify = true
            elseif self:GetActivityClass(tab:Id()) == ActivityClass.Commercial then
                commercialNotify = true
            end
        end
    end
    return gamePlayNotify, commercialNotify
end

---@param tabId number
---@return boolean
function ActivityCenterModule:IsActivityTabOpenByTabId(tabId)
    local tab = ConfigRefer.ActivityCenterTabs:Find(tabId)
    return self:IsActivityTabOpen(tab)
end

---@param tabId number
---@return number @ActivityClass
function ActivityCenterModule:GetActivityClass(tabId)
    local tab = ConfigRefer.ActivityCenterTabs:Find(tabId)
    if tab:Class() == 0 then
        return ActivityClass.GamePlay
    end
    return tab:Class()
end

---@param tabId number
---@return google.protobuf.Timestamp, google.protobuf.Timestamp
function ActivityCenterModule:GetActivityTabStartEndTime(tabId)
    local tab = ConfigRefer.ActivityCenterTabs:Find(tabId)
    local actRewardId = tab:RefActivityReward()
    for i = 1, tab:StagesLength() do
        local stage = tab:Stages(i)
        if self:IsActivityTemplateOpen(stage) then
            return self:GetActivityStartEndTimeByActivityTemplateId(stage)
        end
    end
    if actRewardId and actRewardId > 0 then
        return self:GetActivityStartEndTime(actRewardId)
    end
    return google.protobuf.Timestamp.New(), google.protobuf.Timestamp.New()
end

---@param tabId number
---@param category number
---@return google.protobuf.Timestamp, google.protobuf.Timestamp
function ActivityCenterModule:GetActivityStartEndTimeByCategory(tabId, category)
    local tab = ConfigRefer.ActivityCenterTabs:Find(tabId)
    for i = 1, tab:StagesLength() do
        local stageId = tab:Stages(i)
        if tab:Category(i) == category then
            return self:GetActivityStartEndTimeByActivityTemplateId(stageId)
        end
    end
    return google.protobuf.Timestamp.New(), google.protobuf.Timestamp.New()
end

---@param tabId number
---@return number
function ActivityCenterModule:GetActivityAutoRewardType(tabId)
    local tab = ConfigRefer.ActivityCenterTabs:Find(tabId)
    local rewardCfg = ConfigRefer.ActivityRewardTable:Find(tab:RefActivityReward())
    if not rewardCfg then return 0 end
    return rewardCfg:Type()
end

---@param tab ActivityCenterTabsConfigCell
---@return boolean
function ActivityCenterModule:IsActivityTabOpen(tab)
    if self:GMOpenAllActivity() then return true end
    return self.checker:Check(tab)
end

function ActivityCenterModule:UpdateNewlyUnlockStatus()
    for _, tab in ConfigRefer.ActivityCenterTabs:ipairs() do
        local tabId = tab:Id()
        local tabKey = ClientDataKeys.GameData.ActivityCenterTab + tabId
        local isUnlock = ModuleRefer.ClientDataModule:GetData(tabKey)
        if isUnlock == nil then
            self.newlyUnlockStatus[tabId] = true
            ModuleRefer.ClientDataModule:SetData(tabKey, 1)
        else
            local isNewlyUnlock = isUnlock == '1'
            self.newlyUnlockStatus[tabId] = isNewlyUnlock
        end
    end
end

function ActivityCenterModule:GetActivityCategory(tabId)
    local cfg = ConfigRefer.ActivityCenterTabs:Find(tabId)
    for i = 1, cfg:StagesLength() do
        local stage = cfg:Stages(i)
        if self:IsActivityTemplateOpen(stage) then
            return cfg:Category(i)
        end
    end
    return ActivityCategory.Regular
end

function ActivityCenterModule:GetTabNewlyUnlockStatus(tabId)
    return self.newlyUnlockStatus[tabId]
end

function ActivityCenterModule:IsActivityTabNewlyUnlock(tabId)
    return self.newlyUnlockStatus[tabId] and self:IsActivityTabOpen(ConfigRefer.ActivityCenterTabs:Find(tabId))
end

function ActivityCenterModule:ClearTabNewlyUnlockStatus(tabId)
    if not self.newlyUnlockStatus[tabId] then return end
    self.newlyUnlockStatus[tabId] = false
    local tabKey = ClientDataKeys.GameData.ActivityCenterTab + tabId
    ModuleRefer.ClientDataModule:SetData(tabKey, 0)
    self:UpdateRedDotByTabId(tabId)
end

---@param tabId number
function ActivityCenterModule:GotoActivity(tabId)
    if self:IsActivityTabOpenByTabId(tabId) then
        if self:GetActivityClass(tabId) == ActivityClass.GamePlay then
            ---@type EarthRevivalUIParameter
            local data = {}
            data.tabIndex = require("EarthRevivalDefine").EarthRevivalTabType.News
            data.defaultActivityId = tabId
            ModuleRefer.EarthRevivalModule:OpenEarthRevivalMediator(data)
        elseif self:GetActivityClass(tabId) == ActivityClass.Commercial then
            ---@type ActivityCenterOpenParam
            local data = {}
            data.tabId = tabId
            g_Game.UIManager:Open(UIMediatorNames.ActivityCenterMediator, data)
        end
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_challenge_state1"))
    end
end

function ActivityCenterModule:GetTurntableCostItemId()
    local cfg = ConfigRefer.Turntable:Find(1)
    local costLength = cfg:TurnCostItemLength()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curRound = player.PlayerWrapper2.PlayerAutoReward.Rewards[2].TurntableParam.Round + 1
    curRound = math.min(curRound, costLength)
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:TurnCostItem(curRound))[1]
    local costItemId = costItem.configCell:Id()
    return costItemId
end

function ActivityCenterModule:GetTurntableCostItemCurAmount()
    local cfg = ConfigRefer.Turntable:Find(1)
    local costLength = cfg:TurnCostItemLength()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curRound = player.PlayerWrapper2.PlayerAutoReward.Rewards[2].TurntableParam.Round + 1
    curRound = math.min(curRound, costLength)
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:TurnCostItem(curRound))[1]
    local costItemId = costItem.configCell:Id()
    local costItemUid = ModuleRefer.InventoryModule:GetUidByConfigId(costItemId)
    local amount = ModuleRefer.InventoryModule:GetAmountByUid(costItemUid)
    return amount
end

---@param gmOpenAllActivity boolean | nil
---@return boolean
function ActivityCenterModule:GMOpenAllActivity(gmOpenAllActivity)
    if gmOpenAllActivity ~= nil then
        self.gmOpenAllActivity = gmOpenAllActivity
    end
    return self.gmOpenAllActivity
end

---@param type number
function ActivityCenterModule:GetCurOpeningAutoRewardId(type)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local rewards = player.PlayerWrapper2.PlayerAutoReward.Rewards
    for k, v in pairs(rewards) do
        local cfg = ConfigRefer.ActivityRewardTable:Find(k)
        local thisType = cfg:Type()
        if thisType == type and v.Open then
            return k
        end
    end
    return 0
end

---@param getMoreCfg GetMoreConfigCell
function ActivityCenterModule:GetOpeningActivityFromGetMoreCfg(getMoreCfg, index)
    if not getMoreCfg then return 0 end
    local gotoCfg = getMoreCfg:Goto(index)
    for i = 1, gotoCfg:GotoActivityLength() do
        local activityId = gotoCfg:GotoActivity(i)
        if self:IsActivityTabOpenByTabId(activityId) then
            return activityId
        end
    end
    return 0
end

--拿到第一个TabId
---@param getMoreCfg GetMoreConfigCell
function ActivityCenterModule:GetTabIdFromGetMoreCfg(getMoreCfg, index)
    if not getMoreCfg then return 0 end
    local tabId = 0
    local gotoCfg = getMoreCfg:Goto(index)
    for i = 1, gotoCfg:GotoActivityLength() do
        tabId = gotoCfg:GotoActivity(i)
        if self:IsActivityTabOpenByTabId(tabId) then
            return tabId , true
        end
    end
    return tabId , false
end

return ActivityCenterModule