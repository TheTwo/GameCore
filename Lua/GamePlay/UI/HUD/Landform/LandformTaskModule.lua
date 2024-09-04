local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local LandformTaskState = require("LandformTaskState")
local LandTaskType = require("LandTaskType")
local KingdomMapUtils = require("KingdomMapUtils")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local NotificationType = require("NotificationType")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local LandformTaskState = require("LandformTaskState")

---@class LandformTaskModule :BaseModule
---@field descKeyMap table<number, string>
---@field notifyStates table<number, boolean>
local LandformTaskModule = class("LandformTaskModule", BaseModule)

LandformTaskModule.NotifyHudRootUniqueName = "LandformTask_HudRoot"
LandformTaskModule.NotifyActivityRootUniqueName = "LandformTask_Activity"
LandformTaskModule.NotifyTabUniqueName = "LandformTask_Tab"
LandformTaskModule.NotifyCellUniqueName = "LandformTask_Cell"

function LandformTaskModule:OnRegister()
    self.descKeyMap =
    {
        [LandTaskType.FistKill] = "landtask_info_task_1",
        [LandTaskType.FallCastle] = "landtask_info_task_2",
        [LandTaskType.MistUnlock] = "landtask_info_task_3",
        [LandTaskType.PetGet] = "landtask_info_task_4",
        [LandTaskType.KillMonster] = "landexplore_task_contant_monster",
    }
    
    self.notifyStates = {}
    local hudRootNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyHudRootUniqueName, NotificationType.LANDFORM_TASK_MAIN)
    local activityRootNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyActivityRootUniqueName, NotificationType.LANDFORM_TASK_MAIN)
    for _, config in ConfigRefer.Land:ipairs() do
        local layer = config:LayerNum()
        local tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyTabUniqueName .. layer, NotificationType.LANDFORM_TASK_MAIN)
        ModuleRefer.NotificationModule:AddToParent(tabNode, hudRootNode)
        ModuleRefer.NotificationModule:AddToParent(tabNode, activityRootNode)
        local cellNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyCellUniqueName .. layer, NotificationType.LANDFORM_TASK_MAIN)
        ModuleRefer.NotificationModule:AddToParent(cellNode, hudRootNode)
        ModuleRefer.NotificationModule:AddToParent(cellNode, activityRootNode)
    end
    self:OnActivityInfoChange()
        
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.Landform.LandActivityInfos.MsgPath, Delegate.GetOrCreate(self, self.OnActivityInfoChange))
end

function LandformTaskModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.Landform.LandActivityInfos.MsgPath, Delegate.GetOrCreate(self, self.OnActivityInfoChange))
end

function LandformTaskModule:OnActivityInfoChange()
   self:RefreshNotifications()
end

function LandformTaskModule:RefreshNotifications()
    for _, config in ConfigRefer.Land:ipairs() do
        local landformConfigID = config:Id()
        local activityInfo = self:GetActivityInfo(landformConfigID)
        if activityInfo then
            local landformConfig = ConfigRefer.Land:Find(landformConfigID)
            local states = self:GetStageRewardStates(activityInfo, landformConfig)
            local notify = false
            for _, state in ipairs(states) do
                if state == LandformTaskState.CanClaim then
                    notify = true
                    break
                end
            end
            self.notifyStates[landformConfigID] = notify
        end
    end
    for landformConfigID, state in pairs(self.notifyStates) do
        local config = ConfigRefer.Land:Find(landformConfigID)
        local layer = config:LayerNum()
        local tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyTabUniqueName .. layer, NotificationType.LANDFORM_TASK_MAIN)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(tabNode, state and 1 or 0)
        local cellNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyCellUniqueName .. layer, NotificationType.LANDFORM_TASK_MAIN)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(cellNode, state and 1 or 0)
    end
end

function LandformTaskModule:GetGeneralNotifyState()
    for _, state in pairs(self.notifyStates) do
        if state then
            return true
        end
    end
    return false
end

function LandformTaskModule:GetNotifyState(landformConfigID)
    return self.notifyStates[landformConfigID]
end

