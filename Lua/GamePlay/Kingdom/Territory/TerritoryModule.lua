local BaseModule = require("BaseModule")
local DBEntityType = require("DBEntityType")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ObjectType = require("ObjectType")
local DBEntityPath = require("DBEntityPath")
local KingdomConstant = require("KingdomConstant")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local OnChangeHelper = require("OnChangeHelper")
local MapFoundation = require("MapFoundation")
local VillageType = require('VillageType')
local ColorConsts = require('ColorConsts')
local TerritoryDisplayMode = require("TerritoryDisplayMode")
local TerritoryCommunicationType = require("TerritoryCommunicationType")
local ConfigTimeUtility = require("ConfigTimeUtility")
local Layers = require("Layers")
local I18N = require("I18N")

local TerritorySystem = CS.Territory.TerritorySystem
local HashSetInt32 = CS.System.Collections.Generic.HashSet(typeof(CS.System.Int32))
local DictInt32Int32 = CS.System.Collections.Generic.Dictionary(typeof(CS.System.Int32), typeof(CS.System.Int32))
local DictInt32Color = CS.System.Collections.Generic.Dictionary(typeof(CS.System.Int32), typeof(CS.UnityEngine.Color))
local MapUtils = CS.Grid.MapUtils
local Vector3 = CS.UnityEngine.Vector3
local Vector2Short = CS.DragonReborn.Vector2Short
local LayerMask = CS.UnityEngine.LayerMask

---@class TerritoryModule : BaseModule
---@field territorySystem CS.Territory.TerritorySystem
---@field mapSystem CS.Grid.MapSystem
---@field settings CS.Territory.MapTerritorySettings
---@field drawMode number
---@field mapTerritoryIDs number[]
---@field creepPaletteForMesh table<number, CS.System.Collections.Generic.HashSet(typeof(CS.System.Int32))>
---@field creepPalette CS.System.Collections.Generic.HashSet(typeof(CS.System.Int32)
---@field occupyPalette CS.System.Collections.Generic.Dictionary(typeof(CS.System.Int32), typeof(CS.System.Int32))
---@field occupyColorMap CS.System.Collections.Generic.Dictionary(typeof(CS.System.Int32), typeof(CS.UnityEngine.Color))
---@field dirtyDistricts table<number>
---@field dirtyTerritories table<number>
---@field lowLodDataChanged boolean
---@field highLodDataChanged boolean
---@field allianceBuildingDataChanged boolean
---@field allianceVillageNeighborCache table<number, number>
---@field districtEntries table<number, number>
local TerritoryModule = class("TerritoryModule", BaseModule)


function TerritoryModule:OnRegister()
    self.territorySystem = TerritorySystem()
    self.territorySystem:SetupData(KingdomMapUtils.GetStaticMapData(), KingdomMapUtils.GetMapSystem().GlobalOffset)
    self.creepPalette = HashSetInt32()
    self.occupyPalette = DictInt32Int32()
    self.allianceVillageNeighborCache = {}

    self.dirtyDistricts = {} --for creep mesh generation
    self.dirtyTerritories = {} --for cleaned areas
    self.creepPaletteForMesh = {}
    self:InitOccupyColorMap()
    self:InitDistrictEntries()
end

function TerritoryModule:OnRemove()
    table.clear(self.creepPaletteForMesh)
    self.mapTerritoryIDs = nil
    self.creepPaletteForMesh = nil
    self.creepPalette = nil
    self.occupyPalette = nil
    self.territorySystem:ReleaseData()
    self.territorySystem = nil
    self.mapSystem = nil
    self.allianceVillageNeighborCache = nil
end

function TerritoryModule:SetupView()
    self.mapSystem = KingdomMapUtils.GetMapSystem()
    self.settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Territory.MapTerritorySettings))

    self.territorySystem:SetupView(self.settings, KingdomMapUtils.GetMapSystem().Parent, MapFoundation.HideObject)
    self.territorySystem:SetTerritoryPalette(self.occupyPalette, self.occupyColorMap)
    self.territorySystem:SetTerritoryLayer(Layers.Tile)
    self.territorySystem:SetDistrictLayer(Layers.MapAboveFog)
    self.territorySystem:SetDistrictBorderSortingOrder(100)
    self.territorySystem:SetTerritoryNeutralColor(self.settings.TerritoryNeutralColor)
    self.territorySystem:SetDistrictNeutralColor(self.settings.DistrictBorderColor)
    self.territorySystem:SetCreepLod(self.settings.CreepStartLod, self.settings.CreepEndLod)
    self.territorySystem:SetTerritoryLod(self.settings.TerritoryBorderStartLod, self.settings.TerritoryBorderEndLod, self.settings.TerritoryAreaStartLod, self.settings.TerritoryAreaEndLod)
    self.territorySystem:SetDistrictLod(self.settings.DistrictBorderStartLod, self.settings.DistrictBorderEndLod)

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Village, Delegate.GetOrCreate(self, self.OnVillageAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Village, Delegate.GetOrCreate(self, self.OnVillageRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Village.MsgPath, Delegate.GetOrCreate(self, self.OnVillageChanged))

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Pass, Delegate.GetOrCreate(self, self.OnPassAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Pass, Delegate.GetOrCreate(self, self.OnPassRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Pass.OccupyDropInfo.MsgPath, Delegate.GetOrCreate(self, self.OnPassChanged))

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.BehemothCage, Delegate.GetOrCreate(self, self.OnCageAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.BehemothCage, Delegate.GetOrCreate(self, self.OnCageRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.BehemothCage.OccupyDropInfo.MsgPath, Delegate.GetOrCreate(self, self.OnCageChanged))

    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnMapEntityAdded))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnMapEntityRemoved))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnMapEntityChanged))

    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBuildingChanged))

    g_Game.EventManager:AddListener(EventConst.ON_LOW_MEMORY, Delegate.GetOrCreate(self, self.OnLowMemory))
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_TRANSITION_START_AFTER_CAPTURE, Delegate.GetOrCreate(self, self.OnKingdomTransitionEnd))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))

    self:InitCreepPalette()
    self:RefreshAllianceVillageNeighborCache()
    self:OnLodChanged(0, KingdomMapUtils.GetLOD())

    self:DirtyAllCreepPalette()
    self:HideCreepAreas()
