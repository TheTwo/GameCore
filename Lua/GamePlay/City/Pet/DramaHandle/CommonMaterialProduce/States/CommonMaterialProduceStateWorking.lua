
local CommonMaterialProduceState = require("CommonMaterialProduceState")

---@class CommonMaterialProduceStateWorking:CommonMaterialProduceState
---@field super CommonMaterialProduceState
local CommonMaterialProduceStateWorking = class("CommonMaterialProduceStateWorking", CommonMaterialProduceState)

function CommonMaterialProduceStateWorking:Enter()
    self.handle.petUnit:PlayLoopState(self.handle:GetWorkCfgAnimName())
    self.handle.petUnit:SyncAnimatorSpeed()
end

return CommonMaterialProduceStateWorking