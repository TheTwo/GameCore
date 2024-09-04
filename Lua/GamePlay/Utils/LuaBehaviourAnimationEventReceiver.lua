---@class LuaBehaviourAnimationEventReceiver
---@field new fun():LuaBehaviourAnimationEventReceiver
local LuaBehaviourAnimationEventReceiver = class('LuaBehaviourAnimationEventReceiver')

---@param callback fun(parameter:string)
function LuaBehaviourAnimationEventReceiver:SetEventCallback(callback)
    self._callback = callback
end

---@param parameter string
function LuaBehaviourAnimationEventReceiver:OnAnimationEvent(parameter)
    if self._callback then
        self._callback(parameter)
    end
end

return LuaBehaviourAnimationEventReceiver