end

function TerritoryModule:ReleaseView()
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Village, Delegate.GetOrCreate(self, self.OnVillageAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Village, Delegate.GetOrCreate(self, self.OnVillageRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Village.MsgPath, Delegate.GetOrCreate(self, self.OnVillageChanged))

    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Pass, Delegate.GetOrCreate(self, self.OnPassAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Pass, Delegate.GetOrCreate(self, self.OnPassRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Pass.OccupyDropInfo.MsgPath, Delegate.GetOrCreate(self, self.OnPassChanged))

    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.BehemothCage, Delegate.GetOrCreate(self, self.OnCageAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.BehemothCage, Delegate.GetOrCreate(self, self.OnCageRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.BehemothCage.OccupyDropInfo.MsgPath, Delegate.GetOrCreate(self, self.OnCageChanged))

    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnMapEntityAdded))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.MapEntityInfos, Delegate.GetOrCreate(self, self.OnMapEntityRemoved))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapEntityInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnMapEntityChanged))

    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBuildingChanged))

    g_Game.EventManager:RemoveListener(EventConst.ON_LOW_MEMORY, Delegate.GetOrCreate(self, self.OnLowMemory))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_TRANSITION_START_AFTER_CAPTURE, Delegate.GetOrCreate(self, self.OnKingdomTransitionEnd))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))

    self.creepPalette:Clear()
    self.occupyPalette:Clear()
    self.territorySystem:ReleaseView()
    
    self.settings = nil
end

