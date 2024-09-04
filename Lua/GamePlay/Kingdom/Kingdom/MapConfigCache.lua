local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local MapBuildingSubType = require("MapBuildingSubType")
local ManualUIConst = require("ManualUIConst")

local Vector3 = CS.UnityEngine.Vector3
local Vector2Short = CS.DragonReborn.Vector2Short

---@class LandmarkSliceMetric
---@field GridSize number
---@field GridCount number
---@field StartLod number
---@field EndLod number

---@class MapConfigCache
---@field cached boolean
---@field landmarkSliceMetrics table<number,LandmarkSliceMetric>
---@field landmarkSliceData table<number,table<number, table<number>>>
---@field lodMap table<number, number>
---@field nameLut table<number, string>
---@field levelLut table<number, number>
---@field landformLut table<number, number>
---@field centerPositionLut table<number, CS.UnityEngine.Vector3>
---@field centerCoordinateLut table<number, CS.DragonReborn.Vector2Short>
---@field fixedIconPrefixLut table<number, string>
---@field fixedIconLodLut table<number, number>
---@field fixedNameLodLut table<number, number>
---@field fixedHiddenLodLut table<number, number>
---@field fixedLevelBaseLut table<number, string>
---@field fixedHideShowLut table<number, boolean>
---@field flexibleIconLodLut table<number, number>
---@field flexibleNameLodLut table<number, number>
---@field flexibleHiddenLod table<number, number>
local MapConfigCache = class("MapConfigCache")

function MapConfigCache.Initialize()
    if not MapConfigCache.cached then
        MapConfigCache.InitLandmarkSliceMetrics()
        MapConfigCache.InitLandmarkSlice()
        MapConfigCache.InitBuildingConfigLUT()
        MapConfigCache.InitTerritoryConfigLUT()
        MapConfigCache.cached = true
    end
end

function MapConfigCache.Dispose()
    MapConfigCache.landmarkSliceMetrics = nil
    MapConfigCache.landmarkSliceData = nil
    MapConfigCache.lodMap = nil
    MapConfigCache.nameLut = nil
    MapConfigCache.levelLut = nil
    MapConfigCache.landformLut = nil
    MapConfigCache.centerPositionLut = nil
    MapConfigCache.centerCoordinateLut = nil
    MapConfigCache.fixedIconPrefixLut = nil
    MapConfigCache.fixedNameLodLut = nil
    MapConfigCache.fixedHiddenLodLut = nil
    MapConfigCache.fixedLevelBaseLut = nil
    MapConfigCache.flexibleIconLodLut = nil
    MapConfigCache.flexibleNameLodLut = nil
    MapConfigCache.flexibleHiddenLod = nil
    
    MapConfigCache.cached = false
end

---@private
function MapConfigCache.InitLandmarkSliceMetrics()
    MapConfigCache.lodMap =
    {
        [4] = 1,
        [5] = 1,
        [6] = 2,
        [7] = 3,
        [8] = 3,
    }
    MapConfigCache.landmarkSliceMetrics = {}


    local staticMapData = require("KingdomMapUtils").GetStaticMapData()
    
    ---@type LandmarkSliceMetric
    local metric1 = {}
    metric1.StartLod = 4
    metric1.EndLod = 5
    metric1.GridCount = 32
    metric1.GridSize = staticMapData.TilesPerMapX / metric1.GridCount
    MapConfigCache.landmarkSliceMetrics[1] = metric1

    ---@type LandmarkSliceMetric
    local metric2 = {}
    metric2.StartLod = 6
    metric2.EndLod = 6
    metric2.GridCount = 8
    metric2.GridSize = staticMapData.TilesPerMapX / metric2.GridCount
    MapConfigCache.landmarkSliceMetrics[2] = metric2

    ---@type LandmarkSliceMetric
    local metric3 = {}
    metric3.StartLod = 7
    metric3.EndLod = 8
    metric3.GridCount = 1
    metric3.GridSize = staticMapData.TilesPerMapX / metric3.GridCount
    MapConfigCache.landmarkSliceMetrics[3] = metric3
end

