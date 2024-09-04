local CityTileAssetSLGUnitLifeBarTempBase = require("CityTileAssetSLGUnitLifeBarTempBase")
---@class CityTileAssetNpcSLGUnitLifeBarTemp:CityTileAssetSLGUnitLifeBarTempBase
---@field new fun():CityTileAssetNpcSLGUnitLifeBarTemp
local CityTileAssetNpcSLGUnitLifeBarTemp = class("CityTileAssetNpcSLGUnitLifeBarTemp", CityTileAssetSLGUnitLifeBarTempBase)
local ModuleRefer = require("ModuleRefer")

function CityTileAssetNpcSLGUnitLifeBarTemp:GetBody()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        return self:GetCity().elementManager:GetElementById(cell.configId)
    end
    return nil
end

function CityTileAssetNpcSLGUnitLifeBarTemp:GetBuildingTroopCtrl()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        local troopManager = ModuleRefer.SlgModule.troopManager
        if troopManager then
            return troopManager:FindElementCtrlByConfigId(cell.configId)
        end
    end
    return nil
end

function CityTileAssetNpcSLGUnitLifeBarTemp:SlgUnitType()
    return wds.CityBattleObjType.CityBattleObjTypeElement
end

function CityTileAssetNpcSLGUnitLifeBarTemp:BodyUniqueId()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        return cell.configId
    end
    return nil
end

return CityTileAssetNpcSLGUnitLifeBarTemp