function TerritoryModule:Tick()
    if not self.territorySystem then
        return
    end
    
    if self.lowLodDataChanged or self.highLodDataChanged then
        self.lowLodDataChanged = false
        self.highLodDataChanged = false

        self:RefreshPalette()
        --if table.nums(self.dirtyDistricts) > 0 then
        --    self:RefreshCreepPalette()
        --    table.clear(self.dirtyDistricts)
        --end
        if table.nums(self.dirtyTerritories) > 0 then
            self.mapSystem:SetCleanedTerritories(self.dirtyTerritories)
            table.clear(self.dirtyTerritories)
        end
        g_Game.EventManager:TriggerEvent(EventConst.TERRITORY_OCCUPY_CHANGED)
    end

    if self.allianceBuildingDataChanged then
        self.allianceBuildingDataChanged = false
        self:RefreshAllianceVillageNeighborCache()
    end

    self.territorySystem:Tick()
    
    local mapSystem = KingdomMapUtils.GetMapSystem()
    local cameraBox = KingdomMapUtils.GetCameraBox()
    self.territorySystem:Cull(cameraBox, mapSystem.Lod, false)
end

function TerritoryModule:ShowTerritory()
    local layer = KingdomMapUtils.InSymbolMapLod() and Layers.SymbolMap or Layers.Tile
    self.territorySystem:SetTerritoryLayer(layer)
end

function TerritoryModule:HideTerritory()
    local layer = KingdomMapUtils.InSymbolMapLod() and Layers.Tile or Layers.SymbolMap
    self.territorySystem:SetTerritoryLayer(layer)
end

---@return CS.System.Collections.Generic.Dictionary(typeof(CS.System.Int32), typeof(CS.System.Int32))
function TerritoryModule:GetOccupiedPalette()
    return self.occupyPalette
end

---@param territoryID number
---@param colorIndex number
function TerritoryModule:SetOccupyPalette(territoryID, colorIndex)
    if colorIndex and colorIndex > 0 then
        self.occupyPalette[territoryID] = colorIndex
    else
        self.occupyPalette:Remove(territoryID)
    end
end

function TerritoryModule:RefreshPalette()
    self.territorySystem:SetTerritoryPalette(self.occupyPalette, self.occupyColorMap)
end

---@param mode number
---@param lod number
function TerritoryModule:SetDrawMode(mode, lod)
    if self.drawMode == mode then return end

    if not lod then
        lod = self.mapSystem.Lod
    end
    
    self.drawMode = mode
    if mode == TerritoryDisplayMode.SymbolMap then
        self.territorySystem:SetTerritoryLayer(Layers.SymbolMap)
        self.territorySystem:SetDrawMode(true   , true, true, false, lod)
    else
        self.territorySystem:SetTerritoryLayer(Layers.Tile)
        self.territorySystem:SetDrawMode(true, false, false, false, lod)
    end
    self:RefreshPalette()

    local mapSystem = KingdomMapUtils.GetMapSystem()
    self.territorySystem:Cull(mapSystem.CameraBox, mapSystem.Lod, true)
end

function TerritoryModule:InitOccupyColorMap()
    if not self.occupyColorMap then
        self.occupyColorMap = DictInt32Color()
        for i, config in ConfigRefer.AllianceTerritoryColor:ipairs() do
            local id = config:Id()
            local color = ModuleRefer.AllianceModule:GetTerritoryColor(id)
            self.occupyColorMap:Add(id, color)
        end
    end
end

function TerritoryModule:InitCreepPalette()
    self.creepPalette:Clear()
    for id, set in pairs(self.creepPaletteForMesh)do
        if set then
            set:Clear()
        end
    end
    local allTerritories = self:GetAllTerritories()
    for _, territoryID in ipairs(allTerritories) do
        local territoryConfig = ConfigRefer.Territory:Find(territoryID)
        local districtID = territoryConfig:DistrictId()
        local set = self.creepPaletteForMesh[districtID]
        if not set then
            set = HashSetInt32()
            self.creepPaletteForMesh[districtID] = set
        end
        set:Add(territoryID)
        self.creepPalette:Add(territoryID)
    end
end

function TerritoryModule:DirtyAllCreepPalette()
    table.clear(self.dirtyDistricts)
    for _, config in ConfigRefer.District:ipairs() do
        self.dirtyDistricts[config:Id()] = true
    end
end

function TerritoryModule:ShowCreepAreas()
    local layer = KingdomMapUtils.InSymbolMapLod() and Layers.SymbolMap or Layers.Tile
    self.territorySystem:SetCreepLayer(layer)
end

