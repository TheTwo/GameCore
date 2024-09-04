---@class Condition
---@field private state State
---@field private targetStateName string
local Condition = class('Condition')

---@param name string
function Condition:ctor(name)
    self.targetStateName = name
    self.state = nil
end

---@param state State
function Condition:SetState(state)
    self.state = state
end

---@return State
function Condition:GetState()
    return self.state
end

function Condition:GetTargetStateName()
    return self.targetStateName
end

---@return boolean
function Condition: Satisfied()
    -- 重载这个函数
    return false
end

function Condition:Release()
    self.state = nil;
    self.targetStateName = nil;
end

return Condition