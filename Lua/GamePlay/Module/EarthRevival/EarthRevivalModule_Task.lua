local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local NotificationType = require('NotificationType')
---@class EarthRevivalModule_Task
local EarthRevivalModule_Task = class("EarthRevivalModule_Task")

---@class EarthRevivalTaskList
---@field playerTasks number[]
---@field allianceTasks number[]

function EarthRevivalModule_Task:ctor(baseModule)
    self.baseModule = baseModule

    ---@type table<number, EarthRevivalTaskList[]>
    self.taskLists = nil

    ---@type table<number, table<number, number[]>> @cfgId, table<number, taskId[]>
    self.taskLinks = {}

    ---@type table<number, number[]> @cfgId, itemGroupId[]
    self.progressRewards = nil

    self.dayKeys = {}

    ---@type table<number, number>
    self.taskId2LinkId = {}
end

function EarthRevivalModule_Task:OnRegister()
    self:SetupReddot()
    self:UpdateReddot()
end

function EarthRevivalModule_Task:OnRemove()
    self.taskLists = nil
    self.progressRewards = nil
end

function EarthRevivalModule_Task:GetTaskLists()
    if not self.taskLists then
        self.taskLists = {}
        ---@type number, WorldStageTaskPlanConfigCell
        for _, cfg in ConfigRefer.WorldStageTaskPlan:ipairs() do
            self.taskLists[cfg:Id()] = {}
            self.taskLinks[cfg:Id()] = {}
            self.dayKeys[cfg:Id()] = {}
            for i = 1, cfg:PlanDayOffsetLength() do
                local day = cfg:PlanDayOffset(i)
                table.insert(self.dayKeys[cfg:Id()], day)
                self.taskLists[cfg:Id()][day] = {}
                local taskGroupId = cfg:PlanTaskGroup(i)
                local taskGroup = ConfigRefer.ActivityTaskGroup:Find(taskGroupId)
                local playerTasks = {}
                local allianceTasks = {}
                for j = 1, taskGroup:TasksLength() do
                    local taskId = taskGroup:Tasks(j)
                    playerTasks[j] = taskId
                end
                for j = 1, taskGroup:AllianceTasksLength() do
                    local taskId = taskGroup:AllianceTasks(j)
                    allianceTasks[j] = taskId
                end
                self.taskLists[cfg:Id()][day].playerTasks = playerTasks
                self.taskLists[cfg:Id()][day].allianceTasks = allianceTasks
            end
            for i = 1, cfg:LinkLength() do
                self.taskLinks[cfg:Id()][i] = {}
                local link = cfg:Link(i)
                local linkCfg = ConfigRefer.TaskLink:Find(link)
                if not linkCfg then goto continue end
                for j = 1, linkCfg:LinkLength() do
                    local taskId = linkCfg:Link(j)
                    table.insert(self.taskLinks[cfg:Id()][i], taskId)
                    self.taskId2LinkId[taskId] = link
                end
                ::continue::
            end
        end
    end
    return self.taskLists
end

function EarthRevivalModule_Task:GetDayKeysByCfgId(cfgId)
    return self.dayKeys[cfgId] or {}
end

---@return EarthRevivalTaskList[]
function EarthRevivalModule_Task:GetTaskListByCfgId(cfgId)
    return self:GetTaskLists()[cfgId] or {}
end

---@return EarthRevivalTaskList
function EarthRevivalModule_Task:GetTaskListByCfgIdAndDay(cfgId, day)
    return self:GetTaskListByCfgId(cfgId)[day] or {}
end

---@return number | nil
function EarthRevivalModule_Task:GetLinkIdByTaskId(taskId)
    return self.taskId2LinkId[taskId]
end

---@param cfgId number
---@return boolean, boolean @playerTask, allianceTask
function EarthRevivalModule_Task:IsAnyTaskCanClaimByCfgId(cfgId)
    local playerTask = false
    local allianceTask = false
    local curDay = self:GetCurrentDayOffsetByCfgId(cfgId)
    local taskList = self:GetTaskListByCfgId(cfgId)
    for day, _ in pairs(taskList) do
        if day > curDay then
            break
        end
        local player, alliance= self:IsAnyTaskCanClaimByCfgIdAndDay(cfgId, day)
        if player then
            playerTask = true
        end
        if alliance then
            allianceTask = true
        end
    end
    return playerTask, allianceTask
