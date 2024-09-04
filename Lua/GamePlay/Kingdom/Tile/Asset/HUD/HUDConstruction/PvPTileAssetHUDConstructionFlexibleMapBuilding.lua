local PvPTileAssetHUDConstruction = require("PvPTileAssetHUDConstruction")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@class PvPTileAssetHUDConstructionFlexibleMapBuilding : PvPTileAssetHUDConstruction
local PvPTileAssetHUDConstructionFlexibleMapBuilding = class("PvPTileAssetHUDConstructionFlexibleMapBuilding", PvPTileAssetHUDConstruction)

---@param entity wds.CommonMapBuilding|wds.EnergyTower|wds.DefenceTower
function PvPTileAssetHUDConstructionFlexibleMapBuilding:OnRefresh(entity)
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)

    local durability = entity.Battle.Durability
    local maxDurability = entity.Battle.MaxDurability
    if maxDurability <= 0 then
        if buildingConfig then
            maxDurability = buildingConfig:BuildValue()
        end
    end
    self:RefreshDurability(durability, maxDurability)

    local troopCount = 0
    local myTroopCount = 0
    if entity.Army then
        troopCount = table.nums(entity.Army.PlayerTroopIDs)
        myTroopCount = ModuleRefer.MapBuildingTroopModule:GetMyTroopCount(entity.Army)
    end
    self:RefreshTroopQuantity(troopCount, myTroopCount)
end

return PvPTileAssetHUDConstructionFlexibleMapBuilding
