local BaseModule = require("BaseModule")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local DBEntityPath = require('DBEntityPath')
local TaskConfigUtils = require('TaskConfigUtils')
local TaskType = require('TaskType')
local ItemGroupConsts = require('ItemGroupConsts')
local PushConsts = require("PushConsts")
local I18N = require("I18N")
local TimeFormatter = require('TimeFormatter')
local TaskFinishStateParamter = require('Framework.Service._Parameter.PlayerTaskFinishCountParameter')

---@class CachedTaskItem
---@field unit wds.TaskUnit
---@field config TaskConfigCell
---@field type TaskType

---@class QuestModule
---@field Chapter QuestModule_Chapter
---@field _followTask wds.TaskUnit
---@field taskCache table<number,CachedTaskItem>
local QuestModule = class("QuestModule", BaseModule)

QuestModule.ResetFollowQuestDuration = 300 --5min

function QuestModule:ctor()
    self._playingStory = ''
    self.Chapter = nil
    self._followTimer = -1
    self._followTask = nil
    ---@type table<number, {id:number,index:number,chapters:table<number,{id:number,index:number,next:number}>}>
    self._chapterGroupIndexCache = {}
end

function QuestModule:Tick(delta)
    if self._followTimer ~= nil and self._followTimer > 0 then
        if g_Game.Time.time - self._followTimer > QuestModule.ResetFollowQuestDuration then
            --TODO: show pointer finger to Chapter Task HUD
        end
    end
end


function QuestModule:OnSetLocalNotification(callBack)
    if callBack == nil then return end
    local time = g_Game.ServerTime:GetServerTimestampInSeconds()
    local dateTime = CS.System.DateTimeOffset.FromUnixTimeSeconds(math.floor(time))
    local dayPastSeconds = dateTime.Hour * TimeFormatter.OneHourSeconds + dateTime.Minute * TimeFormatter.OneMinuteSeconds + dateTime.Second
    local refreshSeconds = TimeFormatter.ParseFormatTimeToSeconds(ConfigRefer.DailyTaskConst:RefreshTime())
    local delay
    if refreshSeconds > dayPastSeconds then
        delay = refreshSeconds - dayPastSeconds
    else
        delay = TimeFormatter.OneDaySeconds - (dayPastSeconds - refreshSeconds)
    end
    local dialyTaskPushCfg = ConfigRefer.Push:Find(PushConsts.daily_task)
    local notifyId = tonumber(dialyTaskPushCfg:Id())
    local title = I18N.Get(dialyTaskPushCfg:Title())
    local subtitle = I18N.Get(dialyTaskPushCfg:SubTitle())
    local content = I18N.Get(dialyTaskPushCfg:Content())
    callBack(notifyId, title, subtitle, content, delay, nil, true, TimeFormatter.OneDaySeconds)
end

---OnSetFollowQuest
---@param quest wds.TaskUnit
function QuestModule:OnSetFollowQuest(quest)

      --Update followTask data
    if self._followTask then
        local tid = self._followTask.TID
        local cacheItem = self.Chapter:GetQuestCacheItem(tid)
        if cacheItem then
            self._followTask = cacheItem.unit
        else
            self._followTask = nil
        end
    end

    if quest ~= nil then
        local firstChpaterQuest = self:GetFirstChapterQuest()
        if not firstChpaterQuest or firstChpaterQuest.TID ~= quest.TID then
            if  not self._followTask or self._followTask.TID ~= quest.TID then
                self._followTask = quest
            end
        end
    end

    if self._followTask ~= nil and self._followTask.State >= wds.TaskState.TaskStateFinished then
        self._followTask = nil
    end

    g_Game.EventManager:TriggerEvent( EventConst.QUEST_FOLLOW_REFRESH )
end

function QuestModule:GetFollowQuest()
    return self._followTask
end


function QuestModule:UpdateFollowQuest()
    if self._followTask then

        local firstChpaterQuest = self:GetFirstChapterQuest()
        if firstChpaterQuest.TID == self._followTask.TID then
            self._followTask = nil
            return
        end

        local player = ModuleRefer.PlayerModule:GetPlayer()
        local taskDB = nil
        if player then
            taskDB = player.PlayerWrapper.Task
        end
        if taskDB then
            local taskUnit = self:GetTaskUnit(self._followTask.TID, taskDB)
            if taskUnit.State ~= wds.TaskState.TaskStateCanFinish
                and taskUnit.State ~= wds.TaskState.TaskStateReceived
            then
                self._followTask = nil
            else
                self._followTask = taskUnit
            end
        end
    end
