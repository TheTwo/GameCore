---@class StoryStepActionBase
---@field protected new fun():StoryStepActionBase
---@field public IsDone boolean
---@field public IsFailure boolean
---@field public HashError boolean
---@field public IsExecuting boolean
---@field public Owner StoryStep
---@field private _isAddedEvent boolean
local StoryStepActionBase = class('StoryStepActionBase')

function StoryStepActionBase:ctor()
    self.IsDone = false
    self.IsFailure = false
    self.HashError = false
    self.IsExecuting = false
    self.Owner = nil
    self.NeedDelayCleanUp = false
    
    self.IsEntered = false
    self._isAddedEvent = false
    self._clsName = GetClassOf(self).__cname
    ---@type BlockGestureRef
    self._blockRef = nil
end

---@param actionParam string
function StoryStepActionBase:LoadConfig(actionParam)
    
end

---virtual
---@param stepInfo wds.StoryStepInfo
function StoryStepActionBase:Init(stepInfo)
    
end

---@param step StoryStep
function StoryStepActionBase:AttachStep(step)
    self.Owner = step
end

function StoryStepActionBase:DetachStep()
    self.Owner = nil
end

function StoryStepActionBase:Enter()
    g_Logger.TraceChannel(nil, "StepActionEnter:%s", self._clsName)
    self.IsExecuting = true
    if not self._isAddedEvent then
        self:AddEvent()
        self._isAddedEvent = true
    end
    if not self.IsEntered then
        self.IsEntered = true
        self:OnEnter()
    end
end

function StoryStepActionBase:Leave()
    g_Logger.TraceChannel(nil, "StepActionLeave:%s", self._clsName)
    self.IsExecuting = false
    if self.IsEntered then
        self.IsEntered = false
        self:OnLeave()
    end
    if self._isAddedEvent then
        self:RemoveEvent()
        self._isAddedEvent = false
    end
end

function StoryStepActionBase:Execute()
    if self.IsDone or self.IsFailure or self.HashError then
        return
    end
    self:OnExecute()
end

---@return fun() @delayCleanUpFun
function StoryStepActionBase:GetDelayCleanUpCall()
    return function()
        if not self.NeedDelayCleanUp then return end
        self:OnDelayCleanUp()
        self.NeedDelayCleanUp = false
    end
end

---@param isRestore boolean
function StoryStepActionBase:SetEndStatus(isRestore)
    if not self.IsDone then
        return
    end
    self:OnSetEndStatus(isRestore)
end

function StoryStepActionBase:Release(fromRelogin)
    self:OnRelease(fromRelogin)
    self:UnSetGestureBlock()
end

---virtual
function StoryStepActionBase:Reset()
    self.IsDone = false
    self.HashError = false
    self.IsExecuting = false
end

---virtual
function StoryStepActionBase:AddEvent()

end

---virtual
function StoryStepActionBase:RemoveEvent()

end

---virtual
---@protected
function StoryStepActionBase:OnEnter()
end

---virtual
---@protected
function StoryStepActionBase:OnLeave()
end

---virtual
---@protected
function StoryStepActionBase:OnExecute()

end

---virtual
---@protected
function StoryStepActionBase:OnDelayCleanUp()
    
end

---virtual
---@protected
---@param isRestore boolean
function StoryStepActionBase:OnSetEndStatus(isRestore)
    g_Logger.LogChannel("StoryStepActionBase", "OnSetEndStatus:%s override me!", isRestore)
end

---virtual
function StoryStepActionBase:OnRelease(fromRelogin)
    
end

---@param result boolean
function StoryStepActionBase:EndAction(result)
    if result or result == nil then
        self.IsDone = true
    else
        self.IsFailure = true
    end
end

function StoryStepActionBase:SetGestureBlock()
    if self._blockRef then
        self._blockRef:UnRef()
    end
    self._blockRef = g_Game.GestureManager:SetBlockAddRef()
end

function StoryStepActionBase:UnSetGestureBlock()
    if self._blockRef then
        self._blockRef:UnRef()
    end
    self._blockRef = nil
end

function StoryStepActionBase:IsType(class)
    return GetClassOf(self) == class
end

return StoryStepActionBase