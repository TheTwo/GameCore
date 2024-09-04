local CommonMaterialProduceState = require("CommonMaterialProduceState")

---@class CommonMaterialProduceStateAssetUnload:CommonMaterialProduceState
---@field super CommonMaterialProduceState
local CommonMaterialProduceStateAssetUnload = class("CommonMaterialProduceStateAssetUnload", CommonMaterialProduceState)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

function CommonMaterialProduceStateAssetUnload:Enter()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

return CommonMaterialProduceStateAssetUnload