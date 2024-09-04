local BaseModule = require('BaseModule')
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TaskRewardType = require("TaskRewardType")
local WorldTrendDefine = require("WorldTrendDefine")
local TimeFormatter = require("TimeFormatter")
local TaskConfigUtils = require("TaskConfigUtils")
local Utils = require("Utils")
local NotificationType = require("NotificationType")
local EventConst = require("EventConst")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local DBEntityPath = require('DBEntityPath')
local TimeUtils = CS.TimeUtils
local AllianceTaskCondType = require('AllianceTaskCondType')
local MapBuildingSubType = require('MapBuildingSubType')

---@class WorldTrendModule : BaseModule
local WorldTrendModule = class('WorldTrendModule', BaseModule)

function WorldTrendModule:ctor()
end

function WorldTrendModule:OnRegister()
    self:InitCanRewardStageIndexCache()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Kingdom.WorldStage.HistoryStages.MsgPath, Delegate.GetOrCreate(self, self.UpdateCanRewardStageIndex))
end

function WorldTrendModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Kingdom.WorldStage.HistoryStages.MsgPath, Delegate.GetOrCreate(self, self.UpdateCanRewardStageIndex))
end

--region ----------------CommonFunc------------------
---@param configCell TaskConfigCell | AllianceTaskConfigCell | KingdomTaskConfigCell
---@param branch number @Branch index (0~n)
---@return ItemGroupInfo[] Items,Nums,Weights
function WorldTrendModule:GetTaskRewards(configCell,branch,index)
    if not configCell then  return nil end
    branch = branch or 0
    branch = math.min(branch+1, configCell:FinishBranchLength())
    if branch < 1 then
        return nil
    end
    local finish = configCell:FinishBranch(branch)
    if not finish then
        return nil
    end
    index = index or 0
    index = math.min(index+1,finish:BranchRewardLength())
    if index < 1 then
        return nil
    end
    local reward = finish:BranchReward(index)
    if not reward or reward:Typ() ~= TaskRewardType.RewardItem then
        return nil
    end
    return ModuleRefer.QuestModule.GetItemGroupInfoByStringId(reward:Param())
end

---@param configCell TaskConfigCell | AllianceTaskConfigCell | KingdomTaskConfigCell
function WorldTrendModule:GetTaskDesc(configCell, type)
    local taskNameKey,taskNameParam = WorldTrendModule:GetTaskName(configCell, type)
	return I18N.GetWithParamList(taskNameKey,taskNameParam)
end

---@param taskUnit wds.TaskUnit
---@param type WorldTrendDefine.TASK_TYPE
---@param branch number condition branch
---@param index number condtion index
---@return number,number count,maxCount
function WorldTrendModule:GetTaskProgress(taskUnit, type, branch, index)
    if not taskUnit then return 0 end
    branch = branch or 0
    index = index or 0

    local taskCond = self:GetTaskFinishCond(taskUnit.TID, type, branch,index)
    local max = 1
    if taskCond and taskCond.count ~= nil then
        if taskCond.typ == AllianceTaskCondType.StudyTechById then
            max = 1
        else
            max = taskCond.count
        end
    end

    local current = nil
    if taskUnit.Counters then
        current = taskUnit.Counters[TaskConfigUtils.TaskCondKey(branch,index)]
    end
    if not current then
        if taskUnit.State >= wds.TaskState.TaskStateCanFinish then
        --说明任务已经完成
            current = max
        else
            current = 0
        end
    end
    return current,max
end

---@param tid number
---@param branch number @index of Branchs, start from ZERO
---@param index number @index of Conditions, start from ZERO
---@return CacheTaskCondition
function WorldTrendModule:GetTaskFinishCond(tid, type, branch, index)
    branch = branch or 0
    index = index or 0
    type = type or WorldTrendDefine.TASK_TYPE.Personal
    ---@type table<number,CacheTaskCondition>
    local cacheItem = {}
    local config = self:GetTaskConfigByType(tid, type)
    if config then
        for i = 0, config:FinishBranchLength()-1 do
            local branchConfig = config:FinishBranch(i+1)
            local condition = branchConfig:BranchCondition()

            local staticCondLength = condition:FixedConditionLength()
            for j = 0, staticCondLength - 1 do
                local cond = condition:FixedCondition(j+1)
                local key = TaskConfigUtils.TaskCondKey(i,j)
                ---@type CacheTaskCondition
                local item = {
                    typ = cond:Typ(),
                    op = cond:Op()
                }
                item.count,item.params,item.desc = WorldTrendModule:CondProcesserByTaskType(type, item.typ,cond:Param())
                cacheItem[key] = item
            end
            local opCondLength = condition:OptionalConditionLength()
            for j = 0, opCondLength - 1 do
                local cond = condition:OptionalCondition(j+1)
                local key = TaskConfigUtils.TaskCondKey(i, j + staticCondLength )
                ---@type CacheTaskCondition
                local item = {
                    typ = cond:Typ(),
                    op = cond:Op()
                }
                item.count,item.params,item.desc = WorldTrendModule:CondProcesserByTaskType(type, item.typ,cond:Param())
                cacheItem[key] = item
            end
        end
    end
    local condKey = TaskConfigUtils.TaskCondKey(branch,index)
    return cacheItem[condKey]
