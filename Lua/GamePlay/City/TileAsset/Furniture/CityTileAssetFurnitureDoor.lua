local CityDefenseType = require("CityDefenseType")
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetFurnitureDoor:CityTileAsset
---@field new fun():CityTileAssetFurnitureDoor
---@field super CityTileAsset
local CityTileAssetFurnitureDoor = class('CityTileAssetFurnitureDoor', CityTileAsset)

function CityTileAssetFurnitureDoor:ctor()
    CityTileAsset.ctor(self)
    self._castleBriefId = nil
    self._isTracking = false
    self._furnitureId = nil
    ---@type CS.UnityEngine.Animator
    self._animator = nil
    self._doorOpenStatus = false
end

function CityTileAssetFurnitureDoor:OnTileViewInit()
    ---@type CityFurnitureTile
    local tile = self.tileView.tile
    self._furnitureId = tile:GetCell():UniqueId()
    local type = tile:GetFurnitureTypesCell()
    if type and type:DefenseType() == CityDefenseType.Door then
        self._isTracking = true
        local city = self.tileView.tile:GetCity()
        self._castleBriefId = city.uid
        self._doorOpenStatus = city.furnitureManager:GetFurnitureDoorOpenStatus(self._furnitureId)
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_DOOR_OPEN_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnDoorOpenStatusChanged))
    else
        self._isTracking = false
    end
end

function CityTileAssetFurnitureDoor:OnTileViewRelease()
    if self._isTracking then
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_DOOR_OPEN_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnDoorOpenStatusChanged))
    end
    self._isTracking = false
end

function CityTileAssetFurnitureDoor:OnMainAssetLoaded(mainAsset, go)
    if not self._isTracking then
        return
    end
    if not mainAsset or GetClassName(mainAsset) ~= "CityTileAssetFurniture" then
        return
    end
    if Utils.IsNull(go) then
        return
    end
    self._animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
    if Utils.IsNull(self._animator) then
        return
    end
    if self._animator:HasParameter("open") then
        self._animator:SetBool("open", self._doorOpenStatus)
    end
end

function CityTileAssetFurnitureDoor:OnMainAssetUnloaded(mainAsset)
    if not mainAsset or GetClassName(mainAsset) ~= "CityTileAssetFurniture" then
        return
    end
    self._animator = nil
    if not self._isTracking then
        return
    end
end

function CityTileAssetFurnitureDoor:OnDoorOpenStatusChanged(castleBriefId, furnitureId, status)
    if not self._castleBriefId or self._castleBriefId ~= castleBriefId then
        return
    end
    if not self._furnitureId or self._furnitureId ~= furnitureId then
        return
    end
    if self._doorOpenStatus == status then
        return
    end
    self._doorOpenStatus = status
    if Utils.IsNull(self._animator) then
        return
    end
    if self._animator:HasParameter("open") then
        self._animator:SetBool("open", self._doorOpenStatus)
    end
end

return CityTileAssetFurnitureDoor