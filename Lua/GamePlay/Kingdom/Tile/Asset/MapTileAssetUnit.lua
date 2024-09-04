--警告：不要在这个基类中写业务相关的特化逻辑，避免不必要的耦合

local MapTileAssetSolo = require("MapTileAssetSolo")
local TileAssetPriority = require("TileAssetPriority")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")

local Vector3 = CS.UnityEngine.Vector3

---@class MapTileAssetUnit : MapTileAssetSolo
---@field super MapTileAssetSolo
local MapTileAssetUnit = class("MapTileAssetUnit", MapTileAssetSolo)

function MapTileAssetUnit:ctor()
    MapTileAssetSolo.ctor(self)
    self.position = CS.UnityEngine.Vector3.zero
end

function MapTileAssetUnit:GetData()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        entity = ModuleRefer.MapUnitModule:GetPlayerUnitData(self.view.uniqueId, self.view.typeId)
    end
    return entity
end

function MapTileAssetUnit:GetBehavior(behaviorName)
    local go = self.handle.Asset
    if Utils.IsNull(go) then
        return nil
    end

    local luaBehavior = go:GetLuaBehaviour(behaviorName)
    if Utils.IsNull(luaBehavior) then
        return nil
    end
    local behavior = luaBehavior.Instance
    return behavior
end

---@generic T
---@param _ T
---@return T
function MapTileAssetUnit:GetDataGeneric(_)
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        entity = ModuleRefer.MapUnitModule:GetPlayerUnitData(self.view.uniqueId, self.view.typeId)
    end
    return entity
end

---@return string
function MapTileAssetUnit:GetLodPrefabName(lod)
    -- 子类重载这个函数
    return string.Empty
end

---@return string
---@private
function MapTileAssetUnit:GetLodPrefab(lod)
    self.position = self:CalculatePosition()
    return self:GetLodPrefabName(lod)
end

---@return CS.UnityEngine.Vector3
function MapTileAssetUnit:GetPosition()
    return self.position
end

function MapTileAssetUnit:GetPriority()
    return TileAssetPriority.Get("MapTileAssetUnit")
end

---@return CS.UnityEngine.Vector3
function MapTileAssetUnit:CalculatePosition()
    local x, z = self:GetServerPosition()
    local staticMapData = self:GetStaticMapData()

    x = x * staticMapData.UnitsPerTileX
    z = z * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)

    return Vector3(x, y, z)
end

---@return CS.UnityEngine.Vector3
function MapTileAssetUnit:CalculateCenterPosition()
    local x, z = self:GetServerCenterPosition()
    local staticMapData = self:GetStaticMapData()

    x = x * staticMapData.UnitsPerTileX
    z = z * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)

    return Vector3(x, y, z)
end

function MapTileAssetUnit:GetServerPosition()
    local entity = self:GetData()
    if entity == nil then
        return 0, 0
    end

    if entity.MapBasics then
        local buildingPos = entity.MapBasics.BuildingPos
        return buildingPos.X, buildingPos.Y
    else
        return ModuleRefer.MapUnitModule:GetPlayerUnitBaseCoordinate(entity)
    end
end

function MapTileAssetUnit:GetServerCenterPosition()
    local entity = self:GetData()
    if entity == nil then
        return 0, 0
    end

    if entity.MapBasics then
        local position = entity.MapBasics.Position
        return position.X, position.Y
    else
        return ModuleRefer.MapUnitModule:GetPlayerUnitCenterCoordinate(entity)
    end
end

return MapTileAssetUnit