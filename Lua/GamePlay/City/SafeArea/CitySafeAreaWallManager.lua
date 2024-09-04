local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityManagerBase = require("CityManagerBase")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityGridLayerMask = require("CityGridLayerMask")
local FurnitureCategory = require("FurnitureCategory")
local RectDyadicMap = require("RectDyadicMap")
local ConfigRefer = require("ConfigRefer")
local CitySafeAreaWallDoor = require("CitySafeAreaWallDoor")
local UIMediatorNames = require("UIMediatorNames")
local CitySafeAreaWallBattleObject = require("CitySafeAreaWallBattleObject")

---@class CitySafeAreaWallManager:CityManagerBase
---@field new fun():CitySafeAreaWallManager
local CitySafeAreaWallManager = class('CitySafeAreaWallManager', CityManagerBase)

function CitySafeAreaWallManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    ---@type CS.DragonReborn.City.CitySafeAreaWallController
    self._wallController = nil
    ---@type RectDyadicMap
    self.wallPlaced = nil
    ---@type table<number, CitySafeAreaWallDoor>
    self.wallHashMap = nil
    self.doorZoneListeners = {}
    ---@type table<number, CitySafeAreaWallBattleObject>
    self._runtimeBattleViews = {}
    ---@type table<number, RectDyadicMap>
    self._wallToGrid = {}
    self._doorAndWallLoaded = false
    self._dummyDoorId = 99999
end

function CitySafeAreaWallManager:NeedLoadBasicAsset()
    return true
end

function CitySafeAreaWallManager:OnBasicResourceLoadFinish()
    self._wallController = self.city.safeAreaWallController
end

function CitySafeAreaWallManager:DoDataLoad()
    self.wallHashMap = setmetatable({}, { __mode = "kv"})
    self.wallPlaced = RectDyadicMap.new(self.city.gridConfig.cellsX, self.city.gridConfig.cellsY)
    local safeAreaDataProvider = self.city:GetSafeAreaSliceDataUsage()
    local dataProvider = self.city:GetSafeAreaWallSliceDataUsage()
    self.city.gridLayer:InitPlaceSafeArea(safeAreaDataProvider)
    local inUsingWallMap = {}
    for _, wallId in ipairs(ModuleRefer.CitySafeAreaModule._inUsingWall) do
        inUsingWallMap[wallId] = true
    end
    self.city.gridLayer:InitPlaceSafeAreaWall(dataProvider, inUsingWallMap)
    self:InitWallGridMap(dataProvider, self.city.gridConfig.cellsX, self.city.gridConfig.cellsY)
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnSafeAreaStatusChanged))
    return self:DataLoadFinish()
end

function CitySafeAreaWallManager:OnCameraLoaded(camera)
    self.camera = camera
    if self._wallController then
        self._wallController:SetCamera(camera:GetUnityCamera())
    end
end

function CitySafeAreaWallManager:OnCameraUnload()
    self.camera = nil
    if self._wallController then
        self._wallController:SetCamera(nil)
    end
end

function CitySafeAreaWallManager:OnViewLoadStart()
    local safeAreaDataProvider = self.city:GetSafeAreaSliceDataUsage()
    local dataProvider = self.city:GetSafeAreaWallSliceDataUsage()
    local edgeProvider = self.city:GetSafeAreaEdgeDataUsage()
    local gridCount = CS.UnityEngine.Vector2Int(self.city.gridConfig.cellsX, self.city.gridConfig.cellsY)
    local gridSize = CS.UnityEngine.Vector2(self.city.gridConfig.unitsPerCellX, self.city.gridConfig.unitsPerCellY)
    self._wallController:Initialize(safeAreaDataProvider, dataProvider, edgeProvider, self.city.zeroPoint, gridCount, gridSize, self.city.scale)
    self._wallController:InitConfig(ModuleRefer.CitySafeAreaModule:GetDoorIdsIntArray())
    if self.camera and self._wallController then
        self._wallController:SetCamera(self.camera:GetUnityCamera())
    end
    self:LoadWallAndDoors()
end

function CitySafeAreaWallManager:OnBasicResourceUnloadStart()
    if self._wallController then
        self._wallController:Release()
    end
    self._wallController = nil
end

