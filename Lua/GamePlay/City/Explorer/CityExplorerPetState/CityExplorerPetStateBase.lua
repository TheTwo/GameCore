
local State = require("State")

---@class CityExplorerPetStateBase:State
---@field new fun(pet:CityUnitExplorerPet):CityExplorerPetStateBase
local CityExplorerPetStateBase = class("CityExplorerPetStateBase", State)

---@param pet CityUnitExplorerPet
function CityExplorerPetStateBase:ctor(pet)
    ---@type CityUnitExplorerPet
    self._pet = pet
end

function CityExplorerPetStateBase:ExitToIdle()
    self.stateMachine:ChangeState("CityExplorerPetStateEnter")
end

return CityExplorerPetStateBase