end

function WorldTrendModule:CondProcesserByTaskType(taskType, type, param)
    if taskType == WorldTrendDefine.TASK_TYPE.Alliance then
        return WorldTrendModule:AllianceCondProcesser(type, param)
    elseif taskType == WorldTrendDefine.TASK_TYPE.Global then
        return WorldTrendModule:KingdomCondProcesser(type, param)
    else
        return TaskConfigUtils.CondProcesser(type, param)
    end
end

---按条件类型，解析条件参数
---@param type number @AllianceTaskCondType
---@param param string
---@return number,string[] @跟踪数值，参数数组
function WorldTrendModule:AllianceCondProcesser(type, param)
    local params = string.split(param,';')
    local condNumber = tonumber(params[1])
    local condParam = params
    local condDesc = params
    if type == AllianceTaskCondType.DeclareWarOnBuildingByTypeByLevelByTimes then
        condDesc[3] =self:GetDescByType(condDesc[3])
    elseif type == AllianceTaskCondType.OccupyBuildingByTypeByLevelByCount then
        condDesc[3] =self:GetDescByType(condDesc[3])
    elseif type == AllianceTaskCondType.OccupyOthersBuildingByTypeByCount then
        condDesc[2] =self:GetDescByType(condDesc[2])
    elseif type == AllianceTaskCondType.DeclareWarOnBuildingByTypeByTimes then
        condDesc[2] =self:GetDescByType(condDesc[2])
    elseif type == AllianceTaskCondType.DeclareWarOnOthersBuildingByTypeByTimes then
        condDesc[2] =self:GetDescByType(condDesc[2])
    elseif type == AllianceTaskCondType.OccupyBuildingByTypeByCount then
        condDesc[2] =self:GetDescByType(condDesc[2])
    end

    return condNumber, condParam, condDesc
end

function WorldTrendModule:GetDescByType(param)
    local res
    local fixedBuildingType = tonumber(param)
    if fixedBuildingType == MapBuildingSubType.Stronghold then
        res = "village_outpost_name"
    elseif fixedBuildingType == MapBuildingSubType.City then
        res ="Alliance_bj_town"
    elseif fixedBuildingType == MapBuildingSubType.CageSubType1 then
        res ="alliance_behemoth_turtle_name"
    elseif fixedBuildingType == MapBuildingSubType.CageSubType2 then
        res ="alliance_behemoth_lion_name"
    end
    return I18N.Get(res)
end


---按条件类型，解析条件参数
---@param type number @KingdomTaskCondType
---@param param string
---@return number,string[] @跟踪数值，参数数组
function WorldTrendModule:KingdomCondProcesser(type, param)
    local params = string.split(param,';')
    local condNumber = tonumber(params[1])
    local condParam = params
    local condDesc = params
    -- if type == KingdomTaskCondType.DefeatMobByLevel then
        
    -- end
    return condNumber, condParam, condDesc
end

---@param config TaskConfigCell
---@return string,string[]
function WorldTrendModule:GetTaskName(config, type)
    local taskProp = config:Property()
    if not taskProp then
        return '',nil
    end
    local taskCond = self:GetTaskFinishCond(config:Id(), type)
    return taskProp:Name(), (taskCond ~= nil) and taskCond.desc or nil
end

function WorldTrendModule:GetTaskConfigByType(tid, type)
    if type == WorldTrendDefine.TASK_TYPE.Alliance then
        return ConfigRefer.AllianceTask:Find(tid)
    elseif type == WorldTrendDefine.TASK_TYPE.Global then
        return ConfigRefer.KingdomTask:Find(tid)
    else
        return ConfigRefer.Task:Find(tid)
    end
end

function WorldTrendModule:GetCurSeason()
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return 0
    end
    return kingdomEntity.WorldStage.Season or 0
end

---@return WorldSeasonConfigCell
function WorldTrendModule:GetCurSeasonConfigInfo()
    local season = self:GetCurSeason()
    return ConfigRefer.WorldSeason:Find(season)
end

function WorldTrendModule:GetCurSeasonBeginStage()
    local season = self:GetCurSeason()
    local seasonConfig = ConfigRefer.WorldSeason:Find(season)
    if seasonConfig then
        return seasonConfig:BeginStage()
    end
    return 0
end

