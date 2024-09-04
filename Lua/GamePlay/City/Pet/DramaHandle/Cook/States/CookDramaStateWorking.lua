
local CookDramaState = require("CookDramaState")

---@class CookDramaStateWorking:CookDramaState
---@field super CookDramaState
local CookDramaStateWorking = class("CookDramaStateWorking", CookDramaState)

function CookDramaStateWorking:Enter()
    self.handle.petUnit:PlayLoopState(self.handle:GetWorkCfgAnimName())
    self.handle.petUnit:SyncAnimatorSpeed()
end

return CookDramaStateWorking