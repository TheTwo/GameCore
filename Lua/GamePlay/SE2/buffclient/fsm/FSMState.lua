---
--- Created by wupei. DateTime: 2022/3/1
---

local FSMEnum = require("FSMEnum")

---@class FSMState
---@field public status string
---@field public name string
local FSMState = class("FSMState")

---@param self FSMState
function FSMState:ctor()
    self.status = FSMEnum.State.NotStarted
    self.name = ""
end

---@param self FSMState
function FSMState:Start()
    if self.status == FSMEnum.State.NotStarted then
        try_catch_traceback_with_vararg(self.OnStart, nil, self)
        self.status = FSMEnum.State.Running
    end
end

---@param self FSMState
function FSMState:Update()
    if self.status == FSMEnum.State.Running then
        self.status = try_catch_traceback_with_vararg(self.OnUpdate, nil, self) or FSMEnum.State.Running
    end
end

---@param self FSMState
function FSMState:End()
    if self.status ~= FSMEnum.State.NotStarted then
        try_catch_traceback_with_vararg(self.OnEnd, nil, self)
        self.status = FSMEnum.State.NotStarted
    end
end

---@param self FSMState
function FSMState:OnStart()

end

---@param self FSMState
function FSMState:OnUpdate()

end

---@param self FSMState
function FSMState:OnEnd()

end

return FSMState