function WorldTrendModule:GetCurSeasonLastStage()
    local season = self:GetCurSeason()
    local seasonConfig = ConfigRefer.WorldSeason:Find(season)
    if seasonConfig then
        local beginStage = seasonConfig:BeginStage()
        local stageConfig = ConfigRefer.WorldStage:Find(beginStage)
        if not stageConfig then
            return 0
        end
        if stageConfig:BranchesLength() > 0 then
            return self:GetCurStageNextStage(beginStage, true)
        else
            return beginStage
        end
    end
    return 0
end

function WorldTrendModule:IsWorldTrendCanReward()
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
        return false
    end
    for i = 1, #self.canRewardStageIndex do
        if self.canRewardStageIndex[i] == 1 then
            return true
        end
    end
    return false
end

function WorldTrendModule:UpdateCanRewardStageIndex(_, changedData)
    local data = changedData
    if not changedData or not changedData.Add then
        return
    end
    for k, v in ipairs(changedData.Add) do
        if self:GetStageState(v.Stage) == WorldTrendDefine.BRANCH_STATE.CanReward then
            self.canRewardStageIndex[k] = 1
        else
            self.canRewardStageIndex[k] = 0
        end
    end
end

function WorldTrendModule:InitCanRewardStageIndexCache()
    self.canRewardStageIndex = {}
    local season = self:GetCurSeason()
    local seasonConfig = ConfigRefer.WorldSeason:Find(season)
    if seasonConfig then
        local beginStage = seasonConfig:BeginStage()
        local stageConfig = ConfigRefer.WorldStage:Find(beginStage)
        if not stageConfig then
            return
        end
        local lastStage = self:GetCurSeasonLastStage()
        if lastStage <= beginStage then
            return
        end
        local curStage = beginStage
        local maxCount = 10
        local lastStage = beginStage
        while curStage <= lastStage and maxCount >= 0 do
            if self:GetStageState(curStage) == WorldTrendDefine.BRANCH_STATE.CanReward then
                table.insert(self.canRewardStageIndex, 1)
            else
                table.insert(self.canRewardStageIndex, 0)
            end
            curStage = self:GetCurStageNextStage(curStage, false)
            if lastStage == curStage  then
                break
            else
                lastStage = curStage
            end
            maxCount = maxCount - 1
        end
    end
end

function WorldTrendModule:AddCanRewardStage(index)
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
    end
    for i = 1, #self.canRewardStageIndex do
        if index == i and self.canRewardStageIndex[i] == 0 then
            self.canRewardStageIndex[i] = 1
        end
    end
end

function WorldTrendModule:RemoveCanRewardStage(index)
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
    end
    for i = 1, #self.canRewardStageIndex do
        if index == i and self.canRewardStageIndex[i] == 1 then
            self.canRewardStageIndex[i] = 0
        end
    end
end

function WorldTrendModule:GetCanRewardStageLeftCount(index)
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
    end
    local count = 0
    for i = 1, #self.canRewardStageIndex do
        if index - 1 > i and self.canRewardStageIndex[i] == 1 then
            count = count + 1
        end
    end
    return count
end

function WorldTrendModule:GetCanRewardStageRightCount(index)
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
    end
    local count = 0
    for i = 1, #self.canRewardStageIndex do
        if index + 1 < i and self.canRewardStageIndex[i] == 1 then
            count = count + 1
        end
    end
    return count
end

--返回最左的stageIndex
function WorldTrendModule:GetLeftRewardIndex(index)
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
    end
    for i = 1, #self.canRewardStageIndex do
        if index - 1 > i and self.canRewardStageIndex[i] == 1 then
            return i
        end
    end
end

--返回最左的stageIndex
function WorldTrendModule:GetRightRewardIndex(index)
    if not self.canRewardStageIndex then
        self:InitCanRewardStageIndexCache()
    end
    for i = 1, #self.canRewardStageIndex do
        if index + 1 < i and self.canRewardStageIndex[i] == 1 then
            return i
        end
    end
end


function WorldTrendModule:GetCurStageNextStage(curStage, isRecursion)
    isRecursion = isRecursion or false
    local stageConfig = ConfigRefer.WorldStage:Find(curStage)
    if not stageConfig then
        return 0
    end
    if isRecursion then
        if stageConfig:BranchesLength() > 0 then
            return self:GetCurStageNextStage(stageConfig:Branches(1), isRecursion)
        else
            return curStage
        end
    end
    return stageConfig:BranchesLength() > 0 and stageConfig:Branches(1) or curStage
end

function WorldTrendModule:GetCurSeasonHistoryStages()
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return {}
    end
    return kingdomEntity.WorldStage.HistoryStages or {}
end

function WorldTrendModule:GetCurSeasonAttrAddonID()
    local curSeason = self:GetCurSeason()
    local seasonConfig = ConfigRefer.WorldSeason:Find(curSeason)
    if not seasonConfig then
        return 0
    end
    return seasonConfig:Addon()