end

---@return wds.TaskUnit
function QuestModule:GetFirstChapterQuest()
    return self.Chapter:GetFirstTask()
end

function QuestModule:GetFirstTwoChapterQuest()
    return self.Chapter:GetFirstTwoChapterQuest()
end


function QuestModule:OnRegister()
    self.growUpQuests = {}
    self:InitChapterGroupIndexCache()
    self:InitGrowUpTask()
    --    init submodule
    self.Chapter = require('QuestModule_Chapter').new()
    self.Chapter:OnRegister(self)
    self.Daily = require('QuestModule_Daily').new()
    self.Daily:OnRegister(self)
    g_Game.EventManager:AddListener(EventConst.QUEST_SET_FOLLOW, Delegate.GetOrCreate(self,self.OnSetFollowQuest))
    --g_Game.EventManager:AddListener(EventConst.STORY_END, Delegate.GetOrCreate(self,self.OnStoryPlayFin))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.Tick))

    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath,Delegate.GetOrCreate(self,self.OnTaskDBChanged))
    self.dataWatcher = require('QuestDataWatcher').new()
    self.dataWatcher:Init()

    g_Game.ServiceManager:AddResponseCallback(TaskFinishStateParamter.GetMsgId(),Delegate.GetOrCreate(self,self.QuestFinishStateResponse))
end

function QuestModule:OnRemove()
    self.Chapter:OnRemove()
    self.Chapter = nil
    self:ClearTaskCondCache()

    self.Daily:OnRemove()
    self.Daily = nil

    g_Game.EventManager:RemoveListener(EventConst.QUEST_SET_FOLLOW, Delegate.GetOrCreate(self,self.OnSetFollowQuest))
    --g_Game.EventManager:RemoveListener(EventConst.STORY_END, Delegate.GetOrCreate(self,self.OnStoryPlayFin))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath,Delegate.GetOrCreate(self,self.OnTaskDBChanged))
    g_Game.ServiceManager:RemoveResponseCallback(TaskFinishStateParamter.GetMsgId(),Delegate.GetOrCreate(self,self.QuestFinishStateResponse))
    self.dataWatcher:Destory()
    self.dataWatcher = nil
end

