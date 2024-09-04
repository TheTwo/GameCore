local CityManagerBase = require("CityManagerBase")
---@class CityGridLayer:CityManagerBase
---@field new fun():CityGridLayer
local CityGridLayer = class("CityGridLayer", CityManagerBase)
local RectDyadicMap = require("RectDyadicMap")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityGridLayerMask = require("CityGridLayerMask")
local ConfigRefer = require("ConfigRefer")
local CityLegoDefine = require("CityLegoDefine")
local lazyMeta = {__index = function(t,k) return CityGridLayerMask.None end}
local CityUtils = require("CityUtils")

---@param gridConfig CityGridConfig
function CityGridLayer:DoDataLoad()
    self.gridConfig = self.city.gridConfig
    --- 利用元表省略掉初始化遍历全图的赋值
    self.layerMap = RectDyadicMap.new(self.gridConfig.cellsX, self.gridConfig.cellsY, lazyMeta)

    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnGridCellAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnGridCellRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_MOVING, Delegate.GetOrCreate(self, self.OnGridCellMoving))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_ID_CHANGED, Delegate.GetOrCreate(self, self.OnGridIdChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_UPDATE_WITH_SIZE_CHANGE, Delegate.GetOrCreate(self, self.OnGridSizeChanged))

    g_Game.EventManager:AddListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:AddListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMoving))

    g_Game.EventManager:AddListener(EventConst.CITY_GENERATING_RES_ADD, Delegate.GetOrCreate(self, self.OnGeneratingResAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_GENERATING_RES_REMOVE, Delegate.GetOrCreate(self, self.OnGeneratingResRemove))

    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_ADD, Delegate.GetOrCreate(self, self.OnLegoBuildingAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_REMOVE, Delegate.GetOrCreate(self, self.OnLegoBuildingRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_MOVE, Delegate.GetOrCreate(self, self.OnLegoBuildingMove))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_RESIZE, Delegate.GetOrCreate(self, self.OnLegoBuildingResize))

    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_FLOOR_ADD, Delegate.GetOrCreate(self, self.OnLegoFloorAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_FLOOR_REMOVE, Delegate.GetOrCreate(self, self.OnLegoFloorRemove))

    return self:DataLoadFinish()
end

function CityGridLayer:DoDataUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnGridCellAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnGridCellRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_MOVING, Delegate.GetOrCreate(self, self.OnGridCellMoving))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_ID_CHANGED, Delegate.GetOrCreate(self, self.OnGridIdChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_UPDATE_WITH_SIZE_CHANGE, Delegate.GetOrCreate(self, self.OnGridSizeChanged))

    g_Game.EventManager:RemoveListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMoving))

    g_Game.EventManager:RemoveListener(EventConst.CITY_GENERATING_RES_ADD, Delegate.GetOrCreate(self, self.OnGeneratingResAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GENERATING_RES_REMOVE, Delegate.GetOrCreate(self, self.OnGeneratingResRemove))

    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_ADD, Delegate.GetOrCreate(self, self.OnLegoBuildingAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_REMOVE, Delegate.GetOrCreate(self, self.OnLegoBuildingRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_MOVE, Delegate.GetOrCreate(self, self.OnLegoBuildingMove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_RESIZE, Delegate.GetOrCreate(self, self.OnLegoBuildingResize))

    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_FLOOR_ADD, Delegate.GetOrCreate(self, self.OnLegoFloorAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_FLOOR_REMOVE, Delegate.GetOrCreate(self, self.OnLegoFloorRemove))

    self.layerMap:Clear()
    self.layerMap = nil
end

---@param city City
---@param x number
---@param y number
function CityGridLayer:OnGridCellAdd(city, x, y)
    if self.city ~= city then
        return
    end

    local cell = self.city.grid:GetCell(x, y)
    if cell:IsBuilding() then
        self:PlusLayerByBuilding(cell)
    elseif cell:IsResource() then
        self:PlusLayerByResource(cell)
    elseif cell:IsNpc() then
        self:PlusLayerByNpc(cell)
    elseif cell:IsCreepNode() then
        self:PlusLayerByCreepNode(cell)
    end
    self:NoticeUpdate(x, y, cell.sizeX, cell.sizeY)
end

---@param cell CityGridCell
function CityGridLayer:PlusLayerByBuilding(cell)
    local levelCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    local status = self.city:GetCastle().BuildingInfos[cell.tileId].Status
    local offset = levelCell:InnerPos()
    local minX, minY = cell.x + offset:X(), cell.y + offset:Y()
    local maxX, maxY = minX + levelCell:InnerSizeX(), minY + levelCell:InnerSizeY()
    
    if not CityUtils.IsStatusReadyForFurniture(status) or (CityUtils.IsRepairing(status) and levelCell:Level() == 1) then
        for x = cell.x, cell.x + cell.sizeX - 1 do
            for y = cell.y, cell.y + cell.sizeY - 1 do
                self:PlaceBuildingBorder(x, y)
            end
        end
    else
        for x = cell.x, cell.x + cell.sizeX - 1 do
            for y = cell.y, cell.y + cell.sizeY - 1 do
                if minX <= x and x < maxX and minY <= y and y < maxY then
                    self:PlaceIndoorSpace(x, y)
                else
                    self:PlaceBuildingBorder(x, y)
                end
            end
        end
    end
end

function CityGridLayer:PlusLayerByResource(cell)
    for x = cell.x, cell.x + cell.sizeX - 1 do
        for y = cell.y, cell.y + cell.sizeY - 1 do
            self:PlaceResource(x, y)
        end
    end
end

---@param cell CityGridCell
function CityGridLayer:PlusLayerByNpc(cell)
    for x = cell.x, cell.x + cell.sizeX - 1 do
        for y = cell.y, cell.y + cell.sizeY - 1 do
            self:PlaceNpc(x, y)
        end
    end
end

function CityGridLayer:PlusLayerByCreepNode(cell)
    for x = cell.x, cell.x + cell.sizeX - 1 do
        for y = cell.y, cell.y + cell.sizeY - 1 do
            self:PlaceCreepNode(x, y)
        end
    end
end

---@param city City
---@param cell CityGridCell
function CityGridLayer:OnGridCellRemove(city, cell)
    if self.city ~= city then return end
    self:OnGridCellRemoveImp(cell.x, cell.y, cell.sizeX, cell.sizeY)
    self:NoticeUpdate(cell.x, cell.y, cell.sizeX, cell.sizeY)
end

function CityGridLayer:OnGridCellRemoveImp(x, y, sizeX, sizeY)
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            self:CleanGridCell(i, j)
        end
    end
end

---@param city City
---@param oriX number
---@param oriY number
---@param newX number
---@param newY number
function CityGridLayer:OnGridCellMoving(city, oriX, oriY, newX, newY)
    if self.city ~= city then return end
    local cell = self.city.grid:GetCell(newX, newY)
    self:OnGridCellRemoveImp(oriX, oriY, cell.sizeX, cell.sizeY)
    self:NoticeUpdate(oriX, oriY, cell.sizeX, cell.sizeY)
    self:OnGridCellAdd(city, newX, newY)
end

---@param city City
---@param x number
---@param y number
function CityGridLayer:OnGridIdChanged(city, x, y)
    if self.city ~= city then return end
    local cell = self.city.grid:GetCell(x, y)
    self:OnGridCellRemoveImp(x, y, cell.sizeX, cell.sizeY)
    self:NoticeUpdate(x, y, cell.sizeX, cell.sizeY)
    self:OnGridCellAdd(city, x, y)
end

---@param city City
---@param x number
---@param y number
---@param oriSizeX number
---@param oriSizeY number
function CityGridLayer:OnGridSizeChanged(city, x, y, oriSizeX, oriSizeY, newSizeX, newSizeY)
    if self.city ~= city then return end
    self:OnGridCellRemoveImp(x, y, oriSizeX, oriSizeY)
    self:NoticeUpdate(x, y, oriSizeX, oriSizeY)
    self:OnGridCellAdd(city, x, y)
end

function CityGridLayer:OnFurniturePlaced(city, x, y)
    if self.city ~= city then return end
    local furniture = self.city.furnitureManager:GetPlaced(x, y)
    for i = furniture.x, furniture.x + furniture.sizeX - 1 do
        for j = furniture.y, furniture.y + furniture.sizeY - 1 do
            self:PlaceFurniture(i, j)
        end
    end
    self:NoticeUpdate(x, y, furniture.sizeX, furniture.sizeY)
end

function CityGridLayer:OnFurnitureStorage(city, x, y, sizeX, sizeY)
    if self.city ~= city then return end
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            self:CleanFurniture(i, j)
        end
    end
    self:NoticeUpdate(x, y, sizeX, sizeY)
end

function CityGridLayer:OnFurnitureMoving(city, oriX, oriY, newX, newY, tileId, oldSizeX, oldSizeY)
    if self.city ~= city then return end

    self:OnFurnitureStorage(city, oriX, oriY, oldSizeX, oldSizeY)
    self:OnFurniturePlaced(city, newX, newY)
end

function CityGridLayer:OnGeneratingResAdd(city, id)
    if self.city ~= city then return end

    local cell = self.city.cityWorkManager:GetResGenUnit(id)
    for i = cell.x, cell.x + cell.sizeX - 1 do
        for j = cell.y, cell.y + cell.sizeY - 1 do
            self:PlaceGenerateRes(i, j)
        end
    end
    self:NoticeUpdate(cell.x, cell.y, cell.sizeX, cell.sizeY)
end

---@param unit CityWorkProduceResGenUnit
function CityGridLayer:OnGeneratingResRemove(city, unit)
    if self.city ~= city then return end
   
    for i = unit.x, unit.x + unit.sizeX - 1 do
        for j = unit.y, unit.y + unit.sizeY - 1 do
            self:CleanGenerateRes(i, j)
        end
    end
    self:NoticeUpdate(unit.x, unit.y, unit.sizeX, unit.sizeY)
end

function CityGridLayer:OnLegoBuildingAdd(city, legoBuilding)
    if self.city ~= city then return end

    for i = legoBuilding.x, legoBuilding.x + legoBuilding.sizeX - 1 do
        for j = legoBuilding.z, legoBuilding.z + legoBuilding.sizeZ - 1 do
            self:PlaceLegoBuildingArea(i, j)
        end
    end
    self:NoticeUpdate(legoBuilding.x, legoBuilding.z, legoBuilding.sizeX, legoBuilding.sizeZ)
end

function CityGridLayer:OnLegoBuildingRemove(city, legoBuilding)
    if self.city ~= city then return end
    
    for i = legoBuilding.x, legoBuilding.x + legoBuilding.sizeX - 1 do
        for j = legoBuilding.z, legoBuilding.z + legoBuilding.sizeZ - 1 do
            self:ClearLegoBuildingArea(i, j)
        end
    end
    self:NoticeUpdate(legoBuilding.x, legoBuilding.z, legoBuilding.sizeX, legoBuilding.sizeZ)
end

function CityGridLayer:OnLegoBuildingMove(city, legoBuilding, oldX, oldY, newX, newY, sizeX, sizeY)
    if self.city ~= city then return end

    for i = oldX, oldX + sizeX - 1 do
        for j = oldY, oldY + sizeY - 1 do
            self:ClearLegoBuildingArea(i, j)
        end
    end
    self:NoticeUpdate(oldX, oldY, sizeX, sizeY)

    for i = newX, newX + sizeX - 1 do
        for j = newY, newY + sizeY - 1 do
            self:PlaceLegoBuildingArea(i, j)
        end
    end
    self:NoticeUpdate(newX, newY, sizeX, sizeY)
end

function CityGridLayer:OnLegoBuildingResize(city, legoBuilding, oldSizeX, oldSizeY, newSizeX, newSizeY, x, z)
    if self.city ~= city then return end

    for i = x, x + oldSizeX - 1 do
        for j = z, z + oldSizeY - 1 do
            self:ClearLegoBuildingArea(i, j)
        end
    end

    for i = x, x + newSizeX - 1 do
        for j = z, z + newSizeY - 1 do
            self:PlaceLegoBuildingArea(i, j)
        end
    end

    self:NoticeUpdate(x, z, math.max(oldSizeX, newSizeX), math.max(oldSizeY, newSizeY))
end

function CityGridLayer:OnLegoFloorRemove(city, legoBuilding)
    if self.city ~= city then return end

    for i = legoBuilding.x, legoBuilding.x + legoBuilding.sizeX - 1 do
        for j = legoBuilding.z, legoBuilding.z + legoBuilding.sizeZ - 1 do
            self:ClearLegoBuildingArea(i, j)
        end
    end
    self:NoticeUpdate(legoBuilding.x, legoBuilding.y, legoBuilding.sizeX, legoBuilding.sizeY)
end

function CityGridLayer:OnLegoFloorAdd(city, x, y)
    if self.city ~= city then return end

    for i = x, x + CityLegoDefine.BlockSize - 1 do
        for j = y, y + CityLegoDefine.BlockSize - 1 do
            self:PlaceLegoBase(i, j)
        end
    end
    self:NoticeUpdate(x, y, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize)
end

function CityGridLayer:OnLegoFloorRemove(city, x, y)
    if self.city ~= city then return end

    for i = x, x + CityLegoDefine.BlockSize - 1 do
        for j = y, y + CityLegoDefine.BlockSize - 1 do
            self:ClearLegoBase(i, j)
        end
    end
    self:NoticeUpdate(x, y, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize)
end

function CityGridLayer:PlaceBuildingBorder(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.Building)
end

function CityGridLayer:PlaceIndoorSpace(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.Building)
end

function CityGridLayer:PlaceFurniture(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.Furniture)
end

function CityGridLayer:CleanFurniture(x, y)
    self:IntersectionFlag(x, y, ~CityGridLayerMask.Furniture)
end

function CityGridLayer:PlaceNpc(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.Npc)
end

function CityGridLayer:PlaceCreepNode(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.Creep)
end

function CityGridLayer:PlaceResource(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.Resource)
end

function CityGridLayer:CleanGridCell(x, y)
    self:IntersectionFlag(x, y, ~(CityGridLayerMask.CellTileFlag))
end

function CityGridLayer:PlaceGenerateRes(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.GeneratingRes)
end

function CityGridLayer:CleanGenerateRes(x, y)
    self:IntersectionFlag(x, y, ~CityGridLayerMask.GeneratingRes)
end

function CityGridLayer:PlaceLegoBuildingArea(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.LegoBuilding)
end

function CityGridLayer:ClearLegoBuildingArea(x, y)
    self:IntersectionFlag(x, y, ~CityGridLayerMask.LegoBuilding)
end

function CityGridLayer:PlaceLegoBase(x, y)
    self:UnionFlag(x, y, CityGridLayerMask.LegoBase)
end

function CityGridLayer:ClearLegoBase(x, y)
    self:IntersectionFlag(x, y, (~CityGridLayerMask.LegoBase))
end

---@param areaData CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
function CityGridLayer:InitPlaceSafeArea(areaData)
    local map = areaData:ZoneSliceMap()
    for _, v in pairs(map) do
        local length = v.Length
        for i = 0, length - 1 do
            local valueTuple = v[i]
            local posX = valueTuple.Item1
            local posY = valueTuple.Item2
            local count = valueTuple.Item3
            for offset = 0, count - 1 do
                self:UnionFlag(posX, posY + offset, CityGridLayerMask.SafeArea)
            end
        end
    end
end

---@param wallData CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
function CityGridLayer:InitPlaceSafeAreaWall(wallData, inUsingWallMap)
    local map = wallData:ZoneSliceMap()
    for wallId, v in pairs(map) do
        if not inUsingWallMap[wallId] then
            goto continue
        end
        local length = v.Length
        for i = 0, length - 1 do
            local valueTuple = v[i]
            local posX = valueTuple.Item1
            local posY = valueTuple.Item2
            local count = valueTuple.Item3
            for offset = 0, count - 1 do
                local y = posY + offset
                self:UnionFlag(posX, y, CityGridLayerMask.SafeAreaWall)
            end
        end
        ::continue::
    end
end

---取并集
function CityGridLayer:UnionFlag(x, y, flag)
    local value = self.layerMap:Get(x, y)
    value = value | flag
    self.layerMap:Update(x, y, value)
end

---取交集(清除某些位)
function CityGridLayer:IntersectionFlag(x, y, flag)
    local value = self.layerMap:Get(x, y)
    value = value & flag
    self.layerMap:Update(x, y, value)
end

function CityGridLayer:Get(x, y)
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    return self.layerMap:Get(x, y)
end

function CityGridLayer:IsEmpty(x, y)
    local mask = self:Get(x, y)
    return mask and (mask & CityGridLayerMask.PlacedFlag) == 0
end

function CityGridLayer:IsInnerBuildingMask(x, y)
    local mask = self:Get(x, y)
    return CityGridLayerMask.IsInLego(mask)
end

function CityGridLayer:IsGeneratingRes(x, y)
    local mask = self:Get(x, y)
    return CityGridLayerMask.IsGeneratingRes(mask)
end

function CityGridLayer:Print()
    local ret = {}
    for y = self.layerMap.maxY - 1, 0, -1 do
        local array = {}
        for x = 0, self.layerMap.maxX - 1 do
            table.insert(array, self:Get(x, y))
        end
        table.insert(ret, table.concat(array, ','))
    end
    print(table.concat(ret, '\n'))
end

function CityGridLayer:NoticeUpdate(x, y, sizeX, sizeY)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_GRID_LAYER_UPDATE, self.city, x, y, sizeX, sizeY)
end

function CityGridLayer:NeedLoadData()
    return true
end

return CityGridLayer