end

function WorldTrendModule:GetStageInfo(stage)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return nil
    end
    ---@type wds.WorldStage
    local worldStage = kingdomEntity.WorldStage
    if worldStage.CurStage.Stage == stage then
        return worldStage.CurStage
    end
    for i = 1, #worldStage.HistoryStages do
        if worldStage.HistoryStages[i].Stage == stage then
            return worldStage.HistoryStages[i]
        end
    end
    return nil
end

---@return WorldTrendDefine.BRANCH_STATE
function WorldTrendModule:GetStageState(stage)
    local stageConfig = ConfigRefer.WorldStage:Find(stage)
    if not stageConfig then
        return WorldTrendDefine.BRANCH_STATE.None
    end
    if self:IsCurStage(stage) then
        return WorldTrendDefine.BRANCH_STATE.Processing
    end
    if self:IsHistoryStage(stage) then
        local rewardedStages = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper3.WorldStageInfo.RewardedStages
        for i = 1, #rewardedStages do
            if rewardedStages[i] == stage then
                return WorldTrendDefine.BRANCH_STATE.Rewarded
            end
        end
        return WorldTrendDefine.BRANCH_STATE.CanReward
    else
        return WorldTrendDefine.BRANCH_STATE.None
    end
end

function WorldTrendModule:IsHistoryStage(stage)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return false
    end
    local worldStage = kingdomEntity.WorldStage
    for i = 1, #worldStage.HistoryStages do
        if worldStage.HistoryStages[i].Stage == stage then
            return true
        end
    end
    return false
end

function WorldTrendModule:IsCurStage(stage)
    local curStage = self:GetCurStage()
    return curStage.Stage == stage
end

---@return wds.WorldStageNode
function WorldTrendModule:GetCurStage()
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return {Stage = 0}
    end
    return kingdomEntity.WorldStage.CurStage or {Stage = 0}
end

--获取阶段开启时间
function WorldTrendModule:GetStageOpenTime(stage)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return 0
    end
    local curStage = kingdomEntity.WorldStage.CurStage
    --活动未开启，从活动开启时间开始计算
    if curStage.Stage == 0 then
        local openTime = self:GetWorldTrendOpenTime()
        if stage == 1 then
            return openTime or 0
        end
        local stageConfig = ConfigRefer.WorldStage:Find(self:GetCurSeasonBeginStage())
        if not stageConfig then
            return 0
        end
        if stageConfig:BranchesLength() > 0 then
            if stageConfig:Branches(1) == stage then
                return openTime + Utils.ParseDurationToSecond(stageConfig:Duration())
            else
                return openTime + Utils.ParseDurationToSecond(stageConfig:Duration()) +
                 self:GetTillTargetStageDuration(stageConfig:Branches(1), stage)
            end
        end
    else
        if stage == curStage.Stage then
            return curStage.StartTime.Seconds or 0
        end
        local historyStages = kingdomEntity.WorldStage.HistoryStages
        for i = 1, #historyStages do
            if stage == historyStages[i].Stage then
                return historyStages[i].StartTime.Seconds or 0
            end
        end
        local stageConfig = ConfigRefer.WorldStage:Find(curStage.Stage)
        if not stageConfig then
            return 0
        end
        if stageConfig:BranchesLength() > 0 then
            if stageConfig:Branches(1) == stage then
                return curStage.EndTime.Seconds or 0
            else
                return curStage.EndTime.Seconds + self:GetTillTargetStageDuration(stageConfig:Branches(1), stage)
            end
        end
    end
end

--获取当前阶段到目标阶段的配置持续时间
function WorldTrendModule:GetTillTargetStageDuration(curStage, targetStage)
    local stageConfig = ConfigRefer.WorldStage:Find(curStage)
    if not stageConfig then
        return 0
    end
    if curStage == targetStage or stageConfig:BranchesLength() == 0 then
        return 0
    else
        return Utils.ParseDurationToSecond(stageConfig:Duration()) + self:GetTillTargetStageDuration(stageConfig:Branches(1), targetStage)
    end
end

--当前阶段有可领奖励
function WorldTrendModule:IsCurStageCanReward(stage)
    local stageConfig = ConfigRefer.WorldStage:Find(stage)
    if not stageConfig then
        return false
    end

    if self:GetPersonalTaskState(stageConfig:PlayerTasks(1)) == WorldTrendDefine.TASK_STATE.CanReward then
        return true
    end

    if self:IsAllianceTaskCanReward(stageConfig:AllianceTasks(1)) then
        return true
    end

    --有分支
    if stageConfig:BranchesLength() > 1 then
        local branchID_1, branchID_2 = self:GetGlobalBranchID(stage)
        if self:IsHaveRewardState(branchID_1, branchID_2) and 
        self:GetBranchState(stage, true) == WorldTrendDefine.BRANCH_STATE.CanReward then
            return true
        end
    else
       if self:IsKingdomTaskCanReward(stageConfig:KingdomTasks(1)) then
            return true
       end
    end
    return false
