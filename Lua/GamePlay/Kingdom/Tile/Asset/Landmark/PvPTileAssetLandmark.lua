local MapTileAssetSolo = require("MapTileAssetSolo")

---@class PvPTileAssetLandmark : MapTileAssetSolo
local PvPTileAssetLandmark = class("PvPTileAssetLandmark", MapTileAssetSolo)
local DBEntityType = require('DBEntityType')

function PvPTileAssetLandmark:ctor()
    MapTileAssetSolo.ctor(self)
    self.position = CS.UnityEngine.Vector3.zero
    self.rotation = CS.UnityEngine.Quaternion.identity
    self.scale = CS.UnityEngine.Vector3.one
end

function PvPTileAssetLandmark:GetSyncCreate()
    return true
end

---@return string
function PvPTileAssetLandmark:GetLodPrefab(lod)
    return self:GetLodPrefabInternal(lod)
end

function PvPTileAssetLandmark:GetLodPrefabInternal()
    local uniqueId = self:GetUniqueId()
    local staticMapData = self:GetStaticMapData()
    ---@type CS.Grid.DecorationInstance
    local instance, decoration = staticMapData:GetDecorationInstance(uniqueId)
    self.position, self.rotation, self.scale = instance:GetTransform()
    -- instance.ID 
    return decoration ~= nil and decoration.PrefabName or string.Empty
end

---@return CS.UnityEngine.Vector3
function PvPTileAssetLandmark:GetPosition()
    local globalOffset = self:GetMapSystem().GlobalOffset
    return self.position + globalOffset
end

---@return CS.UnityEngine.Quaternion
function PvPTileAssetLandmark:GetRotation()
    return self.rotation
end

---@return CS.UnityEngine.Vector3
function PvPTileAssetLandmark:GetScale()
    return self.scale
end

function PvPTileAssetLandmark:GetData()
    local uniqueId = self:GetUniqueId()
    local staticMapData = self:GetStaticMapData()
    local territoryId = staticMapData:GetExtensionTerritoryID(uniqueId)
    local entities = g_Game.DatabaseManager:GetEntitiesByType(self:GetEntityType())

    for k, v in pairs(entities) do
        if v.OccupyDropInfo.TerritoryID == territoryId then
            return v
        end
    end

    return nil
end

function PvPTileAssetLandmark:GetEntityType()
    return DBEntityType.Pass
end

return PvPTileAssetLandmark
