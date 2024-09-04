local Delegate = require("Delegate")
local QueuedTaskResult = require("QueuedTaskResult")
local QueuedTaskNode = require("QueuedTaskNode")

---@class QueuedTaskNodeWaitResponse : QueuedTaskNode
---@field new fun(msgId:number,timeout:number, action:fun()):QueuedTaskNodeWaitResponse
local QueuedTaskNodeWaitResponse = class("QueuedTaskNodeWaitResponse", QueuedTaskNode)

QueuedTaskNodeWaitResponse.DefaultTimeout = 5

---@param eventName string
---@param action fun()
function QueuedTaskNodeWaitResponse:ctor(msgId, timeout, action)
    self.msgId = msgId
    if timeout == nil then
        self.timeout = QueuedTaskNodeWaitResponse.DefaultTimeout
    else
        self.timeout = timeout
    end
    self._action = action
end

function QueuedTaskNodeWaitResponse:Begin()
    g_Game.ServiceManager:AddResponseCallback(self.msgId, Delegate.GetOrCreate(self, self.ProcessResponse))    
    if self._action ~= nil then
        try_catch(self._action,function(result) 
            g_Logger.Error(result)
        end)
    end
    self.begineTime = g_Game.Time.time
end

function QueuedTaskNodeWaitResponse:Execute()
    if self._trigger then
        return QueuedTaskResult.MoveNext
    end

    if g_Game.Time.time - self.begineTime > self.timeout then
        self._trigger = true
    end
    
    return QueuedTaskResult.Execute
end

function QueuedTaskNodeWaitResponse:End()
    g_Game.ServiceManager:RemoveResponseCallback(self.msgId, Delegate.GetOrCreate(self, self.ProcessResponse))
end

function QueuedTaskNodeWaitResponse:ProcessResponse(isSuccess,response)
    self._trigger = true
end

return QueuedTaskNodeWaitResponse