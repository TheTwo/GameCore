local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local DBEntityPath = require('DBEntityPath')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Utils = require("Utils")
local EventConst = require("EventConst")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
local UIMediatorNames = require("UIMediatorNames")
local NotificationType = require("NotificationType")
local CityConst = require('CityConst')
local KingdomMapUtils = require('KingdomMapUtils')
local NpcServiceObjectType = require('NpcServiceObjectType')
local TaskConfigUtils = require('TaskConfigUtils')

---@class AllianceJourneyModule
local AllianceJourneyModule = class('AllianceJourneyModule', BaseModule)
function AllianceJourneyModule:ctor()
    self._allianceTasks = {}
    self._shortTermTasks = {}
    self._longTermTasks = {}
    self._leaderTasks = {}
end

function AllianceJourneyModule:OnRegister()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.Task.Processing.MsgPath, Delegate.GetOrCreate(self, self.RefreshTaskProcessRedDot))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.TaskExtra.RewardAllianceTasks.MsgPath, Delegate.GetOrCreate(self, self.RefreshTaskRewardRedDot))
end

function AllianceJourneyModule:OnRemove()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnAllianceChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.Task.Processing.MsgPath, Delegate.GetOrCreate(self, self.RefreshTaskProcessRedDot))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.TaskExtra.RewardAllianceTasks.MsgPath, Delegate.GetOrCreate(self, self.RefreshTaskRewardRedDot))
end

function AllianceJourneyModule:OnAllianceChanged()
    self:InitTasks()
end

function AllianceJourneyModule:SetUp()
    self:InitPlayer()
    self:InitTasks()
end

function AllianceJourneyModule:InitTasks()
    self._allianceTasks = {}
    self._shortTermTasks = {}
    self._longTermTasks = {}
    self._leaderTasks = {}

    local alliance = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not alliance then
        return
    end
    for k, v in pairs(alliance.AllianceWrapper.Task.Processing) do
        self._allianceTasks[k] = v
    end

    self:LoadAllianceShortTermTasks()
    self:LoadAllianceLongTermTasks()
    self:LoadAllianceLeaderTasks()
    self:InitRedDot()
end

-- 任务可领奖和任务完成 存在两个字段里分别监听
function AllianceJourneyModule:RefreshTaskProcessRedDot(entity, changedData)
    local alliance = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not alliance then
        return
    end

    local needFullRefresh = false
    if changedData.Add then
        for k, v in pairs(changedData.Add) do
            if v.State == wds.TaskState.TaskStateCanFinish then
                needFullRefresh = true
            elseif v.State == wds.TaskState.TaskStateExpired then
                needFullRefresh = true
            end
        end
    end

    if needFullRefresh then
        self:RefreshRedDot(true)
    end
end

-- 任务可领奖和任务完成 存在两个字段里分别监听
function AllianceJourneyModule:RefreshTaskRewardRedDot(entity, changedData)
    local alliance = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not alliance then
        return
    end

    local needRefresh = false
    local needFullRefresh = false

    if changedData.Add then
        for k, v in pairs(changedData.Add) do
            local state = ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(k)
            if state == wds.TaskState.TaskStateFinished then
                needFullRefresh = true
            elseif state == wds.TaskState.TaskStateExpired then
                needRefresh = true
            end
        end
    end

    if needFullRefresh then
        self:RefreshRedDot(true)
    elseif needRefresh then
        self:RefreshRedDot()
    end
end

-- Reddot Start--
function AllianceJourneyModule:InitRedDot()
    local mainNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Main", NotificationType.ALLIANCE_ACHIEVEMENT)
    local longTermTaskNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_LongTerm", NotificationType.ALLIANCE_ACHIEVEMENT_LONG)
    local leaderTaskNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Leader", NotificationType.ALLIANCE_ACHIEVEMENT_LEADER)
    ModuleRefer.NotificationModule:AddToParent(longTermTaskNode, mainNode)
    ModuleRefer.NotificationModule:AddToParent(leaderTaskNode, mainNode)

    self:RefreshLongTermTask(true)
    self:RefreshShortTermTask()
    self:RefreshLeaderTask(true)
end

function AllianceJourneyModule:RefreshRedDot(isFull)
    local mainNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Main", NotificationType.ALLIANCE_ACHIEVEMENT)
    if mainNode.NotificationCount > 0 and not isFull then
        return
    end
    self:RefreshLongTermTask()
    if mainNode.NotificationCount > 0 and not isFull then
        return
    end
    self:RefreshShortTermTask()
    if mainNode.NotificationCount > 0 and not isFull then
        return
    end
    self:RefreshLeaderTask()
end

function AllianceJourneyModule:RefreshLongTermTask(init)
    local longTermTaskNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_LongTerm", NotificationType.ALLIANCE_ACHIEVEMENT_LONG)
    local longTermTasks = self:GetAllianceLongTermTasks()
    if #longTermTasks == 0 then
        return
    end
    for i = 1, 3 do
        local tasks = longTermTasks[i]
        local count = 0
        for k, v in pairs(tasks) do
            if ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(v.TID) == wds.TaskState.TaskStateCanFinish then
                count = count + 1
            end
        end
        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_LongTerm_" .. i, NotificationType.ALLIANCE_ACHIEVEMENT_LONG)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, count)
        if init then
            ModuleRefer.NotificationModule:AddToParent(node, longTermTaskNode)
        end
    end
