local DramaStateDefine = require("DramaStateDefine")

local CookDramaState = require("CookDramaState")

---@class CookDramaStateRoute:CookDramaState
---@field super CookDramaState
local CookDramaStateRoute = class("CookDramaStateRoute", CookDramaState)

function CookDramaStateRoute:Enter()
    if not self.handle:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
        return
    end

    local petUnit = self.handle.petUnit
    local targetPos = self.handle:GetTargetPositionWithPetCenterFix()
    petUnit:StopMove()
    if petUnit:IsCloseTo(targetPos) then
        self.stateMachine:ChangeState(DramaStateDefine.State.work)
    else
        self.stateMachine:ChangeState(DramaStateDefine.State.move)
    end
end

return CookDramaStateRoute