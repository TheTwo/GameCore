local LumbermillDramaState = require("LumbermillDramaState")
---@class LumbermillDramaStateAssetUnload:LumbermillDramaState
local LumbermillDramaStateAssetUnload = class("LumbermillDramaStateAssetUnload", LumbermillDramaState)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")

function LumbermillDramaStateAssetUnload:Enter()
    self.handle.petUnit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

return LumbermillDramaStateAssetUnload