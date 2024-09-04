local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local ActivityRewardType = require("ActivityRewardType")
local BattlePassConst = require('BattlePassConst')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local EventConst = require('EventConst')
local NotificationType = require('NotificationType')
local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
---@class BattlePassModule : BaseModule
---@field lookupTable table<number, BattlePassData>
local BattlePassModule = class('BattlePassModule', BaseModule)

---@class BattlePassNodeInfo
---@field normal number @ItemGroupId
---@field adv number @ItemGroupId
---@field neededExp number
---@field buyLevelCost number @ItemGroupId
---@field cumulativeExp number

---@class BattlePassData
---@field cfg BattlePassConfigCell @read only
---@field dataId number
---@field actId number @ActivityRewardTable cfgId
---@field dailyTasks table<number, number>
---@field weeklyTasks table<number, number>
---@field seasonTasks table<number, number>
---@field nodeInfos table<number, BattlePassNodeInfo>
---@field spRewardIndices table<number, boolean>
---@field disPlayRewardIndex table<number, number>

function BattlePassModule:OnRegister()
    self:InitLookupTable()
    self:SetupReddot()
    self:UpdateReddot()

    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.RedDotSecondTicker))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath, Delegate.GetOrCreate(self, self.SetReddotDirty))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetReddotDirty))
end

function BattlePassModule:OnRemove()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.RedDotSecondTicker))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath, Delegate.GetOrCreate(self, self.SetReddotDirty))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self, self.SetReddotDirty))
end

function BattlePassModule:InitLookupTable()
    ---@type table<number, BattlePassData>
    self.lookupTable = {}
    for _, cfg in ConfigRefer.ActivityRewardTable:ipairs() do
        if cfg:Type() == ActivityRewardType.BattlePass then
            local battlePassCfgId = cfg:RefConfig()
            local battlePassCfg = ConfigRefer.BattlePass:Find(battlePassCfgId)
            self.lookupTable[battlePassCfgId] = {}
            self.lookupTable[battlePassCfgId].cfg = battlePassCfg
            self.lookupTable[battlePassCfgId].actId = cfg:Id()
            local player = ModuleRefer.PlayerModule:GetPlayer()
            for i, reward in pairs(player.PlayerWrapper2.PlayerAutoReward.Rewards) do
                if reward.ConfigId == cfg:Id() then
                    self.lookupTable[battlePassCfgId].dataId = i
                end
            end
            local spRewardIndices = {}
            for i = 1, battlePassCfg:SpRewardIndexLength() do
                spRewardIndices[battlePassCfg:SpRewardIndex(i)] = true
            end
            self.lookupTable[battlePassCfgId].spRewardIndices = spRewardIndices
            local disPlayRewardIndex = {}
            for i = 1, battlePassCfg:DisplayRewardIndexLength() do
                table.insert(disPlayRewardIndex, battlePassCfg:DisplayRewardIndex(i))
            end
            self.lookupTable[battlePassCfgId].disPlayRewardIndex = disPlayRewardIndex
        end
    end
end

---@private
function BattlePassModule:GetData(cfgId, key)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local dataId = self.lookupTable[cfgId].dataId
    if not dataId or not player then return nil end
    return ((player.PlayerWrapper2.PlayerAutoReward.Rewards[dataId] or {}).BattlePassParam or {})[key]
end

--- Interfaces ---

function BattlePassModule:GetDataIdByCfgId(cfgId)
    return self.lookupTable[cfgId].dataId
end

--- 获取当前等级
---@param cfgId number
---@return number
function BattlePassModule:GetLevelByCfgId(cfgId)
    return self:GetData(cfgId, 'Level') or 0
end

--- 获取当前等级已获得的经验
---@param cfgId number
---@return number
function BattlePassModule:GetExpByCfgId(cfgId)
    return self:GetData(cfgId, 'Exp') or 0
end

--- 获取本周已获得的经验
---@param cfgId number
---@return number
function BattlePassModule:GetWeekExpByCfgId(cfgId)
    return self:GetData(cfgId, 'WeekExp') or 0
