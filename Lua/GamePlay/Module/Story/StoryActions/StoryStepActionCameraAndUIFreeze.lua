local StoryActionUtils = require("StoryActionUtils")
local StoryActionConst = require("StoryActionConst")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionCameraAndUIFreeze:StoryStepActionBase
---@field new fun():StoryStepActionCameraAndUIFreeze
---@field super StoryStepActionBase
local StoryStepActionCameraAndUIFreeze = class('StoryStepActionCameraAndUIFreeze', StoryStepActionBase)

function StoryStepActionCameraAndUIFreeze:OnEnter()
    StoryActionUtils.TemporaryUIRootInteractable(false)
    self._unBlockRef = g_Game.GestureManager:SetBlockAddRef()
    ---@type BlockGestureRef
    local last = self.Owner.Owner:WriteContext(StoryActionConst.StepContextKey.StoryStepActionCameraAndUIFreeze, self._unBlockRef)
    if last and last.UnRef then
        last:UnRef()
    end
    self.NeedDelayCleanUp = true
    self:EndAction()
end

function StoryStepActionCameraAndUIFreeze:OnSetEndStatus(isRestore)
    -- do nothing
end

function StoryStepActionCameraAndUIFreeze:OnDelayCleanUp()
    if self._unBlockRef then
        self._unBlockRef:UnRef()
    end
    self._unBlockRef = nil
end

return StoryStepActionCameraAndUIFreeze