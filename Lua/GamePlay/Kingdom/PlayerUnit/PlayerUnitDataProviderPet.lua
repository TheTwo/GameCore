local PlayerUnitDataProvider = require("PlayerUnitDataProvider")
local ModuleRefer = require("ModuleRefer")
local PlayerUnitDataProviderPet = class("PlayerUnitDataProviderPet", PlayerUnitDataProvider)

function PlayerUnitDataProviderPet.GetPlayerUnitData(uniqueID, typeID)
    return ModuleRefer.PetModule:GetPetData(uniqueID)
end

return PlayerUnitDataProviderPet