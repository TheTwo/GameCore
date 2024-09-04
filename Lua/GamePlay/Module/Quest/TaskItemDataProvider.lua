local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local ColorConsts = require('ColorConsts')
local GuideUtils = require('GuideUtils')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local PlayerTaskOperationParameter = require('PlayerTaskOperationParameter')
local TaskCondType = require('TaskCondType')
---@class TaskItemDataProvider
local TaskItemDataProvider = class("TaskItemDataProvider")

---@param taskCfgId number
---@param clickTransform CS.UnityEngine.Transform
function TaskItemDataProvider:ctor(taskCfgId, clickTransform)
    self.taskCfgId = taskCfgId
    self.taskCfg = ConfigRefer.Task:Find(taskCfgId)
    self.clickTransform = clickTransform
    self.stateColors = {
        [false] = ColorConsts.warning,
        [true] = ColorConsts.quality_green
    }
    self.onClaim = function ()
        g_Logger.LogChannel("TaskItemDataProvider", "onClaim is not set, using default")
        local operationParameter = PlayerTaskOperationParameter.new()
        operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
        operationParameter.args.CID = self.taskCfgId
        operationParameter:SendOnceCallback(self.clickTransform, nil, nil, function (_, isSuccess, _)
            if isSuccess then
                self.claimCallback()
            end
        end)
    end

    self.claimCallback = function ()
        g_Logger.LogChannel("TaskItemDataProvider", "claimCallback is not set")
    end

    self.onGoto = function ()
        g_Logger.LogChannel("TaskItemDataProvider", "onGoto is not set, using default")
        local taskProp = self:GetTaskCfg():Property()
        if not taskProp or taskProp:Goto() == 0 then return end
        GuideUtils.GotoByGuide(taskProp:Goto(), true)
    end
end

---@return number @wds.TaskState
function TaskItemDataProvider:GetTaskState()
    return ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskCfgId)
end

---@return TaskConfigCell
function TaskItemDataProvider:GetTaskCfg()
    return self.taskCfg
end

---@return number
function TaskItemDataProvider:GetTaskCfgId()
    return self.taskCfgId
end

---@return string
function TaskItemDataProvider:GetTaskStr(hideProgress)
    local ret = ""
    local desc, infoParam = ModuleRefer.QuestModule:GetTaskNameByID(self.taskCfgId)
    local numCurrent, numNeeded = ModuleRefer.QuestModule:GetTaskProgressByTaskID(self.taskCfgId)
    numCurrent = numCurrent or 0
    numNeeded = numNeeded or 0
    numCurrent = math.min(numCurrent, numNeeded)
    local color = self.stateColors[numCurrent >= numNeeded]
    local coloredNumCurrent = UIHelper.GetColoredText(tostring(numCurrent), color)
    local taskStr
    if infoParam then
        taskStr = I18N.GetWithParamList(desc, infoParam)
    else
        taskStr = I18N.Get(desc)
    end
    if numNeeded == 0 or hideProgress then
        ret = string.format('%s', taskStr)
    else
        ret = string.format('<b>(%s/%d)</b> %s', coloredNumCurrent, numNeeded, taskStr)
    end
    return ret
end

---@return string
function TaskItemDataProvider:GetTaskUnlockStr()
    local cfg = self:GetTaskCfg()
    local unlockStr = ""
    local condLength = cfg:ReceiveCondition():FixedConditionLength()
    if condLength <= 0 then return unlockStr end
    local cond = cfg:ReceiveCondition():FixedCondition(1)
    local condType = cond:Typ()
    if condType == TaskCondType.SystemSwitchOpen then
        local switchId = cond:Param()
        local switchCfg = ConfigRefer.SystemEntry:Find(tonumber(switchId))
        if switchCfg then
            local refTask = switchCfg:UnlockTask()
            if refTask and refTask > 0 then
                local desc, infoParam = ModuleRefer.QuestModule:GetTaskNameByID(refTask)
                unlockStr = I18N.GetWithParamList(desc, infoParam)
            end
        end
    end
    return unlockStr
end

---@param branch number | nil
---@param index number | nil @this param is no longer used
---@param returnInItemGroupInfo boolean
---@return ItemIconData[] | ItemGroupInfo[]
function TaskItemDataProvider:GetTaskRewards(branch, index, returnInItemGroupInfo)
    local configCell = self:GetTaskCfg()
    branch = branch or 0
    branch = math.min(branch + 1, configCell:FinishBranchLength())
    local rewardList = {}
    for i = 1, configCell:FinishBranch(branch):BranchRewardLength() do
        local reward = ModuleRefer.QuestModule.Chapter:GetQuestRewards(configCell, branch, i - 1) or {}
        for _, v in ipairs(reward) do
            table.insert(rewardList, v)
        end
    end
    if returnInItemGroupInfo then
        return rewardList
    end
    ---@type ItemIconData[]
    local ret = {}
    for _, v in ipairs(rewardList) do
        ---@type ItemIconData
        local data = {}
        data.configCell = ConfigRefer.Item:Find(v:Items())
        data.count = v:Nums()
        data.showTips = true
        table.insert(ret, data)
    end
    return ret
end

---@return number
function TaskItemDataProvider:GetTaskReceiveTimeSec()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then return 0 end
    local task = player.PlayerWrapper.Task.Processing[self.taskCfgId]
    if not task then return 0 end
    return task.TimeStamp
end

---@param branch number
---@param condIndex number
---@param paramIndex number
---@return number
function TaskItemDataProvider:GetTaskConditionParam(branch, condIndex, paramIndex)
    local configCell = self:GetTaskCfg()
    branch = branch or 0
    branch = math.min(branch + 1, configCell:FinishBranchLength())
    condIndex = condIndex or 1
    paramIndex = paramIndex or 1
    local cond = configCell:FinishBranch(branch):BranchCondition():FixedCondition(condIndex)
    return cond:Param(paramIndex)
end

---@return boolean
function TaskItemDataProvider:IsTaskFinished()
    return self:GetTaskState() == wds.TaskState.TaskStateFinished
end

---@return boolean
function TaskItemDataProvider:HasGoto()
    local taskProp = self:GetTaskCfg():Property()
    return taskProp ~= nil and taskProp:Goto() > 0
end

---@param clickTransform CS.UnityEngine.Transform
function TaskItemDataProvider:SetClickTransform(clickTransform)
    self.clickTransform = clickTransform
end

---@param callback fun()
function TaskItemDataProvider:SetClaimCallback(callback)
    self.claimCallback = callback
end

---@param onClaim fun()
function TaskItemDataProvider:SetOnClaim(onClaim)
    self.onClaim = onClaim
end

---@param onGoto fun()
function TaskItemDataProvider:SetOnGoto(onGoto)
    self.onGoto = onGoto
end

---@param state number @wds.TaskState
---@param color string @hex code
function TaskItemDataProvider:SetStateColor(state, color)
    self.stateColors[state] = color
end

function TaskItemDataProvider:OnClaim()
    self.onClaim()
end

function TaskItemDataProvider:OnGoto()
    self.onGoto()
end

return TaskItemDataProvider