end

--- 获取每周经验上限
---@param cfgId number
---@return number
function BattlePassModule:GetWeekExpLimitByCfgId(cfgId)
    local cfg = (self.lookupTable[cfgId] or {}).cfg
    if not cfg then return 1 end
    return cfg:MaxExpPerWeek()
end

--- 获取已领取的普通奖励等级
---@param cfgId number
function BattlePassModule:GetReceivedNormalLevelByCfgId(cfgId)
    return self:GetData(cfgId, 'ReceivedNormalLevel') or {}
end

--- 获取已领取的进阶奖励等级
---@param cfgId number
function BattlePassModule:GetReceivedAdvLevelByCfgId(cfgId)
    return self:GetData(cfgId, 'ReceivedVIPLevel') or {}
end

--- 是否购买进阶版
---@param cfgId number
---@return boolean
function BattlePassModule:IsVIP(cfgId)
    return self:GetData(cfgId, 'VIP') or false
end

--- 获取轮播奖励下标
---@param cfgId number
---@return table<number, number>
function BattlePassModule:GetDisplayRewardIndex(cfgId)
    return (self.lookupTable[cfgId] or {}).disPlayRewardIndex or {}
end

--- 获取轮播奖励道具
---@param cfgId number
---@return number[]
function BattlePassModule:GetDisplayRewardItems(cfgId)
    local cfg = (self.lookupTable[cfgId] or {}).cfg
    if not cfg then return {} end
    local ret = {}
    for i = 1, cfg:DisplayRewardItemsLength() do
        table.insert(ret, cfg:DisplayRewardItems(i))
    end
    return ret
end

function BattlePassModule:GetProgressItemId(cfgId)
    local cfg = (self.lookupTable[cfgId] or {}).cfg
    if not cfg then return 0 end
    return cfg:ProgressPointItem()
end

---@param cfgId number
---@return table<number, number>
function BattlePassModule:GetDailyTasksByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return {} end
    local dailyTasks = self.lookupTable[cfgId].dailyTasks
    if dailyTasks then
        return dailyTasks
    end
    local cfg = self.lookupTable[cfgId].cfg
    dailyTasks = {}
    for j = 1, cfg:DailyTasksLength() do
        local taskGroupId = cfg:DailyTasks(j)
        local taskGroupCfg = ConfigRefer.TaskGroup:Find(taskGroupId)
        for i = 1, taskGroupCfg:TasksLength() do
            table.insert(dailyTasks, taskGroupCfg:Tasks(i))
        end
    end
    self.lookupTable[cfgId].dailyTasks = dailyTasks
    return dailyTasks
end

---@param cfgId number
---@return table<number, number>
function BattlePassModule:GetWeeklyTasksByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return {} end
    local weeklyTasks = self.lookupTable[cfgId].weeklyTasks
    if weeklyTasks then
        return weeklyTasks
    end
    local cfg = self.lookupTable[cfgId].cfg
    weeklyTasks = {}
    for j = 1, cfg:WeeklyTasksLength() do
        local taskGroupId = cfg:WeeklyTasks(j)
        local taskGroupCfg = ConfigRefer.TaskGroup:Find(taskGroupId)
        for i = 1, taskGroupCfg:TasksLength() do
            table.insert(weeklyTasks, taskGroupCfg:Tasks(i))
        end
    end
    self.lookupTable[cfgId].weeklyTasks = weeklyTasks
    return weeklyTasks
end

---@param cfgId number
---@return table<number, number>
function BattlePassModule:GetSeasonTasksByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return {} end
    local seasonTasks = self.lookupTable[cfgId].seasonTasks
    if seasonTasks then
        return seasonTasks
    end
    local cfg = self.lookupTable[cfgId].cfg
    seasonTasks = {}
    for j = 1, cfg:ActivityTasksLength() do
        local taskGroupId = cfg:ActivityTasks(j)
        local taskGroupCfg = ConfigRefer.TaskGroup:Find(taskGroupId)
        for i = 1, taskGroupCfg:TasksLength() do
            table.insert(seasonTasks, taskGroupCfg:Tasks(i))
        end
    end
    self.lookupTable[cfgId].seasonTasks = seasonTasks
    return seasonTasks
