local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellTaskDatum:TouchMenuCellDatumBase
---@field new fun(taskId):TouchMenuCellTaskDatum
local TouchMenuCellTaskDatum = class("TouchMenuCellTaskDatum", TouchMenuCellDatumBase)
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

function TouchMenuCellTaskDatum:ctor(taskId)
    self.taskId = taskId
end

function TouchMenuCellTaskDatum:GetTaskDesc()
    local taskName,param = ModuleRefer.QuestModule:GetTaskNameByID(self.taskId)
    local taskInfoStr = ''
    if param then
        taskInfoStr = taskInfoStr .. I18N.GetWithParamList(taskName,param)
    else
        taskInfoStr = taskInfoStr .. I18N.Get(taskName)
    end
    return taskInfoStr
end

function TouchMenuCellTaskDatum:IsFinish()
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskId)
    return taskState == wds.TaskState.TaskStateFinished
end

function TouchMenuCellTaskDatum:GetPrefabIndex()
    return 4
end

return TouchMenuCellTaskDatum