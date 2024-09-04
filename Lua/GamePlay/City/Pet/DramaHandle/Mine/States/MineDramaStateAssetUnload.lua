local MineDramaState = require("MineDramaState")

---@class MineDramaStateAssetUnload:MineDramaState
---@field super MineDramaState
local MineDramaStateAssetUnload = class("MineDramaStateAssetUnload", MineDramaState)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

function MineDramaStateAssetUnload:Enter()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

return MineDramaStateAssetUnload