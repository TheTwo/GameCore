local PlayerUnitDataProvider = require("PlayerUnitDataProvider")
local ModuleRefer = require("ModuleRefer")
local PlayerUnitDataProviderWorldRewardInteractor = class("PlayerUnitDataProviderWorldRewardInteractor", PlayerUnitDataProvider)

function PlayerUnitDataProviderWorldRewardInteractor.GetPlayerUnitData(uniqueID, typeID)
    return ModuleRefer.WorldRewardInteractorModule:GetInteractorData(uniqueID)
end

return PlayerUnitDataProviderWorldRewardInteractor