local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetSafeAreaDoor:CityTileAsset
---@field new fun():CityTileAssetSafeAreaDoor
---@field super CityTileAsset
local CityTileAssetSafeAreaDoor = class('CityTileAssetSafeAreaDoor', CityTileAsset)

function CityTileAssetSafeAreaDoor:ctor()
    CityTileAsset.ctor(self)
    self._doorOpenStatus = false
    ---@type CityTileAssetSafeAreaDoorComp
    self._doorComp = nil
    ---@type CS.UnityEngine.Vector3
    self._doorCenterPos = nil
end

function CityTileAssetSafeAreaDoor:OnTileViewInit()
    ---@type CitySafeAreaWallDoor
    local cell = self.tileView.tile:GetCell()
    self._wallId = cell.singleId
    self._config = ConfigRefer.CitySafeAreaWall:Find(self._wallId)
    self._status = ModuleRefer.CitySafeAreaModule:GetWallStatus(self._wallId)
    local city = self:GetCity()
    self._castleBriefId = self:GetCity().uid
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
    self._doorOpenStatus = self:GetCity().safeAreaWallMgr:GetDoorOpenStatus(self._wallId)
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_DOOR_OPEN_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnDoorOpenStatusChanged))
    local mgr = city.safeAreaWallMgr
    local match, pos = mgr:GetWallCenterGrid(self._wallId)
    if match then
        self._doorCenterPos = city:GetWorldPositionFromCoord(pos.x + 0.5, pos.y + 0.5)
    else
        self._doorCenterPos = nil
    end
end

function CityTileAssetSafeAreaDoor:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_DOOR_OPEN_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnDoorOpenStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
end

function CityTileAssetSafeAreaDoor:GetPrefabName()
    if not self:ShouldShow() or not self._config or not self._doorCenterPos then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(self._config:DoorAsset())
end

function CityTileAssetSafeAreaDoor:ShouldShow()
    return self._status == 0
end

function CityTileAssetSafeAreaDoor:Refresh()
    self:Hide()
    self:Show()
end

function CityTileAssetSafeAreaDoor:OnWallStatusChanged(castleBriefId)
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

function CityTileAssetSafeAreaDoor:OnDoorOpenStatusChanged(castleBriefId, wallId, status)
    if not self._castleBriefId or self._castleBriefId ~= castleBriefId then
        return
    end
    if not self._wallId or self._wallId ~= wallId then
        return
    end
    if self._doorOpenStatus == status then
        return
    end
    self._doorOpenStatus = status
    if not self._doorComp then return end
    self._doorComp:SetOpenStatus(self._doorOpenStatus)
end

function CityTileAssetSafeAreaDoor:OnAssetLoaded(go, userdata)
    CityTileAsset.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    go.transform.position = self._doorCenterPos
    local be = go:GetLuaBehaviourInChildren("CityTileAssetSafeAreaDoorComp", true)
    if Utils.IsNull(be) then
        return
    end
    self._doorComp = be.Instance
    if not self._doorComp then return end
    self._doorComp:SetOpenStatus(self._doorOpenStatus)
end

function CityTileAssetSafeAreaDoor:OnAssetUnload(go, fade)
    self._doorComp = nil
end

return CityTileAssetSafeAreaDoor