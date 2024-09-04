local DramaStateDefine = require("DramaStateDefine")

local FarmDramaStateBase = require("FarmDramaStateBase")
---@class FarmDramaStateRoute:FarmDramaStateBase
local FarmDramaStateRoute = class("FarmDramaStateRoute", FarmDramaStateBase)

function FarmDramaStateRoute:Enter()
    if not self.handle:IsResReady() then
        self.stateMachine:ChangeState("assetunload")
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

return FarmDramaStateRoute