function TerritoryModule:HideCreepAreas()
    local layer = KingdomMapUtils.InSymbolMapLod() and Layers.Tile or Layers.SymbolMap
    self.territorySystem:SetCreepLayer(layer)
end

---@return boolean
function TerritoryModule:CheckHasCreep(territoryID)
    return self.creepPalette:Contains(territoryID)
end

---@param entity wds.Village|wds.BehemothCage|wds.Pass|{MapStates:{StateWrapper2:{CreepInfected:boolean}}}
function TerritoryModule:SetCreepPaletteByEntity(territoryID, entity)
    if not KingdomMapUtils.IsMapEntityCreepInfected(entity) then
        self:SetCreepPalette(territoryID)
    end
end

---@param brief wds.MapEntityBrief
function TerritoryModule:SetCreepPaletteByBrief(territoryID, brief)
    if not KingdomMapUtils.IsMapEntityBriefCreepInfected(brief) then
        self:SetCreepPalette(territoryID)
    end
end

---@param territoryID number
function TerritoryModule:SetCreepPalette(territoryID)
    if self.creepPalette:Contains(territoryID) then
        self.creepPalette:Remove(territoryID)

        local config = ConfigRefer.Territory:Find(territoryID)
        if config then
            local districtID = config:DistrictId()
            local set = self.creepPaletteForMesh[districtID]
            if set and set:Contains(territoryID) then
                set:Remove(territoryID)
                self.dirtyDistricts[districtID] = true
                self.dirtyTerritories[territoryID] = true
            end
        end
    end
end

function TerritoryModule:RefreshCreepPalette()
    for id, _ in pairs(self.dirtyDistricts) do
        local districtIdSet = self.creepPaletteForMesh[id]
        if districtIdSet then
            self.territorySystem:SetCreepPalette(id, districtIdSet)
        end
    end
end

function TerritoryModule:OnLowMemory()
    if self.territorySystem then
        self.territorySystem:OnLowMemory()
    end
end

function TerritoryModule:OnLodChanged(oldLod, newLod)
    if not self.settings then
        return
    end
    
    local thicknessMap = self.settings.LineThickness
    local index = math.clamp(newLod, 0, thicknessMap.Count - 1)
    local thickness = thicknessMap[index];
    self.territorySystem:SetTerritoryLineThickness(thickness, self.settings.TerritoryLineMultiplier)
    self.territorySystem:SetDistrictLineThickness(thickness, self.settings.DistrictLineMultiplier)

    local inSymbolLod = KingdomMapUtils.InSymbolMapLod(newLod)
    local drawMode
    if inSymbolLod then
        drawMode = TerritoryDisplayMode.SymbolMap
    else
        drawMode = TerritoryDisplayMode.NormalMap
    end
    self:SetDrawMode(drawMode, newLod)
end

function TerritoryModule:OnKingdomTransitionEnd()
    local mapSystem = KingdomMapUtils.GetMapSystem()
    self.territorySystem:Cull(mapSystem.CameraBox, mapSystem.Lod, true)
end

---@return number[]
function TerritoryModule:GetAllTerritories()
    if not self.mapTerritoryIDs then
        local staticMapData = KingdomMapUtils.GetStaticMapData()
        self.mapTerritoryIDs = {}
        for _, territoryConfig in ConfigRefer.Territory:ipairs() do
            if territoryConfig:Version() == staticMapData.Version then
                table.insert(self.mapTerritoryIDs, territoryConfig:Id())
            end
        end
    end
    return self.mapTerritoryIDs
end

function TerritoryModule:GetTerritoryAt(tileX, tileZ)
    local territoryID, _ = self.territorySystem:GetTerritoryIdAt(tileX, tileZ)
    return territoryID;
end

---@return CS.UniityEngine.Vector3
function TerritoryModule:GetDistrictCenter(districtID)
    local pos = self.territorySystem:GetDistrictCenter(districtID)
    return MapUtils.CalculateWorldPositionToCoord(pos, KingdomMapUtils.GetStaticMapData())
end

function TerritoryModule:GetDistrictAt(tileX, tileZ)
    return self.territorySystem:GetDistrictIdAt(tileX, tileZ)
end

