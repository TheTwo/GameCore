local State = require("State")
---@class CityUnitPetStateBase:State
local CityUnitPetStateBase = class("CityUnitPetStateBase", State)

---@param unit CityUnitPet
function CityUnitPetStateBase:ctor(unit)
    self.unit = unit
end

function CityUnitPetStateBase:OnModelReady()
    ---override this
end

return CityUnitPetStateBase