---@private
function MapConfigCache.InitLandmarkSlice()
    MapConfigCache.landmarkSliceData = {}
    for lod, sliceID in pairs(MapConfigCache.lodMap) do
        local slice = MapConfigCache.landmarkSliceData[sliceID]
        if not slice then
            MapConfigCache.landmarkSliceData[sliceID] = {}
        end
    end
    
    local allTerritories = ModuleRefer.TerritoryModule:GetAllTerritories()
    for _, territoryID in ipairs(allTerritories) do
        local territoryConfig = ConfigRefer.Territory:Find(territoryID)
        local buildingConfigID = territoryConfig:VillageId()
        local pos = territoryConfig:VillagePosition()
        local tileX = pos:X()
        local tileY = pos:Y()
        
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(buildingConfigID)
        local startLod = buildingConfig:IconLod()
        local endLod = buildingConfig:HiddenLod() - 1
        for id, metric in pairs(MapConfigCache.landmarkSliceMetrics) do
            if endLod >= metric.StartLod and startLod <= metric.EndLod then
                local slice = MapConfigCache.landmarkSliceData[id]
                local gridX = math.floor(tileX / metric.GridSize)
                local gridZ = math.floor(tileY / metric.GridSize)
                local gridIndex = gridZ * metric.GridCount + gridX
                local list = slice[gridIndex]
                if not list then
                    list = {}
                    slice[gridIndex] = list
                end
                table.insert(list, territoryID)
            end
        end
    end
end

function MapConfigCache.CalculateLandmarkRange(xMin, zMin, xMax, zMax, lod)
    local sliceID = MapConfigCache.lodMap[lod]
    if not sliceID then
        return
    end

    local metric = MapConfigCache.landmarkSliceMetrics[sliceID]
    if not metric then
        return
    end

    local slice = MapConfigCache.landmarkSliceData[sliceID]
    if not slice then
        return
    end

    local gridMinX = math.floor(xMin / metric.GridSize)
    local gridMinZ = math.floor(zMin / metric.GridSize)
    local gridMaxX = math.ceil(xMax / metric.GridSize)
    local gridMaxZ = math.ceil(zMax / metric.GridSize)
    return gridMinX, gridMinZ, gridMaxX, gridMaxZ
end

---@param landmarks table<number, boolean>
function MapConfigCache.CollectLandmarks(gridMinX, gridMinZ, gridMaxX, gridMaxZ, lod, landmarks)
    local sliceID = MapConfigCache.lodMap[lod]
    if not sliceID then
        return
    end
    
    local metric = MapConfigCache.landmarkSliceMetrics[sliceID]
    if not metric then
        return
    end
    
    local slice = MapConfigCache.landmarkSliceData[sliceID]
    if not slice then
        return
    end
    
    for i = gridMinX, gridMaxX do
        for j = gridMinZ, gridMaxZ do
            local gridIndex = j * metric.GridCount + i
            local list = slice[gridIndex]
            if list then
                for _, id in ipairs(list) do
                    landmarks[id] = true
                end
            end
        end
    end
end

---@private
function MapConfigCache.InitTerritoryConfigLUT()
    MapConfigCache.nameLut = {}
    MapConfigCache.levelLut = {}
    MapConfigCache.landformLut = {}
    MapConfigCache.centerCoordinateLut = {}
    MapConfigCache.centerPositionLut = {}


    local staticMapData = require("KingdomMapUtils").GetStaticMapData()
    local allTerritories = ModuleRefer.TerritoryModule:GetAllTerritories()
    for _, territoryID in ipairs(allTerritories) do
        local config = ConfigRefer.Territory:Find(territoryID)
        if not config then
            g_Logger.Error("can't find village config! id=%s", territoryID)
        end
        local buildingConfigID = config:VillageId()
        local template = ConfigRefer.FixedMapBuilding:Find(buildingConfigID)
        if not template then
            g_Logger.Error("can't find village template config! id=%s", buildingConfigID)
        end
        
        local name = template and I18N.Get(template:Name()) or string.Empty
        MapConfigCache.nameLut[territoryID] = name
        local level = template and template:Level() or 0
        MapConfigCache.levelLut[territoryID] = level
        local landformID = config and config:LandId() or 0
        MapConfigCache.landformLut[territoryID] = landformID

        local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(template:Layout())
        local coord = config:VillagePosition()
        local tileX, tileZ = coord:X(), coord:Y()
        local centerCoord = Vector2Short(tileX, tileZ)
        MapConfigCache.centerCoordinateLut[territoryID] = centerCoord
        local x, y, z  = MapConfigCache.CalculateCenterPosition(tileX, tileZ, layout.SizeX, layout.SizeY, staticMapData)
        MapConfigCache.centerPositionLut[territoryID] = Vector3(x, y, z)
    end