function LandformTaskModule:GetActivityInfo(landformConfigID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local activityInfos = player.PlayerWrapper3.Landform.LandActivityInfos
    return activityInfos[landformConfigID]
end

---@param activityInfo wds.LandActivityInfo
function LandformTaskModule:GetCurrentScore(activityInfo)
    return activityInfo and activityInfo.CurScore or 0
end

---@param activityInfo wds.LandActivityInfo
---@param landformConfig LandConfigCell
---@return number[] @AllianceBossEventRewardState
function LandformTaskModule:GetStageRewardStates(activityInfo, landformConfig)
    local result = {}
    local length = landformConfig:ActivityRewardScoresLength()
    if activityInfo then
        local currentScore = activityInfo.CurScore
        for i = 1, length do
            local scoreLimit = landformConfig:ActivityRewardScores(i)
            if currentScore < scoreLimit then
                table.insert(result, LandformTaskState.NotClaimed)
            else
                if activityInfo.RewardScores[scoreLimit] then
                    table.insert(result, LandformTaskState.Claimed)
                else
                    table.insert(result, LandformTaskState.CanClaim)
                end
            end
        end
    else
        for i = 1, length do
            table.insert(result, LandformTaskState.NotClaimed)
        end
    end
    return result
end

function LandformTaskModule:RequestClaimReward(landformConfigID, score)
    local parameter = require("LandActivityGetRewardParameter").new()
    parameter.args.LandId = landformConfigID
    parameter.args.RewardScore = score
    parameter:Send()
end

---@param activityInfo wds.LandActivityInfo
function LandformTaskModule:GetTaskDesc(activityInfo, taskID)
    local taskConfig = ConfigRefer.LandTask:Find(taskID)
    local taskType = taskConfig:TaskType()
    local descKey = self.descKeyMap[taskType]
    if taskType == LandTaskType.FistKill then
        local firstParam = taskConfig:TaskParams(1)
        local lastParam = taskConfig:TaskParams(taskConfig:TaskParamsLength())
        local levelRange = ("%d-%d"):format(firstParam, lastParam)
        local currentParam = ModuleRefer.WorldSearchModule:GetCanAttackNormalMobLevel()
        return I18N.GetWithParams(descKey, levelRange, currentParam)
    end
    
    local desc = string.Empty
    local currentCount = activityInfo and activityInfo.TaskFinishCount[taskID] or 0 
    local maxCount = taskConfig:MaxTimes()
    if taskType == LandTaskType.PetGet then
        local param = taskConfig:TaskParams(1)
        local petConfig = ConfigRefer.Pet:Find(param)
        local petName = I18N.Get(petConfig:Name())
        desc = I18N.GetWithParams(descKey, petName)
    elseif taskType == LandTaskType.KillMonster then
        local param = taskConfig:TaskParams(1)
        desc = I18N.GetWithParams(descKey, param)
    else
        desc = I18N.Get(descKey)
    end
    desc = desc .. ("(%d/%d)"):format(currentCount, maxCount)
    return desc
end

function LandformTaskModule:GetTaskRewardDesc(taskID)
    local taskConfig = ConfigRefer.LandTask:Find(taskID)
    if self:IsRepeatTask(taskConfig) then
        return I18N.GetWithParams("landtask_info_score_every_time", taskConfig:ScoreAddPerTime())
    else
        return I18N.GetWithParams("landtask_info_score_one_time", taskConfig:ScoreAddPerTime())
    end
end

---@param activityInfo wds.LandActivityInfo
function LandformTaskModule:CheckTaskFinished(activityInfo, taskID)
    local taskConfig = ConfigRefer.LandTask:Find(taskID)
    if self:IsRepeatTask(taskConfig) then
        local index = activityInfo and activityInfo.TaskFinishCount[taskID] or 0
        return index >= taskConfig:TaskParamsLength()
    else
        local currentCount = activityInfo and activityInfo.TaskFinishCount[taskID] or 0
        local maxCount = taskConfig:MaxTimes()
        return currentCount >= maxCount
    end
end

function LandformTaskModule:GotoTask(taskType, landformConfigID)
    local gotoFunc = function()
        if taskType == LandTaskType.FallCastle then
            ModuleRefer.LandformModule:GotoLandform(landformConfigID)
        elseif taskType == LandTaskType.FistKill or
                taskType == LandTaskType.KillMonster then
            local searchType = require("SearchEntityType").NormalMob
            g_Game.UIManager:Open(UIMediatorNames.UIWorldSearchMediator, {selectType = searchType})
        elseif taskType == LandTaskType.MistUnlock then
            --todo
        elseif taskType == LandTaskType.PetGet then
            ---@type RadarMediatorParam
            local param = 
            {
                isInCity = false,
            }
            g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)
        end
    end
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    if not KingdomMapUtils.IsMapState() then
        KingdomMapUtils.GetKingdomScene():LeaveCity(gotoFunc)
    else
        gotoFunc()
    end
end

---@param taskConfig LandTaskConfigCell
function LandformTaskModule:IsRepeatTask(taskConfig)
    return taskConfig and taskConfig:TaskParamsLength() > 1
end

return LandformTaskModule