end

---@param cfgId number
---@return table<number, BattlePassNodeInfo> | nil
function BattlePassModule:GetRewardInfosByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return nil end
    local cfg = self.lookupTable[cfgId].cfg
    local nodeInfos = self.lookupTable[cfgId].nodeInfos
    if nodeInfos then
        return nodeInfos
    end
    nodeInfos = {}
    for i = 1, cfg:NodesLength() do
        local node = cfg:Nodes(i)
        local normalRewards = node:Free()
        local advRewards = node:VIP()
        local neededExp = node:NeedExp()
        local buyLevelCost = node:BuyLevelCost()
        local costNum = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(buyLevelCost)[1].count
        if not normalRewards or not advRewards then
            break
        end
        local cumulativeExp = neededExp
        local cumulativeCostNum = costNum
        if i > 1 then
            cumulativeExp = nodeInfos[i - 1].cumulativeExp + neededExp
            cumulativeCostNum = nodeInfos[i - 1].cumulativeCostNum + costNum
        end
        nodeInfos[i] = {
            normal = normalRewards,
            adv = advRewards,
            neededExp = neededExp,
            cumulativeExp = cumulativeExp,
            buyLevelCost = buyLevelCost,
            cumulativeCostNum = cumulativeCostNum,
        }
    end
    self.lookupTable[cfgId].nodeInfos = nodeInfos
    return nodeInfos
end

---@param bpCfgId number
---@param nodeIndex number
---@return boolean
function BattlePassModule:IsSpecialReward(bpCfgId, nodeIndex)
    return ((self.lookupTable[bpCfgId] or {}).spRewardIndices or {})[nodeIndex] or false
end

---@param cfgId number
---@return number @PayGoods cfgId
function BattlePassModule:GetVIPGoodsByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return 0 end
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:VIPGood()
end

---@param cfgId number
---@return number @PayGoods cfgId
function BattlePassModule:GetSVIPGoodsByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return 0 end
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:SVIPGood()
end

---@param cfgId number
---@return number @PayGoods cfgId
function BattlePassModule:GetReplaceGoodsByCfgId(cfgId)
    if not self.lookupTable[cfgId] then return 0 end
    local cfg = self.lookupTable[cfgId].cfg
    return cfg:ReplaceGood()
end

function BattlePassModule:GetCurOpeningBattlePassId()
    local actId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    if actId == 0 then return 0 end
    local cfgId = ConfigRefer.ActivityRewardTable:Find(actId):RefConfig()
    return cfgId
end

--- end of Interfaces ---

--- Wraps ---

function BattlePassModule:GetMaxLevelByCfgId(cfgId)
    local nodeInfos = self:GetRewardInfosByCfgId(cfgId)
    if not nodeInfos then return 0 end
    return #nodeInfos
end

--- 获取当前等级的所需经验
---@param cfgId number
---@param lvl number
---@return number
function BattlePassModule:GetLevelNeededExp(cfgId, lvl)
    local nodeInfos = self:GetRewardInfosByCfgId(cfgId)
    if not nodeInfos or not nodeInfos[lvl] then return 1 end
    return nodeInfos[lvl].neededExp
end

--- 获取当前等级的累计经验
---@param cfgId number
---@param lvl number
---@return number
function BattlePassModule:GetLevelCumulativeExp(cfgId, lvl)
    local nodeInfos = self:GetRewardInfosByCfgId(cfgId)
    if not nodeInfos or not nodeInfos[lvl] then return 0 end
    return nodeInfos[lvl].cumulativeExp
end

