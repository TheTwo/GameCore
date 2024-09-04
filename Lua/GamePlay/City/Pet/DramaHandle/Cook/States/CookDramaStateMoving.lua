local DramaStateDefine = require("DramaStateDefine")

local CookDramaState = require("CookDramaState")

---@class CookDramaStateMoving:CookDramaState
---@field super CookDramaState
local CookDramaStateMoving = class("CookDramaStateMoving", CookDramaState)

function CookDramaStateMoving:Enter()
    self.checkMoving = true
    self.handle:SetIgnoreStrictMovingSpeedUp(true)
    self.handle.petUnit:PlayMove()
end

function CookDramaStateMoving:Exit()
    self.handle:SetIgnoreStrictMovingSpeedUp(false)
    local pos, dir = self.handle:GetTargetPositionWithPetCenterFix()
    self.handle.petUnit:StopMove(pos, dir)
    self.handle.petUnit:SyncAnimatorSpeed()
end

function CookDramaStateMoving:Tick()
    if self.checkMoving then
        if self.handle.petUnit._moveAgent._isMoving or self.handle.petUnit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self.stateMachine:ChangeState(DramaStateDefine.State.route)
    end
end

return CookDramaStateMoving