end

function AllianceJourneyModule:RefreshShortTermTask()
    local shortTermTask = self:GetAllianceShortTermTasks()
    local count = 0
    for k, v in pairs(shortTermTask) do
        if ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(v.TID) == wds.TaskState.TaskStateCanFinish then
            count = count + 1
        end
    end
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_ShortTerm", NotificationType.ALLIANCE_ACHIEVEMENT_SHORT)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, count)
end

function AllianceJourneyModule:RefreshLeaderTask(isInit)
    local leaderNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Leader", NotificationType.ALLIANCE_ACHIEVEMENT_LEADER)
    local isLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    if isLeader then
        local leaderTasks = self:GetAllianceLeaderTasks()
        for i = 1, #leaderTasks do
            local isUnlock = i == 1 and true or self:IsLeaderTaskChapterUnlock(i - 1)
            if isUnlock then
                local chapterNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Leader_" .. i, NotificationType.ALLIANCE_ACHIEVEMENT_LEADER)
                local count = 0
                for j = 1, (leaderTasks[i]:SubTasksLength()) do
                    local id = leaderTasks[i]:SubTasks(j)
                    local task = ModuleRefer.AllianceJourneyModule:GetTask(id)
                    if task and ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(id) == wds.TaskState.TaskStateCanFinish then
                        count = count + 1
                    end
                end
                ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(chapterNode, count)
                if isInit then
                    ModuleRefer.NotificationModule:AddToParent(chapterNode, leaderNode)
                end
            end
        end
    end
end
-- Reddot End--

---@param AllianceTaskID
function AllianceJourneyModule:GetTask(id)
    return self._allianceTasks[id]
end

function AllianceJourneyModule:InitPlayer()
    self.player = ModuleRefer.PlayerModule:GetPlayer()
end

-- 限时任务
function AllianceJourneyModule:LoadAllianceShortTermTasks()
    self._shortTermTasks = {}
    for id, v in ConfigRefer.AllianceShortTermTask:ipairs() do
        local k = v:RelTask()
        if self._allianceTasks[k] then
            if self.player.PlayerWrapper3.TaskExtra.RewardAllianceTasks[k] then
                self._allianceTasks[k].State = wds.TaskState.TaskStateFinished
            end
            table.insert(self._shortTermTasks, self._allianceTasks[k])
        end
    end
    table.sort(self._shortTermTasks, AllianceJourneyModule.SortShortTermTasks)
end

-- 优先级-可领奖按ID/解锁早的/过期早的/完成晚的
function AllianceJourneyModule.SortShortTermTasks(a, b)
    if a.State ~= b.State then
        if a.State == wds.TaskState.TaskStateCanFinish then
            return true
        elseif b.State == wds.TaskState.TaskStateCanFinish then
            return false
        else
            return a.State < b.State
        end
    elseif a.UnlockTimeStamp ~= b.UnlockTimeStamp then
        return a.UnlockTimeStamp < b.UnlockTimeStamp
    elseif a.ExpireTimeStamp ~= b.ExpireTimeStamp then
        return a.ExpireTimeStamp < b.ExpireTimeStamp
    elseif a.FinishTimeStamp ~= b.FinishTimeStamp then
        return a.FinishTimeStamp > b.FinishTimeStamp
    else
        return a.TID < b.TID
    end
end

function AllianceJourneyModule:GetFirstAllianceShortTermTask()
    return self._shortTermTasks[1]
end

-- 成就
function AllianceJourneyModule:LoadAllianceLongTermTasks()
    self._longTermTasks = {}
    -- 三个类型
    for i = 1, 3 do
        self._longTermTasks[i] = {}
    end

    for id, v in ConfigRefer.AllianceLongTermTask:ipairs() do
        local k = v:RelTask()
        if self._allianceTasks[k] then
            local type = v:Type()
            self._allianceTasks[k].RewardAlliancePoint = v:RewardAlliancePoint()
            table.insert(self._longTermTasks[type], self._allianceTasks[k])
        end
    end
end

-- 盟主任务
function AllianceJourneyModule:LoadAllianceLeaderTasks()
    self._leaderTasks = {}
    for id, v in ConfigRefer.AllianceLeaderTask:ipairs() do
        table.insert(self._leaderTasks, v)
    end
end

function AllianceJourneyModule:IsLeaderTaskChapterUnlock(chapter, canClaim)
    if not self._leaderTasks or not self._leaderTasks[chapter] then
        return false
    end

    local isUnlock = true
    for i = 1, (self._leaderTasks[chapter]:SubTasksLength()) do
        local id = self._leaderTasks[chapter]:SubTasks(i)
        local task = ModuleRefer.AllianceJourneyModule:GetTask(id)
        local status = ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(id)
        if task and not (status == wds.TaskState.TaskStateCanFinish or status == wds.TaskState.TaskStateFinished) then
            isUnlock = false
            break
        end
    end

    return isUnlock
end

function AllianceJourneyModule:GetAllianceLeaderTasks()
    return self._leaderTasks
end
function AllianceJourneyModule:GetAllianceLongTermTasks()
    return self._longTermTasks
end
function AllianceJourneyModule:GetAllianceShortTermTasks()
    return self._shortTermTasks
end
return AllianceJourneyModule
