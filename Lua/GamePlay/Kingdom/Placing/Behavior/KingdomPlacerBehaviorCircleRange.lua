local KingdomPlacerBehavior = require("KingdomPlacerBehavior")
local KingdomMapUtils = require("KingdomMapUtils")
local PoolUsage = require("PoolUsage")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local PvPTileAssetCircleRange = require("PvPTileAssetCircleRange")

local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle

---@class KingdomPlacerBehaviorCircleRange : KingdomPlacerBehavior
local KingdomPlacerBehaviorCircleRange = class("KingdomPlacerBehaviorCircleRange", KingdomPlacerBehavior)

function KingdomPlacerBehaviorCircleRange:OnInitialize(placer, context)
    KingdomPlacerBehaviorCircleRange.super.OnInitialize(self, placer, context)
    self.rangeHandle = PooledGameObjectHandle(PoolUsage.Map)
end

function KingdomPlacerBehaviorCircleRange:OnShow()
    local unitViews = KingdomMapUtils.GetMapSystem():GetUnitViewsInRange()
    self:RefreshUnitInRange(unitViews)
    self:ShowRangeEffect()
end

function KingdomPlacerBehaviorCircleRange:OnHide()
    local unitViews = KingdomMapUtils.GetMapSystem():GetUnitViewsInRange()
    self:RefreshUnitInRange(unitViews)
    self:HideRangeEffect()
end

function KingdomPlacerBehaviorCircleRange:OnDispose()
    self:HideRangeEffect(true)
end

function KingdomPlacerBehaviorCircleRange:RefreshUnitInRange(unitViews)
    for i = 0, unitViews.Count - 1 do
        ---@type MapTileView
        local view = unitViews[i]:GetInstance()
        local typeId = view:GetTypeId()
        if PvPTileAssetCircleRange.RangePrefabTable[typeId] then
            view:Refresh()
        end
    end
end

local function LoadCallback(go, behavior)
    if Utils.IsNotNull(go) then
        behavior:UpdateRangeEffect(go)
        KingdomMapUtils.DirtyMapMark()
    end
end

function KingdomPlacerBehaviorCircleRange:ShowRangeEffect()
    if Utils.IsNotNull(self.rangeHandle.Asset) then
        self.rangeHandle.Asset:SetActive(true)
        self:UpdateRangeEffect(self.rangeHandle.asset)
    else
        if self.rangeHandle.Idle then
            local typeId = ModuleRefer.KingdomConstructionModule.ConfigTypeToEntityType(self.context.buildingConfig:Type())
            local prefab = PvPTileAssetCircleRange.RangePrefabTable[typeId]
            self.rangeHandle:Create(prefab, self.placer.transform, LoadCallback, self)
        end
    end
end

---@param destroy boolean
function KingdomPlacerBehaviorCircleRange:HideRangeEffect(destroy)
    if Utils.IsNotNull(self.rangeHandle.Asset) then
        self.rangeHandle.Asset:SetActive(false)
        if destroy then
            self.rangeHandle:Delete()
        end
        KingdomMapUtils.DirtyMapMark()
    end
end

---@param go CS.UnityEngine.GameObject
function KingdomPlacerBehaviorCircleRange:UpdateRangeEffect(go)
    local radius = self.context.buildingConfig ~= nil and self.context.buildingConfig:EffectRaid() or 0
    
    ---@type PvPTileAssetCircleRangeBehavior
    local behavior = go:GetLuaBehaviour("PvPTileAssetCircleRangeBehavior").Instance
    behavior:ShowRange(radius, self.placer.staticMapData, true)
    behavior:SetOffset(self.context.sizeX / 2, self.context.sizeY / 2, self.placer.staticMapData)
end

return KingdomPlacerBehaviorCircleRange