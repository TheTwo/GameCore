local MapTileAssetSolo = require("MapTileAssetSolo")

---@class PvPTileAssetDecoration : MapTileAssetSolo
local PvPTileAssetDecoration = class("PvPTileAssetDecoration", MapTileAssetSolo)

function PvPTileAssetDecoration:ctor()
    MapTileAssetSolo.ctor(self)
    self.position = CS.UnityEngine.Vector3.zero
    self.rotation = CS.UnityEngine.Quaternion.identity
    self.scale = CS.UnityEngine.Vector3.one
end

---@return string
function PvPTileAssetDecoration:GetLodPrefab(lod)
    return self:GetLodPrefabInternal()
end

function PvPTileAssetDecoration:GetLodPrefabInternal()
    local uniqueId = self:GetUniqueId()
    local staticMapData = self:GetStaticMapData()
    ---@type CS.Grid.DecorationInstance
    local instance, decoration = staticMapData:GetDecorationInstance(uniqueId)
    self.position, self.rotation, self.scale = instance:GetTransform()
    return decoration ~= nil and decoration.PrefabName or string.Empty
end

---@return CS.UnityEngine.Vector3
function PvPTileAssetDecoration:GetPosition()
    local globalOffset = self:GetMapSystem().GlobalOffset
    return self.position + globalOffset
end

---@return CS.UnityEngine.Quaternion
function PvPTileAssetDecoration:GetRotation()
    return self.rotation
end

---@return CS.UnityEngine.Vector3
function PvPTileAssetDecoration:GetScale()
    return self.scale
end

return PvPTileAssetDecoration