end

--活动开启时间
function WorldTrendModule:GetWorldTrendOpenTime()
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return 0
    end
    local osTime = kingdomEntity.KingdomBasic.OsTime
    --有开服时间
    if osTime.Seconds > 0 then
        local timeStamp = osTime.Seconds
        local dateTime = TimeFormatter.ToDateTime(osTime.Seconds)
        --计算当天0点时间戳
        timeStamp = timeStamp - dateTime.Hour * 3600 - dateTime.Minute * 60 - dateTime.Second
        local beginStage = ModuleRefer.WorldTrendModule:GetCurSeasonBeginStage()
        if beginStage <= 0 then
            return 0
        end
        local stageConfig = ConfigRefer.WorldStage:Find(beginStage)
        if not stageConfig then
            return 0
        end
        return math.floor(timeStamp + Utils.ParseDurationToSecond(stageConfig:StartOffset()))
    end
    return 0
end

--当前阶段奖励全领完
function WorldTrendModule:IsCurStageRewarded(stage)
    local stageConfig = ConfigRefer.WorldStage:Find(stage)
    if not stageConfig then
        return false
    end

    local personalRewarded = false
    local allianceRewarded = false
    local branchRewarded = false
    local kingdomRewarded = false
    if self:GetPersonalTaskState(stageConfig:PlayerTasks(1)) == WorldTrendDefine.TASK_STATE.Rewarded then
        personalRewarded = true
    end

    if self:IsAllianceTaskFinish(stageConfig:AllianceTasks(1)) then
        allianceRewarded = true
    end

    --有分支
    if stageConfig:BranchesLength() > 1 then
        local branchID_1, branchID_2 = self:GetGlobalBranchID(stage)
        if self:IsHaveRewardState(branchID_1, branchID_2) and 
        self:GetBranchState(stage, true) == WorldTrendDefine.BRANCH_STATE.Rewarded then
            branchRewarded = true
        elseif not self:IsHaveRewardState(branchID_1, branchID_2) and 
        self:GetBranchState(stage, false) == WorldTrendDefine.BRANCH_STATE.CanReward then
            branchRewarded = true
        end
    else
       if self:IsKingdomTaskFinish(stageConfig:KingdomTasks(1)) then
            kingdomRewarded = true
       end
    end
    return personalRewarded and allianceRewarded and (branchRewarded or kingdomRewarded)
end

--阶段是否是开启状态
function WorldTrendModule:IsOpenStage(stage)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    local curStage = kingdomEntity.WorldStage.CurStage
    if stage == curStage.Stage then
        return true
    end
    local historyStages = kingdomEntity.WorldStage.HistoryStages
    for i = 1, #historyStages do
        if stage == historyStages[i].Stage then
            return true
        end
    end
    return false
end

function WorldTrendModule:GetRandomBranchSelectID()
    local curStageID = self:GetCurStage().Stage
    local idList = {}
    for k, v in ConfigRefer.BranchSelect:ipairs() do
        if v:StageId() == curStageID then
            table.insert(idList, v:Id())
        end
    end
    if #idList > 0 then
        return idList[math.random(1, #idList)]
    end
    return 0
end

function WorldTrendModule:InitRedDot()
    if self.createRedDot then
        return
    end
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode("WorldTrendBtnNode", NotificationType.WORLD_TREND)
    self.createRedDot = true
end

function WorldTrendModule:RefreshRedPoint()
    if not self.createRedDot then
        self:InitRedDot()
    end
    local isHasReward = self:IsHasReward()
    
    local worldTrendRedDot = ModuleRefer.NotificationModule:GetDynamicNode("WorldTrendBtnNode", NotificationType.WORLD_TREND)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(worldTrendRedDot, isHasReward and 1 or 0)
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_STATE_CHANGED)
end

function WorldTrendModule:CheckWorldTrendIsOpen(systemEntryIds)
    local sysIndex = NewFunctionUnlockIdDefine.WorldTrend
    if table.ContainsValue(systemEntryIds, sysIndex) then
        self:RefreshRedPoint()
    end
end

function WorldTrendModule:IsHasReward()
    for _, v in pairs(self.canRewardStageIndex) do
        if v == 1 then
            return true
        end
    end
    return false
end

---@return WorldStageConfigCell
function WorldTrendModule:GetStageConfigByStageIndex(stageIndex)
    for k, v in ConfigRefer.WorldStage:ipairs() do
        if v:Stage() == stageIndex then
            return v
        end
    end
    return nil
end

function WorldTrendModule:IsOpen()
    local kingdomOpen = self:GetCurStage().Stage == 0 and false or true
    local personalOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.WorldTrend)
    return kingdomOpen and personalOpen
