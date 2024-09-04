local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetWaitRibbonCutting:CityTileAsset
---@field new fun():CityTileAssetWaitRibbonCutting
local CityTileAssetWaitRibbonCutting = class("CityTileAssetWaitRibbonCutting", CityTileAsset)
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")

function CityTileAssetWaitRibbonCutting:GetPrefabName()
    self.scale = nil
    ---@type CityFurniture
    local furniture = self.tileView.tile:GetCell()
    local castleFurniture = self:GetCity().furnitureManager:GetCastleFurniture(furniture.singleId)
    if not castleFurniture then
        return string.Empty
    end

    if furniture:GetUpgradeCostTime() > 0
        and castleFurniture.LevelUpInfo.Working
        and castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress
        and furniture.furnitureCell:RibbonCuttingModel() > 0 then
        local mdl, scale = ArtResourceUtils.GetItemAndScale(furniture.furnitureCell:RibbonCuttingModel())
        self.scale = scale
        if self.scale == 0 then
            self.scale = 1
        end
        return mdl
    end

    return string.Empty
end

function CityTileAssetWaitRibbonCutting:GetScale()
    if self.scale then
        return self.scale
    else
        return CityTileAsset.GetScale(self)
    end
end

function CityTileAssetWaitRibbonCutting:OnAssetLoaded(go, userdata, handle)
    ---@type CityFurniture
    local cell = self.tileView.tile:GetCell()
    local city = self:GetCity()
    local pos = city:GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)

    go.transform.position = pos

    local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
    if Utils.IsNotNull(collider) then
        local trigger = go:AddMissingLuaBehaviour("CityTrigger")
        self.cityTrigger = trigger.Instance
        self.cityTrigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self.tileView.tile, false)
        self.cityTrigger:SetOnPress(Delegate.GetOrCreate(self, self.OnPressDown), Delegate.GetOrCreate(self, self.OnPress), Delegate.GetOrCreate(self, self.OnPressUp))
    end
end


function CityTileAssetWaitRibbonCutting:OnClick()
    if self.tileView and self.tileView.tile then
        local city = self:GetCity()
        if city then
            if city.stateMachine.currentState.OnClickFurnitureTile then
                city.stateMachine.currentState:OnClickFurnitureTile(self.tileView.tile)
                return true
            end
        end
    end
end

function CityTileAssetWaitRibbonCutting:OnPressDown()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressDownFurnitureTile then
        city.stateMachine.currentState:OnPressDownFurnitureTile(self.tileView.tile)
        return true
    end
end

function CityTileAssetWaitRibbonCutting:OnPress()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressFurnitureTile then
        city.stateMachine.currentState:OnPressFurnitureTile(self.tileView.tile)
        return true
    end
end

function CityTileAssetWaitRibbonCutting:OnPressUp()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressUpFurnitureTile then
        city.stateMachine.currentState:OnPressUpFurnitureTile(self.tileView.tile)
        return true
    end
end

return CityTileAssetWaitRibbonCutting