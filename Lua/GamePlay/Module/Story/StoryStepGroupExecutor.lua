local ModuleRefer = require("ModuleRefer")

---@class StoryStepGroupExecutor
---@field new fun():StoryStepGroupExecutor
---@field public IsExecuting boolean
---@field public HasError boolean
---@field private _executeQueue StoryStepGroup[]
---@field private _currentGroup StoryStepGroup
local StoryStepGroupExecutor = class('StoryStepGroupExecutor')

function StoryStepGroupExecutor:ctor()
    self.IsExecuting = false
    self.HasError = false
    
    ---@type StoryStepGroup[]
    self._executeQueue = {}
    self._currentGroup = nil
end

function StoryStepGroupExecutor:Init()
    
end

function StoryStepGroupExecutor:Release(fromRelogin)
    self:Stop(fromRelogin)
    while #self._executeQueue > 0 do
        local group = table.remove(self._executeQueue, 1)
        group:Release(fromRelogin)
    end
    table.clear(self._executeQueue)
end

---@param storyStepGroup StoryStepGroup
---@param ignoreLastError boolean
function StoryStepGroupExecutor:AddToExecute(storyStepGroup, ignoreLastError)
    if storyStepGroup:IsEmpty() then
        g_Logger.Error("Empty Group not allowed!")
        return
    end
    if ignoreLastError then
        g_Logger.Warn("last has error, and ignoreLastError turn it to normal")
        self.HasError = false
    end
    table.insert(self._executeQueue, storyStepGroup)
    if not self.IsExecuting then
        self:Start()
    end
end

function StoryStepGroupExecutor:HasGroupInExecutingOrQueue(storyStepGroupId)
    if self._currentGroup and self._currentGroup:Id() == storyStepGroupId then return true end
    for i = #self._executeQueue, 1, -1 do
        local group = self._executeQueue[i]
        if group:Id() == storyStepGroupId then return true end
    end
    return false
end

function StoryStepGroupExecutor:Start()
    self:StartNextGroup()
    if self._currentGroup then
        self.IsExecuting = true
    end
end

function StoryStepGroupExecutor:Stop(fromRelogin)
    if self.IsExecuting then
        local delayCleanUps = self:StopCurrentGroup(true)
        for _, callback in ipairs(delayCleanUps) do
            callback()
        end
    end
    self.IsExecuting = false
    if fromRelogin then return end
    ModuleRefer.ToastModule:SetStoryPlayingBlockToast(false)
end

function StoryStepGroupExecutor:OnTick()
    self:Execute()
end

---@private
function StoryStepGroupExecutor:Execute()
    if not self.IsExecuting then
        return
    end
    if self.HasError then
        return
    end
    local currentGroup = self._currentGroup
    if not currentGroup then
        self:StartNextGroup()
        return
    end
    if currentGroup.IsDone then
        currentGroup:SetEndStatus(false)
        currentGroup:FireEndCallback()
        self:StartNextGroup(true)
    elseif currentGroup.HasError then
        local id = currentGroup:Id()
        g_Logger.Error("StoryStepGroupExecutor Stopped because currentGroup:%s HasError, leftGroupCount:%d",id, #self._executeQueue)
        table.clear(self._executeQueue)
        currentGroup:FireEndCallback()
        self.IsExecuting = false
        self.HasError = true
        local delayCleanUps = self:StopCurrentGroup(true)
        for _, callback in ipairs(delayCleanUps) do
            callback()
        end
        if UNITY_DEBUG then
            self:FireExecuteErrorPopupInDebug(currentGroup)
        end
        ModuleRefer.ToastModule:SetStoryPlayingBlockToast(false)
    else
        currentGroup:Execute()
        if currentGroup.IsDone then
            g_Logger.Log("currentGroup Done fast forward next")
            currentGroup:SetEndStatus(false)
            currentGroup:FireEndCallback()
            self:StartNextGroup(true)
        end
    end
end

---@param currentGroup StoryStepGroup
function StoryStepGroupExecutor:FireExecuteErrorPopupInDebug(currentGroup)
    local groupId = tostring(currentGroup:Id())
    local stepId = "nil"
    local actions = "nil"
    local sending = tostring(false)
    local currentStep = currentGroup:GetCurrentStep()
    if currentStep then
        stepId = tostring(currentStep.StepId)
        actions = currentStep:DumpErrorActions()
        sending = tostring(currentStep.IsSending)
    end
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.title = "error during execute story group"
    parameter.content = string.format("Group:%s, Step:%s[sending:%s], errorActions:%s", groupId, stepId, sending ,actions)
    local def = require("CommonConfirmPopupMediatorDefine")
    parameter.styleBitMask = def.Style.ConfirmAndCancel
    parameter.onConfirm = function(context) 
        g_Game:RestartGame()
        return true
    end
    parameter.forceClose = true
    g_Game.UIManager:Open(require("UIMediatorNames").CommonConfirmPopupMediator, parameter)
end

function StoryStepGroupExecutor:StartNextGroup(releaseCurrent)
    local delayCleanUps = self:StopCurrentGroup(releaseCurrent)
    if #self._executeQueue > 0 then
        self._currentGroup = table.remove(self._executeQueue, 1)
        ModuleRefer.ToastModule:SetStoryPlayingBlockToast(true)
        self._currentGroup:Enter()
        for _, callback in ipairs(delayCleanUps) do
            callback()
        end
    else
        for _, callback in ipairs(delayCleanUps) do
            callback()
        end
        self:Stop()
    end
end

---@return fun()[] @delayCleanUpFun
function StoryStepGroupExecutor:StopCurrentGroup(releaseGroup)
    ModuleRefer.ToastModule:SetStoryPlayingBlockToast(false)
    local ret = {}
    if not self._currentGroup then
        return ret
    end
    table.addrange(ret, self._currentGroup:Leave())
    if releaseGroup then
        self._currentGroup:Release()
    end
    self._currentGroup = nil
    return ret
end

---@return StoryStepGroup, number
function StoryStepGroupExecutor:GetCurrentGroup()
    return self._currentGroup, #self._executeQueue
end

return StoryStepGroupExecutor