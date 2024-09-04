---
--- Created by wupei. DateTime: 2022/3/1
---

local enum = require("FSMEnum")

---@class BuffClientStateFinish:FSMState
local FSMState = require("FSMState");
local BuffClientStateFinish = class("BuffClientStateFinish", FSMState);

---@param self BuffClientStateFinish
---@param onFinish function
---@param onFinishTarget any
function BuffClientStateFinish:ctor(onFinish, onFinishTarget)
    FSMState:ctor()

    self._onFinish = onFinish
    self._onFinishTarget = onFinishTarget
end

---@param self BuffClientStateFinish
---@return void
function BuffClientStateFinish:OnUpdate()
    try_catch_traceback_with_vararg(self._onFinish, nil, self._onFinishTarget)
    return enum.State.Finished
end

return BuffClientStateFinish
