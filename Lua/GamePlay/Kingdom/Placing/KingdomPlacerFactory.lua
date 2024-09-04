
local PoolUsage = require("PoolUsage")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomPlacerBehaviorBuilding = require("KingdomPlacerBehaviorBuilding")
local KingdomPlacerBehaviorCircleRange = require("KingdomPlacerBehaviorCircleRange")
local KingdomPlacerBehaviorEnergyTower = require("KingdomPlacerBehaviorEnergyTower")
local KingdomPlacerBehaviorTransferTower = require("KingdomPlacerBehaviorTransferTower")
local KingdomPlacerBehaviorDefenseTower = require("KingdomPlacerBehaviorDefenseTower")
local KingdomPlacerBehaviorMobileFortress = require("KingdomPlacerBehaviorMobileFortress")
local KingdomPlacerBehaviorBehemothDevice = require("KingdomPlacerBehaviorBehemothDevice")
local KingdomPlacerBehaviorBehemothSummoner = require("KingdomPlacerBehaviorBehemothSummoner")
local KingdomPlacerContextBuilding = require("KingdomPlacerContextBuilding")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local KingdomPlacerHolder = require("KingdomPlacerHolder")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")

local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle

---@class KingdomPlacerFactory
local KingdomPlacerFactory = class("KingdomPlacerFactory")

---@param buildingConfig FlexibleMapBuildingConfigCell
---@param coord CS.DragonReborn.Vector2Short
---@param rangePrefab string
---@return KingdomPlacerHolder
function KingdomPlacerFactory.CreateBuilding(buildingConfig, coord)

    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    local handle = PooledGameObjectHandle(PoolUsage.Map)
    local placer = KingdomPlacerHolder.new(handle)
    handle:Create(ManualResourceConst.kingdom_placer, KingdomMapUtils.GetMapSystem().Parent, Delegate.GetOrCreate(placer, placer.OnAssetLoaded))
    local behaviors = {}
    table.insert(behaviors, KingdomPlacerBehaviorBuilding.new())
    local buildingConfigType = buildingConfig:Type()
    if buildingConfigType == FlexibleMapBuildingType.EnergyTower then
        table.insert(behaviors, KingdomPlacerBehaviorEnergyTower.new())
        table.insert(behaviors, KingdomPlacerBehaviorCircleRange.new())
    elseif buildingConfigType == FlexibleMapBuildingType.TransferTower then
        table.insert(behaviors, KingdomPlacerBehaviorTransferTower.new())
    elseif buildingConfigType == FlexibleMapBuildingType.DefenseTower then
        table.insert(behaviors, KingdomPlacerBehaviorDefenseTower.new())
        table.insert(behaviors, KingdomPlacerBehaviorCircleRange.new())
    elseif buildingConfigType == FlexibleMapBuildingType.MobileFortress then
        table.insert(behaviors, KingdomPlacerBehaviorMobileFortress.new())
    elseif buildingConfigType == FlexibleMapBuildingType.BehemothDevice then
        table.insert(behaviors, KingdomPlacerBehaviorBehemothDevice.new())
    elseif buildingConfigType == FlexibleMapBuildingType.BehemothSummoner then
        table.insert(behaviors, KingdomPlacerBehaviorBehemothSummoner.new())
    end
    
    local context = KingdomPlacerContextBuilding.new()
    context.allowDragTarget = true
    placer:Initialize(behaviors, context)
    
    local parameter = {buildingConfig, coord}
    placer:SetParameter(parameter)

    return placer
end

---@return KingdomPlacerHolder
function KingdomPlacerFactory.CreateCastle(castleConfig, coord)
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    local handle = PooledGameObjectHandle(PoolUsage.Map)
    local placer = KingdomPlacerHolder.new(handle)
    handle:Create(ManualResourceConst.kingdom_placer, KingdomMapUtils.GetMapSystem().Parent, Delegate.GetOrCreate(placer, placer.OnAssetLoaded))
    
    local behaviors = {}
    table.insert(behaviors, KingdomPlacerBehaviorBuilding.new())
    
    local context = KingdomPlacerContextBuilding.new()
    placer:Initialize(behaviors, context)
    
    local parameter = {castleConfig, coord}
    placer:SetParameter(parameter)
    
    return placer
end

return KingdomPlacerFactory