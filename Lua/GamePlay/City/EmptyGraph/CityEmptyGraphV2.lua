local CityManagerBase = require("CityManagerBase")
---@class CityEmptyGraphV2:CityManagerBase
---@field new fun():CityEmptyGraphV2
local CityEmptyGraphV2 = class("CityEmptyGraphV2", CityManagerBase)
local CityGridLayerMask = require("CityGridLayerMask")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityZoneStatus = require("CityZoneStatus")
local ConfigRefer = require("ConfigRefer")

function CityEmptyGraphV2:DoDataLoad()
    self.sizeX = self.city.gridConfig.cellsX
    self.sizeY = self.city.gridConfig.cellsY

    self.length = self.sizeX * self.sizeY
    self.rowData = bytearray.new(self.length)
    self.status = bytearray.new(self.length)
    self.innerBuffer = bytearray.new(self.length)
    self.safeAreaIdsDirty = true
    self:InitData()
    self:AddEventListener()
    return self:DataLoadFinish()
end

function CityEmptyGraphV2:OnBasicResourceLoadFinish()
    self.safeAreaWallController = self.city.safeAreaWallController
end

function CityEmptyGraphV2:OnBasicResourceUnloadStart()
    self.safeAreaWallController = nil
end

---@private
function CityEmptyGraphV2:InitData()
    self.zoneStatus = {}
    for id, zone in pairs(self.city.zoneManager.zoneIdMap) do
        self.zoneStatus[id] = zone:Recovered()
    end

    local mapData = require("CityMapBinaryData").Instance
    local tiledGridLayer = self.city.gridLayer.layerMap.map
    local tiledZoneMap = mapData.zoneData
    local tiledValidMap = mapData.validData
    for i = 1, self.sizeX * self.sizeY do
        self.status[i] = (tiledValidMap[i] and self.zoneStatus[tiledZoneMap[i]] and not CityGridLayerMask.IsPlaced(tiledGridLayer[i])) and 1 or 0-- TileGood or TileBad
    end
end

function CityEmptyGraphV2:DoDataUnload()
    self:RemoveEventListener()
    self.rowData = nil
    self.sizeX = nil
    self.sizeY = nil
    self.zoneStatus = nil
    self.status = nil
    self.safeAreaBuffer = nil
    self.innerBuffer = nil
    self.postResourceLoadData = nil
end

function CityEmptyGraphV2:DoViewLoad()
    self.safeAreaBuffer = bytearray.new(self.length)
    local pointer, length = self.safeAreaBuffer:topointer()
    local areaIdsArray =  self:GetSafeAreaIds()
    self.safeAreaWallController:UpdateSafeAreaLuaBuffer(pointer, length, areaIdsArray, #areaIdsArray, true)

    local source1, length1 = self.status:topointer()
    local source2, length2 = self.safeAreaBuffer:topointer()
    local target, length = self.rowData:topointer()
    if length1 == length and length2 == length then
        CS.BytePtrHelper.And(source1, source2, target, length)
    end
    return self:ViewLoadFinish()
end

function CityEmptyGraphV2:DoViewUnload()
    self.safeAreaBuffer = nil
end

---@private
function CityEmptyGraphV2:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_LAYER_UPDATE, Delegate.GetOrCreate(self, self.OnGridLayerUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneBatchChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnSafeAreaStatusRefresh))
end

---@private
function CityEmptyGraphV2:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_LAYER_UPDATE, Delegate.GetOrCreate(self, self.OnGridLayerUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneBatchChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnSafeAreaStatusRefresh))
end

---@private
function CityEmptyGraphV2:OnGridLayerUpdate(city, x, y, sizeX, sizeY)
    if city ~= self.city then return end

    local mapData = require("CityMapBinaryData").Instance
    local tiledGridLayer = self.city.gridLayer.layerMap.map
    local tiledZoneMap = mapData.zoneData
    local tiledValidMap = mapData.validData

    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            local idx = j * self.sizeX + i + 1
            if idx <= self.length then
                self.status[idx] = (tiledValidMap[idx] and self.zoneStatus[tiledZoneMap[idx]] and not CityGridLayerMask.IsPlaced(tiledGridLayer[idx])) and 1 or 0 --TileGood or TileBad
                if self.safeAreaBuffer then
                    self.rowData[idx] = (self.status[idx] & self.safeAreaBuffer[idx])
                end
            end
        end
    end
end

---@private
function CityEmptyGraphV2:OnZoneBatchChanged(city, changedMap)
    if city ~= self.city then return end

    local zones = {}
    for k, v in pairs(changedMap) do
        if v == CityZoneStatus.Recovered then
            zones[k] = true
            self.zoneStatus[k] = true
        end
    end

    local mapData = require("CityMapBinaryData").Instance
    local tiledGridLayer = self.city.gridLayer.layerMap.map
    local tiledZoneMap = mapData.zoneData
    local tiledValidMap = mapData.validData
    
    for zoneId, _ in pairs(zones) do
        local area2idx = mapData.area2idx[zoneId]
        for _, idx in ipairs(area2idx) do
            self.status[idx] = (tiledValidMap[idx] and self.zoneStatus[tiledZoneMap[idx]] and not CityGridLayerMask.IsPlaced(tiledGridLayer[idx])) and 1 or 0 --TileGood or TileBad
        end
    end

    if self.safeAreaBuffer then
        local source1, length1 = self.status:topointer()
        local source2, length2 = self.safeAreaBuffer:topointer()
        local target, length = self.rowData:topointer()
        if length1 == length and length2 == length then
            CS.BytePtrHelper.And(source1, source2, target, length)
        end
    end
