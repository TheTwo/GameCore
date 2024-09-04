local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetCanUpgradeBubble:CityTileAssetBubble
---@field new fun():CityTileAssetCanUpgradeBubble
local CityTileAssetCanUpgradeBubble = class("CityTileAssetCanUpgradeBubble", CityTileAssetBubble)
local Delegate = require("Delegate")
local CityUtils = require("CityUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local Utils = require("Utils")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")

function CityTileAssetCanUpgradeBubble:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnPlayerBagChange))
    g_Game.EventManager:AddListener(EventConst.CITY_UPGRADE_BUILDING_UI_OPEN, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:AddListener(EventConst.CITY_UPGRADE_BUILDING_UI_CLOSE, Delegate.GetOrCreate(self, self.Show))
    g_Game.EventManager:AddListener(EventConst.CITY_ROOM_DIRTY_FOR_UPGRADE, Delegate.GetOrCreate(self, self.ForceRefresh))
end

function CityTileAssetCanUpgradeBubble:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnPlayerBagChange))
    g_Game.EventManager:RemoveListener(EventConst.CITY_UPGRADE_BUILDING_UI_OPEN, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:RemoveListener(EventConst.CITY_UPGRADE_BUILDING_UI_CLOSE, Delegate.GetOrCreate(self, self.Show))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ROOM_DIRTY_FOR_UPGRADE, Delegate.GetOrCreate(self, self.ForceRefresh))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetCanUpgradeBubble:OnPlayerBagChange()
    self:ForceRefresh()
end

function CityTileAssetCanUpgradeBubble:ShouldShow()
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityBuildUpgradeUIMediator) then
        return false
    end

    local tile = self.tileView.tile
    if not tile then return false end

    local buildingInfo = tile:GetCastleBuildingInfo()
    if buildingInfo == nil then
        return false
    end

    if not CityUtils.IsStatusReady(buildingInfo.Status) then
        return false
    end

    return tile:CanUpgrade()
end

function CityTileAssetCanUpgradeBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_group)
end

function CityTileAssetCanUpgradeBubble:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then
        return
    end

    local luaBehaviour = go:GetLuaBehaviour("City3DBubbleStandard")
    ---@type City3DBubbleStandard
    local bubble = luaBehaviour.Instance
    bubble:EnableTrigger(true)
    bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCellTile), self.tileView.tile, true)
    if not self:TrySetPosToMainAssetAnchor(bubble.transform) then
        self:SetPosToTileWorldCenter(go)
    end
    self.bubble = bubble
    self.bubble:PlayInAni(Delegate.GetOrCreate(self.bubble, self.bubble.PlayLoopAni))
    self:Refresh()
end

function CityTileAssetCanUpgradeBubble:Refresh()
    if self.bubble == nil then return end

    local showDanger = self:GetCity().buildingManager:IsPolluted(self.tileView.tile:GetCell().tileId)
    self.bubble:ShowBubble("sp_item_icon_expand", showDanger):ShowDangerImg(showDanger)
end

function CityTileAssetCanUpgradeBubble:GetFadeOutDuration()
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityBuildUpgradeUIMediator) then
        return 0
    end

    if self.bubble then
        return self.bubble:GetFadeOutDuration()
    end
    return 0
end

function CityTileAssetCanUpgradeBubble:OnAssetUnload(go, fade)
    if self.bubble then
        self.bubble:PlayOutAni()
        self.bubble:ClearTrigger()
        self.bubble = nil
    end
end

return CityTileAssetCanUpgradeBubble