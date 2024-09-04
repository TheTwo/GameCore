local BaseModule = require("BaseModule")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local MapFoundation = require("MapFoundation")

local Vector2Short = CS.DragonReborn.Vector2Short
local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))

---@class MapPreloadModule : BaseModule
---@field hasChecked boolean
---@field baseMapSet
local MapPreloadModule = class("MapPreloadModule", BaseModule)

local MapConfigName = "%s_config"
local TerritoryName = "%s_territory"
local MistName = "%s_mist"
local SettingsName = "map_settings_%s"
local SymbolAtlasName = "map_symbol_atlas_%s"
local BasemapName = "mdl_%s_basemap"
local TerrainBaseMapName = "tex_symbol_basemap_%s_%s_%s"
local SymbolDecorationDistMapName = "tex_symbol_deco_distribution_%s"

local RequiredAssets =
{
    "___EmptyObstacle",
    "basic_camera_settings",
    "kingdom_placer",
    "map_creep_selector",
    "mask_all_unlocked",
    "mat_full_screen",
    "mask_circle",
    "mat_kingdom_fog_plane",
    "mat_kingdom_grid_mesh",
    "HexGridPerimeter",
}

function MapPreloadModule:OnRegister()
    self.hasChecked = false
end

function MapPreloadModule:OnRemove()
end

function MapPreloadModule:GetRequiredAssetsInLoading()
    local assetNames = HashSetString()
	assetNames:Add("map_file_name_config")
    assetNames:Add(("%s_map_atlas"):format(MapFoundation.MapName))
	assetNames:Add("troop_skill")
    return assetNames
end

function MapPreloadModule:GetRequiredAssets()
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local isNewbie = true
    
    local assetNames = HashSetString()
    local mapName = staticMapData.Prefix

    assetNames:Add(staticMapData.EmptyGround or string.Empty)
    
    --terrain assets
    --local terrainCoordList
    --if isNewbie then
    --    local pos = ModuleRefer.PlayerModule:GetCastle().MapBasics.BuildingPos
    --    local playerCoord = CS.DragonReborn.Vector2Short(KingdomMapUtils.ParseBuildingPos(pos))
    --    terrainCoordList = self:GetSurroundedTerrainIndexList(playerCoord, staticMapData)
    --else
    --    terrainCoordList = self:GetAllTerrainIndexList(staticMapData)
    --end
    --for _, coord in ipairs(terrainCoordList) do
    --    assetNames:Add(string.format(TerrainName, mapName, coord.X, coord.Y))
    --    break
    --end
    
    --decoration assets
    --local decorationNames = staticMapData:GetAllDecorationNames()
    --for i = 0, decorationNames.Count - 1 do
    --    assetNames:Add(decorationNames[i])
    --end

    local prefabName = string.format("mdl_%s_basemap", staticMapData.Prefix)
    assetNames:Add(prefabName)


    --symbol atlas
    assetNames:Add(string.format(BasemapName, mapName))
    assetNames:Add(string.format(SymbolAtlasName, mapName))
    assetNames:Add(string.format(SymbolDecorationDistMapName, mapName))

    --settings
    assetNames:Add(string.format(SettingsName, mapName))

    --misc assets
    for _, asset in ipairs(RequiredAssets) do
        assetNames:Add(asset)
    end

    return assetNames
end

---@param assetNames CS.System.Collections.Generic.HashSet<string>
function MapPreloadModule:GetRequiredFiles(assetNames)
    local fileList = g_Game.AssetManager:GetAllDependencyAssetBundlesByAssets(assetNames)

    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local mapName = staticMapData.Prefix

    --map data files
    fileList:Add(mapName)
    fileList:Add(string.format(MapConfigName, mapName))
    fileList:Add(string.format(TerritoryName, mapName))
    fileList:Add(string.format(MistName, mapName))
    self.hasChecked = true
    return fileList
end

---@param staticMapData CS.Grid.StaticMapData
function MapPreloadModule:GetAllTerrainIndexList(staticMapData)
    local terrainsPerMapX = staticMapData.TerrainsPerMapX
    local terrainsPerMapZ = staticMapData.TerrainsPerMapZ
    local result = {}
    for i = 0, terrainsPerMapX - 1 do
        for j = 0, terrainsPerMapZ - 1 do
            table.insert(result, {X = i, Y = j})
        end
    end
    return result
end

---@param coord CS.DragonReborn.Vector2Short
---@param staticMapData CS.Grid.StaticMapData
function MapPreloadModule:GetSurroundedTerrainIndexList(coord, staticMapData)
    local tilesPerTerrainX = staticMapData.TilesPerTerrainX
    local tilesPerTerrainZ = staticMapData.TilesPerTerrainZ
    local terrainX, terrainZ = KingdomMapUtils.ParseCoordinate(coord.X / tilesPerTerrainX, coord.Y / tilesPerTerrainZ)
    local nextOffsetX = coord.X % tilesPerTerrainX > tilesPerTerrainX / 2  and 1 or -1
    local nextOffsetZ = coord.Y % tilesPerTerrainZ > tilesPerTerrainZ / 2  and 1 or -1
    local terrainNextX = math.clamp(terrainX + nextOffsetX, 0, tilesPerTerrainX - 1)
    local terrainNextZ = math.clamp(terrainZ + nextOffsetZ, 0, tilesPerTerrainZ - 1)

    local result = {}
    table.insert(result, {X = terrainX, Y = terrainZ})
    if terrainNextX ~= terrainX then
        table.insert(result, {X = terrainNextX, Y = terrainZ})
    end
    if terrainNextZ ~= terrainZ then
        table.insert(result, {X = terrainX, Y = terrainNextZ})
    end
    if terrainNextX ~= terrainX and terrainNextZ ~= terrainZ then
        table.insert(result, {X = terrainNextX, Y = terrainNextZ})
    end
    return result
end

function MapPreloadModule:GetSurroundedTerrainRange(coord)

end

function MapPreloadModule:BaseMapAssetsDownloadFinished()
    --local staticMapData = KingdomMapUtils.GetStaticMapData()
    --local baseMapFirstAssetName = string.format(TerrainBaseMapName, staticMapData.Prefix, 0, 0)
    --local canLoadSync = g_Game.AssetManager:CanLoadSync(baseMapFirstAssetName)
    --if canLoadSync then
    --    if not self.baseMapSet then
    --        self.baseMapSet = HashSetString()
    --        local terrainsPerMapX = staticMapData.BaseMapsPerMapX
    --        local terrainsPerMapZ = staticMapData.BaseMapsPerMapZ
    --        for i = 0, terrainsPerMapX - 1 do
    --            for j = 0, terrainsPerMapZ - 1 do
    --                local name = string.format(TerrainBaseMapName, staticMapData.Prefix, i, j)
    --                self.baseMapSet:Add(name)
    --            end
    --        end
    --        g_Game.AssetManager:EnsureSyncLoadAssets(self.baseMapSet, false)
    --    end
    --end
    --return canLoadSync
    return true
end

function MapPreloadModule:TempDeleteMistBin()
	local staticMapData = KingdomMapUtils.GetStaticMapData()
	local binName = MistName:format(staticMapData.Prefix)
	local relativePath = ("GameAssets/Territory/%s.pack"):format(binName)
	local IOUtils = CS.DragonReborn.IOUtils
	if IOUtils.HaveGameAssetInDocument(relativePath) then
		IOUtils.DeleteGameAsset(relativePath)
	end
end


return MapPreloadModule