end

---@return boolean, boolean @playerTask, allianceTask
function EarthRevivalModule_Task:IsAnyTaskCanClaimByCfgIdAndDay(cfgId, day)
    local playerTask = false
    local allianceTask = false
    if day > self:GetCurrentDayOffsetByCfgId(cfgId) then
        return false, false
    end
    local taskList = self:GetTaskListByCfgIdAndDay(cfgId, day)
    for _, taskId in ipairs(taskList.playerTasks or {}) do
        if ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId) == wds.TaskState.TaskStateCanFinish
        and self:CanLinkTaskDisplay(taskId) then
            playerTask = true
            break
        end
    end
    for _, taskId in ipairs(taskList.allianceTasks or {}) do
        if ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(taskId) == wds.TaskState.TaskStateCanFinish
        and self:CanLinkTaskDisplay(taskId) then
            allianceTask = true
            break
        end
    end
    return playerTask, allianceTask
end

---@param taskId number
---@return boolean
function EarthRevivalModule_Task:CanLinkTaskDisplay(taskId)
    local link = self:GetBelongedTaskLink(taskId)
    if not link then return true end
    local nextTid = self:GetNextTaskIdInLink(taskId)
    if not nextTid and ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId) == wds.TaskState.TaskStateFinished then
        return true
    end
    for _, linkTaskId in ipairs(link) do
        if linkTaskId == taskId and ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(linkTaskId) ~= wds.TaskState.TaskStateFinished then
            return true
        end
        if ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(linkTaskId) ~= wds.TaskState.TaskStateFinished then
            return false
        end
    end
    return false
end

---@param taskId number
---@return number[] | nil @taskId[]
function EarthRevivalModule_Task:GetBelongedTaskLink(taskId)
    local stage = self:GetCurrentStage()
    for _, link in ipairs(self.taskLinks[stage] or {}) do
        for _, linkTaskId in ipairs(link) do
            if linkTaskId == taskId then
                return link
            end
        end
    end
    return nil
end

---@param taskId number
---@return number | nil @taskId
function EarthRevivalModule_Task:GetNextTaskIdInLink(taskId)
    local stage = self:GetCurrentStage()
    for _, link in ipairs(self.taskLinks[stage] or {}) do
        for i, linkTaskId in ipairs(link) do
            if linkTaskId == taskId then
                return link[i + 1]
            end
        end
    end
    return nil
end

---@return boolean
function EarthRevivalModule_Task:IsAnyTaskCanClaim()
    local lists = self:GetTaskLists()
    local curOpenedStages = self:GetCurrentOpenedStages()
    for cfgId, _ in pairs(lists) do
        if not table.ContainsValue(curOpenedStages, cfgId) then
            return false
        end
        for day, _ in pairs(lists[cfgId] or {}) do
            local playerTask, allianceTask = self:IsAnyTaskCanClaimByCfgIdAndDay(cfgId, day)
            if playerTask or allianceTask then
                return true
            end
        end
    end
    return false
end

---@return number[]
function EarthRevivalModule_Task:GetTaskDaysByCfgId(cfgId)
    local ret = {}
    for day, _ in pairs(self:GetTaskLists()[cfgId] or {}) do
        table.insert(ret, day)
    end
    return ret
end

