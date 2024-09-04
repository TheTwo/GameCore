local Delegate = require("Delegate")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local EventConst = require("EventConst")
local ManualResourceConst = require("ManualResourceConst")
local ModuleRefer = require('ModuleRefer')
local CityStaticObjectTile = require("CityStaticObjectTile")

---@class CityStaticObjectTileHeroRescueBubble:CityStaticObjectTile
---@field new fun(gridView:CityGridView, zoneId:number, zoneConfig:CityZoneConfigCell):CityStaticObjectTileHeroRescueBubble
---@field super CityStaticObjectTile
local CityStaticObjectTileHeroRescueBubble = class('CityStaticObjectTileHeroRescueBubble', CityStaticObjectTile)

---@param gridView CityGridView
---@param zoneId number
---@param zoneConfig CityZoneConfigCell
function CityStaticObjectTileHeroRescueBubble:ctor(gridView, zoneId, zoneConfig)
    self.config = zoneConfig
    self.zoneId = zoneId
    local index = ModuleRefer.HeroRescueModule:GetItemBubbleIndexByZoneId(zoneId)
    local pos = ModuleRefer.HeroRescueModule:GetItemBubblePos(index)
    CityStaticObjectTile.ctor(self, gridView, pos:X(), pos:Y(), 1, 1, ManualResourceConst.ui3d_bubble_group_hero_rescue)
    self.isUI = true
    ---@type CS.UnityEngine.GameObject
    self.goRoot = nil
    ---@type City3DBubbleHeroRescue
    self.bubble = nil
    self.tempHide = false
end

---@param go CS.UnityEngine.GameObject
function CityStaticObjectTileHeroRescueBubble:OnAssetLoaded(go, userdata)
    CityStaticObjectTile.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    go:SetLayerRecursively("Scene3DUI", true)
    self.goRoot = go
    local bar = go:GetLuaBehaviour("City3DBubbleHeroRescue")
    if not bar then
        return
    end
    self.bubble = bar.Instance
    if not self.bubble then
        return
    end
    self.bubble:Reset()
    self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickBubble), nil)
    self.bubble:ShowBubble(ModuleRefer.HeroRescueModule:GetItemIcon())
    self.bubble:EnableTrigger(true)
    self.tempHide = self.gridView.city.zoneManager:InTempSelected(self.zoneId) or self.gridView.city.zoneManager:IsZoneRecoveredById(self.zoneId)
    self:RefreshTempHide()
    self:SetupEvent(true)
end

function CityStaticObjectTileHeroRescueBubble:OnAssetUnload()
    self:SetupEvent(false)
    if self.bubble then
        self.bubble:ClearTrigger()
    end
    self.bubble = nil
    self.goRoot = nil
end

function CityStaticObjectTileHeroRescueBubble:RefreshBubbleCheckStatus()

end

function CityStaticObjectTileHeroRescueBubble:OnClickBubble()
    local city = self.gridView.city
    local zone = city.zoneManager:GetZoneById(self.zoneId)
    local hitPoint = city:GetCenterPlanePositionFromCoord(self.x, self.y, self.sizeX, self.sizeY)
    -- g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_ZONE_CLICK, city.uid, zone, hitPoint, nil, true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_TRY_UNLOCK_ZONE, city.uid, zone, hitPoint)
    g_Game.SoundManager:Play("sfx_ui_click_low")
    return true
end

function CityStaticObjectTileHeroRescueBubble:OnTempZoneHideChanged(cityUid)
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

function CityStaticObjectTileHeroRescueBubble:RefreshTempHide()
    if Utils.IsNotNull(self.goRoot) then
        local zone = self.gridView.city.zoneManager:GetZoneById(self.zoneId)

        if not zone:NotExplore() then
            self.goRoot:SetVisible(false)
            return
        end

        local city = self.gridView.city
        local isGuide
        if ModuleRefer.HeroRescueModule then
            isGuide = ModuleRefer.HeroRescueModule:GetManualShowItemBubble()
        end
        local canShow = isGuide or not self.tempHide and not city:IsInRecoverZoneEffectMode() and not city:IsInSeBattleMode() and not city:IsInSingleSeExplorerMode()
        self.goRoot:SetVisible(canShow)
    end
end

function CityStaticObjectTileHeroRescueBubble:Release()
    self:SetupEvent(false)
    CityStaticObjectTileHeroRescueBubble.super.Release(self)
end

function CityStaticObjectTileHeroRescueBubble:SetupEvent(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.RefreshTempHide))
    elseif self._eventsAdd and not add then
        g_Game.EventManager:RemoveListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.RefreshTempHide))
        self._eventsAdd = false
    end
end

return CityStaticObjectTileHeroRescueBubble
