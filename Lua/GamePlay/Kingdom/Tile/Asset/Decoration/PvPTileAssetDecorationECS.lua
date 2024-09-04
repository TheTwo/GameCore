local MapTileAssetSoloECS = require("MapTileAssetSoloECS")

local Zero = CS.Unity.Mathematics.float3(0, 0, 0)
local One = CS.Unity.Mathematics.float3(1, 1, 1)
local Identity = CS.Unity.Mathematics.quaternion

---@class PvPTileAssetDecorationECS : MapTileAssetSoloECS
local PvPTileAssetDecorationECS = class("PvPTileAssetDecorationECS", MapTileAssetSoloECS)

function PvPTileAssetDecorationECS:ctor()
    MapTileAssetSoloECS.ctor(self)
    self.position = Zero
    self.rotation = Identity
    self.scale = One
end

---@return string
function PvPTileAssetDecorationECS:GetLodPrefab(lod)
    return self:GetLodPrefabInternal()
end

function PvPTileAssetDecorationECS:GetLodPrefabInternal()
    local uniqueId = self:GetUniqueId()
    local staticMapData = self:GetStaticMapData()
    ---@type CS.Grid.DecorationInstance
    local instance = staticMapData:GetInstanceRef(uniqueId)
    self.position, self.rotation, self.scale = instance:GetTransformECS()
    local decoration = staticMapData:GetDecoration(instance.ID)
    return decoration ~= nil and decoration.PrefabName or string.Empty
end

---@return CS.Unity.Mathematics.float3
function PvPTileAssetDecorationECS:GetPosition()
    local globalOffset = self:GetMapSystem().GlobalOffsetBurst
    return self.position + globalOffset
end

---@return CS.Unity.Mathematics.quaternion
function PvPTileAssetDecorationECS:GetRotation()
    return self.rotation
end

---@return CS.Unity.Mathematics.float3
function PvPTileAssetDecorationECS:GetScale()
    return self.scale
end

function MapTileAssetSoloECS:GetSyncCreate()
    return true
end

return PvPTileAssetDecorationECS