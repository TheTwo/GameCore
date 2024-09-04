local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

local PastureDramaStateBase = require("PastureDramaStateBase")

---@class PastureDramaStateAssetUnload:PastureDramaStateBase
---@field new fun(handle:PastureDramaHandle):PastureDramaStateAssetUnload
---@field super PastureDramaStateBase
local PastureDramaStateAssetUnload = class("FarmDramaStateAssetUnload", PastureDramaStateBase)

function PastureDramaStateAssetUnload:Enter()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

return PastureDramaStateAssetUnload