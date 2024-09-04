local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellNpcTaskDatum:TouchMenuCellDatumBase
---@field new fun(tasks):TouchMenuCellNpcTaskDatum
local TouchMenuCellNpcTaskDatum = class("TouchMenuCellNpcTaskDatum", TouchMenuCellDatumBase)

function TouchMenuCellNpcTaskDatum:ctor(taskId)
    self.taskId = taskId
end

function TouchMenuCellNpcTaskDatum:GetPrefabIndex()
    return 12
end

return TouchMenuCellNpcTaskDatum