---@return CS.DragonReborn.Range2Int
function TerritoryModule:GetDistrictRange(id)
    return self.territorySystem:GetDistrictRange(id)
end

-----@param tileX number
-----@param tileZ number
function TerritoryModule:GetCalculatedDistrictAt(tileX, tileZ)
   local districtID = self.territorySystem:GetDistrictIdAt(tileX, tileZ)
   local baseID = KingdomMapUtils.GetStaticMapData():GetBaseId()
   return districtID - baseID
end

---@return number @LandConfigCell Id
function TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
    local _, ringLevel = self.territorySystem:GetTerritoryIdAt(tileX, tileZ)
    return ModuleRefer.LandformModule:GetIdFromIndex(ringLevel)
end

---@param startCoord CS.DragonReborn.Vector3Short
---@param endCoord CS.DragonReborn.Vector3Short
---@param list CS.DragonReborn.Vector3Short[]
function TerritoryModule:GetDistinctLandforms(startCoord, endCoord, list)
    if not list or not startCoord or not endCoord then
        return
    end
    local lerpCount = 100
    self.territorySystem:GetDistinctLandforms(startCoord, endCoord, lerpCount, list)
end

---@return number[]
function TerritoryModule:GetOpenedDistrictsForMe(startDistrictID)
    ---@type table<number, MapDistrictNeighborConfigCell>
    local districts = {}
    for _, district in ConfigRefer.MapDistrictNeighbor:ipairs() do
        districts[district:DistrictId()] = district
    end
    local entries = {}
    for _, district in ConfigRefer.MapDistrictNeighbor:ipairs() do
        local entry = district:DistrictEntry() == 0 or ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(district:DistrictEntry())
        entries[district:DistrictId()] = entry
    end
    
    ---@type number[]
    local openedDistricts = {}
    
    local startDistrict = districts[startDistrictID]
    if not startDistrict then
        return openedDistricts
    end
    
    ---@type MapDistrictNeighborConfigCell[]
    local pendingDistricts = {}
    table.insert(pendingDistricts, startDistrict)
    districts[startDistrict:DistrictId()] = nil
    table.insert(openedDistricts, startDistrict:DistrictId())
    
    while #pendingDistricts > 0 do
        local district = table.remove(pendingDistricts)
        for i = 1, district:DistrictNeighborsLength() do
            local neighborID = district:DistrictNeighbors(i)
            local neighborDistrict = districts[neighborID]
            if neighborDistrict and entries[neighborID]  then
                table.insert(pendingDistricts, neighborDistrict)
                districts[neighborID] = nil
                table.insert(openedDistricts, neighborDistrict:DistrictId())
            end
        end
    end
    return openedDistricts
end

---判断坐标是否在自己的通讯范围内
function TerritoryModule:IsInCommunicationArea(tileX, tileZ)
    --if self.communicationPalette then
    --    local territoryID = self:GetTerritoryAt(tileX, tileZ)
    --    return self.communicationPalette:ContainsKey(territoryID)
    --end
    return false
end

---@param territoryA number
---@param territoryB number
---@return boolean
function TerritoryModule:IsTerritoryConnected(territoryA, territoryB)
    local configA = ConfigRefer.Territory:Find(territoryA)
    if configA then
        local length = configA:NeighborListLength()
        for i = 1, length do
            local neighborID = configA:NeighborList(i)
            if neighborID == territoryB then
                local configB = ConfigRefer.Territory:Find(territoryB)
                if configB:DistrictId() == configA:DistrictId() then
                    return true
                end
            end
        end
    end
    return false
end

---@param ID number
---@return boolean
function TerritoryModule:IsEntityConnected(ID, entityType)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false
    end
    local entity = g_Game.DatabaseManager:GetEntity(ID, entityType)

    if entityType == DBEntityType.Village then
        return self.allianceVillageNeighborCache and entity and self.allianceVillageNeighborCache[entity.Village.VID] ~= nil
    elseif entityType == DBEntityType.Pass then
        return self.allianceVillageNeighborCache and entity and self.allianceVillageNeighborCache[entity.OccupyDropInfo.TerritoryID] ~= nil
    elseif entityType == DBEntityType.BehemothCage then
        return self.allianceVillageNeighborCache and entity and self.allianceVillageNeighborCache[entity.BehemothCage.VID] ~= nil
    end
