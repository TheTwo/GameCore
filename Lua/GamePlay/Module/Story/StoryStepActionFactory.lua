local StoryStepActionTypes = require("StoryStepActionTypes")

---@class StoryStepActionFactory
local StoryStepActionFactory = class('StoryStepActionFactory')

---@param actionType number
---@param actionParam string
---@return StoryStepActionBase
function StoryStepActionFactory.CreateAction(actionType, actionParam)
    local actionCls = StoryStepActionTypes.Get(actionType)
    if actionCls then
        local ret = actionCls.new()
        ret:LoadConfig(actionParam)
        return ret
    end
    return nil
end

return StoryStepActionFactory