local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetSafeAreaDoorBroken:CityTileAsset
---@field new fun():CityTileAssetSafeAreaDoorBroken
---@field super CityTileAsset
local CityTileAssetSafeAreaDoorBroken = class('CityTileAssetSafeAreaDoorBroken', CityTileAsset)

function CityTileAssetSafeAreaDoorBroken:ctor()
    CityTileAsset.ctor(self)
    self.allowSelected = true
end

function CityTileAssetSafeAreaDoorBroken:OnTileViewInit()
    ---@type CitySafeAreaWallDoor
    local cell = self.tileView.tile:GetCell()
    self._wallId = cell.singleId
    self._config = ConfigRefer.CitySafeAreaWall:Find(self._wallId)
    self._status = ModuleRefer.CitySafeAreaModule:GetWallStatus(self._wallId)
    self._castleBriefId = self:GetCity().uid
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
end

function CityTileAssetSafeAreaDoorBroken:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
end

function CityTileAssetSafeAreaDoorBroken:GetPrefabName()
    if not self:ShouldShow() or not self._config then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(self._config:BrokenDoorAsset())
end

function CityTileAssetSafeAreaDoorBroken:ShouldShow()
    return self._status == 1
end

function CityTileAssetSafeAreaDoorBroken:Refresh()
    self:Hide()
    self:Show()
end

function CityTileAssetSafeAreaDoorBroken:OnWallStatusChanged(castleBriefId)
    if not self._castleBriefId or self._castleBriefId ~= castleBriefId then
        return
    end
    local status = ModuleRefer.CitySafeAreaModule:GetWallStatus(self._wallId)
    if status == self._status then
        return
    end
    self._status = status
    self:Refresh()
end

return CityTileAssetSafeAreaDoorBroken