end

function TerritoryModule:RefreshAllianceVillageNeighborCache()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end

    table.clear(self.allianceVillageNeighborCache)

    local buildings = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for _, brief in pairs(buildings) do
        local territoryConfig = ConfigRefer.Territory:Find(brief.VID)
        if territoryConfig then
            local length = territoryConfig:NeighborListLength()
            for i = 1, length do
                local neighborTerritoryID = territoryConfig:NeighborList(i)
                local neighborTerritoryConfig = ConfigRefer.Territory:Find(neighborTerritoryID)
                if neighborTerritoryConfig:VillageType() == VillageType.Village or neighborTerritoryConfig:VillageType() == VillageType.BehemothCage then
                    if neighborTerritoryConfig:DistrictId() == territoryConfig:DistrictId() then
                        self.allianceVillageNeighborCache[neighborTerritoryID] = neighborTerritoryID
                    end
                elseif neighborTerritoryConfig:VillageType() == VillageType.Gate then
                    self.allianceVillageNeighborCache[neighborTerritoryID] = neighborTerritoryID
                end
            end
        end
    end
end

function TerritoryModule:GetNeutralColor()
    return self.settings.TerritoryNeutralColor
end

---@param coord CS.DragonReborn.Vector2Short
---@param villageLevel number
---@param filter fun(vx,vy,level,territoryConfig:TerritoryConfigCell,villageConfig:FixedMapBuildingConfigCell):boolean
---@return CS.UnityEngine.Vector3,number,number|nil,number|nil @pos,id,vx,vy
function TerritoryModule:GetNearestTerritoryPosition(coord, villageLevel, filter)
    if not coord then
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local pos = castle.MapBasics.BuildingPos
        coord = Vector2Short(KingdomMapUtils.ParseBuildingPos(pos))
    end
    filter = filter or function(vx,vy,level,territoryConfig,villageConfig)
        return ModuleRefer.MapFogModule:IsFogUnlocked(vx, vy) and (villageLevel == 0 or level == villageLevel)
    end
    local list = self.territorySystem:GetSortedTerritoryIDList(coord)
    for i = 0, list.Count - 1 do
        local id = list[i]
        local territoryConfig = ConfigRefer.Territory:Find(id)
        if not territoryConfig then goto continue end
        local villagePos = territoryConfig:VillagePosition()
        local vx = villagePos:X()
        local vy = villagePos:Y()
        local villageConfig = ConfigRefer.FixedMapBuilding:Find(territoryConfig:VillageId())
        if not villageConfig:HideShow() then
            if filter(vx,vy,villageConfig:Level(), territoryConfig, villageConfig) then
                local position = MapUtils.CalculateCoordToTerrainPosition(vx, vy, KingdomMapUtils.GetMapSystem())
                return position, id, vx, vy
            end
        end
        ::continue::
    end
    return Vector3.zero, 0, nil, nil
end

function TerritoryModule:GetTerritoryNeighbors(territoryID)
    local ListInt32 = CS.System.Collections.Generic.List(typeof(CS.System.Int32))
    local list = ListInt32()
    self.territorySystem:GetTerritoryNeighbors(territoryID, list)
    local log = string.Empty
    for i = 0, list.Count - 1 do
        log = log .. tostring(list[i]) .. "\n"
    end
    g_Logger.Log(log)
end

function TerritoryModule:GetTerritoryGrids(territoryId)
end

function TerritoryModule:InitDistrictEntries() 
    if not self.districtEntries then
        local staticMapData = KingdomMapUtils.GetStaticMapData()
        local baseID = staticMapData:GetBaseId()
        
        self.districtEntries = {}
        for _, config in ConfigRefer.MapDistrict:ipairs() do
            for i = 1, config:DistrictListLength() do
                local districtID = config:DistrictList(i) + baseID
                self.districtEntries[districtID] = config:UnlockMistPreCond()
            end
        end
    end
end

