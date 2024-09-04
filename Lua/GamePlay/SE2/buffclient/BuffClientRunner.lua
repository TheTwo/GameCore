---
--- Created by wupei. DateTime: 2022/2/24
---

local TimerUtility = require("TimerUtility")
local SELogger = require("SELogger")
local BuffClientEnum = require("BuffClientEnum")
local BuffClientState = require("BuffClientState")
local BuffClientStateFinish = require("BuffClientStateFinish")
local Delegate = require("Delegate")

local STATE_FINISH = "finish"

local trueTransition = function() return true end

local convertList = function(list)
    if list and #list > 0 then
        return list
    end
    return nil
end

---@class BuffClientRunner
---@field _buffParam BuffClientParam
---@field _state number
---@field onEndCallback function
---@field _stages table
---@field FSM FiniteStateMachine
---@field _frameHandle table
local BuffClientRunner = class("BuffClientRunner")

---@param self BuffClientRunner
---@param buffParam BuffClientParam
---@param buffData table
---@return void
function BuffClientRunner:ctor(buffParam, buffData)
    self._buffParam = buffParam
    self._stages = buffData["Stages"]
    self._state = BuffClientEnum.RunningState.NotRunning
    self.onEndCallback = nil
    self.FSM = nil
    self._frameHandle = nil
end

---@param self BuffClientRunner
---@return BuffClientParam
function BuffClientRunner:GetParam()
    return self._buffParam
end

---@param self BuffClientRunner
---@param onEndCallback function
function BuffClientRunner:Start(onEndCallback)
    if self._state ~= BuffClientEnum.RunningState.NotRunning then
        g_Logger.Error("BuffClientRunner._state error. _state: %s", self._state)
        return
    end

    self._state = BuffClientEnum.RunningState.Running
    self.onEndCallback = onEndCallback

    if self._buffParam:GetStage() == BuffClientEnum.Stage.Logic then
        self:CreateLogicState()
    else
        self:CreateStates()
    end
end

---@param self BuffClientRunner
function BuffClientRunner:CreateStates()
    local buffTarget = self._buffParam:GetTarget()
    self.FSM = require("FSMMachine").new()
    local firstState = nil

    -- add
    local buffAdd = convertList(self._stages[BuffClientEnum.Stage.Add])
    if buffAdd then
        self.FSM:AddState(BuffClientEnum.Stage.Add, BuffClientState.new(buffAdd, buffTarget))
        firstState = BuffClientEnum.Stage.Add
    end

    -- persist
    local buffPersist = convertList(self._stages[BuffClientEnum.Stage.Persist])
    if buffPersist then
        self.FSM:AddState(BuffClientEnum.Stage.Persist, BuffClientState.new(buffPersist, buffTarget))
        if firstState == nil then
            firstState = BuffClientEnum.Stage.Persist
        end
    end

    -- end
    local buffEnd = convertList(self._stages[BuffClientEnum.Stage.End])
    if buffEnd then
        self.FSM:AddState(BuffClientEnum.Stage.End, BuffClientState.new(buffEnd, buffTarget))
    end

    -- finish
    self.FSM:AddState(STATE_FINISH, BuffClientStateFinish.new(self.OnFinish, self))

    -- add -> (Persist) -> end -> finish

    self.FSM:AddTransition(BuffClientEnum.Stage.Add, BuffClientEnum.Stage.Persist, trueTransition)
    self.FSM:AddTransition(BuffClientEnum.Stage.Persist, BuffClientEnum.Stage.Persist, trueTransition)
    self.FSM:AddTransition(BuffClientEnum.Stage.End, STATE_FINISH, trueTransition)

    if firstState then
        self.FSM:SetState(firstState)
    else
        self.FSM:SetState(STATE_FINISH)
    end

    self._frameHandle = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnUpdate), 0, -1, true)
end

---@param self BuffClientRunner
function BuffClientRunner:CreateLogicState()
    local buffTarget = self._buffParam:GetTarget()
    self.FSM = require("FSMMachine").new()
    local firstState = nil

    -- logic
    local buffLogic = convertList(self._stages[BuffClientEnum.Stage.Logic])
    if buffLogic then
        self.FSM:AddState(BuffClientEnum.Stage.Logic, BuffClientState.new(buffLogic, buffTarget))
        firstState = BuffClientEnum.Stage.Logic
    end

    -- finish
    self.FSM:AddState(STATE_FINISH, BuffClientStateFinish.new(self.OnFinish, self))

    self.FSM:AddTransition(BuffClientEnum.Stage.Logic, STATE_FINISH, trueTransition)

    if firstState then
        self.FSM:SetState(firstState)
    else
        self.FSM:SetState(STATE_FINISH)
    end

    self._frameHandle = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnUpdate), 0, -1, true)
end

function BuffClientRunner:OnUpdate()
    if self.FSM then
        self.FSM:Update()
    end
end

---@param self BuffClientRunner
function BuffClientRunner:End()
    if not self.FSM then
        return
    end
    if not self.FSM:SetState(BuffClientEnum.Stage.End) then
        self.FSM:SetState(STATE_FINISH)
    end
end

---@param self BuffClientRunner
function BuffClientRunner:OnFinish()
    self._state = BuffClientEnum.RunningState.End
    try_catch_traceback(self.onEndCallback)

    if self._frameHandle then
        TimerUtility.StopAndRecycle(self._frameHandle)
        self._frameHandle = nil
    end

    self.FSM = nil
end

return BuffClientRunner