---@param cfgId number
---@param type number
---@return table<number, number>
function BattlePassModule:GetTasksByTaskType(cfgId, type)
    if type == BattlePassConst.TASK_TAB_TYPE.DAILY then
        return self:GetDailyTasksByCfgId(cfgId)
    elseif type == BattlePassConst.TASK_TAB_TYPE.WEEKLY then
        return self:GetWeeklyTasksByCfgId(cfgId)
    elseif type == BattlePassConst.TASK_TAB_TYPE.SEASON then
        return self:GetSeasonTasksByCfgId(cfgId)
    end
    return {}
end

---@param cfgId number
---@param type number
---@return boolean
function BattlePassModule:IsAnyTaskRewardCanClaimByType(cfgId, type)
    local tasks = self:GetTasksByTaskType(cfgId, type)
    for _, taskId in ipairs(tasks) do
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        if taskState == wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    return false
end

---@param cfgId number
---@return boolean
function BattlePassModule:IsAnyTaskRewardCanClaim(cfgId)
    for _, taskType in pairs(BattlePassConst.TASK_TAB_TYPE) do
        if self:IsAnyTaskRewardCanClaimByType(cfgId, taskType) then
            return true
        end
    end
    return false
end

---@param cfgId number
---@return boolean
function BattlePassModule:IsAnyNodeRewardCanClaim(cfgId)
    local nodeInfos = self:GetRewardInfosByCfgId(cfgId)
    if not nodeInfos then return false end
    local curLevel = self:GetLevelByCfgId(cfgId)
    for i = 1, curLevel do
        local normalRewardStatus, advRewardStatus = self:GetRewardStatus(cfgId, i)
        if normalRewardStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE or advRewardStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE then
            return true
        end
    end
    return false
end

---@param cfgId number
---@param lvl number
---@return number, number @ normal reward, adv reward
function BattlePassModule:GetRewardStatus(cfgId, lvl)
    local normalRewardStatus = BattlePassConst.REWARD_STATUS.UNCLAIMABLE
    local advRewardStatus = BattlePassConst.REWARD_STATUS.UNCLAIMABLE
    local isVIP = self:IsVIP(cfgId)
    local receivedNormalLevel = self:GetReceivedNormalLevelByCfgId(cfgId)
    local receivedAdvLevel = self:GetReceivedAdvLevelByCfgId(cfgId)
    if self:GetLevelByCfgId(cfgId) >= lvl then
        if table.ContainsKey(receivedNormalLevel, lvl - 1) then -- 后端下标从0开始，下同
            normalRewardStatus = BattlePassConst.REWARD_STATUS.CLAIMED
        else
            normalRewardStatus = BattlePassConst.REWARD_STATUS.CLAIMABLE
        end
        if isVIP then
            if table.ContainsKey(receivedAdvLevel, lvl - 1) then
                advRewardStatus = BattlePassConst.REWARD_STATUS.CLAIMED
            else
                advRewardStatus = BattlePassConst.REWARD_STATUS.CLAIMABLE
            end
        end
    end
    if not isVIP then
        advRewardStatus = BattlePassConst.REWARD_STATUS.LOCKED
    end
    return normalRewardStatus, advRewardStatus
end

---@param cfgId number
---@param nodeIndex number
---@return number
function BattlePassModule:GetNextSpRewardIndex(cfgId, nodeIndex)
    local spRewardIndices = self.lookupTable[cfgId].spRewardIndices
    if not spRewardIndices then return 0 end
    local nextSpRewardIndex = 0
    for index, _ in pairs(spRewardIndices) do
        if index > nodeIndex then
            if nextSpRewardIndex == 0 or index < nextSpRewardIndex then
                nextSpRewardIndex = index
            end
        end
    end
    return nextSpRewardIndex
end

---@class BattlePassCostItemInfo
---@field id number
---@field count number

