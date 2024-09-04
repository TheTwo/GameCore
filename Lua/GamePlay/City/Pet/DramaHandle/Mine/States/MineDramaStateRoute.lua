local DramaStateDefine = require("DramaStateDefine")

local MineDramaState = require("MineDramaState")

---@class MineDramaStateRoute:MineDramaState
---@field super MineDramaState
local MineDramaStateRoute = class("MineDramaStateRoute", MineDramaState)

function MineDramaStateRoute:Enter()
    if not self.handle:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
        return
    end

    local petUnit = self.handle.petUnit
    local targetPos = self.handle:GetTargetPositionWithPetCenterFix()
    local index = self.handle:GetIndex()
    petUnit:StopMove()
    if petUnit:IsCloseTo(targetPos) then
        if index == self.handle.storageIndex then
            self.stateMachine:ChangeState(DramaStateDefine.State.storage)
        else
            self.stateMachine:ChangeState(DramaStateDefine.State.work)
        end
    else
        self.stateMachine:ChangeState(DramaStateDefine.State.move)
    end
end

return MineDramaStateRoute