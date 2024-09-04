local DramaStateDefine = require("DramaStateDefine")

local LumbermillDramaState = require("LumbermillDramaState")
---@class LumbermillDramaStateRoute:LumbermillDramaState
local LumbermillDramaStateRoute = class("LumbermillDramaStateRoute", LumbermillDramaState)

function LumbermillDramaStateRoute:Enter()
    if not self.handle:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
        return
    end

    local petUnit = self.handle.petUnit
    local index = self.handle:GetIndex()
    local targetPos = self.handle:GetTargetPositionWithPetCenterFix()
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

return LumbermillDramaStateRoute