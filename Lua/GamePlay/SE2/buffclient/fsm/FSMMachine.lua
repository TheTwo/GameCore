---
--- Created by wupei. DateTime: 2022/3/1
---

local FSMEnum = require("FSMEnum")
local FSMTransition = require("FSMTransition")

---@class FSMMachine
---@field public currentState FSMState
---@field public states table<string, FSMState>
---@field public transitions table<string, string>
local FSMMachine = class("FSMMachine")

---@param self FSMMachine
---@param ... any
function FSMMachine:ctor(...)
    self.currentState = nil
    self.states = {}
    self.transitions = {}
end

---@param self FSMMachine
---@param stateName string
---@return boolean
function FSMMachine:ContainState(stateName)
    return self.states[stateName] ~= nil
end

---@param self FSMMachine
---@param fromStateName string
---@param toStateName string
---@return boolean
function FSMMachine:ContainTransition(fromStateName, toStateName)
    return self.transitions[fromStateName] ~= nil and
            self.transitions[fromStateName][toStateName] ~= nil
end

---@param self FSMMachine
---@return string
function FSMMachine:GetCurrentStateName()
    if self.currentState then
        return self.currentState.name
    end
end

---@param self FSMMachine
---@return string
function FSMMachine:GetCurrentStateStatus()
    if self.currentState then
        return self.currentState.status
    end
end

---@param self FSMMachine
---@param stateName string
---@return boolean
function FSMMachine:SetState(stateName)
    if self:ContainState(stateName) then
        self:RunState(self.states[stateName])
        return true
    end
    return false
end

---@param self FSMMachine
---@param name string
---@param state FSMState
function FSMMachine:AddState(name, state)
    state.name = name
    self.states[name] = state
end

---@param self FSMMachine
---@param fromStateName string
---@param toStateName string
---@param evaluator function
function FSMMachine:AddTransition(fromStateName, toStateName, evaluator)
    if self:ContainState(fromStateName) and self:ContainState(toStateName) then
        if self.transitions[fromStateName] == nil then
            self.transitions[fromStateName] = {}
        end
        table.insert(self.transitions[fromStateName], FSMTransition.new(toStateName, evaluator))
    end
end

function FSMMachine:EvaluateTransitions(transitions)
    if not transitions then
        return
    end
    for index = 1, #transitions do
        if transitions[index].evaluator() then
            return transitions[index].toStateName
        end
    end
end

---@param self FSMMachine
---@param state FSMState
function FSMMachine:RunState(state)
    if self.currentState then
        self.currentState:End()
    end
    self.currentState = state
    self.currentState:Start()
    self:Update()
end

---@param self FSMMachine
function FSMMachine:Update()
    if self.currentState then
        self.currentState:Update()
        while self.currentState.status ~= FSMEnum.State.Running do
            self.currentState:End()
            local toStateName = self:EvaluateTransitions(self, self.transitions[self.currentState.name])
            if self:ContainState(toStateName) then
                self.currentState = self.states[toStateName]
                self.currentState:Start()
                self.currentState:Update()
            else
                break
            end
        end
    end
end

return FSMMachine
