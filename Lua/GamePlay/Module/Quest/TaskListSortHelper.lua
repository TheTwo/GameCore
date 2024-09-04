local ModuleRefer = require('ModuleRefer')
local TaskListSortHelper = {}

local TaskStatePriority = {
    [wds.TaskState.TaskStateFinished] = 2,
    [wds.TaskState.TaskStateCanFinish] = 4,
    [wds.TaskState.TaskStateReceived] = 3,
    [wds.TaskState.TaskStateCanReceive] = 1,
    [wds.TaskState.TaskStateInit] = 0,
}

TaskListSortHelper.TaskStatePriority = TaskStatePriority

function TaskListSortHelper.DefaultPriorityCaculator(id)
    local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(id)
    return TaskStatePriority[state]
end

function TaskListSortHelper.DefaultSorter(a, b, priorityCaculator)
    if not priorityCaculator then
        priorityCaculator = TaskListSortHelper.DefaultPriorityCaculator
    end
    local aPriority = priorityCaculator(a)
    local bPriority = priorityCaculator(b)
    if aPriority == bPriority then
        return a < b
    else
        return aPriority > bPriority
    end
end

---@param taskList table<number, number>
---@param priorityCaculator fun(id: number): number | nil
function TaskListSortHelper.Sort(taskList, priorityCaculator)
    table.sort(taskList, function (a, b)
        return TaskListSortHelper.DefaultSorter(a, b, priorityCaculator)
    end)
end

return TaskListSortHelper