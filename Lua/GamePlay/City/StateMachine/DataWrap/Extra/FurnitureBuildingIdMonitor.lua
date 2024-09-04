---@class FurnitureBuildingIdMonitor
---@field new fun(city, tileHandle, sizeX, sizeY):FurnitureBuildingIdMonitor
local FurnitureBuildingIdMonitor = class("FurnitureBuildingIdMonitor")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param city City
---@param tileHandle CityStateTileHandle
function FurnitureBuildingIdMonitor:ctor(city, tileHandle, sizeX, sizeY)
    self.city = city
    self.gridLayer = self.city.gridLayer
    self.tileHandle = tileHandle
    self.sizeX = sizeX
    self.sizeY = sizeY

    self.currentBuildingIdMap = {}
    self:UpdatePosition(tileHandle.curX, tileHandle.curY)
end

function FurnitureBuildingIdMonitor:Initialize()
    g_Game.EventManager:AddListener(EventConst.CITY_STATE_TILE_HANDLE_MOVING, Delegate.GetOrCreate(self, self.OnHandleMoving))
    g_Game.EventManager:AddListener(EventConst.CITY_STATE_TILE_HANDLE_ROTATE, Delegate.GetOrCreate(self, self.OnHandleRotate))
end

function FurnitureBuildingIdMonitor:Release()
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATE_TILE_HANDLE_MOVING, Delegate.GetOrCreate(self, self.OnHandleMoving))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATE_TILE_HANDLE_ROTATE, Delegate.GetOrCreate(self, self.OnHandleRotate))
end

function FurnitureBuildingIdMonitor:UpdateSize(sizeX, sizeY)
    self.sizeX = sizeX
    self.sizeY = sizeY
    self:UpdatePosition(self.tileHandle.curX, self.tileHandle.curY)
end

function FurnitureBuildingIdMonitor:UpdatePosition(x, y)
    local currentBuildingIdMap = {}
    for i = x, x + self.sizeX - 1 do
        for j = y, y + self.sizeY - 1 do
            if self.gridLayer:IsInnerBuildingMask(i, j) then
                local legoBuilding = self.city.legoManager:GetLegoBuildingAt(i, j)
                if legoBuilding then
                    currentBuildingIdMap[legoBuilding.id] = true
                end
            end
        end
    end

    for id, _ in pairs(self.currentBuildingIdMap) do
        if not currentBuildingIdMap[id] then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_SELECTER_LEAVE_BUILDING, self.city, id, self.tileHandle)
        end
    end

    for id, _ in pairs(currentBuildingIdMap) do
        if not self.currentBuildingIdMap[id] then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_SELECTER_ENTER_BUILDING, self.city, id, self.tileHandle)
        end
    end

    self.currentBuildingIdMap = currentBuildingIdMap
end

---@param tileHandle CityStateTileHandle
function FurnitureBuildingIdMonitor:OnHandleMoving(tileHandle)
    if self.tileHandle == tileHandle then
        self:UpdatePosition(tileHandle.curX, tileHandle.curY)
    end
end

---@param tileHandle CityStateTileHandle
function FurnitureBuildingIdMonitor:OnHandleRotate(tileHandle)
    if self.tileHandle == tileHandle then
        self:UpdateSize(tileHandle.dataSource.sizeX, tileHandle.dataSource.sizeY)
    end
end

function FurnitureBuildingIdMonitor:GetCurrentBuildingIdMap()
    local ret = {}
    for id, _ in pairs(self.currentBuildingIdMap) do
        ret[id] = true
    end
    return ret
end

return FurnitureBuildingIdMonitor