--- 获取购买等级所需的道具信息
---@param cfgId number
---@param lvl number
---@return BattlePassCostItemInfo | nil
function BattlePassModule:GetCostItemInfoForPurchaseLvl(cfgId, lvl)
    local cfg = (self.lookupTable[cfgId] or {}).cfg
    if not cfg then return nil end
    local nodeInfos = self:GetRewardInfosByCfgId(cfgId)
    if not nodeInfos then return nil end
    local costItemId = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(nodeInfos[1].buyLevelCost)[1].id
    local curLvl = self:GetLevelByCfgId(cfgId)
    if lvl + curLvl > #nodeInfos then return nil end
    local costItemNum = nodeInfos[lvl + curLvl].cumulativeCostNum - ((nodeInfos[curLvl] or {}).cumulativeCostNum or 0)
    local costItemInfo = {
        id = costItemId,
        count = costItemNum,
    }
    return costItemInfo
end

---@param actId number
---@param type number @BattlePassConst.REWARD_CLAIM_TYPE
---@param lvl number
---@param transform CS.UnityEngine.Transform
---@param callback fun()
function BattlePassModule:ClaimReward(actId, type, lvl, transform, callback)
    local op = wrpc.PlayerGetAutoReward()
    op.ConfigId = actId
    op.Arg1 = type
    if type ~= BattlePassConst.REWARD_CLAIM_TYPE.ALL then
        op.Arg2 = lvl - 1
    end
    local msg = PlayerGetAutoRewardParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(transform, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            if callback then
                callback()
            end
            g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_REWARD_CLAIM, lvl)
        end
    end)
end

function BattlePassModule:GetRemainTime(cfgId)
    local actId = (self.lookupTable[cfgId] or {}).actId
    if not actId then return 0 end
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTime(actId)
    if not endTime then return 0 end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local RemainTime = endTime.Seconds - curTime
    return RemainTime
end

--- end of Wraps ---

--- reddot ---

function BattlePassModule:SetupReddot()
    local hudNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(BattlePassConst.NOTIFY_NAMES.ENTRY, NotificationType.BATTLEPASS_HUD)
    local taskNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(BattlePassConst.NOTIFY_NAMES.TASK, NotificationType.BATTLEPASS_TASK)
    for _, taskType in pairs(BattlePassConst.TASK_TAB_TYPE) do
        local taskTabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(BattlePassConst.NOTIFY_NAMES.TASK .. taskType, NotificationType.BATTLEPASS_TASK_SUB)
        ModuleRefer.NotificationModule:AddToParent(taskTabNode, taskNode)
    end
    ModuleRefer.NotificationModule:AddToParent(taskNode, hudNode)
    local rewardNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(BattlePassConst.NOTIFY_NAMES.REWARD, NotificationType.BATTLEPASS_REWARD)
    ModuleRefer.NotificationModule:AddToParent(rewardNode, hudNode)
end

function BattlePassModule:UpdateReddot()
    local id = self:GetCurOpeningBattlePassId()
    for _, taskType in pairs(BattlePassConst.TASK_TAB_TYPE) do
        local isTaskRewardCanClaim = self:IsAnyTaskRewardCanClaimByType(id, taskType)
        local taskTabNode = ModuleRefer.NotificationModule:GetDynamicNode(BattlePassConst.NOTIFY_NAMES.TASK .. taskType, NotificationType.BATTLEPASS_TASK_SUB)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(taskTabNode, isTaskRewardCanClaim and 1 or 0)
    end
    local isAnyNodeRewardCanClaim = self:IsAnyNodeRewardCanClaim(id)
    local rewardNode = ModuleRefer.NotificationModule:GetDynamicNode(BattlePassConst.NOTIFY_NAMES.REWARD, NotificationType.BATTLEPASS_REWARD)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(rewardNode, isAnyNodeRewardCanClaim and 1 or 0)
end

function BattlePassModule:RedDotSecondTicker()
    if self.isRedDotDirty then
        self.isRedDotDirty = false
        self:UpdateReddot()
    end
end

function BattlePassModule:SetReddotDirty()
    self.isRedDotDirty = true
end

return BattlePassModule