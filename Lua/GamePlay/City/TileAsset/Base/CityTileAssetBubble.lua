local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetBubble:CityTileAsset
---@field new fun():CityTileAssetBubble
local CityTileAssetBubble = class("CityTileAssetBubble", CityTileAsset)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require('ModuleRefer')
local Utils = require("Utils")
local CityWorkHelper = require("CityWorkHelper")
local UIMediatorNames = require("UIMediatorNames")

function CityTileAssetBubble:ctor()
    CityTileAsset.ctor(self)
    self.isUI = true
end

function CityTileAssetBubble:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.ForceRefresh))
end

function CityTileAssetBubble:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.ForceRefresh))
end

function CityTileAssetBubble:CheckCanShow()
    local outsideBubble = not self.tileView.tile:IsInner() or self:GetCity().roofHide
    local notInRadar = not ModuleRefer.RadarModule:IsInRadar()
    local notInEdit = not self:GetCity():IsEditMode()
    local notFogMask = not self:GetCity():IsFogMask(self.tileView.tile.x, self.tileView.tile.y)
    local notInStory = not ModuleRefer.StoryModule:IsStoryTimelineOrDialogPlaying()
    local notRelativeUiOpened = not CityWorkHelper.IsRelativeUiOpened()
    local notPlacedUiOpened = not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityFurniturePlaceUIMediator)
    local notInSeBattleMode = not self:GetCity():IsInSeBattleMode()
    local notInSeSingleExplorerMode = not self:GetCity():IsInSingleSeExplorerMode()
    local notInZoneRecoverEffectMode = not self:GetCity():IsInRecoverZoneEffectMode()
    return outsideBubble and notInRadar and notInEdit and notFogMask and notInStory and notRelativeUiOpened and notPlacedUiOpened and notInSeBattleMode and (notInSeSingleExplorerMode or self:ShowInSingleSeExplorerMode()) and notInZoneRecoverEffectMode
end

function CityTileAssetBubble:OnMainAssetLoaded(asset, go)
    if Utils.IsNotNull(self.tileView.gameObjs[self]) then
        self:OnAssetLoaded(self.tileView.gameObjs[self], nil)
    end
end

function CityTileAssetBubble:ShowInSingleSeExplorerMode()
    return false
end

return CityTileAssetBubble