local StoryStepActionFactory = require("StoryStepActionFactory")
local StoryActionType = require("StoryActionType")

---@class StoryStep
---@field new fun():StoryStep
---@field public IsDone boolean
---@field public IsFailure boolean
---@field public HashError boolean
---@field public IsExecuting boolean
---@field public Owner StoryStepGroup
---@field public IsRequestNodeReset boolean
---@field private _config StoryTaskStepConfigCell
---@field private _isAddedEvent boolean
---@field private _translateOffsetSuccess number @ nil - for default
---@field private _translateOffsetFailure number
---@field protected _actions StoryStepActionBase[]
local StoryStep = class('StoryStep')
StoryStep.actionTypeMap = {}
for _, v in pairs(StoryActionType) do
    StoryStep.actionTypeMap[v] = true
end

function StoryStep:ctor()
    self.IsDone = false
    self.IsFailure = false
    self.HashError = false
    self.IsExecuting = false
    self.Owner = nil
    self.StepId = 0
    
    self._config = nil
    self._isAddedEvent = false
    self._translateOffsetSuccess = nil
    self._translateOffsetFailure = 0
    self._actions = {}
    self._nextStepOffset = {}
    self.IsSending = false
    self._sendingIndex = 0
end

---@param config StoryTaskStepConfigCell
function StoryStep:LoadConfig(config)
    self._config = config
    self.StepId = self._config:Id()
end

---@param offset number
function StoryStep:AddNextStepOffset(offset)
    table.insert(self._nextStepOffset, offset)
end

function StoryStep:CreateActions()
    local configWrapper = {}
    configWrapper[1] = { type = self._config:Action1(), param = self._config:ActionParam1()}
    configWrapper[2] = { type = self._config:Action2(), param = self._config:ActionParam2()}
    configWrapper[3] = { type = self._config:Action3(), param = self._config:ActionParam3()}
    for i = 1, 3 do
        local actionType = configWrapper[i].type
        local actionParam = configWrapper[i].param
        if StoryStep.actionTypeMap[actionType] then
            local action = StoryStepActionFactory.CreateAction(actionType, actionParam)
            if action then
                table.insert(self._actions, action)
                action:AttachStep(self)
            else
                error("nil action:" .. actionType)
            end
        end
    end
end

---@param stepInfo wds.StoryStepInfo
function StoryStep:InitActionWithServerData(stepInfo)
    if not stepInfo then
        return
    end
    if stepInfo.State > 0 then
        self.IsDone = true
        for _, v in ipairs(self._actions) do
            v.IsDone = true
            v:Init(stepInfo)
        end
    end
end

function StoryStep:ReleaseActions(fromRelogin)
    for _, action in ipairs(self._actions) do
        action:DetachStep()
        action:Release()
    end
    table.clear(self._actions)
end

---@param group StoryStepGroup
function StoryStep:AttachGroup(group)
    self.Owner = group
end

function StoryStep:DetachGroup()
    self.Owner = nil
end

function StoryStep:SetChoice(choice)
    self._translateOffsetSuccess = choice
end

---@param isSuccess boolean
function StoryStep:GetTranslateOffset(isSuccess)
    if isSuccess then
        if #self._nextStepOffset > 1 and self._translateOffsetSuccess then
            return self._nextStepOffset[self._translateOffsetSuccess]
        end
        if #self._nextStepOffset > 0 then
            return self._nextStepOffset[1] 
        end
        return 0
    else
        return self._translateOffsetFailure
    end
end

function StoryStep:Enter()
    g_Logger.TraceChannel(nil, "StepEnter:%s", self._config:Id())
    self.IsExecuting = true
    if not self._isAddedEvent then
        self:AddEvent()
        self._isAddedEvent = true
    end
    for _, action in ipairs(self._actions) do
        action:Enter()
    end
end

---@return fun()[] @delayCleanUpFun
function StoryStep:Leave()
    g_Logger.TraceChannel(nil, "StepLeave:%s", self._config:Id())
    local ret = {}
    self.IsExecuting = false
    for _, action in ipairs(self._actions) do
        action:Leave()
        if action.NeedDelayCleanUp then
            table.insert(ret, action:GetDelayCleanUpCall())
        end
    end
    if self._isAddedEvent then
        self:RemoveEvent()
        self._isAddedEvent = false
    end
    return ret
end

function StoryStep:Execute()
    if self.IsSending then
        return
    end
    if self.IsDone or self.IsFailure or self.HashError or (not self.Owner) then
        return
    end
    local isDone = true
    for _, action in ipairs(self._actions) do
        action:Execute()
        if action.HashError then
            self.HashError = true
        end
        if action.IsFailure then
            self.IsFailure = true
        end
        if not action.IsDone then
            isDone = false
        end
    end
    if isDone then
        self:EndStep(not self.IsFailure)
    end
end

---@param isRestore boolean
function StoryStep:SetEndStatus(isRestore)
    if not self.IsDone then
        return
    end
    for _, action in ipairs(self._actions) do
        action:SetEndStatus(isRestore)
    end
end

function StoryStep:Reset()
    for _, action in ipairs(self._actions) do
        action:Reset()
    end
    self.IsDone = false
    self.IsFailure = false
    self.HashError = false
    self.IsExecuting = false
end

function StoryStep:AddEvent()
    for _, action in ipairs(self._actions) do
        action:AddEvent()
    end
end

function StoryStep:RemoveEvent()
    for _, action in ipairs(self._actions) do
        action:RemoveEvent()
    end
end

function StoryStep:GetChoice()
    return self._translateOffsetSuccess or 1
end

---@param result boolean
function StoryStep:EndStep(result)
    if result == nil then
        result = true
    end
    if result then
        if self.Owner and self.Owner.NoReportServerRun then
            self.IsDone = true
            return
        end
        ---@type StoryModule
        local storyModule = g_Game.ModuleManager:RetrieveModule("StoryModule")
        self.IsSending = true
        storyModule:StoryFinish(self._config:Id(), self:GetChoice())
        self.IsSending = false
        self.IsDone = true
    else
        self.IsFailure = true
    end
end

---@param predict fun(action:StoryStepActionBase):boolean
function StoryStep:ForeachAction(predict)
    for _, v in ipairs(self._actions) do
        if not predict(v) then
            return
        end
    end
end

function StoryStep:Print()
    local ret = "StepId:" .. tostring(self._config:Id())
    if self.IsExecuting then
        ret = ret .. ":Run"
    end
    if self.IsFailure then
        ret = ret .. ":Fail"
    end
    if self.IsDone then
        ret = ret .. ":Done"
    end
    return ret
end

---@return string
function StoryStep:DumpErrorActions()
    local ret = string.Empty
    if self._actions then
        for _, v in ipairs(self._actions) do
            if v.IsFailure or v.HashError then
                if string.IsNullOrEmpty(ret) then
                    ret = string.IsNullOrEmpty(v._clsName) and 'unknown' or v._clsName
                    ret = ret .. (":[error:%s,fail:%s]"):format(v.HashError,v.IsFailure )
                else
                    ret = ret .. ',' .. string.IsNullOrEmpty(v._clsName) and 'unknown' or v._clsName
                    ret = ret .. (":[error:%s,fail:%s]"):format(v.HashError,v.IsFailure )
                end
            end
        end
    end
    return ret
end

return StoryStep