---@param wallData CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
function CitySafeAreaWallManager:InitWallGridMap(wallData, cellX, cellY)
    table.clear(self._wallToGrid)
    local map = wallData:ZoneSliceMap()
    for wallId, zoneSliceData in pairs(map) do
        local length = zoneSliceData.Length
        local wallGridArray = RectDyadicMap.new(cellX, cellY)
        self._wallToGrid[wallId] = wallGridArray
        for i = 0, length - 1 do
            local valueTuple = zoneSliceData[i]
            local posX = valueTuple.Item1
            local posY = valueTuple.Item2
            local count = valueTuple.Item3
            for offset = 0, count - 1 do
                wallGridArray:Add(posX, posY + offset, true)
            end
        end
    end
end

function CitySafeAreaWallManager:LoadWallAndDoors()
    if self.dataStatus ~= CityManagerBase.LoadState.Loaded then return end
    if self.basicResourceStatus ~= CityManagerBase.LoadState.Loaded then return end
    if self._doorAndWallLoaded then return end
    self._doorAndWallLoaded = true
    local inUsingWallAndDoor = {}
    for _, value in ipairs(ModuleRefer.CitySafeAreaModule._inUsingWall) do
        inUsingWallAndDoor[value] = true
    end
    for _, v in ConfigRefer.CitySafeAreaWall:pairs() do
        local id = v:Id()
        if not inUsingWallAndDoor[id] then
            goto continue
        end
        local has,gridCenterPox = self._wallController:GetWallCenterGrid(id)
        if has then
            local dir = self:GetWallDir(id)
            local door = CitySafeAreaWallDoor.new(id, gridCenterPox.x, gridCenterPox.y, dir, v:IsDoor(), self._wallToGrid[id])
            self.wallHashMap[id] = door
            self.wallPlaced:Add(door.x, door.y, door)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_PLACE, self.city, door.x, door.y)
        else
            g_Logger.Warn("check this wallId:%s, no center", id)
        end
        ::continue::
    end
end

function CitySafeAreaWallManager:UnLoadWallAndDoors()
    self._doorAndWallLoaded = false
    for _, door in pairs(self.wallHashMap) do
        local x, y = door.x, door.y
        local id = door.singleId
        self.wallHashMap[id] = nil
        g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_REMOVE, self.city, x, y)
    end
    self.wallPlaced:Clear()
end

function CitySafeAreaWallManager:OnCityActive()
    self._wallController:OnCityMapActive()
    self._wallController:SyncDoorAndWallState(ModuleRefer.CitySafeAreaModule:GetNeedShowWalls(), self.city.cityPathFinding and self.city.cityPathFinding._navMeshWrapper)
    self:NotifySafeAreaStatusToCsharp()
    self:RegisterGridEvent()
end

function CitySafeAreaWallManager:OnCityInactive()
    self:UnregisterGridEvent()
end

function CitySafeAreaWallManager:DoDataUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnSafeAreaStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
    self:UnLoadWallAndDoors()
end

function CitySafeAreaWallManager:OnWallStatusChanged(castleBriefId)
    if not self.city or self.city.uid ~= castleBriefId then
        return
    end
    local needSyncAddGridLayer = {}
    local needSyncRemoveGridLayer = {}
    local inUsingWallAndDoor = {}
    for _, wallId in ipairs(ModuleRefer.CitySafeAreaModule._inUsingWall) do
        inUsingWallAndDoor[wallId] = true
    end
    for _, door in pairs(self.wallHashMap) do
        local x, y = door.x, door.y
        local id = door.singleId
        if not inUsingWallAndDoor[id] then
            self.wallHashMap[id] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_REMOVE, self.city, x, y)
            self.wallPlaced:Delete(x, y)
            needSyncRemoveGridLayer[id] = true
        else
            inUsingWallAndDoor[id] = nil
        end
    end
    for _, v in ConfigRefer.CitySafeAreaWall:pairs() do
        local id = v:Id()
        if not inUsingWallAndDoor[id] then
            goto continue
        end
        local has,gridCenterPox = self._wallController:GetWallCenterGrid(id)
        if has and not self.wallHashMap[id] then
            local dir = self:GetWallDir(id)
            local door = CitySafeAreaWallDoor.new(id, gridCenterPox.x, gridCenterPox.y, dir, v:IsDoor(), self._wallToGrid[id])
            self.wallHashMap[id] = door
            needSyncAddGridLayer[id] = true
            self.wallPlaced:Add(door.x, door.y, door)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_PLACE, self.city, door.x, door.y)
        else
            g_Logger.Warn("check this wallId:%s, no center", id)
        end
        ::continue::
    end
    self._wallController:SyncDoorAndWallState(ModuleRefer.CitySafeAreaModule:GetNeedShowWalls(), self.city.cityPathFinding and self.city.cityPathFinding._navMeshWrapper)
    local gridLayer = self.city.gridLayer
    local toRemoveMask = ~CityGridLayerMask.SafeAreaWall
    local toAddMask = CityGridLayerMask.SafeAreaWall
    for wallId, _ in pairs(needSyncRemoveGridLayer) do
        local gridArray = self._wallToGrid[wallId]
        if gridArray then
            for x,y,_ in gridArray:pairs() do
                gridLayer:IntersectionFlag(x, y, toRemoveMask)
            end
        end
    end
    for wallId, _ in pairs(needSyncAddGridLayer) do
        local gridArray = self._wallToGrid[wallId]
        if gridArray then
            for x,y,_ in gridArray:pairs() do
                gridLayer:UnionFlag(x, y, toAddMask)
            end
        end
    end