function TerritoryModule:GetDistrictOpenTime(districtID)
    local entryID = self.districtEntries[districtID]
    if entryID then
        local entry = ConfigRefer.SystemEntry:Find(entryID)
        if entry then
            local openTime = ConfigTimeUtility.NsToSeconds(entry:UnlockServerOpenTime())
            openTime = openTime +  ModuleRefer.KingdomModule:GetKingdomTime()
            return openTime
        end
    end
    return 0
end

function TerritoryModule:IsDistrictOpened(districtID)
    local districtOpenTime = self:GetDistrictOpenTime(districtID)
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    return serverTime > districtOpenTime
end

---@param request CS.Territory.TerritoryMeshRequest
function TerritoryModule:GenerateTerritoryMesh(request)
    self.territorySystem:GenerateTerritoryMesh(request)
end

function TerritoryModule:CancelTerritoryMesh()
    self.territorySystem:CancelTerritoryMesh()
end

---@param go CS.UnityEngine.GameObject
function TerritoryModule:DestroyTerritoryMesh(go)
    self.territorySystem:DestroyTerritoryMesh(go)
end

function TerritoryModule:GetDistrictName(id)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local id = id + staticMapData:GetBaseId()
    local districtConfig = ConfigRefer.District:Find(id)
    if districtConfig then
        return I18N.Get(districtConfig:DistrictName())
    end
    return string.Empty
end

function TerritoryModule:CheckAllianceTerritoryMeetLandform(landformConfigID)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false
    end
    
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData then
        return false
    end
    local buildingBriefs = allianceData.MapBuildingBriefs.MapBuildingBriefs
    for _, brief in pairs(buildingBriefs) do
        local territoryID = brief.VID
        local territoryConfig = ConfigRefer.Territory:Find(territoryID)
        if territoryConfig:LandId() == landformConfigID then
            return true
        end
    end
end

----------------------------------------------------
------------------Data Listeners--------------------
----------------------------------------------------

function TerritoryModule:OnAllianceBuildingChanged(entity, changeTable)
    local add, remove, changed = OnChangeHelper.GenerateMapFieldChangeMap(changeTable)
    local villageType = wds.Village.TypeHash
    local passType = wds.Pass.TypeHash

    if add then
        ---@param brief wds.MapBuildingBrief
        for _, brief in pairs(add) do
            if brief.EntityTypeHash == villageType or brief.EntityTypeHash == passType  then
                self.allianceBuildingDataChanged = true
            end
        end
    end
    if remove then
        ---@param brief wds.MapBuildingBrief
        for _, brief in pairs(remove) do
            if brief.EntityTypeHash == villageType or brief.EntityTypeHash == passType then
                self.allianceBuildingDataChanged = true
            end
        end
    end
    if changed then
        ---@param brief wds.MapBuildingBrief
        for _, brief in pairs(changed) do
            if brief[1].EntityTypeHash == villageType or brief[2].EntityTypeHash == villageType
                    or brief[1].EntityTypeHash == passType or brief[2].EntityTypeHash == passType then
                self.allianceBuildingDataChanged = true
            end
        end
    end
end

---@param entity wds.Village
function TerritoryModule:OnVillageAdded(typeID, entity)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local villageInfo = entity.Village
    self:SetOccupyPalette(villageInfo.VID, villageInfo.TerritoryColor)
    self:SetCreepPaletteByEntity(villageInfo.VID, entity)
    self.lowLodDataChanged = true
end

---@param entity wds.Village
function TerritoryModule:OnVillageRemoved(typeID, entity)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local villageInfo = entity.Village
    self:SetOccupyPalette(villageInfo.VID, villageInfo.TerritoryColor)
    self.lowLodDataChanged = true
end

---@param entity wds.VillageInfo
function TerritoryModule:OnVillageChanged(entity, change)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local villageInfo = entity.Village
    self:SetOccupyPalette(villageInfo.VID, villageInfo.TerritoryColor)
    self:SetCreepPaletteByEntity(villageInfo.VID, entity)
    self.lowLodDataChanged = true
end


---@param entity wds.Pass
function TerritoryModule:OnPassAdded(typeID, entity)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local info = entity.OccupyDropInfo
    self:SetOccupyPalette(info.TerritoryID, info.TerritoryColor)
    self:SetCreepPaletteByEntity(info.TerritoryID, entity)
    self.lowLodDataChanged = true
