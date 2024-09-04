local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetSubStateActionLoop:CityUnitPetStateBase
local CityUnitPetSubStateActionLoop = class("CityUnitPetSubStateActionLoop", CityUnitPetStateBase)

function CityUnitPetSubStateActionLoop:Enter()
    self.unit:ChangeAnimatorState(self.unit._targetState)
end

function CityUnitPetSubStateActionLoop:ReEnter()
    self:Exit()
    self:Enter()
end

return CityUnitPetSubStateActionLoop