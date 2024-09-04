local PoolUsage = require("PoolUsage")

local KingdomPlacerBehavior = require("KingdomPlacerBehavior")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomPlacer = require("KingdomPlacer")
local ConfigRefer = require("ConfigRefer")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local DBEntityType = require("DBEntityType")
local KingdomConstant = require("KingdomConstant")
local UIMediatorNames = require("UIMediatorNames")
local Layers = require("Layers")

local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local Vector2Short = CS.DragonReborn.Vector2Short
local MapUtils = CS.Grid.MapUtils

---@class KingdomPlacerBehaviorBuilding : KingdomPlacerBehavior
---@field context  KingdomPlacerContextBuilding
---@field building CS.UnityEngine.GameObject
---@field modelHandle CS.DragonReborn.AssetTool.PooledGameObjectHandle
local KingdomPlacerBehaviorBuilding = class("KingdomPlacerBehaviorBuilding", KingdomPlacerBehavior)

function KingdomPlacerBehaviorBuilding:OnDispose()
    self:UnloadModel()
end

function KingdomPlacerBehaviorBuilding:OnSetParameter()
    self.placer:SetSize(self.context.sizeX, self.context.sizeY)

    self:UnloadModel()
    self:LoadModel()
end

function KingdomPlacerBehaviorBuilding:OnHide()
    self:UnloadModel()
end

---@param go CS.UnityEngine.GameObject
---@param behavior KingdomPlacerBehaviorBuilding
local function LoadCallback(go, behavior)
    if go ~= nil and behavior ~= nil then
        go:SetLayerRecursive(Layers.Tile)
        behavior.building = go
    end
end

function KingdomPlacerBehaviorBuilding:LoadModel()
    self.modelHandle = PooledGameObjectHandle(PoolUsage.Map)
    local modelConfig = ConfigRefer.ArtResource:Find(self.context.buildingConfig:Model())
    if modelConfig then
        self.modelHandle:Create(modelConfig:Path(), self.placer.transform, LoadCallback, self, 0, false, false)
    end
end

function KingdomPlacerBehaviorBuilding:UnloadModel()
    if self.modelHandle ~= nil then
        self.modelHandle:Delete()
    end
end

---@param coord CS.DragonReborn.Vector2Short
function KingdomPlacerBehaviorBuilding:OnUpdatePosition()
    if self.building ~= nil then
        self.building.transform.position = MapUtils.CalculateCoordToTerrainPosition(self.context.coord.X, self.context.coord.Y, self.placer.mapSystem)
        local relocateMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.RelocateMediator)
        if relocateMediator then
            relocateMediator:UpdateRelocatePosParam(CS.UnityEngine.Vector3(self.context.coord.X, self.context.coord.Y, 0), self.building.transform.position)
        end
    end
end

---@param coord CS.DragonReborn.Vector2Short
---@param sizeX number
---@param sizeY number
---@param mapSystem CS.Grid.MapSystem
---@return boolean
function KingdomPlacerBehaviorBuilding.CheckInEnergyTowerRange(coord, sizeX, sizeY, mapSystem)
    local center = Vector2Short(
            math.floor(coord.X + sizeX / 2),
            math.floor(coord.Y + sizeY / 2)
    )

    local views = mapSystem:GetUnitViewsInRange()
    for i = 0, views.Count - 1 do
        ---@type MapTileView
        local tileView = views[i]:GetInstance()
        if tileView:GetTypeId() == DBEntityType.EnergyTower then
            ---@type wds.EnergyTower
            local entity = g_Game.DatabaseManager:GetEntity(tileView:GetUniqueId(), tileView:GetTypeId())
            if entity then
                local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
                local position = entity.MapBasics.Position
                local radius = buildingConfig:EffectRaid()
                local buildingPos = Vector2Short(position.X, position.Y)
                if Vector2Short.DistanceSquared(center, buildingPos) <= radius * radius then
                    return true
                end
            end

        end
    end
    return false
end

return KingdomPlacerBehaviorBuilding