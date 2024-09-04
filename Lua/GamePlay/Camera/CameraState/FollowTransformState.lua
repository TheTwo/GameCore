local CameraStateBase = require("CameraStateBase")
local Utils = require("Utils")

---@class FollowTransformState:CameraStateBase
local FollowTransformState = class("FollowTransformState", CameraStateBase)

function FollowTransformState:ReEnter()
    self:Exit()
    self:Enter()
end

function FollowTransformState:Enter()
    ---@type CS.UnityEngine.Transform
    self.target = self.stateMachine:ReadBlackboard("FollowTargetTransform", true)
    self.position = self.stateMachine:ReadBlackboard("GetTargetPosition", true)
end

function FollowTransformState:Exit()
    self.target = nil
    self.position = nil
end

---@param dt number
function FollowTransformState:LateTick(dt)
    if self.position ~= nil then
        local valid, position = self.position()
        if valid then
            self.basicCamera:LookAt(position)
        else
            self.stateMachine:ChangeState("DefaultCameraState")
        end
    else
        if Utils.IsNotNull(self.target) then
            self.basicCamera:LookAt(self.target.position)
        else
            self.stateMachine:ChangeState("DefaultCameraState")
        end
    end

    local input = CS.UnityEngine.Input
    if input.anyKeyDown or input.mouseScrollDelta.magnitude > 0 then
        self.stateMachine:ChangeState("DefaultCameraState")
    end
end

return FollowTransformState