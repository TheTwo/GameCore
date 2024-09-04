local CityTileView = require("CityTileView")
---@class CityTileViewNpc:CityTileView
---@field new fun():CityTileViewNpc
local CityTileViewNpc = class("CityTileViewNpc", CityTileView)
local CityTileAssetNpc = require("CityTileAssetNpc")
local CityTileAssetNpcSLG = require("CityTileAssetNpcSLG")
local CityTileAssetNpcCityTrigger = require("CityTileAssetNpcCityTrigger")
local CityTileAssetNpcBubbleCommon = require("CityTileAssetNpcBubbleCommon")
local CityTileAssetNpcCommitItemBubble = require("CityTileAssetNpcCommitItemBubble")
local CityTileAssetNpcPollutedPlus = require("CityTileAssetNpcPollutedPlus")
local CityTileAssetNpcUnloadVfx = require("CityTileAssetNpcUnloadVfx")
local CityTileAssetNpcSLGUnitLifeBarTemp = require("CityTileAssetNpcSLGUnitLifeBarTemp")
local CityTileAssetViewVisibleModifier = require("CityTileAssetViewVisibleModifier")
local CityTileAssetNpcBubbleLockedSelectedTip = require("CityTileAssetNpcBubbleLockedSelectedTip")
local CityTileAssetNpcCatchEffect = require("CityTileAssetNpcCatchEffect")

function CityTileViewNpc:ctor()
    CityTileView.ctor(self)
    self:AddMainAsset(CityTileAssetNpc.new())
    self:AddMainAsset(CityTileAssetNpcSLG.new())
    self:AddAsset(CityTileAssetNpcCityTrigger.new())
    self:AddAsset(CityTileAssetNpcBubbleCommon.new())
    self:AddAsset(CityTileAssetNpcCommitItemBubble.new())
    self:AddAsset(CityTileAssetNpcPollutedPlus.new())
    self:AddAsset(CityTileAssetNpcUnloadVfx.new())
    self:AddAsset(CityTileAssetNpcSLGUnitLifeBarTemp.new())
    self:AddAsset(CityTileAssetViewVisibleModifier.new())
    self:AddAsset(CityTileAssetNpcBubbleLockedSelectedTip.new())
    self:AddAsset(CityTileAssetNpcCatchEffect.new())
end

function CityTileViewNpc:ToString()
    local npc = self.tile:GetCell()
    return ("[NPC: cfg:%d]"):format(npc.configId)
end

return CityTileViewNpc