local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local Color = CS.UnityEngine.Color
local MapUtils = CS.Grid.MapUtils

local PoolUsage = require("PoolUsage")
local Utils = require("Utils")
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityType = require('DBEntityType')

---@class TileHighLightMap
local TileHighLightMap = class("TileHighLightMap")

local HandleCache = {}
local HighlightColors = {
    Tile = Color(1, 0.9686, 0.5647, 0.7412)
}

---@param tile MapRetrieveResult
function TileHighLightMap.GetTileHighLightPrefab(tile)
    return "kingdom_selection_highlight"
end

---@param tile MapRetrieveResult
function TileHighLightMap.GetTileHighLightColor(tile)
    return HighlightColors.Tile
end

---@param tile MapRetrieveResult
---@param context any
function TileHighLightMap.ShowTileHighlight(tile, context)
    if tile == nil then
        return
    end

    local prefabName = TileHighLightMap.GetTileHighLightPrefab(tile)
    if string.IsNullOrEmpty(prefabName) then
        return
    end

    local handle = HandleCache[prefabName]
    if handle == nil then
        handle = PooledGameObjectHandle(PoolUsage.Map)
        HandleCache[prefabName] = handle
    end
    if Utils.IsNotNull(handle.Asset) then
        TileHighLightMap.ShowTileHighlightInternal(tile, handle.Asset)
    elseif handle.Idle then
        local mapSystem = KingdomMapUtils.GetMapSystem()
        handle:Create(prefabName, mapSystem.Parent, TileHighLightMap.LoadCallback, tile)
    end
    
    KingdomMapUtils.DirtyMapMark()
end

---@param go CS.UnityEngine.GameObject
---@param tile MapRetrieveResult
function TileHighLightMap.LoadCallback(go, tile)
    if Utils.IsNotNull(go) then
        TileHighLightMap.ShowTileHighlightInternal(tile, go)
    end
end

---@param tile MapRetrieveResult
function TileHighLightMap.HideTileHighlight(tile)
    local prefabName = TileHighLightMap.GetTileHighLightPrefab(tile)
    if string.IsNullOrEmpty(prefabName) then
        return
    end

    local handle = HandleCache[prefabName]
    if handle == nil then
        return
    end

    handle:Delete()

    KingdomMapUtils.DirtyMapMark()
end

function TileHighLightMap.HideAllHighLight()
    for _, handle in pairs(HandleCache) do
        handle:Delete()
    end
end

---@param go CS.UnityEngine.GameObject
---@param tile MapRetrieveResult
function TileHighLightMap.ShowTileHighlightInternal(tile, go)
    local sizeX = tile.sizeX
    local sizeY = tile.sizeY
    local color = TileHighLightMap.GetTileHighLightColor(tile)
    local localPosition = MapUtils.CalculateCoordToTerrainPosition(tile.X, tile.Z, KingdomMapUtils.GetMapSystem())

    go.transform.localPosition = localPosition

    local selectionHighlight = go:GetLuaBehaviour("KingdomSelectionHighlight", true)
    if nil ~= selectionHighlight then
        selectionHighlight.Instance:SetData(sizeX, sizeY, color)
    end
end

return TileHighLightMap
