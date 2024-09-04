local FarmDramaStateBase = require("FarmDramaStateBase")
---@class FarmDramaStateAssetUnload:FarmDramaStateBase
---@field new fun():FarmDramaStateAssetUnload
local FarmDramaStateAssetUnload = class("FarmDramaStateAssetUnload", FarmDramaStateBase)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

function FarmDramaStateAssetUnload:Enter()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

return FarmDramaStateAssetUnload