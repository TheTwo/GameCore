local DramaStateDefine = require("DramaStateDefine")

local LumbermillDramaState = require("LumbermillDramaState")
---@class LumbermillDramaStateMoving:LumbermillDramaState
local LumbermillDramaStateMoving = class("LumbermillDramaStateMoving", LumbermillDramaState)

function LumbermillDramaStateMoving:Enter()
    self.checkMoving = true
    self.handle:SetIgnoreStrictMovingSpeedUp(true)
    self.handle.petUnit:PlayMove()
end

function LumbermillDramaStateMoving:Exit()
    self.handle:SetIgnoreStrictMovingSpeedUp(false)
    local pos, dir = self.handle:GetTargetPositionWithPetCenterFix()
    self.handle.petUnit:StopMove(pos, dir)
    self.handle.petUnit:SyncAnimatorSpeed()
end

function LumbermillDramaStateMoving:Tick()
    if self.checkMoving then
        if self.handle.petUnit._moveAgent._isMoving or self.handle.petUnit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

return LumbermillDramaStateMoving