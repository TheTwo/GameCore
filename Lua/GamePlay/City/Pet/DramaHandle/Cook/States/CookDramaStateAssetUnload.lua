local CookDramaState = require("CookDramaState")

---@class CookDramaStateAssetUnload:CookDramaState
---@field super CookDramaState
local CookDramaStateAssetUnload = class("CookDramaStateAssetUnload", CookDramaState)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

function CookDramaStateAssetUnload:Enter()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

return CookDramaStateAssetUnload