function QuestModule:InitGrowUpTask()
    for _, config in ConfigRefer.Task:ipairs() do
		if config:Property():TaskType() == TaskType.GrowUp then
            self.growUpQuests[#self.growUpQuests + 1] = config:Id()
        end
    end
end

function QuestModule:OnCloseNewChapterWin()
    g_Game.UIManager:Open(require('UIMediatorNames').QuestUIMediator, {page = 1})

end

function QuestModule:ShowNewChapterWin()

end

function QuestModule:OpenMissionWindow(page,initState,callBack)
    page = page or 1
    self.Chapter:CreatePageState()
    self.Chapter:SetInitPageState(initState)
    self.windowId = g_Game.UIManager:Open(require('UIMediatorNames').QuestUIMediator, {page = page}, callBack)
end

function QuestModule:CloseMissionWindow()
    if g_Game.UIManager:IsOpened(self.windowId) then
        g_Game.UIManager:Close(self.windowId)
    end
end

function QuestModule:IsMissionWindowOpend()
    return g_Game.UIManager:IsOpened(self.windowId)
end

---@param group ItemGroupConfigCell
function QuestModule.GetItemGroupInfo(group)
    if not group then return nil end
    local infoLength = group:ItemGroupInfoListLength()
    if infoLength < 1 then return nil end

    local rewards = {}
    for i = 1, infoLength do
        ---@type ItemGroupInfo
        local info = group:ItemGroupInfoList(i)
        if info then table.insert(rewards, info) end
    end
    return rewards
end

---@param groupId number ItemGroupConfig.Id
---@return ItemGroupInfo[] Items,Nums,Weights
function QuestModule.GetItemGroupInfoById(groupId)
    if not groupId then return nil end
    local group = ConfigRefer.ItemGroup:Find(groupId)
    return QuestModule.GetItemGroupInfo(group)
end

---@param groupStrId string
---@return ItemGroupInfo[] Items,Nums,Weights
function QuestModule.GetItemGroupInfoByStringId(groupStrId)
    if string.IsNullOrEmpty(groupStrId) then return nil end
    return QuestModule.GetItemGroupInfo(ConfigRefer.ItemGroup:Find(ItemGroupConsts[groupStrId]))
end


---FindTaskConfig
---@param i_task number
---@return TaskConfigCell
function QuestModule:TaskConfig(i_task)
    return ConfigRefer.Task:Find(i_task)
end

function QuestModule:IsChapterTask(i_task)
    local cfg = self:TaskConfig(i_task)
    local taskType = cfg:Property():TaskType()
    return taskType == TaskType.Chapter
end


---GetTaskCondMax
---@param tid number
---@param branch number @index of Branchs, start from ZERO
---@param index number @index of Conditions, start from ZERO
---@return CacheTaskCondition
function QuestModule:GetTaskFinishCond(tid,branch,index)
    branch = branch or 0
    index = index or 0
    if not self._taskCondCache then
        ---@type table<number,table<number,CacheTaskCondition>>
        self._taskCondCache = {}
    end
    local cacheItem = self._taskCondCache[tid]
    if not cacheItem then
        ---@type table<number,CacheTaskCondition>
        cacheItem = {}
        local config = self:TaskConfig(tid)
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
                    item.count,item.params,item.desc = TaskConfigUtils.CondProcesser(item.typ,cond:Param())
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
                    item.count,item.params,item.desc = TaskConfigUtils.CondProcesser(item.typ,cond:Param())
                    cacheItem[key] = item
                end
            end
        end
        self._taskCondCache[tid] = cacheItem
    end
    local condKey = TaskConfigUtils.TaskCondKey(branch,index)
    return cacheItem[condKey]
end

function QuestModule:DeleteTaskCondCache(tid)
    if not self._taskCondCache then return end
    self._taskCondCache[tid] = nil
end

function QuestModule:ClearTaskCondCache()
    if not self._taskCondCache then return end
    self._taskCondCache = nil
end

---GetTaskProgress
---@param taskUnit wds.TaskUnit
---@param branch number condition branch
---@param index number condtion index
---@return number,number count,maxCount
function QuestModule:GetTaskProgress(taskUnit,branch,index)
    if not taskUnit then return 0 end
    branch = branch or 0
    index = index or 0

    local taskCond = self:GetTaskFinishCond(taskUnit.TID,branch,index)
    local max = 0
    if taskCond then
        max = taskCond.count
    else
        return 0, 0
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
            local clientData = self.dataWatcher:GetDataByCondition(taskCond.typ,taskCond.op,taskCond.params)
            if clientData then
                current = clientData
            else
                current = 0
            end
        end
    end
    return current,max
end


---OnTaskDBChanged
---@param data wds.Player
---@param changed table
function QuestModule:OnTaskDBChanged(data,changed)
    self:UpdateProgressingTask()
    self.Chapter:UpdateQuestCache(true)
    g_Game.EventManager:TriggerEvent(EventConst.TASK_DATA_REFRESH)
    self:OnSetFollowQuest()
end

---@param taskID number TaskConfigCell.ID
------@return string
function QuestModule:GetTaskDescWithProgress(taskID, progressPostfix)
    local progressCount,progressMax = self:GetTaskProgressByTaskID(taskID)
    local taskName,param = self:GetTaskNameByID(taskID)
    local taskInfoStr = ''
    if progressCount and progressMax and progressMax > 0 then
        --直接使用默认空格(Breaking Space)会导致换行，需要使用Unicode字符\u00A0(Non-breaking Space)来避免这种情况的产生
        taskInfoStr = string.format('<b>(%d/%d)</b>\u{00A0}',progressCount, progressMax)
    end
    if param then
        if progressPostfix then
            taskInfoStr = I18N.GetWithParamList(taskName,param) .. taskInfoStr
        else
            taskInfoStr = taskInfoStr .. I18N.GetWithParamList(taskName,param)
        end
    else
        if progressPostfix then
            taskInfoStr = I18N.Get(taskName) .. taskInfoStr
        else
            taskInfoStr = taskInfoStr .. I18N.Get(taskName)
        end
    end
    return taskInfoStr
end

---@param taskID number TaskConfigCell.ID
------@return string
function QuestModule:GetTaskParam(taskID)
    local progressCount,progressMax = self:GetTaskProgressByTaskID(taskID)
    local taskInfoStr = ''
    if progressCount and progressMax and progressMax > 0 then
        --直接使用默认空格(Breaking Space)会导致换行，需要使用Unicode字符\u00A0(Non-breaking Space)来避免这种情况的产生
        taskInfoStr = string.format('<b>(%d/%d)</b>\u{00A0}',progressCount, progressMax)
    end
    return taskInfoStr
end


---@param taskID number TaskConfigCell.ID
------@return string
function QuestModule:GetTaskDesc(taskID)
    local taskName,param = self:GetTaskNameByID(taskID)
    local taskInfoStr = ''
    if param then
        taskInfoStr = taskInfoStr .. I18N.GetWithParamList(taskName,param)
    else
        taskInfoStr = taskInfoStr .. I18N.Get(taskName)
    end
    return taskInfoStr
end

---@param taskID number TaskConfigCell.ID
---@return string, string[] | nil
function QuestModule:GetTaskNameByID(taskID)
    local taskConfig = self:TaskConfig(taskID)
    return self:GetTaskName(taskConfig)
end

---GetTaskName
---@param config TaskConfigCell
---@return string,string[]
function QuestModule:GetTaskName(config)
    local taskProp = config:Property()
    if not taskProp then
        return '',nil
    end
    local taskCond = self:GetTaskFinishCond(config:Id())
    return taskProp:Name(), (taskCond ~= nil) and taskCond.desc or nil
end

---@param taskID number TaskConfigCell.ID
---@return number
function QuestModule:GetTaskGotoID(taskID)
    local taskConfig = self:TaskConfig(taskID)
    if not taskConfig then return 0 end
    local taskProp = taskConfig:Property()
    if not taskProp then return 0 end
    return taskProp:Goto()
end

local BitValueMask = 0x003F
local BitKeyMask = 0xFFFFFFFFFFFFFFC0

function BitHas(id,value)
    return (1<<(id&BitValueMask)&value) ~= 0
end

function QuestModule:IsInBitMap(configId, bitMap)
    local key = configId >> 6
    local mapValue = bitMap[key]
    if mapValue then
        return BitHas(configId,mapValue)
    end
    return false
end

---@param taskId number TaskConfigCell.ID
---@param callback fun(taskId:number,finishCount:number,state:wds.TaskState):void @finishCount表示任务完成的次数. state表示任务当前的状态,如果任务不存在则返回-1
function QuestModule:GetQuestFinishedState(taskID, callback)
    -- if not self.finishStateCallback then
    --     self.finishStateCallback = {}
    -- end
    -- if not self.finishStateCallback[taskID] then
    --     self.finishStateCallback[taskID] = {}
    -- end

    -- table.insert(self.finishStateCallback[taskID],callback)

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        if callback then
            callback(taskID,0,wds.TaskState.TaskStateInit)
        end
        return
    end
    local taskState = nil
    local taskDB = player.PlayerWrapper.Task
    if taskDB and taskDB.Processing and taskDB.FinishedBitMap then
        if taskDB.Processing[taskID] then
            local taskUnit = taskDB.Processing[taskID]
            taskState = taskUnit.State
        elseif self:IsInBitMap(taskID,taskDB.FinishedBitMap) then
            taskState = wds.TaskState.TaskStateFinished
        end
    end
    if taskState ~= nil then
        if callback then
            callback(taskID,0,wds.TaskState.TaskStateInit)
        end
        return
    end


    local operationParameter = TaskFinishStateParamter.new()
    operationParameter.args.TaskID = taskID
    operationParameter:Send(nil,{callback = callback})
end

---@param taskID number
---@return wds.TaskState 只检查本地缓存中任务状态, 不向后端请求
function QuestModule:GetQuestFinishedStateLocalCache(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return wds.TaskState.TaskStateInit
    end
    local taskDB = player.PlayerWrapper.Task
    if taskDB and taskDB.Processing and taskDB.FinishedBitMap then
        if taskDB.Processing[taskID] then
            local taskUnit = taskDB.Processing[taskID]
            return taskUnit.State
        elseif self:IsInBitMap(taskID,taskDB.FinishedBitMap) then
            return wds.TaskState.TaskStateFinished
        end
    end
    return wds.TaskState.TaskStateInit
end

function QuestModule:IsTaskFinishedAtLocalCache(taskId)
    local state = self:GetQuestFinishedStateLocalCache(taskId)
    return state == wds.TaskState.TaskStateFinished
end

function QuestModule:QuestFinishStateResponse(ret, response,req)
    if not ret then return end
    local taskId = req.request.TaskID
    if req.userdata and req.userdata.callback then
        pcall(req.userdata.callback,taskId,response.FinishCount,response.State)
    end
    -- if self.finishStateCallback and self.finishStateCallback[taskId] then
    --     for key, value in pairs(self.finishStateCallback[taskId]) do
    --         -- body
    --         if value then
    --             value()
    --         end
    --     end
    --     self.finishStateCallback[taskId] = nil
    -- end
end

---@return boolean 章节是否完成
function QuestModule:ChapterFinishQuickCheck(chapterId)
    if not self.Chapter then
        return false
    end
    local curChapter = self.Chapter:CurrentChapterId()
    --这里需要保证章节的id是顺序排列的,这样才能使用ID来判断章节是否完成
    return curChapter > chapterId
end

---private
---@param tid number
---@param taskDB wds.Task
---@return wds.TaskUnit
function QuestModule:GetTaskUnit(tid,taskDB)

    local taskDBCell = taskDB.Processing[tid]

    if not taskDBCell then

        if self:IsInBitMap(tid,taskDB.FinishedBitMap) then
            taskDBCell ={
                    TID = tid,
                    State = wds.TaskState.TaskStateFinished
                }

        else
            taskDBCell ={
                TID = tid,
                State = wds.TaskState.TaskStateInit
            }
        end
    end

    return taskDBCell
end
---private
function QuestModule:UpdateProgressingTask()
    if not self.taskCache then
        self.taskCache = {}
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then return nil end

    local taskDB = player.PlayerWrapper.Task
    if not taskDB or not taskDB.Processing or not taskDB.FinishedBitMap then
        return nil
    end

    for key, value in pairs(taskDB.Processing) do
        local taskID = value.TID
        local cachedItem = self.taskCache[taskID]
        if cachedItem == nil then
            cachedItem = {}
            self.taskCache[taskID] = cachedItem
        end
        cachedItem.unit = value
        cachedItem.config = ConfigRefer.Task:Find(taskID)
        if cachedItem.config then
            local property = cachedItem.config:Property()
            if property then
                cachedItem.type = property:TaskType()
            end
        end
    end
end

---@return table<number,CachedTaskItem>
function QuestModule:GetProgressingTask()
    if not self.taskCache then
        self:UpdateProgressingTask()
    end
    return self.taskCache
end

---@param taskID number
---@return number,number @count,maxCount
function QuestModule:GetTaskProgressByTaskID(taskID)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local taskDB = nil
    if player then
        taskDB = player.PlayerWrapper.Task
    end
    if taskDB then
        local taskUnit = self:GetTaskUnit(taskID, taskDB)
        if taskUnit then
            return self:GetTaskProgress(taskUnit)
        end
    end
    return 0,0
end

function QuestModule:InitChapterGroupIndexCache()
    table.clear(self._chapterGroupIndexCache)
    local Chapter = ConfigRefer.Chapter
    ---@type {id:number,index:number,chapters:table<number,{id:number,index:number,next:number}>}[]
    local chapterGroupArray = {}
    for _, c in Chapter:ipairs() do
        local group = c:Group()
        local groupData = self._chapterGroupIndexCache[group]
        if not groupData then
            groupData = {id = group, chapters = {}}
            self._chapterGroupIndexCache[group] = groupData
            table.insert(chapterGroupArray, groupData)
        end
        groupData.chapters[c:Id()] = {id = c:Id(), index = nil, next = c:NextChapter() }
    end
    table.sort(chapterGroupArray, function(a, b)
        return a.id < b.id
    end)
    for i = 1, #chapterGroupArray do
        local g = chapterGroupArray[i]
        g.index = i
        self:SortChapters(g.chapters)
    end
end

---@param chapters table<number,{id:number,index:number,next:number}>
function QuestModule:SortChapters(chapters)
    ---@type table<number, number>
    local reverseMap = {}
    ---@type table<number, {id:number,index:number,next:number}>
    local endPoints = {}
    local count = 0
    local endPointCount = 0
    for _, c in pairs(chapters) do
        count = count + 1
        if c.next > 0 and chapters[c.next] then
            reverseMap[c.next] = c.id
        else
            endPointCount = endPointCount + 1
            endPoints[c.id] = c
        end
    end
    if UNITY_DEBUG then
        if endPointCount > 1 then
            local ids = ""
            for id, _ in pairs(endPoints) do
                ids = ids .. id .. ","
            end
            g_Logger.Error("chapter group has more than one end point" .. ids)
        end
        if endPointCount <= 0 then
            g_Logger.Error("chapter group has no end point")
        end
    end
    ---@type {id:number,index:number,next:number}
    local endPoint
    for _, v in pairs(endPoints) do
        endPoint = v
        break
    end
    ---@type {id:number,index:number,next:number}[]
    local sortedArray = {}
    local current = endPoint
    while current do
        table.insert(sortedArray,1, current)
        local nextId = reverseMap[current.id]
        if not nextId then
            break
        end
        current = chapters[nextId]
    end
    if UNITY_DEBUG then
        if #sortedArray ~= count then
            g_Logger.Error("chapter group has loop or more than one chain")
        end
    end
    for i = 1, #sortedArray do
        local c = sortedArray[i]
        c.index = i
    end
end

---@param chapterConfigId number
---@return boolean,number|nil,number|nil
function QuestModule:IsChapterFinished(chapterConfigId)
    local chapterConfig = ConfigRefer.Chapter:Find(chapterConfigId)
    if not chapterConfig then
        return false,1,1
    end
    local chapterGroup = ConfigRefer.ChapterGroup:Find(chapterConfig:Group())
    if not chapterGroup then
        return false,1,1
    end
    local chapterGroupIndex = self:GetChapterGroupIndex(chapterGroup:Id())
    local chapterIndex = self:GetChapterInGroupIndex(chapterConfig:Id())
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return false,chapterGroupIndex,chapterIndex
    end
    local ChapterDb = player.PlayerWrapper.Chapter
    local currentChapterId = ChapterDb.ChapterID
    local currentChapterConfig = ConfigRefer.Chapter:Find(currentChapterId)
    if not currentChapterConfig then
        return false,chapterGroupIndex,chapterIndex
    end
    local currentChapterGroupId = currentChapterConfig:Group()
    if currentChapterGroupId == chapterGroup:Id() then
        return chapterConfigId < currentChapterId,chapterGroupIndex,chapterIndex
    end
    if currentChapterGroupId < chapterGroup:Id() then
        return false,chapterGroupIndex,chapterIndex
    end
    return true,chapterGroupIndex,chapterIndex
end

---@param chapterGroupConfigId number
---@return number
function QuestModule:GetChapterGroupIndex(chapterGroupConfigId)
    local group = self._chapterGroupIndexCache[chapterGroupConfigId]
    if group then
        return group.index or -1
    end
    return -1
end

---@param chapterConfigId number
---@return number
function QuestModule:GetChapterInGroupIndex(chapterConfigId)
    local chapter = ConfigRefer.Chapter:Find(chapterConfigId)
    if chapter and chapter:Group() then
        local group = self._chapterGroupIndexCache[chapter:Group()]
        return group and group.chapters[chapterConfigId] and group.chapters[chapterConfigId].index or -1
    end
    return -1
end

---@return bool
function QuestModule:HasRewardQuest()
    local questCache = self.Chapter:GetChapterQuests()
    for _, value in pairs(questCache) do
        if value.unit.State == wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    for _, taskId in ipairs(ModuleRefer.QuestModule.growUpQuests) do
        local taskState = self:GetQuestFinishedStateLocalCache(taskId)
        if taskState == wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    local processingRecommendTasks = self.Daily.dailyTaskInfo.ProcessingRecommendTasks
	for _, id in ipairs(processingRecommendTasks) do
        local taskState = self:GetQuestFinishedStateLocalCache(id)
        if taskState == wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    local processingNormalTasks = self.Daily.dailyTaskInfo.ProcessingNormalTasks
    for _, id in ipairs(processingNormalTasks) do
        local taskState = self:GetQuestFinishedStateLocalCache(id)
        if taskState == wds.TaskState.TaskStateCanFinish then
            return true
        end
    end
    return false
end

---@param taskLinkCfgId number
---@return number
function QuestModule:GetTaskLinkCurTask(taskLinkCfgId)
    local taskLinkCfg = ConfigRefer.TaskLink:Find(taskLinkCfgId)
    if not taskLinkCfg then
        return 0
    end
    for i = 1, taskLinkCfg:LinkLength() do
        local taskId = taskLinkCfg:Link(i)
        local taskState = self:GetQuestFinishedStateLocalCache(taskId)
        if taskState <= wds.TaskState.TaskStateCanFinish then
            return taskId
        end
    end
    return 0
end

return QuestModule