end

function CityEmptyGraphV2:OnSafeAreaStatusRefresh()
    self.safeAreaIdsDirty = true
    if not self.safeAreaWallController then return end
    local pointer, size = self.safeAreaBuffer:topointer()
    local areaIdsArray = self:GetSafeAreaIds()
    self.safeAreaWallController:UpdateSafeAreaLuaBuffer(pointer, size, areaIdsArray, #areaIdsArray, true)
    
    local source1, length1 = self.status:topointer()
    local source2, length2 = self.safeAreaBuffer:topointer()
    local target, length = self.rowData:topointer()
    if length1 == length and length2 == length then
        CS.BytePtrHelper.And(source1, source2, target, length)
    end
end

function CityEmptyGraphV2:GetSpaceEnoughPos(sizeX, sizeY, tarX, tarY)
    local pointer, size = self.rowData:topointer()
    local x, y = CS.EmptyGraph.GetCoord(pointer, size, self.sizeX, self.sizeY, sizeX, sizeY, tarX, tarY)
    if x > 0 and y > 0 then
        return x, y
    end
end

---@param singleLego CityLegoBuilding
function CityEmptyGraphV2:GetInnerSpaceEnoughPos(sizeX, sizeY, tarX, tarY, singleLego)
    local mapData = require("CityMapBinaryData").Instance
    local tiledGridLayer = self.city.gridLayer.layerMap.map
    local tiledZoneMap = mapData.zoneData
    local tiledValidMap = mapData.validData
    local creepMap = self.city.creepManager.area.map
    local buffer = self:GetInnerRoomBuffer()

    local legoBuildings = {}
    if singleLego == nil then
        for _, v in pairs(self.city.legoManager.legoBuildings) do
            table.insert(legoBuildings, v)
        end
    else
        table.insert(legoBuildings, singleLego)
    end

    for _, legoBuilding in ipairs(legoBuildings) do
        for x, y, floor in legoBuilding.floorPosMap:pairs() do
            local realIdx = y * self.sizeX + x + 1
            local flag = tiledValidMap[realIdx]
                and self.zoneStatus[tiledZoneMap[realIdx]]
                and not CityGridLayerMask.IsPlacedExceptLego(tiledGridLayer[realIdx])
                and CityGridLayerMask.IsSafeArea(tiledGridLayer[realIdx])
                and (creepMap[realIdx] or 0) == 0
            buffer[realIdx] = flag and 1 or 0
        end
    end

    local pointer, size = buffer:topointer()
    local retX, retY = CS.EmptyGraph.GetCoord(pointer, size, self.sizeX, self.sizeY, sizeX, sizeY, tarX, tarY)
    if retX > 0 and retY > 0 then
        return retX, retY
    end
end

function CityEmptyGraphV2:GetRectSpaceEnoughPos(minX, minY, maxX, maxY, sizeX, sizeY, tarX, tarY)
    local mapData = require("CityMapBinaryData").Instance
    local tiledGridLayer = self.city.gridLayer.layerMap.map
    local tiledZoneMap = mapData.zoneData
    local tiledValidMap = mapData.validData
    local creepMap = self.city.creepManager.area.map

    local innerSizeX = maxX - minX + 1
    local innerSizeY = maxY - minY + 1
    local buffer = bytearray.new(innerSizeX, innerSizeY)
    for j = 0, innerSizeY - 1 do
        for i = 0, innerSizeX - 1 do
            local idx = j * innerSizeX + i + 1
            local realIdx = (minY + j) * self.sizeX + (minX + i) + 1
            local flag = tiledValidMap[realIdx]
                and self.zoneStatus[tiledZoneMap[realIdx]]
                and not CityGridLayerMask.HasFurniture(tiledGridLayer[realIdx])
                and (creepMap[realIdx] or 0) == 0
                and (innerSizeX == 1 or (i == innerSizeX - 1) or not self.city:HasWallOrDoorAtRight(minX+i, minY+j))
                and (innerSizeY == 1 or (j == innerSizeY - 1) or not self.city:HasWallOrDoorAtTop(minX+i, minY+j))
            buffer[idx] = string.pack("<I1", flag and 1 or 0)
        end
    end

    local pointer, size = buffer:topointer()
    local retX, retY = CS.EmptyGraph.GetCoord(pointer, size, innerSizeX, innerSizeY, sizeX, sizeY, tarX - minX, tarY - minY)
    if retX and retY then
        return retX + minX, retY + minY
    end
end

---@return number[]
function CityEmptyGraphV2:GetSafeAreaIds()
    if self.safeAreaIdsDirty then
        self.safeAreaIds = {}
        local ModuleRefer = require("ModuleRefer")
        for id, v in pairs(ModuleRefer.CitySafeAreaModule._safeAreaStatus) do
            if v == 0 then
                table.insert(self.safeAreaIds, id)
            end
        end
    end
    return self.safeAreaIds
end

function CityEmptyGraphV2:GetInnerRoomBuffer()
    self.innerBuffer:clear()
    return self.innerBuffer
end

function CityEmptyGraphV2:NeedLoadData()
    return true
end

function CityEmptyGraphV2:NeedLoadView()
    return true
end

return CityEmptyGraphV2