local CityManagerBase = require("CityManagerBase")
---@class CityGridView:CityManagerBase
---@field new fun():CityGridView
---@field currHashSet table<CityTileBase, CityTileBase>
---@field toShowList CityTileAsset[]
---@field toShowMap table<CityTileAsset, CityTileAsset>
local CityGridView = class("CityGridView", CityManagerBase)
local CityCellTileViewFactory = require("CityCellTileViewFactory")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local RectDyadicMap = require("RectDyadicMap")
local CityCellTile = require("CityCellTile")
local CityFurnitureTile = require("CityFurnitureTile")
local CitySafeAreaWallDoorTile = require("CitySafeAreaWallDoorTile")
local CityGeneratingResTile = require("CityGeneratingResTile")
local CityGridCell = require("CityGridCell")
local CityFurniture = require("CityFurniture")
local CityLegoBuilding = require("CityLegoBuilding")
local CitySafeAreaWallDoor = require("CitySafeAreaWallDoor")
local CityLegoBuildingTile = require("CityLegoBuildingTile")
local TimerUtility = require("TimerUtility")
local QuadTreeNode = require("QuadTreeNode")
local QuadTreeLeaf = require("QuadTreeLeaf")
local Rect = require("Rect")
local Utils = require("Utils")
local DeviceLevel = CS.DragonReborn.Performance.DeviceLevel
local orderByPriority = function(l, r) return l.priority > r.priority end

---@param city City
function CityGridView:DoViewLoad()
    local gridConfig = self.city.gridConfig
    local sizeX, sizeY = gridConfig.cellsX, gridConfig.cellsY
    self.sizeX, self.sizeY = sizeX, sizeY

    self.cellTiles = RectDyadicMap.new(sizeX, sizeY)
    self.furnitureTiles = RectDyadicMap.new(sizeX, sizeY)
    self.safeAreaWallDoorTiles = RectDyadicMap.new(sizeX, sizeY)
    self.generatingResTiles = RectDyadicMap.new(sizeX, sizeY)
    ---@type table<number, CityLegoBuildingTile>
    self.legoTiles = {}

    ---@type table<CityStaticObjectTile, CityStaticObjectTile>
    self.staticTiles = {}

    self.viewFactory = CityCellTileViewFactory.Instance()

    self.currHashSet = {}

    self.forceShowTile = {}
    self.forceHideTile = {}

    self.toShowList = {}
    self.toShowMap = {}

    self.loadEveryTick = 5
    self.need = 0
    self.loaded = 0
    self.needTable = {}
    self.loadedTable = {}
    self.delayTimers = setmetatable({}, {__mode = "k"})

    self.grid = self.city.grid
    self.furnitureManager = self.city.furnitureManager
    self.safeAreaWallMgr = self.city.safeAreaWallMgr
    self.staticTilesManager = self.city.staticTilesManager
    self.cityWorkManager = self.city.cityWorkManager
    self.legoManager = self.city.legoManager
    self.root = self.city:GetRoot()
    self.cameraSize = self.city.cameraSize
    self.lastSize = self.cameraSize

    -- 所有tileAssets共用一个Helper
    self.createHelper = self.city.createHelper
    -- 设备等级缓存, 影响剪裁面积倍率
    local level = g_Game.PerformanceLevelManager:GetDeviceLevel()
    self.expandCulling = DeviceLevel.High == level or DeviceLevel.Medium == level

    self:LoadData()
    self:AddEvents()
    return self:ViewLoadFinish()
end