end

function CitySafeAreaWallManager:NotifySafeAreaStatusToCsharp()
    local validSafeArea = {}
    local idMin
    local idMax
    local ids = {}
    for _, v in ConfigRefer.CitySafeAreaLinkWall:ipairs() do
        if ModuleRefer.CitySafeAreaModule:IsSafeAreaValid(v:Id()) then
            ids[v:Id()] = true
            if not idMin or idMin > v:Id() then
                idMin = v:Id()
            end
            if not idMax or idMax < v:Id() then
                idMax = v:Id()
            end
        end
    end
    local count = -1
    if idMax and idMin then
        count = idMax - idMin
    end
    for index = 0, count do
        local id = idMin + index
        table.insert(validSafeArea, string.pack("<B", ids[id] and 1 or 0))
    end
    self._wallController:SyncAreaState(table.concat(validSafeArea), idMin or 0)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_MAP_CACHE_REBUILT)
end

function CitySafeAreaWallManager:OnSafeAreaStatusChanged(castleBriefId, changeToNormal, changeToBroken)
    if not self.city or self.city.uid ~= castleBriefId then
        return
    end
    if not self.city.showed then
        return
    end
    local isInRecoverEffectMode = self.city:IsInRecoverZoneEffectMode()
    if changeToNormal then
        for i, _ in pairs(changeToNormal) do
            if not isInRecoverEffectMode then
                g_Game.UIManager:CloseAllByName(UIMediatorNames.CitySafeAreaPlaceTipMediator)
                ---@type CitySafeAreaPlaceTipMediatorParameter
                local parameter = {}
                parameter.zoneContent = I18N.Get("zone_safe_complete")
                g_Game.UIManager:Open(UIMediatorNames.CitySafeAreaPlaceTipMediator, parameter)
            end
            self._wallController:DoSafeAreaEdgeEffect(i, 0.5, CS.UnityEngine.Vector4.one, CS.UnityEngine.Vector4(0,1,0,-1))
            break
        end
    end
    self:NotifySafeAreaStatusToCsharp()
end

function CitySafeAreaWallManager:IsLocationValidForOutDoorFurniture(x, y, furnitureCategory)
    local mask = self.city.gridLayer:Get(x, y)
    if CityGridLayerMask.IsSafeAreaWall(mask) then
        return false
    end
    if FurnitureCategory.Military == furnitureCategory then
        return true
    end
    if not CityGridLayerMask.IsSafeArea(mask) then
        return false
    end
    return self:IsValidSafeArea(x, y)
end

function CitySafeAreaWallManager:IsOutDoorFurnitureCanUse(x, y, furnitureCategory)
    if FurnitureCategory.Economy ~=  furnitureCategory then
        return true
    end
    return self:IsLocationValidForOutDoorFurniture(x, y, furnitureCategory)
end

function CitySafeAreaWallManager:GetSafeAreaId(x, y)
    return self._wallController:GetSafeAreaId(x, y)
end

