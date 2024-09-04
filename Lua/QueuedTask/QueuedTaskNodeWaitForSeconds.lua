local QueuedTaskResult = require("QueuedTaskResult")
local QueuedTaskNode = require("QueuedTaskNode")

---@class QueuedTaskNodeWaitForSeconds:QueuedTaskNode
local QueuedTaskNodeWaitForSeconds = class("QueuedTaskNodeWaitForSeconds", QueuedTaskNode)

function QueuedTaskNodeWaitForSeconds:ctor(seconds)
    self._seconds = seconds
end

function QueuedTaskNodeWaitForSeconds:Begin()
    self._startTimestamp = CS.UnityEngine.Time.time
end

function QueuedTaskNodeWaitForSeconds:Execute()
    local timestamp = CS.UnityEngine.Time.time
    if timestamp - self._startTimestamp >= self._seconds then
        return QueuedTaskResult.MoveNext
    end
    
    return QueuedTaskResult.Execute
end

return QueuedTaskNodeWaitForSeconds