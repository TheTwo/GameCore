local DramaStateDefine = require("DramaStateDefine")

local CommonMaterialProduceState = require("CommonMaterialProduceState")

---@class CommonMaterialProduceStateRoute:CommonMaterialProduceState
---@field super CommonMaterialProduceState
local CommonMaterialProduceStateRoute = class("CommonMaterialProduceStateRoute", CommonMaterialProduceState)

function CommonMaterialProduceStateRoute:Enter()
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

return CommonMaterialProduceStateRoute