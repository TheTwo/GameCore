local Delegate = require("Delegate")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")

local CityStaticObjectTile = require("CityStaticObjectTile")

---@class CityStaticObjectTileZoneBubble:CityStaticObjectTile
---@field new fun(gridView:CityGridView, zoneId:number, zoneConfig:CityZoneConfigCell):CityStaticObjectTileZoneBubble
---@field super CityStaticObjectTile
local CityStaticObjectTileZoneBubble = class('CityStaticObjectTileZoneBubble', CityStaticObjectTile)

---@param gridView CityGridView
---@param zoneId number
---@param zoneConfig CityZoneConfigCell
function CityStaticObjectTileZoneBubble:ctor(gridView, zoneId, zoneConfig)
    self.config = zoneConfig
    self.zoneId = zoneId
    local pos = zoneConfig:RecoverPopPos()
    CityStaticObjectTile.ctor(self, gridView, pos:X(), pos:Y(), 1, 1, ManualResourceConst.ui3d_bubble_group_fog)
    self.isUI = true
    ---@type CS.UnityEngine.GameObject
    self.goRoot = nil
    ---@type City3DBubbleFog
    self.bubble = nil
    self.tempHide = false
end

---@param go CS.UnityEngine.GameObject
function CityStaticObjectTileZoneBubble:OnAssetLoaded(go, userdata)
    CityStaticObjectTile.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    go:SetLayerRecursively("Scene3DUI", true)
    self.goRoot = go
    local bar = go:GetLuaBehaviour("City3DBubbleFog")
    if not bar then
        return
    end
    self.bubble = bar.Instance
    if not self.bubble then
        return
    end
    self.bubble:Reset()
    self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickBubble), nil)
    self.bubble:ShowBubble("sp_icon_item_creepmedicine")
    local isReady = self:IsReadyForRecover()
    self.bubble:ShowBubbleCheckImg(isReady)
    self.bubble:EnableTrigger(true)
    self.tempHide = self.gridView.city.zoneManager:InTempSelected(self.zoneId) or self.gridView.city.zoneManager:IsZoneRecoveredById(self.zoneId)
    self:RefreshTempHide()
    if isReady then
        self.bubble:PlayLoopAni()
    end
    self:SetupEvent(true)
end

function CityStaticObjectTileZoneBubble:OnAssetUnload()
    self:SetupEvent(false)
    if self.bubble then
        self.bubble:ClearTrigger()
    end
    self.bubble = nil
    self.goRoot = nil
end

function CityStaticObjectTileZoneBubble:RefreshBubbleCheckStatus()
    if self.bubble then
        self.bubble:ShowBubbleCheckImg(self:IsReadyForRecover())
        self.bubble:PlayLoopAni()
    end
end

function CityStaticObjectTileZoneBubble:IsReadyForRecover()
    local city = self.gridView.city
    local zone = city.zoneManager:GetZoneById(self.zoneId)
    return city.zoneManager:IsReadyForUnlock(zone)
end

function CityStaticObjectTileZoneBubble:OnClickBubble()
    local city = self.gridView.city
    local zone = city.zoneManager:GetZoneById(self.zoneId)
    local hitPoint = city:GetCenterPlanePositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
    -- g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_ZONE_CLICK, city.uid, zone, hitPoint, nil, true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_TRY_UNLOCK_ZONE, city.uid, zone, hitPoint)
    g_Game.SoundManager:Play("sfx_ui_click_low")
    return true
end

function CityStaticObjectTileZoneBubble:OnTempZoneHideChanged(cityUid)
    if self.gridView.city.uid ~= cityUid then
        return
    end
    local tempHide = self.gridView.city.zoneManager:InTempSelected(self.zoneId)
    if tempHide == self.tempHide then
        return
    end
    self.tempHide = tempHide
    self:RefreshTempHide()
end

function CityStaticObjectTileZoneBubble:RefreshTempHide()
    if Utils.IsNotNull(self.goRoot) then
        local city = self.gridView.city
        self.goRoot:SetVisible(not self.tempHide and not city:IsInRecoverZoneEffectMode() and not city:IsInSeBattleMode())
    end
end

function CityStaticObjectTileZoneBubble:Release()
    self:SetupEvent(false)
    CityStaticObjectTileZoneBubble.super.Release(self)
end

function CityStaticObjectTileZoneBubble:SetupEvent(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.RefreshTempHide))
    elseif self._eventsAdd and not add then
        g_Game.EventManager:RemoveListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.RefreshTempHide))
        self._eventsAdd = false
    end
end

return CityStaticObjectTileZoneBubble