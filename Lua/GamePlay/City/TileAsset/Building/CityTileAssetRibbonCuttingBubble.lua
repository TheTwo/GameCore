local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetRibbonCuttingBubble:CityTileAssetBubble
---@field new fun():CityTileAssetRibbonCuttingBubble
local CityTileAssetRibbonCuttingBubble = class("CityTileAssetRibbonCuttingBubble", CityTileAssetBubble)
local CityUtils = require("CityUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityTilePriority = require("CityTilePriority")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local Delegate = require("Delegate")

function CityTileAssetRibbonCuttingBubble:ShouldShow()
    return CityUtils.IsStatusWaitRibbonCutting(self.tileView.tile:GetCastleBuildingInfo().Status)
end

function CityTileAssetRibbonCuttingBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if self:ShouldShow() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_group)
    end
    return string.Empty
end

function CityTileAssetRibbonCuttingBubble:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.BUILDING
end

function CityTileAssetRibbonCuttingBubble:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

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

function CityTileAssetRibbonCuttingBubble:Refresh()
    if not self.bubble then return end

    local showDanger = self:GetCity().buildingManager:IsPolluted(self.tileView.tile:GetCell().tileId)
    self.bubble:ShowBubble("sp_icon_tick_ui3d", showDanger):ShowDangerImg(showDanger)
end

function CityTileAssetRibbonCuttingBubble:OnAssetUnload(go, fade)
    if self.bubble then
        self.bubble:ClearTrigger()
        self.bubble:PlayOutAni()
    end
    self.bubble = nil
end

function CityTileAssetRibbonCuttingBubble:GetFadeOutDuration()
    if self.bubble then
        return self.bubble:GetFadeOutDuration()
    end
    return 0
end

return CityTileAssetRibbonCuttingBubble