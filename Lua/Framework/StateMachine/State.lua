---@class State
---@field new fun():State
---@field stateMachine StateMachine
---@field transitions Condition[]
local State = class('State')

---@param stateMachine StateMachine
function State:SetStateMachine(stateMachine)
    self.stateMachine = stateMachine
    self.transitions = {}
end

function State:ReEnter()
    -- 重载这个函数
end

function State:Enter()
    -- 重载这个函数
end

function State:Exit()
    -- 重载这个函数
end

---@param dt number
function State:Tick(dt)
    -- 重载这个函数
end

---@param dt number
function State:LateTick(dt)
    -- 重载这个函数
end

---@param condition Condition
function State:AddTransition(condition)
    if condition then
        condition:SetState(self)
    end
    --local len = #self.transitions
    --self.transitions[len] = condition
    table.insert(self.transitions,condition)
end

---@return boolean
function State:Transition()
    for _, value in pairs(self.transitions) do
        if value:Satisfied() then
            self.stateMachine:ChangeState(value:GetTargetStateName())
            return true
        end
    end

    return false
end

function State:ClearAllTransitions()
    if self.transitions then
        for k, v in pairs(self.transitions) do
            v:Release();
        end
        table.clear(self.transitions);
    end
end

function State:Release()
    self:ClearAllTransitions();
    self.stateMachine = nil;
end

---@return string
function State:GetName()
    -- 重载这个函数
    return self.__class.__cname
end

function State:CanLightRestart()
    -- 重载这个函数
end

function State:OnLightRestartBegin()
    -- 重载这个函数
end

function State:OnLightRestartEnd()
    -- 重载这个函数
end

function State:OnLightRestartFailed()
    -- 重载这个函数
end


return State