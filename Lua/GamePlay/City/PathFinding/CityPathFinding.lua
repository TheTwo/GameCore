local CityManagerBase = require("CityManagerBase")
local Utils = require("Utils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityGridCellDef = require("CityGridCellDef")
local CellType = CityGridCellDef.CellType
---@type CS.DragonReborn.City.CityMapGridNavMesh.BlockType
local BlockType = CS.DragonReborn.City.CityMapGridNavMesh.BlockType
local ConfigRefer = require("ConfigRefer")
local CityZoneStatus = require("CityZoneStatus")
local CityDefenseType = require("CityDefenseType")

---@class CityPathFinding:CityManagerBase
---@field new fun():CityPathFinding
local CityPathFinding = class('CityPathFinding', CityManagerBase)
CityPathFinding.AreaMask = {
    CityGround = CS.DragonReborn.City.CityMapGridNavMesh.CityGroundAreaMask,
    CityBuildingRoom =  CS.DragonReborn.City.CityMapGridNavMesh.CityBuildingRoomAreaMask,
    CityAllWalkable = CS.DragonReborn.City.CityMapGridNavMesh.CityAllWalkableAreaMask
}

function CityPathFinding:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    self._isSelfCity = city and city:IsMyCity()
    self._gridConfig = nil
    self._scale = 1
    self._isReady = false
    self._walkableGridRate = 1
    ---@type CS.DragonReborn.City.CityMapGridNavMesh
    self._navMeshWrapper = nil
    self._pathBypass = {}
    self._noInViewState = true
    self._dataSourceDirty = false
    self._viewLoadFinished = false
end

function CityPathFinding:OnDataLoadFinish()
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnCellAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnCellRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_MOVING, Delegate.GetOrCreate(self, self.OnCellMoving))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_UPDATE_WITH_SIZE_CHANGE, Delegate.GetOrCreate(self, self.OnCellSizeChanged))

    g_Game.EventManager:AddListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:AddListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMoving))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnCityZoneStatusChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnCityZoneStatusBatchChanged))
    
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_UPDATE, Delegate.GetOrCreate(self, self.OnCityRoomWallDoorDirty))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_ADD, Delegate.GetOrCreate(self, self.OnCityLegoBuildingAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_REMOVE, Delegate.GetOrCreate(self, self.OnCityLegoBuildingRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_MOVE, Delegate.GetOrCreate(self, self.OnCityLegoBuildingMove))
end

function CityPathFinding:OnDataUnloadStart()
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnCellAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnCellRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_MOVING, Delegate.GetOrCreate(self, self.OnCellMoving))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_UPDATE_WITH_SIZE_CHANGE, Delegate.GetOrCreate(self, self.OnCellSizeChanged))

    g_Game.EventManager:RemoveListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMoving))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_CHANGED, Delegate.GetOrCreate(self, self.OnCityZoneStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnCityZoneStatusBatchChanged))

    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_UPDATE, Delegate.GetOrCreate(self, self.OnCityRoomWallDoorDirty))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_ADD, Delegate.GetOrCreate(self, self.OnCityLegoBuildingAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_REMOVE, Delegate.GetOrCreate(self, self.OnCityLegoBuildingRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_MOVE, Delegate.GetOrCreate(self, self.OnCityLegoBuildingMove))
end

function CityPathFinding:OnBasicResourceUnloadStart()
    self._dataSourceDirty = true
    if self._navMeshWrapper then
        self._navMeshWrapper:DetachNavMeshData()
        self._navMeshWrapper = nil
    end
end

function CityPathFinding:DoViewLoad()
    if not self.city.showed then
        self.city.CityRoot:SetActive(true)
    end
    if self._isSelfCity and not self._dataSourceDirty and self._navMeshWrapper then
        self._noInViewState = false
        self._navMeshWrapper:AttachNavMeshDataAndSetOwner(self.city:GetRoot())
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        return self:ViewLoadFinish()
    end
    local gridConfig = self.city.gridConfig
    local scale = self.city.scale
    self._gridConfig = self.city.gridConfig
    self._scale = self.city.scale
    local cityGrid = self.city.grid
    local legoMgr = self.city.legoManager
    local cityFurniture = self.city.furnitureManager
    local cityZone = self.city.zoneManager
    local cityGroundMarker = self.city.cityGroundMarkers
    local zoneSliceDataUsage = self.city:GetZoneSliceDataUsage()
    local safeAreaSliceDataUsage = self.city:GetSafeAreaSliceDataUsage()

    local wGridX,wGridY = self:GridToWalkable(self._gridConfig.cellsX, self._gridConfig.cellsY)

    local CityMapGridNavMesh = CS.DragonReborn.City.CityMapGridNavMesh
    if not self._navMeshWrapper then
        self._navMeshWrapper = CityMapGridNavMesh.Create(wGridX, wGridY, gridConfig.unitsPerCellX * scale / self._walkableGridRate , gridConfig.unitsPerCellY * scale / self._walkableGridRate, self.city:GetCenter(), 1, self._pathBypass, cityGroundMarker)
    else
        self._navMeshWrapper:ClearNavMeshDataSource()
    end
    ---@type CS.DragonReborn.City.CityMapGridNavMesh.BlockType
    local zoneBlockType = CS.DragonReborn.City.CityMapGridNavMesh.BlockType.CityAreaLocked
    local needAddZone = {}
    local unlockedZone = {}
    self._navMeshWrapper:LoadFromBinData(zoneSliceDataUsage, zoneBlockType)
    self._navMeshWrapper:LoadSafeAreaBinData(safeAreaSliceDataUsage)
    local dataMap = zoneSliceDataUsage:ZoneSliceMap()
    for zoneId, _ in pairs(dataMap) do
        table.insert(needAddZone, zoneId)
    end
    self._navMeshWrapper:AttachNavMeshDataAndSetOwner(self.city:GetRoot())
    for _, zoneId in pairs(needAddZone) do
        local zone = self.city.zoneManager:GetZoneById(zoneId)
        if not zone or not zone:IsHideFog() then
            self._navMeshWrapper:AddZone(zoneId)
        elseif zone.status >= CityZoneStatus.Explored then
            table.insert(unlockedZone, zoneId)
        end
    end
    local safeAreaRandomIds = self:GetRandomSafeAreaIdArray()
    self._navMeshWrapper:GenerateExploredSafeArea(#unlockedZone, unlockedZone, #safeAreaRandomIds, safeAreaRandomIds)

    for _, cell in pairs(cityGrid.hashMap) do
        self:DoAddCell(cell)
    end
    
    for _, v in pairs(legoMgr.legoBuildings) do
        if v then
            local pX, pY = self:GridToWalkable(v.x, v.z)
            local sX, sY = self:GridToWalkable(v.sizeX, v.sizeZ)
            local blockType = BlockType.Building
            self:DoModifyWalkable(pX, pY, sX, sY, false, blockType)
        end
    end
    local CityFurnitureTypes = ConfigRefer.CityFurnitureTypes
    for _, v in pairs(cityFurniture.hashMap) do
        if v then
            for x,y,sx,sy in v:NavDataPairs() do
                local pX, pY = self:GridToWalkable(x, y)
                local sX, sY = self:GridToWalkable(sx, sy)
                local typeConfig = CityFurnitureTypes:Find(v:GetFurnitureType())
                if not typeConfig or typeConfig:DefenseType() ~= CityDefenseType.Door then
                    local navObstacle,blockType = self:GetCellBlockType(v)
                    if navObstacle then
                        self:DoModifyWalkableOnHalfSizeGrid(pX, pY, sX, sY , false, blockType)
                    end
                end
            end
        end
    end
    --self._navMeshWrapper:ForceSyncUpdateNow()
    
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self:SyncBuildingWallToNavMesh()
    self._isReady = true
    if not self.city.showed then
        self.city.CityRoot:SetActive(false)
    end
    self._noInViewState = false
    self._dataSourceDirty = false
    return self:ViewLoadFinish()
end

function CityPathFinding:OnViewLoadFinish()
    self._viewLoadFinished = true
end

function CityPathFinding:Tick()
    if not self._viewLoadFinished then return end
    self._navMeshWrapper:Tick()
end

function CityPathFinding:IsNavMeshReady()
    return self._viewLoadFinished and self._navMeshWrapper.NavMeshReady
end

function CityPathFinding:ForceSyncBuildNavMesh()
    self._navMeshWrapper:ForceSyncUpdateNow()
end

function CityPathFinding:DoViewUnload()
    self._noInViewState = true
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    if self._navMeshWrapper then
        if self._isSelfCity then
            self._navMeshWrapper:DetachNavMeshDataButKeep()
        else
            self._navMeshWrapper:DetachNavMeshData()
        end
    end
end

function CityPathFinding:OnViewUnloadStart()
    self._viewLoadFinished = false
end

function CityPathFinding:NeedUnloadViewWhenDisable()
    return true
end

---@param pos CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3
function CityPathFinding:GetFixedHeightWorldPosition(pos)
    local _,result = self._navMeshWrapper:HeightFixedPosition(pos)
    return result
end

---@param startPos CS.UnityEngine.Vector3
---@param endPos CS.UnityEngine.Vector3
---@param areaMask number
---@param callback fun(waypoints:CS.UnityEngine.Vector3[])
---@return CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
function CityPathFinding:FindPath(startPos, endPos, areaMask, callback)
    return self._navMeshWrapper:FindPath(startPos, endPos, areaMask, function(path)
        local param = {}
        if Utils.IsNotNull(path) then
            for _, v in pairs(path) do
                table.insert(param, v)
            end
        end
        if callback then
            callback(param)
        end
    end)
end

---@param startPos CS.UnityEngine.Vector3
---@param length number
---@param areaMask number
---@param callback fun(waypoints:CS.UnityEngine.Vector3[])
---@return CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
function CityPathFinding:RandomPath(startPos, length, areaMask, callback)
    return self._navMeshWrapper:RandomPath(startPos, length, areaMask, function(path)
        local param = {}
        if Utils.IsNotNull(path) then
            for _, v in pairs(path) do
                table.insert(param, v)
            end
        end
        if callback then
            callback(param)
        end
    end)
end

---@param areaMask number
---@return CS.UnityEngine.Vector3 @ nil
function CityPathFinding:RandomPositionOnGraph(areaMask)
    return self._navMeshWrapper:RandomPosition(areaMask)
end

---@param areaMask number
---@return CS.UnityEngine.Vector3 @ nil
function CityPathFinding:RandomPositionInExploredZoneWithInSafeArea(areaMask)
    local tmp = {}
    for id, zone in pairs(self.city.zoneManager.zoneIdMap) do
        if zone:IsHideFog() then
            table.insert(tmp, id)
        end
    end
    local index = math.random(#tmp)
    return self._navMeshWrapper:RandomPositionInExploredZoneInPredefineSafeArea(areaMask, tmp[index])
end

function CityPathFinding:RandomPositionInRange(x,z,sX,sZ,areaMask)
    return self._navMeshWrapper:RandomPositionInRange(x,z, sX, sZ, areaMask)
end

---@param position CS.UnityEngine.Vector3 @ nil
---@param areaMask number
---@return CS.UnityEngine.Vector3 @ nil
function CityPathFinding:NearestWalkableOnGraph(position, areaMask)
    if not position then
        return self:RandomPositionOnGraph(areaMask)
    end
    return self._navMeshWrapper:NearestPosition(position, areaMask)
end


---@return boolean, CS.UnityEngine.Vector3
function CityPathFinding:NavMeshRayCast(originPos, dir, legnth, areaMask)
    if not self._isReady then
        return false,nil
    end
    return self._navMeshWrapper:RayCastOnNavMesh(originPos, dir, legnth, areaMask)
end

---@return number,number @x,y
function CityPathFinding:GridToWalkable(x, y)
    return x * self._walkableGridRate, y * self._walkableGridRate
end

function CityPathFinding:OnCellAdd(city, x, y)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return 
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local cell = self.city.grid:GetCell(x, y)
    if not cell then return end
    self:DoAddCell(cell)
    self:BroadcastWalkableChangTriggerCheck(cell.x, cell.y, cell.sizeX, cell.sizeY)
end

---@param cell CityGridCell
function CityPathFinding:DoAddCell(cell)
    local pX, pY = self:GridToWalkable(cell.x, cell.y)
    local sX, sY = self:GridToWalkable(cell.sizeX, cell.sizeY)
    local navObstacle,blockType = self:GetCellBlockType(cell)
    if not navObstacle then return end
    local cfg
    if blockType == BlockType.Building then
        cfg = ConfigRefer.BuildingLevel:Find(cell.configId)
    end
    self:DoModifyWalkable(pX, pY, sX, sY, false, blockType , cfg)
end

function CityPathFinding:OnCellRemove(city, cell)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    if not cell then return end
    local pX, pY = self:GridToWalkable(cell.x, cell.y)
    local sX, sY = self:GridToWalkable(cell.sizeX, cell.sizeY)
    local navObstacle,blockType = self:GetCellBlockType(cell)
    if not navObstacle then return end
    self:DoModifyWalkable(pX, pY, sX, sY, true, blockType)
end

function CityPathFinding:OnCellMoving(city, oriX, oriY, newX, newY)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local cell = self.city.grid:GetCell(newX, newY)
    if not cell then return end
    local pX, pY = self:GridToWalkable(oriX, oriY)
    local sX, sY = self:GridToWalkable(cell.sizeX, cell.sizeY)
    local navObstacle,blockType = self:GetCellBlockType(cell)
    if not navObstacle then return end
    self:DoModifyWalkable(pX, pY, sX, sY, true, blockType)
    pX, pY = self:GridToWalkable(cell.x, cell.y)
    local cfg
    if blockType == BlockType.Building then
        cfg = ConfigRefer.BuildingLevel:Find(cell.configId)
    end
    self:DoModifyWalkable(pX, pY, sX, sY, false, blockType, cfg)
    if blockType == BlockType.Building then
        local offset = self.city:GetWorldPositionFromCoord(newX, newY) - self.city:GetWorldPositionFromCoord(oriX, oriY)
        self:BroadcastWalkableChangTriggerCheck(cell.x, cell.y, cell.sizeX, cell.sizeY, cell.tileId, offset, oriX, oriY)
    else
        self:BroadcastWalkableChangTriggerCheck(cell.x, cell.y, cell.sizeX, cell.sizeY)
    end
end

function CityPathFinding:OnCellSizeChanged(city, x, y, oldSizeX, oldSizeY, newSizeX, newSizeY)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local cell = self.city.grid:GetCell(x, y)
    if not cell then return end
    local pX, pY = self:GridToWalkable(x, y)
    local sX, sY = self:GridToWalkable(oldSizeX, oldSizeY)
    local navObstacle,blockType = self:GetCellBlockType(cell)
    if not navObstacle then return end
    self:DoModifyWalkable(pX, pY, sX, sY, true, blockType)
    sX, sY = self:GridToWalkable(newSizeX, newSizeY)
    local cfg
    if blockType == BlockType.Building then
        cfg = ConfigRefer.BuildingLevel:Find(cell.configId)
    end
    self:DoModifyWalkable(pX, pY, sX, sY, false, blockType, cfg)
    self:BroadcastWalkableChangTriggerCheck(x, y, newSizeX, newSizeY)
end

function CityPathFinding:OnFurniturePlaced(city, x, y)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local cell = self.city.furnitureManager:GetPlaced(x, y)
    if not cell then
        return
    end
    local typeConfig = ConfigRefer.CityFurnitureTypes:Find(cell:GetFurnitureType())
    if typeConfig and typeConfig:DefenseType() == CityDefenseType.Door then
        return
    end
    local navObstacle,blockType = self:GetCellBlockType(cell)
    if not navObstacle then return end
    for blockX,blockY,blockSx,blockSy in cell:NavDataPairs() do
        local pX, pY = self:GridToWalkable(blockX, blockY)
        local sX, sY = self:GridToWalkable(blockSx, blockSy)
        self:DoModifyWalkableOnHalfSizeGrid(pX, pY, sX, sY, false, blockType)
    end
    self:BroadcastWalkableChangTriggerCheck(cell.x, cell.y, cell.sizeX, cell.sizeY)
end

---@param navDataFunc fun():numberm,number,number,number
function CityPathFinding:OnFurnitureStorage(city, x, y, sizeX, sizeY, type, navDataFunc)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local blockType = BlockType.Furniture
    if type then
        local typeConfig = ConfigRefer.CityFurnitureTypes:Find(type)
        if typeConfig and typeConfig:NavNoIndentation() then
            blockType = BlockType.FurnitureNoBorderReduce
        end
    end
    for blockX,blockY,blockSx,blockSy in navDataFunc do
        local pX, pY = self:GridToWalkable(blockX, blockY)
        local sX, sY = self:GridToWalkable(blockSx, blockSy)
        self:DoModifyWalkableOnHalfSizeGrid(pX, pY, sX, sY, true, blockType)
    end
end

function CityPathFinding:OnFurnitureMoving(city, oriX, oriY, newX, newY, id, oldSizeX, odlSizeY)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local cell = self.city.furnitureManager:GetPlaced(newX, newY)
    if not cell then
        return
    end
    local typeConfig = ConfigRefer.CityFurnitureTypes:Find(cell:GetFurnitureType())
    if typeConfig and typeConfig:DefenseType() == CityDefenseType.Door then
        return
    end
    local navObstacle,blockType = self:GetCellBlockType(cell)
    if not navObstacle then return end
    for blockX,blockY,blockSx,blockSy in cell:PreNavDataPairs() do
        local pX, pY = self:GridToWalkable(blockX, blockY)
        local sX, sY = self:GridToWalkable(blockSx, blockSy)
        self:DoModifyWalkableOnHalfSizeGrid(pX, pY, sX, sY, true, blockType)
    end
    for blockX,blockY,blockSx,blockSy in cell:NavDataPairs() do
        local pX, pY = self:GridToWalkable(blockX, blockY)
        local sX, sY = self:GridToWalkable(blockSx, blockSy)
        self:DoModifyWalkableOnHalfSizeGrid(pX, pY, sX, sY, false, blockType)
    end
end

function CityPathFinding:OnCityZoneStatusChanged(city, zoneId, lastStatus, status)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    if lastStatus < CityZoneStatus.Explored and status >= CityZoneStatus.Explored then
        self._navMeshWrapper:RemoveZone(zoneId)
    end
end

---@param city MyCity|City
---@param addTable table<number, number>
function CityPathFinding:OnCityZoneStatusBatchChanged(city, addTable)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local unlockedZone = {}
    if self.city:IsInSingleSeExplorerMode() then
        for zoneId, cityZone in pairs(self.city.zoneManager.zoneIdMap) do
            if cityZone:IsHideFogForExploring() then
                table.insert(unlockedZone, zoneId)
            end
        end
    else
        for zoneId, cityZone in pairs(self.city.zoneManager.zoneIdMap) do
            if cityZone.status >= CityZoneStatus.Explored then
                table.insert(unlockedZone, zoneId)
            end
        end
    end
    local safeAreaRandomIds = self:GetRandomSafeAreaIdArray()
    self._navMeshWrapper:GenerateExploredSafeArea(#unlockedZone, unlockedZone, #safeAreaRandomIds, safeAreaRandomIds)
end

---@param city MyCity
---@param building CityLegoBuilding
function CityPathFinding:OnCityLegoBuildingAdd(city, building)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local pX, pY = self:GridToWalkable(building.x, building.z)
    local sX, sY = self:GridToWalkable(building.sizeX, building.sizeZ)
    local blockType = BlockType.Building
    self:DoModifyWalkable(pX, pY, sX, sY, false, blockType)
end

function CityPathFinding:OnCityLegoBuildingRemove(city, building)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local pX, pY = self:GridToWalkable(building.x, building.z)
    local sX, sY = self:GridToWalkable(building.sizeX, building.sizeZ)
    local blockType = BlockType.Building
    self:DoModifyWalkable(pX, pY, sX, sY, true, blockType)
end

function CityPathFinding:OnCityLegoBuildingMove(city, building, oldX, oldZ, x, z, sizeX, sizeZ)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    local pX, pY = self:GridToWalkable(oldX, oldZ)
    local sX, sY = self:GridToWalkable(building.sizeX, building.sizeZ)
    local blockType = BlockType.Building
    self:DoModifyWalkable(pX, pY, sX, sY, true, blockType)
    pX, pY = self:GridToWalkable(x, z)
    sX, sY = self:GridToWalkable(sizeX, sizeZ)
    self:DoModifyWalkable(pX, pY, sX, sY, false, blockType)
end

---@param city City
---@param legoBuilding CityLegoBuilding
function CityPathFinding:OnCityRoomWallDoorDirty(city, legoBuilding)
    if self.city ~= city then return end
    if not self._viewLoadFinished then
        self._dataSourceDirty = true
        return
    end
    if not self._isReady then
        self._dataSourceDirty = true
        return
    end
    self:SyncBuildingWallToNavMesh()
end

---@param pX number
---@param pY number
---@param sX number
---@param sY number
---@param flag boolean
---@param buildingConfig BuildingLevelConfigCell
---@param blockType CS.DragonReborn.City.CityMapGridNavMesh.BlockType
function CityPathFinding:DoModifyWalkable(pX, pY, sX, sY, flag, blockType, buildingConfig)
    if self._noInViewState then self._dataSourceDirty = true end
    if flag then
        self._navMeshWrapper:RemoveBlock(pX, pY, sX, sY, blockType)
    else
        if blockType == BlockType.Building and buildingConfig then
            self._navMeshWrapper:AddBlock(pX, pY, sX, sY, blockType, buildingConfig:EntryWall() - 1, buildingConfig:EntryOffset() - 1, 0.1)
        else
            self._navMeshWrapper:AddBlock(pX, pY, sX, sY, blockType)
        end
    end
end

---@param pX number
---@param pY number
---@param sX number
---@param sY number
---@param flag boolean
---@param blockType CS.DragonReborn.City.CityMapGridNavMesh.BlockType
function CityPathFinding:DoModifyWalkableOnHalfSizeGrid(pX, pY, sX, sY, flag, blockType)
    if self._noInViewState then self._dataSourceDirty = true end
    if flag then
        self._navMeshWrapper:RemoveHalfGridBlock(pX, pY, sX , sY, blockType)
    else
        self._navMeshWrapper:AddHalfGridBlock(pX, pY, sX , sY, blockType)
    end
end

---@param cell CityGridCell
---@return boolean,CS.DragonReborn.City.CityMapGridNavMesh.BlockType
function CityPathFinding:GetCellBlockType(cell)
    if cell.cellType == CellType.SQUARE_MAIN then
        if cell:IsBuilding() then
            return true,BlockType.Building
        end
    end
    if cell:IsFurniture() then
        local config = ConfigRefer.CityFurnitureLevel:Find(cell.configId)
        if config then
            local type = ConfigRefer.CityFurnitureTypes:Find(config:Type())
            if type and type:NavNoIndentation() then
                return true,BlockType.FurnitureNoBorderReduce
            end
        end
        return true,BlockType.Furniture
    end
    if cell:IsNpc() then
        local eleCfg = ConfigRefer.CityElementData:Find(cell.configId)
        if eleCfg then
            local npcCfg = ConfigRefer.CityElementNpc:Find(eleCfg:ElementId())
            if npcCfg then
                if not npcCfg:NavObstacle() then
                    return false,BlockType.Npc
                end
                if npcCfg:NavNoIndentation() then
                    return true,BlockType.NpcNoBorderReduce
                end
                return true,BlockType.Npc
            end
        end
    end
    if cell:IsResource() then
        local eleCfg = ConfigRefer.CityElementData:Find(cell.configId)
        if eleCfg then
            local resourceConfig = ConfigRefer.CityElementResource:Find(eleCfg:ElementId())
            if resourceConfig then
                if not resourceConfig:NavObstacle() then
                    return false,BlockType.CityResource
                end
                if resourceConfig:NavNoIndentation() then
                    return true,BlockType.CityResourceNoBorderReduce
                end
                return true,BlockType.CityResource
            end
        end
    end
    return true,BlockType.Unknown
end

---@class CityPathFindingGridRange
---@field x number
---@field y number
---@field xMax number
---@field yMax number
---@field buildingId number @nil
---@field offset CS.UnityEngine.Vector3
---@field oldRange CityPathFindingGridRange

---@param x number
---@param y number
---@param sx number
---@param sy number
---@param buildingId number
---@param offset CS.UnityEngine.Vector3
---@param oldX number
---@param oldY number
function CityPathFinding:BroadcastWalkableChangTriggerCheck(x, y, sx, sy, buildingId, offset, oldX, oldY)
    ---@type CityPathFindingGridRange
    local msg = {
        x = x,
        y = y,
        xMax = x + sx,
        yMax = y + sy,
    }
    if buildingId then
        msg.buildingId = buildingId
        msg.offset = offset
        msg.oldRange = {
            x = oldX,
            y = oldY,
            xMax = oldX + sx,
            yMax = oldY + sy,
        }
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_WALKABLE_CHANGE_CHECK, self.city, msg)
end

function CityPathFinding:IsRangeEffectsPath(x,z, sX, sZ, pathArrayTable)
    return self._navMeshWrapper:RangeEffectsWayPoints(x,z, sX, sZ, pathArrayTable)
end

local function hashCodeForWall(x, y, length, side)
    local hash = 5381
    hash = ((hash << 5) + hash) + x
    hash = ((hash << 5) + hash) + y
    hash = ((hash << 5) + hash) + length
    hash = ((hash << 5) + hash) + side
    return hash
end

function CityPathFinding:SyncBuildingWallToNavMesh(syncBuildingId)
    local syncData = self.city.legoManager:GenerateBuildingsNavmeshData()
    local xArray = {}
    local zArray = {}
    local lengthArray = {}
    local dirArray = {}
    local count = 0
    local filterMap = {}
    for _, walls in pairs(syncData) do
        for _, v in pairs(walls) do
            if not v.walkable then
                local side = v.side % 2
                local hash = hashCodeForWall(v.x, v.y, v.length, side)
                if not filterMap[hash] then
                    filterMap[hash] = true

                    table.insert(xArray, v.x)
                    table.insert(zArray, v.y)
                    table.insert(lengthArray, v.length)
                    table.insert(dirArray, v.side or 0)
                    count = count + 1
                end
            end
        end
    end
    self._navMeshWrapper:BatchSyncBuildingWall(count, xArray, zArray, lengthArray, dirArray)
end

function CityPathFinding:GetRandomSafeAreaIdArray()
    local safeAreaRandomIds = {}
    for i = 1, ConfigRefer.CityConfig:CitizenRandomInSafeZoneLength() do
        if self.city.safeAreaWallMgr:IsValidSafeAreaId(ConfigRefer.CityConfig:CitizenRandomInSafeZone(i)) then
            table.insert(safeAreaRandomIds, ConfigRefer.CityConfig:CitizenRandomInSafeZone(i))
        end
    end
    return safeAreaRandomIds
end

function CityPathFinding:NeedLoadView()
    return true
end

return CityPathFinding