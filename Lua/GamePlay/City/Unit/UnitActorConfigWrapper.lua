---@class UnitActorConfigWrapper
---@field new fun():UnitActorConfigWrapper
local UnitActorConfigWrapper = class("UnitActorConfigWrapper")

function UnitActorConfigWrapper:ctor(walkSpeed, runSpeed)
    self._walSpeed = walkSpeed
    self._runSpeed = runSpeed
end

function UnitActorConfigWrapper:WalkSpeed()
    return self._walSpeed
end

function UnitActorConfigWrapper:RunSpeed()
    return self._runSpeed
end

function UnitActorConfigWrapper:StateCrossfadeTime()
    return 0.05
end

return UnitActorConfigWrapper