---@return number
function EarthRevivalModule_Task:GetCurrentDayOffsetByCfgId(cfgId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    for _, v in pairs(player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans) do
        if v.ConfigId == cfgId then
            return v.DayOffset
        end
    end
    return 0
end

---@param cfgId number @WorldStageTaskPlan Config Id
---@return number
function EarthRevivalModule_Task:GetTaskEndTimeInSecByCfgId(cfgId)
    if not cfgId or cfgId == 0 then
        return 0
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local startTime = 0
    for _, v in pairs(player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans) do
        if v.ConfigId == cfgId then
            startTime = v.StartTime
        end
    end
    local duration = ConfigRefer.WorldStageTaskPlan:Find(cfgId):PlanDuration() / 1e9
    local endTime = startTime + duration
    return endTime
end

---@return table<number, number[]>
function EarthRevivalModule_Task:GetProgressRewards()
    if not self.progressRewards then
        self.progressRewards = {}
        ---@type number, WorldStageTaskPlanConfigCell
        for _, cfg in ConfigRefer.WorldStageTaskPlan:ipairs() do
            self.progressRewards[cfg:Id()] = {}
            for i = 1, cfg:ProgressRewardsLength() do
                local progressReward = cfg:ProgressRewards(i)
                self.progressRewards[cfg:Id()][i] = progressReward
            end
        end
    end
    return self.progressRewards
end

---@return number[]
function EarthRevivalModule_Task:GetProgressRewardsByCfgId(cfgId)
    return self:GetProgressRewards()[cfgId] or {}
end

---@param cfgId number @WorldStageTaskPlan Config Id
---@param progress number
---@return boolean
function EarthRevivalModule_Task:IsProcessRewardClaimed(cfgId, progress)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    for _, v in pairs(player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans) do
        if v.ConfigId == cfgId then
            for _, claimedProgress in ipairs(v.RewardedProgress) do
                if claimedProgress == progress then
                    return true
                end
            end
        end
    end
    return false
end

---@return ItemIconData[]
function EarthRevivalModule_Task:GetProgressRewardInItemIconData(cfgId, index)
    local rewardItemGroupId = self:GetProgressRewardsByCfgId(cfgId)[index]
    local ret = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardItemGroupId)
    return ret
end

---@return number[] @WorldStageTaskPlan Config Id
function EarthRevivalModule_Task:GetCurrentOpenedStages()
    local ret = {}
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local cfgId2PlanInfo = {}
    for _, v in pairs(player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans) do
        table.insert(ret, v.ConfigId)
        cfgId2PlanInfo[v.ConfigId] = v
    end
    table.sort(ret, function(a, b)
        if cfgId2PlanInfo[a].StartTime == cfgId2PlanInfo[b].StartTime then
            return cfgId2PlanInfo[a].ConfigId < cfgId2PlanInfo[b].ConfigId
        else
            return cfgId2PlanInfo[a].StartTime < cfgId2PlanInfo[b].StartTime
        end
    end)
    return ret
end

---@return number @WorldStageTaskPlan Config Id
function EarthRevivalModule_Task:GetCurrentStage()
    local openStages = self:GetCurrentOpenedStages()
    return openStages[#openStages] or 0
end

---@param stageCfgId number @WorldStageTaskPlan Config Id
---@return number
function EarthRevivalModule_Task:GetCurrentTaskPoints(stageCfgId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    for _, v in pairs(player.PlayerWrapper3.WorldStageInfo.PlanInfo.Plans) do
        if v.ConfigId == stageCfgId then
            return v.Progress
        end
    end
    return 0
end

---@param stageCfgId number @WorldStageTaskPlan Config Id
---@return string
function EarthRevivalModule_Task:GetStageDesc(stageCfgId)
    if not stageCfgId or stageCfgId == 0 then
        return ''
    end
    return I18N.Get(ConfigRefer.WorldStage:Find(stageCfgId):Name())
end

function EarthRevivalModule_Task:SetupReddot()
    self.tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode('EarthRevivalTaskTab', NotificationType.EARTHREVIVAL_TAB_TASK)
end

function EarthRevivalModule_Task:UpdateReddot()
    local showReddot = false
    local curStage = self:GetCurrentStage()
    for _, day in ipairs(self:GetTaskDaysByCfgId(curStage)) do
        if day > self:GetCurrentDayOffsetByCfgId(curStage) then
            goto continue
        end
        local playerTask, allianceTask = self:IsAnyTaskCanClaimByCfgIdAndDay(curStage, day)
        if playerTask or allianceTask then
            showReddot = true
            break
        end
        ::continue::
    end
    for i, _ in ipairs(self:GetProgressRewardsByCfgId(curStage)) do
        local progress = ConfigRefer.WorldStageTaskPlan:Find(curStage):ProgressRewards(i)
        if not self:IsProcessRewardClaimed(curStage, progress) and self:GetCurrentTaskPoints(curStage) >= progress then
            showReddot = true
            break
        end
    end
    showReddot = showReddot or ModuleRefer.WorldTrendModule:IsWorldTrendCanReward()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.tabNode, showReddot and 1 or 0)
end

function EarthRevivalModule_Task:GetReddotNode()
    return self.tabNode
end

return EarthRevivalModule_Task