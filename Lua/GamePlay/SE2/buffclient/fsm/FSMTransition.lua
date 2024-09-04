---
--- Created by wupei. DateTime: 2022/3/1
---

---@class FiniteStateTransition
---@field public toStateName string
---@field public evaluator function
local FSMTransition = class("FSMTransition");

---@param self FiniteStateTransition
---@param toStateName any
---@param evaluator any
---@return void
function FSMTransition:ctor(toStateName, evaluator)
    self.toStateName = toStateName
    self.evaluator = evaluator
end

return FSMTransition