---@return CS.UnityEngine.Vector2|nil
function CitySafeAreaWallManager:FindNearestSafeAreaCenter(x, y, requireValid)
    ---@type CS.UnityEngine.Vector2
    local matchCenter
    local distance
    for i, v in ConfigRefer.CitySafeAreaLinkWall:pairs() do
        if not requireValid or ModuleRefer.CitySafeAreaModule:IsSafeAreaValid(v:Id()) then
            if not matchCenter then
                local get, center = self._wallController:GetSafeAreaCenterGrid(v:Id())
                if get then
                    matchCenter = center
                    distance = (matchCenter.x - x ) * (matchCenter.x - x ) + (matchCenter.y - y) * (matchCenter.y - y)
                end
            else
                local get, c = self._wallController:GetSafeAreaCenterGrid(v:Id())
                if get then
                    local d = (c.x - x ) * (c.x - x ) + (c.y - y) * (c.y - y)
                    if d < distance then
                        distance = d
                        matchCenter = c
                    end
                end
            end
        end
    end
    return matchCenter
end

function CitySafeAreaWallManager:IsValidSafeAreaId(safeAreaId)
    return ModuleRefer.CitySafeAreaModule:IsSafeAreaValid(safeAreaId)
end

function CitySafeAreaWallManager:IsValidSafeArea(x, y)
    local safeAreaId = self._wallController:GetSafeAreaId(x, y)
    if safeAreaId == 0 then
        return false
    end
    return ModuleRefer.CitySafeAreaModule:IsSafeAreaValid(safeAreaId)
end

function CitySafeAreaWallManager:IsSafeAreaWall(x, y)
    local mask = self.city.gridLayer:Get(x, y)
    return CityGridLayerMask.IsSafeAreaWall(mask)
end

function CitySafeAreaWallManager:IsSafeAreaWallBroken(x, y)
    if not self:IsSafeAreaWall(x, y) then
        return false
    end
    local wallId = self:GetWallId(x, y)
    return ModuleRefer.CitySafeAreaModule:GetWallStatus(wallId) == 1
end

function CitySafeAreaWallManager:IsSafeAreaWallOrDoorAbilityValid(x, y)
    if not self:IsSafeAreaWall(x, y) then
        return false
    end
    local wallId = self:GetWallId(x, y)
    local wallOrDoor = self.wallHashMap[wallId]
    if not wallOrDoor then
        return
    end
    local config = ConfigRefer.CitySafeAreaWall:Find(wallOrDoor:ConfigId())
    if not config then
        return false
    end
    if config:AbilityNeed() <= 0 then
        return true
    end
    local ability = ConfigRefer.CityAbility:Find(config:AbilityNeed())
    local castle = self.city:GetCastle()
    local lv = castle and castle.CastleAbility and castle.CastleAbility[ability:Type()] or 0
    return lv >= ability:Level()
end

function CitySafeAreaWallManager:GetWallId(x, y)
    return self._wallController:GetWallId(x, y)
end

---@return boolean,CS.UnityEngine.Vector2
function CitySafeAreaWallManager:GetWallCenterGrid(wallId)
    return self._wallController:GetWallCenterGrid(wallId)
end

---@return number @3-AxisX @12-AxisY
function CitySafeAreaWallManager:GetWallDir(wallId)
    return self._wallController:GetWallDir(wallId)
end

---@return boolean
function CitySafeAreaWallManager:IsPolluted(wallId)
    return ModuleRefer.CitySafeAreaModule:GetWallOrDoorIsPolluted(wallId)
end

function CitySafeAreaWallManager:SelectWall(wallId)
    if not wallId or wallId == 0 then
        self._wallController:SetSelectedWallIds(string.Empty)
    else
        self._wallController:SetSelectedWallIds(string.pack("<B", wallId))
    end
end

---@return CitySafeAreaWallDoorTile
function CitySafeAreaWallManager:GetTile(wallId)
    if not wallId then
        return nil
    end 
    ---@type CitySafeAreaWallDoor
    local wallOrDoor = self.wallHashMap[wallId]
    if not wallOrDoor then
        return nil
    end
    return self.city.gridView:GetSafeAreaWallDoorTile(wallOrDoor.x, wallOrDoor.y)
end

---@return CitySafeAreaWallDoor
function CitySafeAreaWallManager:GetPlacedDoor(x, y)
    return self.wallPlaced:Get(x, y)
end

