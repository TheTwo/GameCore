local PlayerUnitDataProvider = require("PlayerUnitDataProvider")
local ModuleRefer = require("ModuleRefer")

---@class PlayerUnitDataProviderCreepTumor : PlayerUnitDataProvider
local PlayerUnitDataProviderCreepTumor = class("PlayerUnitDataProviderCreepTumor", PlayerUnitDataProvider)

function PlayerUnitDataProviderCreepTumor.GetPlayerUnitData(uniqueID, typeID)
    --todo slgCreep -> SlgCreepCenter
    return ModuleRefer.MapCreepModule:GetCreepData(uniqueID)
end

return PlayerUnitDataProviderCreepTumor