end

---@param entity wds.Pass
function TerritoryModule:OnPassRemoved(typeID, entity)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local info = entity.OccupyDropInfo
    self:SetOccupyPalette(info.TerritoryID, info.TerritoryColor)
    self.lowLodDataChanged = true
end

---@param entity wds.Pass
function TerritoryModule:OnPassChanged(entity, change)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local info = entity.OccupyDropInfo
    self:SetOccupyPalette(info.TerritoryID, info.TerritoryColor)
    self:SetCreepPaletteByEntity(info.TerritoryID, entity)
    self.lowLodDataChanged = true
end

---@param entity wds.BehemothCage
function TerritoryModule:OnCageAdded(typeID, entity)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local info = entity.OccupyDropInfo
    self:SetOccupyPalette(info.TerritoryID, info.TerritoryColor)
    self:SetCreepPaletteByEntity(info.TerritoryID, entity)
    self.lowLodDataChanged = true
end

---@param entity wds.BehemothCage
function TerritoryModule:OnCageRemoved(typeID, entity)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local info = entity.OccupyDropInfo
    self:SetOccupyPalette(info.TerritoryID, info.TerritoryColor)
    self.lowLodDataChanged = true
end

---@param entity wds.BehemothCage
function TerritoryModule:OnCageChanged(entity, change)
    if KingdomMapUtils.InMapKingdomLod() then
        return
    end
    local info = entity.OccupyDropInfo
    self:SetOccupyPalette(info.TerritoryID, info.TerritoryColor)
    self:SetCreepPaletteByEntity(info.TerritoryID, entity)
    self.lowLodDataChanged = true
end


---@param entity wds.MapEntityInfos
function TerritoryModule:OnMapEntityAdded(typeId, entity)
    if entity.BasicInfo.Lod ~= KingdomMapUtils.GetServerLOD() then
        return
    end

    ---@param brief wds.MapEntityBrief
    for _, brief in pairs(entity.Infos.Briefs) do
        if (brief.ObjectType == ObjectType.SlgVillage or brief.ObjectType == ObjectType.Pass) and brief.VID > 0 then
            self:SetOccupyPalette(brief.VID, brief.TerritoryColor)
            self:SetCreepPaletteByBrief(brief.VID, brief)
        end
    end
    self.highLodDataChanged = true
end

---@param entity wds.MapEntityInfos
function TerritoryModule:OnMapEntityRemoved(typeId, entity)
    if entity.BasicInfo.Lod ~= KingdomMapUtils.GetServerLOD() then
        return
    end

    ---@param brief wds.MapEntityBrief
    for _, brief in pairs(entity.Infos.Briefs) do
        if (brief.ObjectType == ObjectType.SlgVillage or brief.ObjectType == ObjectType.Pass) and brief.VID > 0 then
            self:SetOccupyPalette(brief.VID, brief.TerritoryColor)
        end
    end
    self.highLodDataChanged = true
end

---@param entity wds.MapEntityInfos
function TerritoryModule:OnMapEntityChanged(entity)
    if entity.BasicInfo.Lod ~= KingdomMapUtils.GetServerLOD() then
        return
    end

    ---@param brief wds.MapEntityBrief
    for _, brief in pairs(entity.Infos.Briefs) do
        if (brief.ObjectType == ObjectType.SlgVillage or brief.ObjectType == ObjectType.Pass) and brief.VID > 0 then
            self:SetOccupyPalette(brief.VID, brief.TerritoryColor)
            self:SetCreepPaletteByBrief(brief.VID, brief)
        end
    end
    self.highLodDataChanged = true
end

function TerritoryModule:OnDrawGizmos()
    self.territorySystem:OnDrawGizmos()
end

---@private
function TerritoryModule:TestOccupyVillage(territoryIDList)
    self.lowLodDataChanged = true
    self.highLodDataChanged = true
    for _, str in ipairs(territoryIDList) do
        local territoryID = tonumber(str)
        self.dirtyTerritories[territoryID] = true
        self.creepPalette:Remove(territoryID)
    end
end

return TerritoryModule
