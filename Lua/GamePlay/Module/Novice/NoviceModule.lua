local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local NoviceConst = require('NoviceConst')
local ReceiveActivityRewardParameter = require('ReceiveActivityRewardParameter')
local ConfigRefer = require('ConfigRefer')
local NotificationType = require('NotificationType')
local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
local Utils = require('Utils')
local EventConst = require('EventConst')
---@class NoviceModule : BaseModule
local NoviceModule = class('NoviceModule', BaseModule)

function NoviceModule:OnRegister()
    self._SetNotificationNodes()
    self:Init()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.RedDotSecondTicker))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetRedDotDirty))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerActivityReward.MsgPath, Delegate.GetOrCreate(self, self.Init))
    ModuleRefer.InventoryModule:AddCountChangeListener(self.scoreItemId, Delegate.GetOrCreate(self, self.SetRedDotDirty))
end

function NoviceModule:OnRemove()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.RedDotSecondTicker))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetRedDotDirty))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerActivityReward.MsgPath, Delegate.GetOrCreate(self, self.Init))
    ModuleRefer.InventoryModule:RemoveCountChangeListener(self.scoreItemId, Delegate.GetOrCreate(self, self.SetRedDotDirty))
end

function NoviceModule:GetOpenTime()
    return self.rewardData.OpenTime
end

function NoviceModule:Init()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self.rewardData = {}
    Utils.CopyTable(player.PlayerWrapper2.PlayerActivityReward.Data[NoviceConst.ActivityId], self.rewardData)
    self.rewardData.rewardTypes = self._GetRewardsType()
    self.rewardData.spRewardNum = self:_GetSpecialRewardNum()
    self.actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    self.scoreItemId = self.actCfg:ScoreItem()
    self.rewardData.taskIdList = {}
    for i = 1, NoviceConst.MAX_DAY do
        self.rewardData.taskIdList[i] = {}
        for j = 1, NoviceConst.MaxSubTabCount do
            self.rewardData.taskIdList[i][j] = self:_GetTaskIdListByDayAndType(i, j)
        end
    end
    self:UpdateRedDot()
end

--- 奖励相关逻辑 ---

function NoviceModule:GetNoviceTaskScore()
    local score = ModuleRefer.InventoryModule:GetAmountByConfigId(self.scoreItemId)
    return score
end

function NoviceModule:ClaimNoviceTaskReward(index, lockable)
    local tid = NoviceConst.ActivityId
    local msg = ReceiveActivityRewardParameter.new()
    msg.args.Tid = tid
    msg.args.Index = index - 1
    msg:Send(lockable)
end

function NoviceModule:GetAllRewardOpenStatusCache()
    local cache = {}
    Utils.CopyTable(self.rewardData.NormalRewardReceived, cache)
    return cache
end

function NoviceModule:GetRewardOpenStatus(index)
    return self.rewardData.NormalRewardReceived[index]
end

function NoviceModule:IsRewardOpened(index)
    return self.rewardData.NormalRewardReceived[index]
end

function NoviceModule:GetRewardTypes()
    return self.rewardData.rewardTypes
end

function NoviceModule:GetRewardNeededScore(index)
    local actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    return actCfg:RewardRequireItemCount(index)
end

function NoviceModule:IsRewardCanClaim(index)
    return self:GetNoviceTaskScore() >= self:GetRewardNeededScore(index)
end

function NoviceModule._GetRewardsType()
    local actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    local rewardTypes = {}
    for i = 1, actCfg:RewardNormalLength() do
        rewardTypes[i] = NoviceConst.RewardType.Normal
        for j = 1, actCfg:SpecialRewardIndexLength() do
            if actCfg:RewardRequireItemCount(i) == actCfg:SpecialRewardIndex(j) then
                rewardTypes[i] = NoviceConst.RewardType.High
                break
            end
        end
    end
    return rewardTypes
end

function NoviceModule:GetSpeicalRewardConfig(index)
    local actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    local rewardId = actCfg:RewardNormal(index)
    local spReward = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardId)[1]
    return spReward.configCell
end

function NoviceModule:_GetSpecialRewardNum()
    local rewardTypes = self._GetRewardsType()
    local spRewardNum = 0
    for i = 1, #rewardTypes do
        if rewardTypes[i] == NoviceConst.RewardType.High then
            spRewardNum = spRewardNum + 1
        end
    end
    return spRewardNum
end

function NoviceModule:GetSpecialRewardNum()
    return self.rewardData.spRewardNum
end

function NoviceModule:GetScoreItemId()
    return self.scoreItemId
end

