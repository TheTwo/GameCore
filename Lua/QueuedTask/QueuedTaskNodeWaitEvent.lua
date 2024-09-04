local Delegate = require("Delegate")
local QueuedTaskResult = require("QueuedTaskResult")
local QueuedTaskNode = require("QueuedTaskNode")

---@class QueuedTaskNodeWaitEvent : QueuedTaskNode
---@field new fun(eventName:string, callback:fun(), onEventReceived:fun(param:table):boolean):QueuedTaskNodeWaitEvent
local QueuedTaskNodeWaitEvent = class("QueuedTaskNodeWaitEvent", QueuedTaskNode)

---@param eventName string
---@param callback fun()
---@param onEventReceived fun(param:table):boolean
function QueuedTaskNodeWaitEvent:ctor(eventName, callback, onEventReceived)
    self._eventName = eventName
    self._callback = callback
    self._onEventReceived = onEventReceived
end

function QueuedTaskNodeWaitEvent:Begin()
    g_Game.EventManager:AddListener(self._eventName, Delegate.GetOrCreate(self, self.ProcessEvent))
    if self._callback ~= nil then
        self._callback()
    end
end

function QueuedTaskNodeWaitEvent:Execute()
    if self._trigger then
        return QueuedTaskResult.MoveNext
    end
    
    return QueuedTaskResult.Execute
end

function QueuedTaskNodeWaitEvent:End()
    g_Game.EventManager:RemoveListener(self._eventName, Delegate.GetOrCreate(self, self.ProcessEvent))
end

function QueuedTaskNodeWaitEvent:ProcessEvent(...)
    if self._onEventReceived then
        self._trigger = self._onEventReceived(...)
    else
        self._trigger = true
    end
end

return QueuedTaskNodeWaitEvent