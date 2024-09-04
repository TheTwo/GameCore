local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetSubStateAction:CityUnitPetStateBase
local CityUnitPetSubStateAction = class("CityUnitPetSubStateAction", CityUnitPetStateBase)

function CityUnitPetSubStateAction:Enter()
    self.unit:ChangeAnimatorState(self.unit._targetState)
end

function CityUnitPetSubStateAction:ReEnter()
    self:Exit()
    self:Enter()
end

return CityUnitPetSubStateAction