local DramaStateDefine = require("DramaStateDefine")

local MineDramaState = require("MineDramaState")

---@class LumbermillDramaStateMoving:MineDramaState
---@field super MineDramaState
local MineDramaStateMoving = class("MineDramaStateMoving", MineDramaState)

function MineDramaStateMoving:Enter()
    self.checkMoving = true
    self.handle:SetIgnoreStrictMovingSpeedUp(true)
    self.handle.petUnit:PlayMove()
end

function MineDramaStateMoving:Exit()
    self.handle:SetIgnoreStrictMovingSpeedUp(false)
    local pos, dir = self.handle:GetTargetPositionWithPetCenterFix()
    self.handle.petUnit:StopMove(pos, dir)
    self.handle.petUnit:SyncAnimatorSpeed()
end

function MineDramaStateMoving:Tick()
    if self.checkMoving then
        if self.handle.petUnit._moveAgent._isMoving or self.handle.petUnit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

return MineDramaStateMoving