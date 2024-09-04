local QueuedTaskResult = require("QueuedTaskResult")
local QueuedTaskNode = require("QueuedTaskNode")

---@class QueuedTaskNodeAction:QueuedTaskNode
local QueuedTaskNodeAction = class("QueuedTaskNodeAction", QueuedTaskNode)

function QueuedTaskNodeAction:ctor(callback, data)
    self._callback = callback
    self._data = data
end

function QueuedTaskNodeAction:Execute()
    if self._callback then
        self._callback(self._data)
    end
    
    return QueuedTaskResult.MoveNext
end

return QueuedTaskNodeAction