function NoviceModule:GetSpecialRewardIdxs()
    local idxs = {}
    for i = 1, #self.rewardData.rewardTypes do
        if self.rewardData.rewardTypes[i] == NoviceConst.RewardType.High then
            idxs[#idxs + 1] = i
        end
    end
    return idxs
end

--- end of 奖励相关逻辑 ---

--- 任务相关逻辑 ---

function NoviceModule:GetUnlockDate(index)
    local openTime = self.rewardData.OpenTime
    local unlockTime = openTime + (index - 1) * 86400
    local date = os.date('*t', unlockTime)
    return date
end

function NoviceModule:GetUnlockLeftDayCount(index)
    local openTime = self.rewardData.OpenTime
    local unlockTime = openTime + (index - 1) * 86400
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftTime = unlockTime - curTime
    return math.ceil(leftTime / 86400)
end

function NoviceModule:GetCurrentDay()
    return self.rewardData.CurOpenTaskList + 1
end

---@private
---@param day number
---@param type number
---@return number[]
function NoviceModule:_GetTaskIdListByDayAndType(day, type)
    local taskIds = {}
    local actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    local taskGroups = actCfg:TaskGroupList(day)
    for i = 1, taskGroups:GroupLength() do
        local groupId = taskGroups:Group(i)
        local group = ConfigRefer.ActivityTaskGroup:Find(groupId)
        if tonumber(group:Group()) == type then
            for j = 1, group:TasksLength() do
                taskIds[j] = group:Tasks(j)
            end
            break
        end
    end
    return taskIds
end

---@public
function NoviceModule:GetTaskIdListByDayAndType(day, type)
    if not day or not type then return {} end
    return self.rewardData.taskIdList[day][type]
end

function NoviceModule:IsTaskCanClaimByDayAndType(day, type)
    for _, taskId in ipairs(self:GetTaskIdListByDayAndType(day, type)) do
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        if taskState == wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    return false
end

--- end of 任务相关逻辑 ---

--- 红点相关逻辑 ---

function NoviceModule:RedDotSecondTicker()
    if self.isRedDotDirty then
        self.isRedDotDirty = false
        self:UpdateRedDot()
    end
end

function NoviceModule:SetRedDotDirty()
    self.isRedDotDirty = true
end

function NoviceModule._SetNotificationNodes()
    local hudNoviceEntryNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        NoviceConst.NoviceNotificationNodeNames.NoviceEntry, NotificationType.NOVICE_HUD)
    local novicePopupBtnNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        NoviceConst.NoviceNotificationNodeNames.NovicePopupBtn, NotificationType.NOVICE_POPUP_BTN)
    local actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    for i = 1, actCfg:RewardNormalLength() do
        local noviceRewardNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
            NoviceConst.NoviceNotificationNodeNames.NoviceReward .. i, NotificationType.NOVICE_REWARD)
        ModuleRefer.NotificationModule:AddToParent(noviceRewardNode, hudNoviceEntryNode)
        ModuleRefer.NotificationModule:AddToParent(noviceRewardNode, novicePopupBtnNode)
    end
    for i = 1, NoviceConst.MAX_DAY do
        local noviceDayTabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
            NoviceConst.NoviceNotificationNodeNames.NoviceDayTab .. i, NotificationType.NOVICE_DAY_TAB)
        ModuleRefer.NotificationModule:AddToParent(noviceDayTabNode, hudNoviceEntryNode)
        ModuleRefer.NotificationModule:AddToParent(noviceDayTabNode, novicePopupBtnNode)
    end
end

function NoviceModule:UpdateRedDot()
    local actCfg = ConfigRefer.ActivityReward:Find(NoviceConst.ActivityId)
    for i = 1, actCfg:RewardNormalLength() do
        local rewardNode = ModuleRefer.NotificationModule:GetDynamicNode(
            NoviceConst.NoviceNotificationNodeNames.NoviceReward .. i, NotificationType.NOVICE_REWARD)
        local shouldShowRewardRedDot = self:IsRewardCanClaim(i) and not self:IsRewardOpened(i)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(rewardNode, shouldShowRewardRedDot and 1 or 0)
    end
    for i = 1, math.min(self:GetCurrentDay(), NoviceConst.MAX_DAY) do
        local dayTabNode = ModuleRefer.NotificationModule:GetDynamicNode(
            NoviceConst.NoviceNotificationNodeNames.NoviceDayTab .. i, NotificationType.NOVICE_DAY_TAB)
        local shouldShowDayTabRedDot = false
        for j = 1, NoviceConst.MaxSubTabCount do
            for _, taskId in ipairs(self:GetTaskIdListByDayAndType(i, j)) do
                local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
                if taskState == wds.TaskState.TaskStateCanFinish then
                    shouldShowDayTabRedDot = true
                    break
                end
            end
        end
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(dayTabNode, shouldShowDayTabRedDot and 1 or 0)
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_NOVICE_REDDOT_UPDATE)
end

--- end of 红点相关逻辑 ---

return NoviceModule