function CitySafeAreaWallManager:RegisterGridEvent()
    local provider = self.city.unitMoveGridEventProvider
    for key, listener in pairs(self.doorZoneListeners) do
        if not listener.isDummy then
            provider:RemoveListener(listener.listener)
        end
        self.doorZoneListeners[key] = nil
    end
    for _, door in pairs(self.wallHashMap) do
        if not door.isDoor then
            goto continue
        end
        local wallId = door.singleId
        local x,y,sx,sy = door:GetUnitArea()
        local listenerTrack = {}
        listenerTrack.isDummy = false
        listenerTrack.count = 0
        listenerTrack.onEnter = function(_, _, l)
            listenerTrack.count = l.count
            self:NotifyDoorOpenStatus(wallId,l.count > 0)
        end
        listenerTrack.onExit = function(_, _, l)
            listenerTrack.count = l.count
            self:NotifyDoorOpenStatus(wallId,l.count > 0)
        end
        local listener = provider:AddListener(x, y, sx, sy, listenerTrack.onEnter, listenerTrack.onExit)
        listenerTrack.listener = listener
        self.doorZoneListeners[wallId] = listenerTrack
        ::continue::
    end
end

function CitySafeAreaWallManager:UnregisterGridEvent()
    local provider = self.city.unitMoveGridEventProvider
    for key, listener in pairs(self.doorZoneListeners) do
        if not listener.isDummy then
            provider:RemoveListener(listener.listener)
        end
        self.doorZoneListeners[key] = nil
    end
end

---@return number
function CitySafeAreaWallManager:RegisterDummyDoorGridEvent(x,y,sx,sy)
    if sx > sy then
        x = x - 0.5
        sx = sx + 1
        y = y - 3
        sy = sy + 6
    else
        y = y - 0.5
        sy = sy + 1
        x = x - 3
        sx = sx + 6
    end
    local id = self._dummyDoorId
    local provider = self.city.unitMoveGridEventProvider
    self._dummyDoorId = self._dummyDoorId + 1
    local listenerTrack = {}
    listenerTrack.isDummy = true
    listenerTrack.count = 0
    listenerTrack.onEnter = function(_, _, l)
        listenerTrack.count = l.count
        self:NotifyDoorOpenStatus(id,l.count > 0)
    end
    listenerTrack.onExit = function(_, _, l)
        listenerTrack.count = l.count
        self:NotifyDoorOpenStatus(id,l.count > 0)
    end
    local listener = provider:AddListener(x, y, sx, sy, listenerTrack.onEnter, listenerTrack.onExit)
    listenerTrack.listener = listener
    self.doorZoneListeners[id] = listenerTrack
    return id
end

function CitySafeAreaWallManager:UnregisterDummyDoorGridEvent(dummyId)
    local listener = self.doorZoneListeners[dummyId]
    if not listener or not listener.isDummy then return end
    self.doorZoneListeners[dummyId] = nil
    local provider = self.city.unitMoveGridEventProvider
    provider:RemoveListener(listener.listener)
end

function CitySafeAreaWallManager:NotifyDoorOpenStatus(wallId, open)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_DOOR_OPEN_STATUS_CHANGED, self.city.uid, wallId, open)
end

function CitySafeAreaWallManager:GetDoorOpenStatus(wallId)
    local tracked = self.doorZoneListeners[wallId]
    return tracked and tracked.count > 0 or false
end

function CitySafeAreaWallManager:GetBattleViewWall(id)
    local ret = self._runtimeBattleViews[id]
    if not ret then
        ret = CitySafeAreaWallBattleObject.new(id)
        self._runtimeBattleViews[id] = ret
    end
    return ret
end

function CitySafeAreaWallManager:NeedLoadData()
    return true
end

---@return fun():number,number,CitySafeAreaWallDoor
function CitySafeAreaWallManager:WallPairs()
    return self.wallPlaced:pairs()
end

function CitySafeAreaWallManager:GetBiggestIdSafeAreaIdCenter()
    local allVaildSafeAreas = ModuleRefer.CitySafeAreaModule:GetVaildSafeAreas()
    if #allVaildSafeAreas > 0 then
        for safeAreaId = #allVaildSafeAreas, 1,-1 do
            local match,cenertGrid = self._wallController:GetSafeAreaCenterGrid(safeAreaId)
            if match then
                return safeAreaId, cenertGrid.x, cenertGrid.y
            end
        end
    end
    return nil, nil, nil
end

return CitySafeAreaWallManager