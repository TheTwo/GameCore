---@class StateMachine
---@field private states table<string, State>
---@field currentName string
---@field currentState State
---@field allowReEnter boolean
---@field new fun():StateMachine
local StateMachine = sealedClass('StateMachine')

---@type Blackboard
local Blackboard = require("Blackboard")

function StateMachine:ctor(usepcall)
    self.states = {}
    self.enableLog = false
    self.currentName = nil
    self.currentState = nil
    self.allowReEnter = false;
    self.blackboard = Blackboard.new()
    self._onStateChanged = {}
    self.pcallChange = usepcall or false
    self.willTransToStateName = nil
end

---@param name string
---@param state State
function StateMachine:AddState(name, state)
    if state then
        state:SetStateMachine(self)
        self.states[name] = state
    end
end

---@param name string
function StateMachine:ChangeState(name)
    if not self.pcallChange then
        return self:ChangeStateImpl(name)
    else
        return self:SafeChangeStateImpl(name)
    end
end

---@private
function StateMachine:ChangeStateImpl(name)
    self.willTransToStateName = name
    local postProcessStateChange = nil
    ---@type State
    local oldState = self.currentState
    if oldState then
        if self:IsCurrentState(name) then
            if self.allowReEnter then
                oldState:ReEnter()
                self.willTransToStateName = nil
                return
            end
        end
        oldState:Exit()
        postProcessStateChange = oldState.PostProcessStateChange
    end

    if self.enableLog then
        g_Logger.LogChannel("StateMachine", ("From State %s to %s"):format(tostring(self.currentName), tostring(name)))
    end
    self.willTransToStateName = nil
    self.currentName = nil
    self.currentState = nil

    ---@type State
    local newState = self.states[name]
    if newState then
        self.currentName = name
        self.currentState = newState
        newState:Enter()
    else
        g_Logger.ErrorChannel("StateMachine", "State %s not found", name)
    end
    if #self._onStateChanged > 0 then
        for _, v in pairs(self._onStateChanged) do
            v(oldState,newState)
        end
    end
    if postProcessStateChange and type(postProcessStateChange) == "function" then
        postProcessStateChange()
    end
end

---@private
function StateMachine:SafeChangeStateImpl(name)
    self.willTransToStateName = name
    local postProcessStateChange = nil
    ---@type State
    local oldState = self.currentState
    if oldState then
        if self:IsCurrentState(name) then
            if self.allowReEnter then
                local ok, err = xpcall(oldState.ReEnter, debug.traceback, oldState)
                if not ok then
                    g_Logger.ErrorChannel("StateMachine", "ReEnter Error: %s", err)
                end
                self.willTransToStateName = nil
                return
            end
        end
        local ok, err = xpcall(oldState.Exit, debug.traceback, oldState)
        postProcessStateChange = oldState.PostProcessStateChange
        if not ok then
            g_Logger.ErrorChannel("StateMachine", "Exit Error: %s", err)
        end
    end

    if self.enableLog then
        g_Logger.LogChannel("StateMachine", ("From State %s to %s"):format(tostring(self.currentName), tostring(name)))
    end

    self.willTransToStateName = nil
    self.currentName = nil
    self.currentState = nil

    ---@type State
    local newState = self.states[name]
    if newState then
        self.currentName = name
        self.currentState = newState
        local ok, err = xpcall(newState.Enter, debug.traceback, newState)
        if not ok then
            g_Logger.ErrorChannel("StateMachine", "Enter Error: %s", err)
        end
    else
        g_Logger.ErrorChannel("StateMachine", "State %s not found", name)
    end

    if #self._onStateChanged > 0 then
        for _, v in pairs(self._onStateChanged) do
            pcall(v, oldState, newState)
        end
    end
    if postProcessStateChange and type(postProcessStateChange) == "function" then
        postProcessStateChange()
    end
end

---@param name string
---@return boolean
function StateMachine:IsCurrentState(name)
    return self.currentName == name and not string.IsNullOrEmpty(name)
end

---@return State
function StateMachine:GetCurrentState()
    return self.currentState
end

---@return string
function StateMachine:GetCurrentStateName()
    return self.currentName
end

---@param dt number
function StateMachine:Tick(dt)
    if self.currentState then
        if self.currentState:Transition() then
            return
        end
        self.currentState:Tick(dt)
    end
end

---@param dt number
function StateMachine:LateTick(dt)
    if self.currentState then
        self.currentState:LateTick(dt)
    end
end

function StateMachine:ClearAllStates()
    if self.currentState then
        self.currentState:Exit();
        self.currentState = nil;
        self.currentName = nil;
    end

    for _, v in pairs(self.states) do
        v:Release();
    end
    table.clear(self.states)
end

function StateMachine:ReadBlackboard(key, clear)
    if clear == nil then clear = true end
    return self.blackboard:Read(key, clear);
end

function StateMachine:WriteBlackboard(key, value, force)
    return self.blackboard:Write(key, value, force);
end

---@param func fun(oldState:State, newState:State)
function StateMachine:AddStateChangedListener(func)
    if func == nil then
        return;
    end   
    table.insert(self._onStateChanged, func)
end

---@param func fun(oldState:State, newState:State)
function StateMachine:RemoveStateChangedListener(func)
    table.removebyvalue(self._onStateChanged, func, true)
end

function StateMachine:ClearStateChangeListener()
    self._onStateChanged = {}
end

return StateMachine