function CityGridView:AddEvents()
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnCellAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_UPDATE, Delegate.GetOrCreate(self, self.OnCellUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnCellRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_MOVING, Delegate.GetOrCreate(self, self.OnCellMoving))

    g_Game.EventManager:AddListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:AddListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMoving))
    g_Game.EventManager:AddListener(EventConst.CITY_UPDATE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureBatchUpdate))
    
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_PLACE, Delegate.GetOrCreate(self, self.OnSafeAreaWallDoorPlace))
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_REMOVE, Delegate.GetOrCreate(self, self.OnSafeAreaWallDoorRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_UPDATE, Delegate.GetOrCreate(self, self.OnSafeAreaDoorUpdate))

    g_Game.EventManager:AddListener(EventConst.CITY_STATIC_TILE_ADD, Delegate.GetOrCreate(self, self.OnStaticTileAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_STATIC_TILE_REMOVE, Delegate.GetOrCreate(self, self.OnStaticTileRemove))

    g_Game.EventManager:AddListener(EventConst.CITY_GENERATING_RES_ADD, Delegate.GetOrCreate(self, self.OnGeneratingResAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_GENERATING_RES_REMOVE, Delegate.GetOrCreate(self, self.OnGeneratingResRemove))

    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_ADD, Delegate.GetOrCreate(self, self.OnLegoBuildingAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_REMOVE, Delegate.GetOrCreate(self, self.OnLegoBuildingRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_UPDATE, Delegate.GetOrCreate(self, self.OnLegoBuildingUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_VIEW_POS_CHANGE, Delegate.GetOrCreate(self, self.OnLegoBuildingMoving))
end

function CityGridView:DoViewUnload()
    self:RemoveEvents()
    ---@param tile CityCellTile
    for _, _, tile in self.cellTiles:pairs() do
        tile:Release(true);
    end
    self.cellTiles = nil

    for _, tile in pairs(self.legoTiles) do
        tile:Release(true)
    end
    self.legoTiles = nil

    ---@param tile CityFurnitureTile
    for _, _, tile in self.furnitureTiles:pairs() do
        tile:Release(true);
    end
    self.furnitureTiles = nil

    ---@param tile CitySafeAreaWallDoorTile
    for _, _, tile in self.safeAreaWallDoorTiles:pairs() do
        tile:Release(true)
    end
    self.safeAreaWallDoorTiles = nil
    
    ---@param tile CityStaticObjectTile
    for _, tile in pairs(self.staticTiles) do
        tile:Release(true)
    end

    ---@param tile CityGeneratingResTile
    for _, _, tile in self.generatingResTiles:pairs() do
        tile:Release(true)
    end

    self.staticTiles = nil
    self.quadTree = nil
    self.tile2Leaf = nil

    for timer, _ in pairs(self.delayTimers) do
        TimerUtility.StopAndRecycle(timer)
    end
    self.delayTimers = nil

    self.grid = nil
    self.furnitureManager = nil
    self.safeAreaWallMgr = nil
    self.root = nil
    self.need = 0
    self.loaded = 0

    self.currHashSet = nil
    self.forceShowTile = nil
    self.forceHideTile = nil
    self.toShowList = nil
    self.toShowMap = nil
end

function CityGridView:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnCellAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_UPDATE, Delegate.GetOrCreate(self, self.OnCellUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnCellRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_MOVING, Delegate.GetOrCreate(self, self.OnCellMoving))

    g_Game.EventManager:RemoveListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMoving))
    g_Game.EventManager:RemoveListener(EventConst.CITY_UPDATE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureBatchUpdate))

    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_PLACE, Delegate.GetOrCreate(self, self.OnSafeAreaWallDoorPlace))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_REMOVE, Delegate.GetOrCreate(self, self.OnSafeAreaWallDoorRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_UPDATE, Delegate.GetOrCreate(self, self.OnSafeAreaDoorUpdate))

    g_Game.EventManager:RemoveListener(EventConst.CITY_STATIC_TILE_ADD, Delegate.GetOrCreate(self, self.OnStaticTileAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATIC_TILE_REMOVE, Delegate.GetOrCreate(self, self.OnStaticTileRemove))

    g_Game.EventManager:RemoveListener(EventConst.CITY_GENERATING_RES_ADD, Delegate.GetOrCreate(self, self.OnGeneratingResAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GENERATING_RES_REMOVE, Delegate.GetOrCreate(self, self.OnGeneratingResRemove))

    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_ADD, Delegate.GetOrCreate(self, self.OnLegoBuildingAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_REMOVE, Delegate.GetOrCreate(self, self.OnLegoBuildingRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_UPDATE, Delegate.GetOrCreate(self, self.OnLegoBuildingUpdate))
end

function CityGridView:OnViewLoadFinish()
    self:ReadPreStaticTileData()
end

function CityGridView:OnCameraLoaded(camera)
    self.camera = camera
    self.camera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
end

function CityGridView:OnCameraUnload()
    self.camera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
    self.camera = nil
end

function CityGridView:LoadData()
    self.quadTree = QuadTreeNode.new(self:GetRect(), 32, 20)
    self.tile2Leaf = {}
    for _, cell in pairs(self.grid.hashMap) do
        ---@type CityCellTile
        local tile = self.cellTiles:Add(cell.x, cell.y, CityCellTile.new(self, cell.x, cell.y))
        if tile then
            tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
            local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
            self.tile2Leaf[tile] = leaf
            self.quadTree:Insert(leaf)
        else
            g_Logger.Error(("CityCellTile not find or overlap at (X:%d, Y:%d)"):format(cell.x, cell.y))
        end
    end

    for _, legoBuilding in pairs(self.legoManager.legoBuildings) do
        local tile = CityLegoBuildingTile.new(self, legoBuilding)
        self.legoTiles[legoBuilding.id] = tile
        local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
        self.tile2Leaf[tile] = leaf
        self.quadTree:Insert(leaf)
    end

    for _, f in pairs(self.furnitureManager.hashMap) do
        ---@type CityFurnitureTile
        local tile = self.furnitureTiles:Add(f.x, f.y, CityFurnitureTile.new(self, f.x, f.y))
        if tile then
            tile:SetPositionCenterAndRotation(self.city:GetWorldPositionFromCoord(tile.x, tile.y), self.city:GetCenterWorldPositionFromCoord(tile.x, tile.y, tile:SizeX(), tile:SizeY()), tile:Quaternion())
            local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
            self.tile2Leaf[tile] = leaf
            self.quadTree:Insert(leaf)
        else
            g_Logger.Error(("CityFurnitureTile not find or overlap at (X:%d, Y:%d)"):format(f.x, f.y))
        end
    end
    for _, door in pairs(self.safeAreaWallMgr.wallHashMap) do
        ---@type CitySafeAreaWallDoorTile
        local tile = self.safeAreaWallDoorTiles:Add(door.x, door.y, CitySafeAreaWallDoorTile.new(self, door.x, door.y))
        if tile then
            tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
            local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
            self.tile2Leaf[tile] = leaf
            self.quadTree:Insert(leaf)
        else
            g_Logger.Error(("SafeAreaDoor not find or overlap at (X:%d, Y:%d)"):format(door.x, door.y))
        end
    end
    for i, tile in pairs(self.staticTilesManager.staticTiles) do
        self.staticTiles[tile] = tile
        local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
        self.tile2Leaf[tile] = leaf
        self.quadTree:Insert(leaf)
    end
    for id, agent in pairs(self.cityWorkManager._furnitureResGenGridAgents) do
        if agent:IsGenerating() then
            local source = agent.generating
            local tile = self.generatingResTiles:Add(source.x, source.y, CityGeneratingResTile.new(self, agent.furnitureId, source.x, source.y))
            if tile then
                tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
                local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
                self.tile2Leaf[tile] = leaf
                self.quadTree:Insert(leaf)
            end
        end
    end
end

function CityGridView:ReadPreStaticTileData()
    local tiles = self.city.staticTilesManager:GetTiles()
    if not tiles then
        return
    end
    for i, v in pairs(tiles) do
        self:OnStaticTileAdd(self.city, v)
    end
end

function CityGridView:GetRect()
    return Rect.new(0, 0, self.sizeX, self.sizeY)
end

function CityGridView:Tick(delta)
    self:LoadPriority(false, true)
end

function CityGridView:IsAllLoaded()
    return true
end

---@param basicCamera BasicCamera
function CityGridView:UpdateCamera(basicCamera)
    if self.viewStatus ~= CityManagerBase.LoadState.Loaded then return end

    if not self.city or not self.city.showed then return end

    self.lastSize = self.cameraSize
    self.cameraSize = basicCamera:GetSize()
    local camera = basicCamera.mainCamera
    local projection = CS.Grid.CameraUtils.CalculateFrustumProjectionOnPlane(camera, camera.nearClipPlane,
                camera.farClipPlane, basicCamera:GetBasePlane());
    local cameraBox = CS.Grid.CameraUtils.CalculateFrustumProjectionAABB(projection);
    local min, max = cameraBox.min, cameraBox.max
    local minX, minY = self.city:GetCoordFromPosition(min)
    local maxX, maxY = self.city:GetCoordFromPosition(max)

    minX, maxX, minY, maxY = self:AdjustFromDeviceLevel(minX, maxX, minY, maxY)

    if self:BlockSame(minX, maxX, minY, maxY) then
        return
    end
    
    for _, enterRect in ipairs(self.enterRect) do
        local leafs = self.quadTree:Query(enterRect)
        for _, leaf in ipairs(leafs) do
            local tile = leaf.value
            if not self.currHashSet[tile] and not self.forceHideTile[tile] then
                self.currHashSet[tile] = tile
                tile:Show()
            end
        end
    end

    for _, exitRect in ipairs(self.exitRect) do
        local leafs = self.quadTree:Query(exitRect)
        for _, leaf in ipairs(leafs) do
            local tile = leaf.value
            if self.currHashSet[tile] and not self.forceShowTile[tile] then
                tile:Hide()
                self.currHashSet[tile] = nil
            end
        end
    end
end

---@private
function CityGridView:BlockSame(minX, maxX, minY, maxY)
    local viewRect = Rect.new(minX, minY, maxX - minX + 1, maxY - minY + 1)
    if self.lastViewRect == nil then
        self.lastViewRect = viewRect
        self.lastExitViewRect = self:GetExitRect(viewRect)
        self.enterRect = {self.lastViewRect}
        self.exitRect = {}
        return false
    end

    if self.lastViewRect:Equals(viewRect) then
        return true
    end

    self.enterRect = viewRect:Difference(self.lastViewRect)
    self.lastExitViewRect = self:GetExitRect(self.lastViewRect, self.lastExitViewRect)
    local curExitViewRect = self:GetExitRect(viewRect)
    self.exitRect = self.lastExitViewRect:Difference(curExitViewRect)
    self.lastViewRect = viewRect
    return false
end

---@param viewRect Rect
---@param inst Rect|nil
---@private
function CityGridView:GetExitRect(viewRect, inst)
    local ret = inst or Rect.new()
    ret.x, ret.y = viewRect.x - 50, viewRect.y - 50
    ret.sizeX, ret.sizeY = viewRect.sizeX + 100, viewRect.sizeY + 100
    return ret
end

function CityGridView:AdjustFromDeviceLevel(minX, maxX, minY, maxY)
    if not self.expandCulling then
        return minX, maxX, minY, maxY
    end

    local offsetX = math.ceil((maxX - minX) * 0.05)
    local offsetY = math.ceil((maxY - minY) * 0.05)
    return minX - offsetX, maxX + offsetX, minY - offsetY, maxY + offsetY
end

function CityGridView:GetExitRangeXY(minX, maxX, minY, maxY)
    local expandX, expandY = 50, 50
    return minX - expandX, maxX + expandX, minY - expandY, maxY + expandY
end

function CityGridView:OnCellAdd(city, x, y)
    if self.city ~= city then return end

    local tile = self.cellTiles:Add(x, y, CityCellTile.new(self, x, y))
    local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
    self.tile2Leaf[tile] = leaf
    self.quadTree:Insert(leaf)
    tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
    if not self.lastViewRect then
        return
    end
    if self.lastViewRect:Intersect(tile:GetRect()) then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

function CityGridView:OnCellUpdate(city, x, y, delay)
    if self.city ~= city then return end

    if delay > 0 then
        local timer = TimerUtility.DelayExecute(function()
            local tile = self:GetCellTile(x, y)
            if tile then
                tile:Refresh(true)
            end
        end, delay)
        self.delayTimers[timer] = true
    else
        local tile = self:GetCellTile(x, y)
        if tile then
            tile:Refresh(true)
        end
    end
end

function CityGridView:OnCellRemove(city, cell)
    if self.city ~= city then return end

    ---@type CityCellTile
    local tile = self.cellTiles:Delete(cell.x, cell.y)
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    tile:Release()
    self.tile2Leaf[tile] = nil
    self.currHashSet[tile] = nil
end

function CityGridView:OnCellMoving(city, oriX, oriY, newX, newY)
    if self.city ~= city then return end

    ---@type CityCellTile
    local tile = self.cellTiles:Delete(oriX, oriY)
    tile.x, tile.y = newX, newY
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    leaf.rect.x, leaf.rect.y = newX, newY
    self.cellTiles:Add(newX, newY, tile)
    self.quadTree:Insert(leaf)
    tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))

    local show = self.lastViewRect:Intersect(tile:GetRect())
    if show then
        if not self.currHashSet[tile] then
            self.currHashSet[tile] = tile
            tile:Show()
        end
    else
        if self.currHashSet[tile] then
            self.currHashSet[tile] = nil
            tile:Hide()
        end
    end
end

function CityGridView:OnFurniturePlaced(city, x, y)
    if self.city ~= city then return end

    ---@type CityFurnitureTile
    local tile = self.furnitureTiles:Add(x, y, CityFurnitureTile.new(self, x, y))
    local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
    self.tile2Leaf[tile] = leaf
    self.quadTree:Insert(leaf)
    tile:SetPositionCenterAndRotation(self.city:GetWorldPositionFromCoord(tile.x, tile.y), self.city:GetCenterWorldPositionFromCoord(tile.x, tile.y, tile:SizeX(), tile:SizeY()), tile:Quaternion())    
    if not self.lastViewRect then
        return
    end
    if self.lastViewRect:Intersect(tile:GetRect()) then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

function CityGridView:OnFurnitureStorage(city, x, y, sizeX, sizeY)
    if self.city ~= city then return end

    ---@type CityFurnitureTile
    local tile = self.furnitureTiles:Delete(x, y)
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    tile:Release()
    self.tile2Leaf[tile] = nil
    self.currHashSet[tile] = nil
end

function CityGridView:OnFurnitureMoving(city, oriX, oriY, newX, newY)
    if self.city ~= city then return end

    local tile = self.furnitureTiles:Delete(oriX, oriY)
    tile.x, tile.y = newX, newY
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    leaf.rect.x, leaf.rect.y = newX, newY
    self.furnitureTiles:Add(newX, newY, tile)
    self.quadTree:Insert(leaf)
    tile:SetPositionCenterAndRotation(self.city:GetWorldPositionFromCoord(tile.x, tile.y), self.city:GetCenterWorldPositionFromCoord(tile.x, tile.y, tile:SizeX(), tile:SizeY()), tile:Quaternion())
    
    local show = self.lastViewRect:Intersect(tile:GetRect())
    if show then
        if not self.currHashSet[tile] then
            self.currHashSet[tile] = tile
            tile:Show()
        end
    else
        if self.currHashSet[tile] then
            self.currHashSet[tile] = nil
            tile:Hide()
        end
    end
end

function CityGridView:OnFurnitureUpdate(city, furniture, force)
    if self.city ~= city then return end
    
    local tile = self.furnitureTiles:Get(furniture.x, furniture.y)
    tile:Refresh(force)
end

function CityGridView:OnFurnitureBatchUpdate(city, batchEvt)
    if self.city ~= city then return end
    for id, _ in pairs(batchEvt.Change) do
        local furniture = self.furnitureManager:GetFurnitureById(id)
        if furniture then
            local tile = self.furnitureTiles:Get(furniture.x, furniture.y)
            tile:Refresh(true)
        end
    end
end

function CityGridView:OnSafeAreaWallDoorPlace(city, x, y)
    if self.city ~= city then return end
    local tile = self.safeAreaWallDoorTiles:Add(x, y, CitySafeAreaWallDoorTile.new(self, x, y))
    local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
    self.tile2Leaf[tile] = leaf
    self.quadTree:Insert(leaf)
    tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
    if not self.lastViewRect then
        return
    end
    if self.lastViewRect:Intersect(tile:GetRect()) then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

function CityGridView:OnSafeAreaWallDoorRemove(city, x, y)
    if self.city ~= city then return end
    local tile = self.safeAreaWallDoorTiles:Delete(x, y)
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    tile:Release()
    self.tile2Leaf[tile] = nil
    self.currHashSet[tile] = nil
end

function CityGridView:OnSafeAreaDoorUpdate(city, x, y)
    if self.city ~= city then return end

    local tile = self.safeAreaWallDoorTiles:Get(x, y)
    tile:Refresh()
end

---@param tile CityStaticObjectTile
function CityGridView:OnStaticTileAdd(city, tile)
    if self.city ~= city then return end
    if self.staticTiles[tile] == tile then return end

    self.staticTiles[tile] = tile
    local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
    self.tile2Leaf[tile] = leaf
    self.quadTree:Insert(leaf)
    if not self.lastViewRect then
        return
    end
    if self.lastViewRect:Intersect(tile:GetRect()) then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

---@param tile CityStaticObjectTile
function CityGridView:OnStaticTileRemove(city, tile)
    if self.city ~= city then return end

    if not self.staticTiles[tile] then return end

    self.staticTiles[tile] = nil
    tile:Hide()
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    self.tile2Leaf[tile] = nil
    self.currHashSet[tile] = nil
end

function CityGridView:OnGeneratingResAdd(city, id)
    if self.city ~= city then return end
    
    local agent = self.cityWorkManager:GetResGenUnit(id)
    local tile = self.generatingResTiles:Add(agent.x, agent.y, CityGeneratingResTile.new(self, id, agent.x, agent.y))
    local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
    self.tile2Leaf[tile] = leaf
    self.quadTree:Insert(leaf)
    tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
    if not self.lastViewRect then
        return
    end
    if self.lastViewRect:Intersect(tile:GetRect()) then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

---@param unit CityWorkProduceResGenUnit
function CityGridView:OnGeneratingResRemove(city, unit)
    if self.city ~= city then return end
    
    local tile = self.generatingResTiles:Delete(unit.x, unit.y)
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    tile:Release()
    self.tile2Leaf[tile] = nil
    self.currHashSet[tile] = nil
end

function CityGridView:OnLegoBuildingAdd(city, legoBuilding)
    if self.city ~= city then return end

    local tile = CityLegoBuildingTile.new(self, legoBuilding)
    self.legoTiles[legoBuilding.id] = tile
    local leaf = QuadTreeLeaf.new(tile:GetRect(), tile)
    self.tile2Leaf[tile] = leaf
    self.quadTree:Insert(leaf)

    if not self.lastViewRect then
        return
    end
    if self.lastViewRect:Intersect(tile:GetRect()) then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

---@param legoBuilding CityLegoBuilding
function CityGridView:OnLegoBuildingRemove(city, legoBuilding)
    if self.city ~= city then return end
    
    local tile = self.legoTiles[legoBuilding.id]
    self.legoTiles[legoBuilding.id] = nil
    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    tile:Release()
    self.tile2Leaf[tile] = nil
    self.currHashSet[tile] = nil
end

---@param legoBuilding CityLegoBuilding
function CityGridView:OnLegoBuildingUpdate(city, legoBuilding)
    if self.city ~= city then return end

    local tile = self.legoTiles[legoBuilding.id]
    tile:Refresh(true)
end

---@param legoBuilding CityLegoBuilding
function CityGridView:OnLegoBuildingMoving(city, legoBuilding)
    if self.city ~= city then return end

    local tile = self.legoTiles[legoBuilding.id]
    tile.x, tile.y = legoBuilding.x, legoBuilding.z

    local leaf = self.tile2Leaf[tile]
    self.quadTree:Remove(leaf)
    leaf.rect.x, leaf.rect.y = legoBuilding.x, legoBuilding.z
    self.quadTree:Insert(leaf)

    if tile.tileView then
        if Utils.IsNotNull(tile.tileView.root) then
            tile.tileView.root.name = tile.tileView:RootName()
        end
        tile.tileView:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
    end
end

---@return CityCellTile
function CityGridView:GetCellTile(x, y)
    if not self.cellTiles then return nil end
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    return self.cellTiles:Get(x, y)
end

---@return CityFurnitureTile
function CityGridView:GetFurnitureTile(x, y)
    if not self.furnitureTiles then return nil end
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    return self.furnitureTiles:Get(x, y)
end

---@return CitySafeAreaWallDoorTile
function CityGridView:GetSafeAreaWallDoorTile(x, y)
    if not self.safeAreaWallDoorTiles then return nil end
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    return self.safeAreaWallDoorTiles:Get(x, y)
end

function CityGridView:GetLegoTile(id)
    if not self.legoTiles then return nil end
    return self.legoTiles[id]
end

---@param tile CityTileBase
---@return CS.UnityEngine.Transform
function CityGridView:GetRoot(tile)
    local cell = tile:GetCell()
    if not cell then
        return nil
    end

    if cell:is(CityGridCell) then
        if cell:IsBuilding() then
            return self.root.transform:Find("building")
        elseif cell:IsResource() then
            return self.root.transform:Find("resource")
        elseif cell:IsNpc() then
            return self.root.transform:Find("npc")
        elseif cell:IsCreepNode() then
            return self.root.transform:Find("creep_node")
        end
    elseif cell:is(CityFurniture) then
        return self.root.transform:Find("decoration")
    elseif cell:is(CitySafeAreaWallDoor) then
        return self.root.transform:Find("building")
    elseif cell:is(CityGeneratingResTile) then
        return self.root.transform:Find("resource")
    elseif cell:is(CityLegoBuilding) then
        return self.root.transform:Find("building")
    else
        g_Logger.Warn("没有配置对应根节点")
        return self.root.transform
    end
end

function CityGridView:GetStaticRoot()
    return self.root.transform:Find("decoration")
end

function CityGridView:ChangeAllBuildingRoofState(roofHide)
    if roofHide == self.roofHide then
        return
    end
    self.roofHide = roofHide
    for _, node in pairs(self.currHashSet or {}) do
        if node.tileView and node.tileView.OnRoofStateChanged then
           node.tileView:OnRoofStateChanged(roofHide)
        end
    end
end

function CityGridView:ChangeAllBuildingWallHide(wallHide)
    self.wallHide = wallHide
    for _, node in pairs(self.currHashSet or {}) do
        if node.tileView and node.tileView.OnWallHideChanged then
           node.tileView:OnWallHideChanged(wallHide)
        end
    end
end

---@param tile CityTileBase
function CityGridView:ForceShow(tile)
    if not self.forceShowTile then return end
    
    self.forceShowTile[tile] = tile
    if self.forceHideTile[tile] then
        self.forceHideTile[tile] = nil
    end

    if not self.currHashSet[tile] then
        self.currHashSet[tile] = tile
        tile:Show()
    end
end

---@param tile CityTileBase
function CityGridView:ForceHide(tile)
    if not self.forceShowTile then return end

    self.forceHideTile[tile] = tile
    if self.forceShowTile[tile] then
        self.forceShowTile[tile] = nil
    end

    if self.currHashSet[tile] then
        self.currHashSet[tile] = nil
        tile:Hide()
    end
end

---@param tile CityTileBase
function CityGridView:CancelForceShow(tile)
    if not self.forceShowTile then return end

    if self.forceShowTile[tile] then
        self.forceShowTile[tile] = nil

        if tile.gridView == nil then
            return
        end
        
        if self.currHashSet[tile] and not self.lastViewRect:Intersect(tile:GetRect()) then
            self.currHashSet[tile] = nil
            tile:Hide()
        end
    end
end

---@param tile CityTileBase
function CityGridView:CancelForceHide(tile)
    if not self.forceHideTile then return end

    if self.forceHideTile[tile] then
        self.forceHideTile[tile] = nil
        
        if not self.currHashSet[tile] and self.lastViewRect:Intersect(tile:GetRect()) then
            self.currHashSet[tile] = tile
            tile:Show()
        end
    end
end

---@param asset CityTileAsset
function CityGridView:EnqueueLoad(asset)
    if self.toShowMap == nil or self.toShowMap[asset] then
        return
    end

    if asset.handle then
        return
    end

    if asset.tileView and asset.tileView.tile then
        if self.forceHideTile[asset.tileView.tile] then
            return
        end
    end

    table.insert(self.toShowList, asset)
    self.toShowMap[asset] = asset
    self.need = self.need + asset:LoadNecessary()
    self.needTable[asset] = asset
end

---@param asset CityTileAsset
function CityGridView:DequeueLoad(asset)
    if self.toShowMap == nil or not self.toShowMap[asset] then
        return
    end

    self.toShowMap[asset] = nil
    table.removebyvalue(self.toShowList, asset)
    self.need = self.need - asset:LoadNecessary()
    self.needTable[asset] = nil
end

---@param asset CityTileAsset
function CityGridView:MarkLoaded(asset)
    if not self.loadedTable then return end

    self.loaded = self.loaded + asset:LoadNecessary()
    self.loadedTable[asset] = asset
end

---@param asset CityTileAsset
function CityGridView:MarkUnload(asset)
    if not self.loadedTable or not self.needTable then return end

    self.need = self.need - asset:LoadNecessary()
    self.loaded = self.loaded - asset:LoadNecessary()
    self.loadedTable[asset] = nil
    self.needTable[asset] = nil
end

---@param asset CityTileAsset
function CityGridView:MarkFailed(asset)
    if not self.needTable then return end

    self.need = self.need - asset:LoadNecessary()
    self.needTable[asset] = nil
end

function CityGridView:LoadPriority(isSync, allLoad)
    if not self.toShowList then return end

    local count = #self.toShowList
    if count == 0 then
        return
    end

    local step = allLoad and #self.toShowList or self.loadEveryTick
    local sync = isSync or false

    table.sort(self.toShowList, orderByPriority)
    while step > 0 and #self.toShowList > 0 do
        ---@type CityTileAsset
        local node = table.remove(self.toShowList, 1)
        self.toShowMap[node] = nil
        if node.handle then
            goto continue
        end

        if Utils.IsNull(node.tileView.root) and node ~= node.tileView then
            g_Logger.ErrorChannel("CityGridView", "%s TileView Root 为空，状态异常:%s", tostring(node), tostring(node.tileView))
            goto continue
        end

        local handle = self.createHelper:Create(node.prefabName, node.tileView:GetAssetAttachTrans(node.isUI),
            Delegate.GetOrCreate(node, node.OnAssetLoadedProcess), node.tileView.tile:GetCell(), node.priority, sync or node.syncLoaded)
        if not node:IsLoadedOrEmpty() then
            step = step - 1
        end
        node.handle = handle
        ::continue::
    end
end

function CityGridView:ShowAll()
    self.lastViewRect = nil
    self:UpdateCamera(self.city:GetCamera())
end

function CityGridView:HideAll()
    if not self.currHashSet then return end
    for _, tile in pairs(self.currHashSet) do
        tile:Hide()
        self.currHashSet[tile] = nil
    end
end

function CityGridView:OnCityActive()
    self:ShowAll()
    self:LoadPriority(true, true)
end

function CityGridView:OnCityInactive()
    -- self:HideAll()
end

function CityGridView:NeedLoadView()
    return true
end

return CityGridView