local TaskItemDataProvider = require("TaskItemDataProvider")
local ColorConsts = require('ColorConsts')
local GuideUtils = require('GuideUtils')
local AllianceTaskOperationParameter = require("AllianceTaskOperationParameter")
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local WorldTrendDefine = require('WorldTrendDefine')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local TaskListSortHelper = require('TaskListSortHelper')
---@class AllianceTaskItemDataProvider : TaskItemDataProvider
local AllianceTaskItemDataProvider = class("AllianceTaskItemDataProvider", TaskItemDataProvider)

AllianceTaskItemDataProvider.TaskSortPriorityCaculator = function(id)
    local state = ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(id)
    return TaskListSortHelper.TaskStatePriority[state]
end

---@param taskCfgId number
---@param clickTransform CS.UnityEngine.Transform
function AllianceTaskItemDataProvider:ctor(taskCfgId, clickTransform)
    self.taskCfgId = taskCfgId
    self.clickTransform = clickTransform
    self.stateColors = {
        [false] = ColorConsts.warning,
        [true] = ColorConsts.quality_green
    }
    self.onClaim = function ()
        g_Logger.WarnChannel("TaskItemDataProvider", "onClaim is not set, using default")
        local operationParameter = AllianceTaskOperationParameter.new()
        operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
        operationParameter.args.CID = self.taskCfgId
        operationParameter:SendOnceCallback(self.clickTransform, nil, nil, function (_, isSuccess, _)
            if isSuccess then
                self.claimCallback()
            end
        end)
    end

    self.claimCallback = function ()
        g_Logger.WarnChannel("TaskItemDataProvider", "claimCallback is not set")
    end

    self.onGoto = function ()
        local cfg = ConfigRefer.AllianceTask:Find(self.taskCfgId)
        local task = ModuleRefer.AllianceJourneyModule:GetTask(self.taskCfgId)
        local state = self:GetTaskState()
        if state == wds.TaskState.TaskStateReceived then
            if task.UnlockTimeStamp ~= 0 then
                local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
                if curT >= task.UnlockTimeStamp then
                    -- 前往
                else
                    -- 未解锁
                    ModuleRefer.ToastModule:AddSimpleToast("#此任务未解锁")
                end
            else
            -- 前往
            end
         elseif state == wds.TaskState.TaskStateFinished then
            -- 已领取
            ModuleRefer.ToastModule:AddSimpleToast("#此任务已完成")
            return
        elseif state == wds.TaskState.TaskStateExpired then
            -- 过期
            ModuleRefer.ToastModule:AddSimpleToast("#此任务已过期")
            return
        end
        g_Logger.WarnChannel("TaskItemDataProvider", "onGoto is not set, using default")
        local taskProp = self:GetTaskCfg():Property()
        if not taskProp then return end
        GuideUtils.GotoByGuide(taskProp:Goto(), true)
    end
end

---@override
---@return number @wds.TaskState
function AllianceTaskItemDataProvider:GetTaskState()
    return ModuleRefer.WorldTrendModule:GetPlayerAllianceTaskState(self.taskCfgId)
end

---@override
---@return AllianceTaskConfigCell
function AllianceTaskItemDataProvider:GetTaskCfg()
    return ConfigRefer.AllianceTask:Find(self.taskCfgId)
end

---@override
---@param hideProgress boolean
---@param style {1:需要颜色和加粗}
---@return string
function AllianceTaskItemDataProvider:GetTaskStr(hideProgress, style)
    local ret = ""
    local numCurrent, numNeeded = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(self.taskCfgId)
    numNeeded = numNeeded or 0
    local taskCfg = self:GetTaskCfg()
    local desc, infoParam = ModuleRefer.WorldTrendModule:GetTaskName(taskCfg, WorldTrendDefine.TASK_TYPE.Alliance)
    local taskStr
    if infoParam then
        taskStr = I18N.GetWithParamList(desc, infoParam)
    else
        taskStr = I18N.Get(desc)
    end
    if numNeeded == 0 or hideProgress then
        ret = string.format('%s', taskStr)
    else
        if style == 1 then
            local color = self.stateColors[numCurrent >= (numNeeded or 0)]
            local coloredNumCurrent = UIHelper.GetColoredText(tostring(numCurrent), color)
            ret = string.format('<b>(%s/%d)</b> %s', coloredNumCurrent, numNeeded, taskStr)
        else
            ret = string.format('(%d/%d) %s', numCurrent, numNeeded, taskStr)
        end

    end
    return ret
end

---@override
---@return string
function AllianceTaskItemDataProvider:GetTaskProgressStr()
    local ret = ""
    local numCurrent, numNeeded = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(self.taskCfgId)
    numNeeded = numNeeded or 0
    local taskCfg = self:GetTaskCfg()
    local desc, infoParam = ModuleRefer.WorldTrendModule:GetTaskName(taskCfg, WorldTrendDefine.TASK_TYPE.Alliance)
    ret = string.format('(%d/%d)', numCurrent, numNeeded)
    return ret
end

---@override
---@param branch number
---@param index number
---@param returnInItemGroupInfo boolean
---@return ItemIconData[] | ItemGroupInfo[]
function AllianceTaskItemDataProvider:GetTaskRewards(branch, index, returnInItemGroupInfo)
    local rewardList = ModuleRefer.WorldTrendModule:GetTaskRewards(self:GetTaskCfg(), branch, index)
    if returnInItemGroupInfo then
        return rewardList
    end
    ---@type ItemIconData[]
    local ret = {}
    for _, v in ipairs(rewardList or {}) do
        ---@type ItemIconData
        local data = {}
        data.configCell = ConfigRefer.Item:Find(v:Items())
        data.count = v:Nums()
        data.showTips = true
        table.insert(ret, data)
    end
    return ret
end

return AllianceTaskItemDataProvider