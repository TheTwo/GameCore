local DramaStateDefine = require("DramaStateDefine")

local PastureDramaStateBase = require("PastureDramaStateBase")

---@class PastureDramaRoute:PastureDramaStateBase
---@field new fun(handle:PastureDramaHandle):PastureDramaStateAssetUnload
---@field super PastureDramaStateBase
local PastureDramaStateRoute = class("PastureDramaStateRoute", PastureDramaStateBase)

function PastureDramaStateRoute:Enter()
    if not self.handle:IsResReady() then
        self.stateMachine:ChangeState(DramaStateDefine.State.assetunload)
        return
    end

    local petUnit = self.handle.petUnit
    petUnit:StopMove()
    self.stateMachine:ChangeState(DramaStateDefine.State.wandering)
end

return PastureDramaStateRoute