end

function MapConfigCache.GetName(territoryID)
    return MapConfigCache.nameLut[territoryID] or string.Empty
end

function MapConfigCache.GetLevel(territoryID)
    return MapConfigCache.levelLut[territoryID] or 0
end

function MapConfigCache.GetLandform(territoryID)
    return MapConfigCache.landformLut[territoryID] or 0
end

---@return CS.DragonReborn.Vector2Short
function MapConfigCache.GetCenterCoordinate(territoryID)
    return MapConfigCache.centerCoordinateLut[territoryID] or nil
end

---@return CS.UnityEngine.Vector3
function MapConfigCache.GetCenterPosition(territoryID)
    return MapConfigCache.centerPositionLut[territoryID] or nil
end

---@private
function MapConfigCache.InitBuildingConfigLUT()
    MapConfigCache.fixedIconPrefixLut = {}
    MapConfigCache.fixedIconLodLut = {}
    MapConfigCache.fixedNameLodLut = {}
    MapConfigCache.fixedHiddenLodLut = {}
    MapConfigCache.fixedLevelBaseLut = {}
    MapConfigCache.fixedHideShowLut = {}
    for id, config in ConfigRefer.FixedMapBuilding:ipairs() do
        local configID = config:Id()
        MapConfigCache.fixedIconPrefixLut[configID] = config:IconPrefix()
        MapConfigCache.fixedIconLodLut[configID] = config:IconLod()
        MapConfigCache.fixedNameLodLut[configID] = config:NameLod()
        MapConfigCache.fixedHiddenLodLut[configID] = config:HiddenLod()
        MapConfigCache.fixedLevelBaseLut[configID] = config:SubType() == MapBuildingSubType.Stronghold and ManualUIConst.sp_comp_base_lv_3 or ManualUIConst.sp_comp_base_lv_village
        MapConfigCache.fixedHideShowLut[configID] = config:HideShow()
    end

    MapConfigCache.flexibleIconLodLut = {}
    MapConfigCache.flexibleNameLodLut = {}
    MapConfigCache.flexibleHiddenLod = {}
    for id, config in ConfigRefer.FlexibleMapBuilding:ipairs() do
        local configID = config:Id()
        MapConfigCache.flexibleIconLodLut[configID] = config:IconLod()
        MapConfigCache.flexibleNameLodLut[configID] = config:NameLod()
        MapConfigCache.flexibleHiddenLod[configID] = config:HiddenLod()
    end
end

function MapConfigCache.GetFixedIconPrefix(configID)
    return MapConfigCache.fixedIconPrefixLut[configID] or "sp_icon_slg_village_lv1_"
end

function MapConfigCache.GetFixedLevelBase(configID)
    return MapConfigCache.fixedLevelBaseLut[configID] or ManualUIConst.sp_comp_base_lv_3
end

function MapConfigCache.GetFixedIconLod(configID)
    return MapConfigCache.fixedIconLodLut[configID] or 0
end

function MapConfigCache.GetFixedNameLod(configID)
    return MapConfigCache.fixedNameLodLut[configID] or 0
end

function MapConfigCache.GetFixedHiddenLod(configID)
    return MapConfigCache.fixedHiddenLodLut[configID] or 0
end

function MapConfigCache.GetFixedHideShow(configID)
    return MapConfigCache.fixedHideShowLut[configID]
end

function MapConfigCache.GetFlexibleIconLod(configID)
    return MapConfigCache.flexibleIconLodLut[configID] or 0
end

function MapConfigCache.GetFlexibleNameLod(configID)
    return MapConfigCache.flexibleNameLodLut[configID] or 0
end

function MapConfigCache.GetFlexibleHiddenLod(configID)
    return MapConfigCache.flexibleHiddenLod[configID] or 0
end

---@param staticMapData CS.Grid.StaticMapData
function MapConfigCache.CalculateCenterPosition(x, y, sizeX, sizeY, staticMapData)
    local posX = (x + sizeX / 2) * staticMapData.UnitsPerTileX
    local posZ = (y + sizeY / 2) * staticMapData.UnitsPerTileZ
    return posX, 0, posZ
end


return MapConfigCache