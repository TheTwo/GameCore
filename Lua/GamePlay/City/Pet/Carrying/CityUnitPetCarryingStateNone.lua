local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetCarryingStateNone:CityUnitPetStateBase
local CityUnitPetCarryingStateNone = class("CityUnitPetCarryingStateNone", CityUnitPetStateBase)

function CityUnitPetCarryingStateNone:Enter()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
end

return CityUnitPetCarryingStateNone