local CameraConst = require('CameraConst')
local KingdomMapUtils = require('KingdomMapUtils')

local Vector3 = CS.UnityEngine.Vector3
local Bounds = CS.UnityEngine.Bounds
local ListComponent = CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Component))

---@class MapHudTransformControl
local MapHudTransformControl = class("MapHudTransformControl")
MapHudTransformControl.offsetY = Vector3.zero
MapHudTransformControl.scale = 1
MapHudTransformControl.rendererCache = ListComponent()

function MapHudTransformControl.RefreshScale(cameraSize, sizeList, scaleList)
    local cameraLodData = KingdomMapUtils.GetKingdomScene().cameraLodData
    local lod = cameraLodData.lod

    --if lod >= CameraConst.MOUNTAIN_ONLY_LOD then
    --    MapHudTransformControl.scale = 1
    --    return
    --end

    local sizeCount = sizeList.Count
    local scaleCount = scaleList.Count
    if cameraSize <= sizeList[0] then
        MapHudTransformControl.scale = scaleList[0]
        return
    elseif cameraSize >= sizeList[sizeCount - 1] then
        MapHudTransformControl.scale = scaleList[sizeCount - 1]
        return
    end

    for i = 0, sizeCount - 1 do
        local size = sizeList[i]
        if i < scaleCount - 1 and cameraSize > size then
            local t = (cameraSize - size) / (sizeList[i + 1] - size)
            local scale = math.lerp(scaleList[i], scaleList[i + 1], t)
            MapHudTransformControl.scale = scale
        end
    end
end

---@param sizeX number
---@param sizeZ number
---@param margin number
---@param staticMapData CS.Grid.StaticMapData
function MapHudTransformControl.CalculateBottomOffset(sizeX, sizeZ, margin, staticMapData)
    local offsetX = -margin - sizeX / 2
    local offsetZ = -margin - sizeZ / 2
    return Vector3(offsetX * staticMapData.UnitsPerTileX, 0, offsetZ * staticMapData.UnitsPerTileZ)
end

---@param sizeX number
---@param sizeZ number
---@param margin number
---@param staticMapData CS.Grid.StaticMapData
function MapHudTransformControl.CalculateTopOffsetBySize(sizeX, sizeZ, margin, staticMapData)
    local offsetX = sizeX / 2
    local offsetZ = sizeZ / 2
    local offsetY = sizeX
    return Vector3(offsetX * staticMapData.UnitsPerTileX, offsetY * staticMapData.UnitsPerTileX, offsetZ * staticMapData.UnitsPerTileZ)
end

---@param asset CS.UnityEngine.GameObject
function MapHudTransformControl.CalculateTopOffsetByBoundingBox(asset)
    MapHudTransformControl.rendererCache:Clear()
    asset:GetComponentsInChildrenOfType(typeof(CS.UnityEngine.MeshRenderer), MapHudTransformControl.rendererCache)
    
    local bounds = Bounds()
    bounds.center = asset.transform.position
    for i = 0, MapHudTransformControl.rendererCache.Count - 1 do
        ---@type CS.UnityEngine.Renderer
        local renderer = MapHudTransformControl.rendererCache[i]
        bounds:Encapsulate(renderer.bounds)
    end
    
    return bounds.size.y * Vector3.up + bounds.center - asset.transform.position
end

return MapHudTransformControl