local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateMoving:CityUnitPetStateBase
local CityUnitPetStateMoving = class("CityUnitPetStateMoving", CityUnitPetStateBase)

function CityUnitPetStateMoving:Enter()
    self.unit:PlayMove()
end

function CityUnitPetStateMoving:Tick(delta)
    if not self.unit._moveAgent._isMoving then
        self.unit:SyncFromServer()
    end
end

return CityUnitPetStateMoving