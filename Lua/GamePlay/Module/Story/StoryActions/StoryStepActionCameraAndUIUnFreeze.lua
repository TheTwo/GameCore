local StoryActionUtils = require("StoryActionUtils")
local StoryActionConst = require("StoryActionConst")

local StoryStepActionBase = require("StoryStepActionBase")

---@class StoryStepActionCameraAndUIUnFreeze:StoryStepActionBase
---@field new fun():StoryStepActionCameraAndUIUnFreeze
---@field super StoryStepActionBase
local StoryStepActionCameraAndUIUnFreeze = class('StoryStepActionCameraAndUIUnFreeze', StoryStepActionBase)

function StoryStepActionCameraAndUIUnFreeze:OnEnter()
    StoryActionUtils.TemporaryUIRootInteractable(true)
    ---@type BlockGestureRef
    local last = self.Owner.Owner:ReadContext(StoryActionConst.StepContextKey.StoryStepActionCameraAndUIFreeze)
    if last then
        last:UnRef()
    end
    self:EndAction()
end

function StoryStepActionCameraAndUIUnFreeze:OnSetEndStatus(isRestore)
    -- do nothing
end

return StoryStepActionCameraAndUIUnFreeze