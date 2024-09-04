local QueuedTaskResult = require("QueuedTaskResult")
local QueuedTaskNode = require("QueuedTaskNode")

---@class QueuedTaskNodeWaitTrue:QueuedTaskNode
local QueuedTaskNodeWaitTrue = class("QueuedTaskNodeWaitTrue", QueuedTaskNode)

function QueuedTaskNodeWaitTrue:ctor(callback, timeout)
    self._callback = callback
    self._timeout = timeout or 0
end

function QueuedTaskNodeWaitTrue:Begin()
    self._startTimestamp = CS.UnityEngine.Time.time
end

function QueuedTaskNodeWaitTrue:Execute()
    if self._callback == nil then
        return QueuedTaskResult.MoveNext
    end

    if self._callback() then
        return QueuedTaskResult.MoveNext
    end
    
    if self._timeout > 0 then
        local timestamp = CS.UnityEngine.Time.time
        if timestamp - self._startTimestamp >= self._timeout then
            return QueuedTaskResult.Break
        end
    end

    return QueuedTaskResult.Execute
end

return QueuedTaskNodeWaitTrue