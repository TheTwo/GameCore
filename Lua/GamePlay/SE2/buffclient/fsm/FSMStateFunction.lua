---
--- Created by wupei. DateTime: 2022/3/1
---

---@class FiniteStateFunction:FiniteState
---@field public _onStart function
---@field public _onUpdate function
---@field public _onEnd function
local FSMState = require("FSMState");
local FSMStateFunction = class("FSMStateFunction", FSMState);

---@param self FiniteStateFunction
---@param onStart any
---@param onUpdate any
---@param onEnd any
---@return void
function FSMStateFunction:ctor(onStart, onUpdate, onEnd)
    FSMStateFunction.super.ctor(self)
    self._onStart = onStart
    self._onUpdate = onUpdate
    self._onEnd = onEnd
end

---@param self FiniteStateFunction
---@return void
function FSMStateFunction:OnStart()
    try_catch(function()
        self._onStart(self)
    end, function(result)
        g_Logger.Error(result)
    end)
end

---@param self FiniteStateFunction
---@return void
function FSMStateFunction:OnUpdate()
    return try_catch(function()
        self._onUpdate(self)
    end, function(result)
        g_Logger.Error(result)
    end)
end

---@param self FiniteStateFunction
---@return void
function FSMStateFunction:OnEnd()
    try_catch(function()
        self._onEnd(self)
    end, function(result)
        g_Logger.Error(result)
    end)
end

return FSMStateFunction