end

function WorldTrendModule:GetStageCellWidth(stageID, isOpen, isLastShowStage)
    local stageConfig = ConfigRefer.WorldStage:Find(stageID)
    if not stageConfig then
        return WorldTrendDefine.NO_BRANCH_CELL_WIDTH
    end
    if stageConfig:BranchesLength() > 1 and isOpen then
        return WorldTrendDefine.BRANCH_CELL_WIDTH
    end
    if not isOpen then
        if isLastShowStage then
            return WorldTrendDefine.NO_BRANCH_CELL_WIDTH
        end
        if stageConfig:BranchKingdomTasksLength() > 1 then
            return WorldTrendDefine.BRANCH_CELL_WIDTH
        end
    end
    return WorldTrendDefine.NO_BRANCH_CELL_WIDTH
end

--endregion

--region ----------------PersonalTask------------------
---@param taskID number
function WorldTrendModule:GetPersonalTaskSchedule(taskID)
    return ModuleRefer.QuestModule:GetTaskProgressByTaskID(taskID)
end

---@return boolean
function WorldTrendModule:IsPersonalTaskFinish(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if ModuleRefer.QuestModule:IsInBitMap(taskID, player.PlayerWrapper.Task.FinishedBitMap) then
        return true
    end
    return false
end

---@return WorldTrendDefine.TASK_STATE
function WorldTrendModule:GetPersonalTaskState(taskID)
    if self:IsPersonalTaskFinish(taskID) then
        return WorldTrendDefine.TASK_STATE.Rewarded
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    for k, v in pairs(player.PlayerWrapper.Task.Processing) do
        if k == taskID then
            if v.State == wds.TaskState.TaskStateCanFinish then
                return WorldTrendDefine.TASK_STATE.CanReward
            elseif v.State == wds.TaskState.TaskStateReceived then
                return WorldTrendDefine.TASK_STATE.Processing
            end
        end
    end

    return WorldTrendDefine.TASK_STATE.None
end

---@return string
function WorldTrendModule:GetPersonalTaskFinishTimeStr(taskID)
    if self.personalTaskFinishTimeTable == nil then
        return nil
    end

    for k,v in pairs(self.personalTaskFinishTimeTable) do
        if k == taskID then
            return v
        end
    end

    return nil
end

function WorldTrendModule:SetPersonalTaskFinishTimeStr(taskID, time)
    if self.personalTaskFinishTimeTable == nil then
        self.personalTaskFinishTimeTable = {}
    end

    self.personalTaskFinishTimeTable[taskID] = time
end
--endregion

--region----------------AllianceTask------------------
---@param taskID number
function WorldTrendModule:GetAllianceTaskSchedule(taskID)
    local taskCond = self:GetTaskFinishCond(taskID, WorldTrendDefine.TASK_TYPE.Alliance)
    local maxCount = 0
    if taskCond then
        if taskCond.typ == AllianceTaskCondType.StudyTechById then
            maxCount = 1
        else
            maxCount = taskCond.count
        end
    end
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceInfo then
        return 0, maxCount
    end
    local allianceTaskInfo = allianceInfo.AllianceWrapper.Task
    for k, v in pairs(allianceTaskInfo.Processing) do
        if k == taskID then
            return self:GetTaskProgress(v, WorldTrendDefine.TASK_TYPE.Alliance)
        end
    end
    return 0, maxCount
end

---@return boolean
function WorldTrendModule:IsAllianceTaskFinish(taskID)
    -- return self:GetAllianceTaskState(taskID) == wds.TaskState.TaskStateCanFinish and self:IsAllianceTaskRewarded(taskID)
    return self:IsAllianceTaskRewarded(taskID)
end

---@return boolean
function WorldTrendModule:IsAllianceTaskCanReward(taskID)
    return self:GetAllianceTaskState(taskID) == wds.TaskState.TaskStateCanFinish and
     not self:IsAllianceTaskRewarded(taskID)
end

---@return wds.TaskState
function WorldTrendModule:GetAllianceTaskState(taskID)
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceInfo then
        return wds.TaskState.TaskStateInit
    end
    local allianceTaskInfo = allianceInfo.AllianceWrapper.Task
    for k, v in pairs(allianceTaskInfo.Processing) do
        if k == taskID then
            return v.State
        end
    end
    return wds.TaskState.TaskStateInit
end

---@param taskId number
---@return number @wds.TaskState
function WorldTrendModule:GetPlayerAllianceTaskState(taskId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if player.PlayerWrapper3.TaskExtra.RewardAllianceTasks[taskId] then
        return wds.TaskState.TaskStateFinished
    end
    return ModuleRefer.WorldTrendModule:GetAllianceTaskState(taskId)
end

---@return boolean
function WorldTrendModule:IsAllianceTaskRewarded(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local taskExtra = player.PlayerWrapper3.TaskExtra
    for k, v in pairs(taskExtra.RewardAllianceTasks) do
        if k == taskID then
            return true
        end
    end
    return false
end

---@return WorldTrendDefine.TASK_STATE
function WorldTrendModule:GetAllianceTaskState_WorldTrendTaskState(taskID)
    if self:IsAllianceTaskFinish(taskID) then
        return WorldTrendDefine.TASK_STATE.Rewarded
    end
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceInfo then
        return WorldTrendDefine.TASK_STATE.None
    end
    local allianceTaskInfo = allianceInfo.AllianceWrapper.Task
    for k, v in pairs(allianceTaskInfo.Processing) do
        if k == taskID then
            if v.State == wds.TaskState.TaskStateCanFinish then
                return WorldTrendDefine.TASK_STATE.CanReward
            elseif v.State == wds.TaskState.TaskStateReceived then
                return WorldTrendDefine.TASK_STATE.Processing
            end
        end
    end

    return WorldTrendDefine.TASK_STATE.None
end

---@return string
function WorldTrendModule:GetAllianceTaskFinishTimeStr(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local timeSpan = 0
    for k, v in pairs(player.PlayerWrapper3.TaskExtra.RewardAllianceTasks) do
        if k == taskID then
            timeSpan = v
            break
        end
    end
    if timeSpan > 0 then
        return TimeFormatter.TimeToDateTimeStringUseFormat(timeSpan, "yyyy/MM/dd")
    end
    return ""
end
--endregion

--region ----------------KingdomTask------------------
---@param taskID number
function WorldTrendModule:GetKingdomTaskSchedule(taskID)
    local taskCond = self:GetTaskFinishCond(taskID, WorldTrendDefine.TASK_TYPE.Global)
    local maxCount = 0
    if taskCond then
        maxCount = taskCond.count
    end
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return 0, maxCount
    end
    for k, v in pairs(kingdomEntity.Task.Processing) do
        if k == taskID then
            return self:GetTaskProgress(v, WorldTrendDefine.TASK_TYPE.Global)
        end
    end
    return 0, maxCount
end

---@return boolean
function WorldTrendModule:IsKingdomTaskFinish(taskID)
    return self:GetKingdomTaskState(taskID) == wds.TaskState.TaskStateCanFinish and self:IsKingdomTaskRewarded(taskID)
end

---@return boolean
function WorldTrendModule:IsKingdomTaskCanReward(taskID)
    return self:GetKingdomTaskState(taskID) == wds.TaskState.TaskStateCanFinish and
     not self:IsKingdomTaskRewarded(taskID)
end

---@return wds.TaskState
function WorldTrendModule:GetKingdomTaskState(taskID)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return wds.TaskState.TaskStateInit
    end
    local kingdomTaskInfo = kingdomEntity.Task
    for k, v in pairs(kingdomTaskInfo.Processing) do
        if k == taskID then
            return v.State
        end
    end
end

---@return boolean
function WorldTrendModule:IsKingdomTaskRewarded(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local rewarded = false
    local taskExtra = player.PlayerWrapper3.TaskExtra
    for k, v in pairs(taskExtra.RewardKingdomTasks) do
        if k == taskID then
            rewarded = true
        end
    end
    return rewarded
end

---@return WorldTrendDefine.TASK_STATE
function WorldTrendModule:GetKingdomTaskState_WorldTrendTaskState(taskID)
    if self:IsKingdomTaskFinish(taskID) then
        return WorldTrendDefine.TASK_STATE.Rewarded
    end
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return WorldTrendDefine.TASK_STATE.None
    end
    local kingdomTaskInfo = kingdomEntity.Task
    for k, v in pairs(kingdomTaskInfo.Processing) do
        if k == taskID then
            if v.State == wds.TaskState.TaskStateCanFinish then
                return WorldTrendDefine.TASK_STATE.CanReward
            elseif v.State == wds.TaskState.TaskStateReceived then
                return WorldTrendDefine.TASK_STATE.Processing
            end
        end
    end

    return WorldTrendDefine.TASK_STATE.None
end

---@return string
function WorldTrendModule:GetKingdomTaskFinishTimeStr(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local timeSpan = 0
    for k, v in pairs(player.PlayerWrapper3.TaskExtra.RewardKingdomTasks) do
        if k == taskID then
            timeSpan = v
            break
        end
    end
    if timeSpan > 0 then
        return TimeFormatter.TimeToDateTimeStringUseFormat(timeSpan, "yyyy/MM/dd")
    end
    return ""
end

function WorldTrendModule:GetKingdomTaskScheduleContent(taskID)
    local taskCfg = ConfigRefer.KingdomTask:Find(taskID)
    if not taskCfg then
        return string.Empty
    end
    local cur, total = self:GetKingdomTaskSchedule(taskID)
    local curStr = tostring(cur)
    local totalStr = tostring(total)
    if cur < total then
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.warning)
    else
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.quality_green)
    end
    local taskDescStr = self:GetTaskDesc(taskCfg, WorldTrendDefine.TASK_TYPE.Global)
    return string.format("<b>(%s/%s)</b>%s", curStr, totalStr, taskDescStr)
end
--endregion

--region ----------------GlobalBranch------------------
function WorldTrendModule:GetGlobalBranchID(stage)
    local config = ConfigRefer.WorldStage:Find(stage)
    if not config then
        return nil
    end
    local branchID_1 = config:Branches(1) or 0
    local branchID_2 = config:Branches(2) or 0
    return branchID_1, branchID_2
end

function WorldTrendModule:IsHaveRewardState(branchID_1, branchID_2)
    local branch1HaveReward = false
    local branch2HaveReward = false
    local branchConfig_1 = ConfigRefer.WorldStage:Find(branchID_1)
    if branchConfig_1 then
        branch1HaveReward = branchConfig_1:Reward() > 0
    end
    local branchConfig_2 = ConfigRefer.WorldStage:Find(branchID_2)
    if branchConfig_2 then
        branch2HaveReward = branchConfig_2:Reward() > 0
    end

    return branch1HaveReward or branch2HaveReward
end

function WorldTrendModule:GetBranchVoteNum(branchID)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return 0
    end
    local votingMap = kingdomEntity.WorldStage.VotingMap
    for k, v in pairs(votingMap) do
        if k == branchID then
            return v
        end
    end
    return 0
end

---@return WorldTrendDefine.BRANCH_STATE
function WorldTrendModule:GetBranchState(stage, isHaveRewardState)
    isHaveRewardState = isHaveRewardState or false
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return WorldTrendDefine.BRANCH_STATE.None
    end
    local curStage = kingdomEntity.WorldStage.CurStage
    if curStage.Stage == stage then
        --当前阶段
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        if curStage.StartTime.Seconds <= curTime and curStage.EndTime.Seconds > curTime then
            return WorldTrendDefine.BRANCH_STATE.Processing
        end
    else
        --历史阶段
        local historyStages = kingdomEntity.WorldStage.HistoryStages
        for i = 1, #historyStages do
            if historyStages[i].Stage == stage then
                local stageConfig = ConfigRefer.WorldStage:Find(stage)
                if not stageConfig then
                    goto continue
                end
                if stageConfig:BranchesLength() > 1 then
                    local branchID_1, branchID_2 = ModuleRefer.WorldTrendModule:GetGlobalBranchID(stage)
                    local rewardedStages = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper3.WorldStageInfo.RewardedStages
                    if isHaveRewardState then
                        for j = 1, #rewardedStages do
                            if rewardedStages[j] == branchID_1 or rewardedStages[j] == branchID_2 then
                                return WorldTrendDefine.BRANCH_STATE.Rewarded
                            end
                        end
                        return WorldTrendDefine.BRANCH_STATE.CanReward
                    end
                end
                return WorldTrendDefine.BRANCH_STATE.Rewarded
            end
            ::continue::
        end

    end
    return WorldTrendDefine.BRANCH_STATE.None
end

function WorldTrendModule:GetWinBranch(stageID)
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return 0
    end
    local historyStages = kingdomEntity.WorldStage.HistoryStages
    local isNextStageIsWinStage = false
    for i = 1, #historyStages do
        if isNextStageIsWinStage then
            return historyStages[i].Stage
        end
        if historyStages[i].Stage == stageID then
            isNextStageIsWinStage = true
        end
    end
    --如果在history里没找到那就是curStage,如果不是则表示数据非法
    if isNextStageIsWinStage then
        return kingdomEntity.WorldStage.CurStage.Stage
    end
    return 0
end
--endregion

--region ----------------DotCell------------------
---@return WorldTrendDefine.DOT_STATE
function WorldTrendModule:GetStageDotState(stage)
    local stageConfig = ConfigRefer.WorldStage:Find(stage)
    if not stageConfig then
        return WorldTrendDefine.DOT_STATE.None
    end
    if self:IsOpenStage(stage) then
        if self:IsCurStageCanReward(stage) then
            return WorldTrendDefine.DOT_STATE.Open_CanReward
        elseif self:IsCurStageRewarded(stage) then
            return WorldTrendDefine.DOT_STATE.Open_AllRewarded
        else
            return WorldTrendDefine.DOT_STATE.Open_Normal
        end
    else
        if stageConfig:UnlockSystemsLength() > 0 then
            return WorldTrendDefine.DOT_STATE.Lock_WithCondition
        else
            return WorldTrendDefine.DOT_STATE.Lock_Normal
        end
    end
end

--endregion

return WorldTrendModule