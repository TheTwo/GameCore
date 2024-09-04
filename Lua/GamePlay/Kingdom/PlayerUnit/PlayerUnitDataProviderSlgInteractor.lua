local PlayerUnitDataProvider = require("PlayerUnitDataProvider")
local ModuleRefer = require("ModuleRefer")

---@class PlayerUnitDataProviderSlgInteractor : PlayerUnitDataProvider
local PlayerUnitDataProviderSlgInteractor = class("PlayerUnitDataProviderSlgInteractor", PlayerUnitDataProvider)

function PlayerUnitDataProviderSlgInteractor.GetPlayerUnitData(uniqueID, typeID)
    return ModuleRefer.MapSlgInteractorModule:GetSlgInteractorData(uniqueID)
end

return PlayerUnitDataProviderSlgInteractor