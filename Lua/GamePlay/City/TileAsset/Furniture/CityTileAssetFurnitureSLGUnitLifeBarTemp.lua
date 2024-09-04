local CityTileAssetSLGUnitLifeBarTempBase = require("CityTileAssetSLGUnitLifeBarTempBase")
---@class CityTileAssetFurnitureSLGUnitLifeBarTemp:CityTileAssetSLGUnitLifeBarTempBase
---@field new fun():CityTileAssetFurnitureSLGUnitLifeBarTemp
local CityTileAssetFurnitureSLGUnitLifeBarTemp = class("CityTileAssetFurnitureSLGUnitLifeBarTemp", CityTileAssetSLGUnitLifeBarTempBase)
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityTileAssetFurnitureSLGUnitLifeBarTemp:GetBody()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        return self:GetCity().furnitureManager:GetFurnitureById(cell.singleId)
    end
    return nil
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:GetBuildingTroopCtrl()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        local troopManager = ModuleRefer.SlgModule.troopManager
        if troopManager then
            return troopManager:FindFurnitureCtrlByFunitureId(cell.singleId)
        end
    end
    return nil
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:SlgUnitType()
    return wds.CityBattleObjType.CityBattleObjTypeFurniture
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:BodyUniqueId()
    local cell = self.tileView.tile:GetCell()
    if cell ~= nil then
        return cell.singleId
    end
    return nil
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:OnTileViewInit()
    CityTileAssetSLGUnitLifeBarTempBase.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_EDIT_MODE_CHANGE, Delegate.GetOrCreate(self, self.OnEditModeChanged))
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_EDIT_MODE_CHANGE, Delegate.GetOrCreate(self, self.OnEditModeChanged))
    CityTileAssetSLGUnitLifeBarTempBase.OnTileViewRelease(self)
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:OnEditModeChanged(flag)
    if flag then
        self:Hide()
    else
        self:Show()
    end
end

function CityTileAssetFurnitureSLGUnitLifeBarTemp:OnRoofStateChanged(roofHide)
    if not self.tileView then return end
    if not self.tileView.tile then return end
    if not self.tileView.tile:IsInner() then return end
    if not roofHide then
        self:Hide()
    else
        self:Show()
    end
end

return CityTileAssetFurnitureSLGUnitLifeBarTemp