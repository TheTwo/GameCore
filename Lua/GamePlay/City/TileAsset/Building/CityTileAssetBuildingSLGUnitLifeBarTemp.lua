local CityTileAssetSLGUnitLifeBarTempBase = require("CityTileAssetSLGUnitLifeBarTempBase")
---@class CityTileAssetBuildingSLGUnitLifeBarTemp:CityTileAssetSLGUnitLifeBarTempBase
---@field new fun():CityTileAssetBuildingSLGUnitLifeBarTemp
local CityTileAssetBuildingSLGUnitLifeBarTemp = class("CityTileAssetBuildingSLGUnitLifeBarTemp", CityTileAssetSLGUnitLifeBarTempBase)
local ModuleRefer = require("ModuleRefer")

function CityTileAssetBuildingSLGUnitLifeBarTemp:GetBody()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        return self:GetCity().buildingManager:GetBuilding(cell.tileId)
    end
    return nil
end

function CityTileAssetBuildingSLGUnitLifeBarTemp:GetBuildingTroopCtrl()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        local troopManager = ModuleRefer.SlgModule.troopManager
        if troopManager then
            return troopManager:FindBuldingCtrlByViewId(cell.tileId)
        end
    end
    return nil
end

function CityTileAssetBuildingSLGUnitLifeBarTemp:SlgUnitType()
    return wds.CityBattleObjType.CityBattleObjTypeBuilding
end

function CityTileAssetBuildingSLGUnitLifeBarTemp:BodyUniqueId()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        return cell.tileId
    end
    return nil
end

return CityTileAssetBuildingSLGUnitLifeBarTemp