local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local TaskItemDataProvider = require('TaskItemDataProvider')
---@class TaskLinkDataProvider
local TaskLinkDataProvider = class("TaskLinkDataProvider")

function TaskLinkDataProvider:ctor(taskLinkId)
    self.taskLinkId = taskLinkId
end

---@return number
function TaskLinkDataProvider:GetCurTaskId()
    return ModuleRefer.QuestModule:GetTaskLinkCurTask(self.taskLinkId)
end

---@return TaskItemDataProvider
function TaskLinkDataProvider:GetCurTaskItemDataProvider()
    return TaskItemDataProvider.new(self:GetCurTaskId())
end

---@return number
function TaskLinkDataProvider:GetLastTaskId()
    local taskLinkCfg = ConfigRefer.TaskLink:Find(self.taskLinkId)
    if not taskLinkCfg then
        return 0
    end
    return taskLinkCfg:Link(taskLinkCfg:LinkLength())
end

---@return TaskItemDataProvider
function TaskLinkDataProvider:GetLastTaskItemDataProvider()
    return TaskItemDataProvider.new(self:GetLastTaskId())
end

---@return number
function TaskLinkDataProvider:GetTaskLinkId()
    return self.taskLinkId
end

---@return boolean
function TaskLinkDataProvider:LinkFinished()
    return self:GetCurTaskId() == 0
end

---@return boolean
function TaskLinkDataProvider:Claimable()
    if self:LinkFinished() then
        return false
    end
    return self:GetCurTaskItemDataProvider():GetTaskState() == wds.TaskState.TaskStateCanFinish
end

return TaskLinkDataProvider