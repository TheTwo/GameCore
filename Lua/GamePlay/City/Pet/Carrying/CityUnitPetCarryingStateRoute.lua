local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetCarryingStateRoute:CityUnitPetStateBase
local CityUnitPetCarryingStateRoute = class("CityUnitPetCarryingStateRoute", CityUnitPetStateBase)

function CityUnitPetCarryingStateRoute:Enter()
    if self.unit.petData:IsMovingToStartPoint() then
        self.stateMachine:ChangeState("tostart")
    elseif not self.unit.petData:IsCurrentActionValid() then
        self.stateMachine:ChangeState("none")
    else
        self.stateMachine:ChangeState("toend")
    end
end

return CityUnitPetCarryingStateRoute