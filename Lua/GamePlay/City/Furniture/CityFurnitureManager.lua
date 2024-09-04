local CityManagerBase = require("CityManagerBase")
---@class CityFurnitureManager:CityManagerBase
---@field new fun():CityFurnitureManager
local CityFurnitureManager = class("CityFurnitureManager", CityManagerBase)
local RectDyadicMap = require("RectDyadicMap")
local CityGridLayerMask = require("CityGridLayerMask")
local EventConst = require("EventConst")
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require("ConfigRefer")
local CityFurnitureType = require("CityFurnitureType")
local Delegate = require("Delegate")
local table = table
local ipairs = ipairs
local pairs = pairs
local CityCitizenDefine = require("CityCitizenDefine")
local FurnitureCategory = require("FurnitureCategory")
local DBEntityPath = require("DBEntityPath")
local CityDefenseType = require("CityDefenseType")
local CityFurniture = require("CityFurniture")
local CastleFurnitureLvUpConfirmParameter = require("CastleFurnitureLvUpConfirmParameter")
local CastleAddFurnitureParameter = require("CastleAddFurnitureParameter")
local CityWorkType = require("CityWorkType")
local CityFurnitureHelper = require("CityFurnitureHelper")
local NotificationType = require("NotificationType")
local CityWorkI18N = require("CityWorkI18N")
local ProtocolId = require("ProtocolId")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")
local CityWorkTargetType = require("CityWorkTargetType")
local CastleMilitiaTrainingSwitchParameter = require("CastleMilitiaTrainingSwitchParameter")
local CityUpgradePetEffectU2DHolder = require("CityUpgradePetEffectU2DHolder")
local CastleDirectFinishWorkByCashParameter = require("CastleDirectFinishWorkByCashParameter")
local ConfigTimeUtility = require("ConfigTimeUtility")
local CityAttrType = require("CityAttrType")

function CityFurnitureManager:DoDataLoad()
    local gridConfig = self.city.gridConfig
    self.placed = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY)
    ---@type table<number, CityFurniture>
    self.hashMap = {}
    ---@type table<number, CityUnitMoveGridEventProvider.Listener>
    self.doorZoneListeners = {}
    self.cityUnitMoveGridEventProviderRegister = false

    local castle = self.city:GetCastle()
    for id, furnitureInfo in pairs(castle.CastleFurniture) do
        local cfgId = furnitureInfo.ConfigId
        if ConfigRefer.CityFurnitureLevel:Find(cfgId) then
            local furniture = self:PlaceFurniture(furnitureInfo.Pos.X, furnitureInfo.Pos.Y, CityFurniture.new(self, cfgId, id, furnitureInfo.Dir))
            if furniture:IsMainFurniture() then
                self.mainFurniture = furniture
            end
        else
            g_Logger.Error(("找不到配置Id为[%d]的家具Level"):format(cfgId))
        end
    end

    self:InitStorageTypeCache()
    self:InitFurniturePlaceNofityData()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleObjectCount.FurnitureCount.MsgPath, Delegate.GetOrCreate(self, self.OnStorageCountChanged))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushAddFurniture, Delegate.GetOrCreate(self, self.OnPushNeedAutoStartWorkFurniture))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnAnyFurnitureLockedChange))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnFurniturePollutedOut))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Delegate.GetOrCreate(self, self.OnBuildingBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self, self.OnFurnitureStartLevelUp))
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_DATA_LOADED)
    return self:DataLoadFinish()
end

function CityFurnitureManager:DoDataUnload()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleObjectCount.FurnitureCount.MsgPath, Delegate.GetOrCreate(self, self.OnStorageCountChanged))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushAddFurniture, Delegate.GetOrCreate(self, self.OnPushNeedAutoStartWorkFurniture))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnAnyFurnitureLockedChange))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnFurniturePollutedOut))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Delegate.GetOrCreate(self, self.OnBuildingBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self, self.OnFurnitureStartLevelUp))
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
    self:ReleaseFurniturePlaceNotifyData()
    self.placed:Clear()
    self.placed = nil
    self.hashMap = nil
    self.storageTypeCountMap = nil
    self.cityUnitMoveGridEventProviderRegister = false
end

function CityFurnitureManager:OnViewLoadFinish()
    self.inQueueUnloadVfx = {}
    ---@type table<CityUpgradePetEffectU2DHolder, CityUpgradePetEffectU2DHolder>
    self.activePetEffectHandles = {}
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityFurnitureManager:OnViewUnloadStart()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    for key, handle in pairs(self.inQueueUnloadVfx) do
        self.inQueueUnloadVfx[key] = nil
        if Utils.IsNotNull(handle) then
            handle:Delete()
        end
    end

    for _, handle in pairs(self.activePetEffectHandles) do
        handle:Dispose()
    end
    self.activePetEffectHandles = {}
    g_Game.VisualEffectManager.manager:Clear("CityFurnitureManager")
end

function CityFurnitureManager:OnCityActive()
    self:LoadFurnitureDoorUnitMoveEvents()
end

function CityFurnitureManager:OnCityInactive()
    self:UnloadFurnitureDoorUnitMoveEvents()
end

function CityFurnitureManager:Tick(delta)
    for k, v in pairs(self.activePetEffectHandles) do
        v.remainTime = v.remainTime - delta
        if v.remainTime <= 0 then
            self.activePetEffectHandles[k] = nil
            v:Dispose()
        end
    end
end

function CityFurnitureManager:GetMainFurniture()
    return self.mainFurniture
end

function CityFurnitureManager:InitStorageTypeCache()
    local castle = self.city:GetCastle()
    self.storageTypeCountMap = {}
    for id, count in pairs(castle.CastleObjectCount.FurnitureCount) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(id)
        if lvCfg then
            local typCfgId = lvCfg:Type()
            self.storageTypeCountMap[typCfgId] = (self.storageTypeCountMap[typCfgId] or 0) + count
        end
    end
end

function CityFurnitureManager:InitFurniturePlaceNofityData()
    local rootNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceHudNotifyName(), NotificationType.CITY_FURNIURE_PLACE)
    local allToggleNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUIAllToggleNotifyName(), NotificationType.CITY_FURNIURE_PLACE)
    ModuleRefer.NotificationModule:AddToParent(allToggleNode, rootNode)
    local toggleNodes = {}
    for name, value in pairs(FurnitureCategory) do
        toggleNodes[value] = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUIToggleNotifyName(value), NotificationType.CITY_FURNIURE_PLACE_TOGGLE)
        ModuleRefer.NotificationModule:AddToParent(toggleNodes[value], allToggleNode)
    end

    local castle = self.city:GetCastle()
    for id, count in pairs(castle.CastleObjectCount.FurnitureCount) do
        local typCfg = ConfigRefer.CityFurnitureTypes:Find(ConfigRefer.CityFurnitureLevel:Find(id):Type())
        if typCfg:HideInConstructionMenu() then goto continue end

        local notifyCount = g_Game.PlayerPrefsEx:GetIntByUid(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), 0)
        if notifyCount > 0 then
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(id)
            if lvCfg then
                local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
                if typCfg and toggleNodes[typCfg:Category()] ~= nil then
                    local dynamicNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), NotificationType.CITY_FURNIURE_PLACE_UNIT)
                    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(dynamicNode, notifyCount)
                    ModuleRefer.NotificationModule:AddToParent(dynamicNode, toggleNodes[typCfg:Category()])
                end
            end
        end
        ::continue::
    end
end

function CityFurnitureManager:ReleaseFurniturePlaceNotifyData()
    local rootNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceHudNotifyName(), NotificationType.CITY_FURNIURE_PLACE)
    if rootNode == nil then return end

    ModuleRefer.NotificationModule:DisposeDynamicNode(rootNode, true)
end

function CityFurnitureManager:ClearRedPoint(lvCfgId)
    local notifyCount = g_Game.PlayerPrefsEx:GetIntByUid(CityFurnitureHelper.GetPlaceUINodeNotifyName(lvCfgId), 0)
    if notifyCount > 0 then
        local dynamicNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(lvCfgId), NotificationType.CITY_FURNIURE_PLACE_UNIT)
        if dynamicNode ~= nil then
            ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(dynamicNode, notifyCount - 1)
            g_Game.PlayerPrefsEx:SetIntByUid(CityFurnitureHelper.GetPlaceUINodeNotifyName(lvCfgId), notifyCount - 1)
        end
    end
end

function CityFurnitureManager:Initialized()
    return self.hashMap ~= nil
end

---@return CityFurniture
function CityFurnitureManager:GetPlaced(x, y)
    return self.placed:Get(x, y)
end

---@param furniture CityFurniture
function CityFurnitureManager:CanPlaceFurniture(x, y, furniture, furnitureType, ignoreNumber)
    if not self:CheckPlaceFurnitureCondition(furniture, ignoreNumber) then
        return false
    end
    local gridLayer = self.city.gridLayer
    local cellCount = furniture.sizeX * furniture.sizeY
    local indoorMark = 0
    local safeAreaWallMgr = self.city.safeAreaWallMgr
    local furnitureCategory = ModuleRefer.CityConstructionModule:GetFurnitureCategory(furniture.configId)

    local isMoving = furniture.x ~= nil and furniture.y ~= nil
    for i = x, x + furniture.sizeX - 1 do
        for j = y, y + furniture.sizeY - 1 do
            local mask = gridLayer:Get(i, j)
            if isMoving then
                local f = self:GetPlaced(i, j)
                if f ~= nil and f.singleId == furniture.singleId and f.configId == furniture.configId then
                    if CityGridLayerMask.IsInLego(mask) then
                        indoorMark = indoorMark + 1
                    end
                    goto continue
                end
            end
            if not CityGridLayerMask.CanPlaceFurniture(mask) then
                g_Logger.Warn("当前地块不可以放家具")
                return false
            end

            if CityGridLayerMask.IsSafeAreaWall(mask) then
                g_Logger.Warn("家具不能在城墙上")
                return false
            end

            if CityGridLayerMask.IsGeneratingRes(mask) then
                g_Logger.Warn("家具不能叠在种植资源上")
                return false
            end

            if CityGridLayerMask.IsInLego(mask) then
                indoorMark = indoorMark + 1
                local legoBuilding = self.city.legoManager:GetLegoBuildingAt(i, j)
                if legoBuilding ~= nil and legoBuilding.blackTypeMap[furnitureType] then
                    g_Logger.Warn("家具不能放在黑名单的乐高建筑上")
                    return false
                end
            elseif furnitureCategory ~= FurnitureCategory.Military then
                if furnitureType == CityFurnitureType.OutDoor or furnitureType == CityFurnitureType.Both then
                    if not safeAreaWallMgr:IsValidSafeArea(i, j) then
                        g_Logger.Warn("非建筑内 无效安全区不可放置家具")
                        return false
                    end
                end
            end

            ::continue::
        end
    end
    if furnitureType == CityFurnitureType.InDoor then
        if indoorMark ~= cellCount then
            g_Logger.Warn("这个室内家具没有完全在建筑物里面!")
        end
        return indoorMark == cellCount
    elseif furnitureType == CityFurnitureType.OutDoor then
        if indoorMark ~= 0 then
            g_Logger.Warn("这个室外家具没有完全在室外！")
        end
        return indoorMark == 0
    elseif furnitureType == CityFurnitureType.Both then
        if indoorMark ~= 0 and indoorMark ~= cellCount then
            g_Logger.Warn("这个通用家具有一部分在室内一部分在室外！")
        end
        return indoorMark == 0 or indoorMark == cellCount
    else
        g_Logger.Warn("你看到这一句的时候说明家具摆放类型有问题了！")
        return indoorMark == 0 or indoorMark == cellCount
    end
end

function CityFurnitureManager:CheckPlaceFurnitureCondition(furniture, ignoreNumber)
    if not ignoreNumber and not self:CheckPlaceFurnitureNumLimit(furniture) then
        g_Logger.Warn("家具id:%s 放置的数量超过策划配置的最大数量了!", furniture.configId)
        return false
    end
    return true
end

---@param furniture CityFurniture
function CityFurnitureManager:CheckPlaceFurnitureNumLimit(furniture)
    local limitNum = self:GetFurniturePlacedLimitCountByTypeCfgId(furniture.furnitureCell:Type())
    if limitNum <= 0 then
        return true
    end
    local curPlacedNum = 0
    for _,v in pairs(self.hashMap or {}) do
        if v.configId == furniture.configId then
            curPlacedNum = curPlacedNum + 1
        end
    end
    return limitNum > curPlacedNum
end

---@param typCfgId number
function CityFurnitureManager:GetFurniturePlacedLimitCountByTypeCfgId(typCfgId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(typCfgId)
    local limitNum = typCfg:MaxCount()
    local limitAttrNum = ModuleRefer.CastleAttrModule:SimpleGetValue(typCfg:MaxCountIncAttr())
    return limitNum + limitAttrNum
end

function CityFurnitureManager:GetFurnitureMaxOwnCount(typCfgId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(typCfgId)
    local maxCount = typCfg:MaxOwnCount()
    local realMaxCount = 0
    local conditionLength = typCfg:MaxOwnCountConditionLength()
    for i = 1, maxCount do
        if conditionLength < i then
            realMaxCount = realMaxCount + 1
            goto continue
        end

        local condition = typCfg:MaxOwnCountCondition(i)
        local taskGroupCfg = ConfigRefer.TaskGroup:Find(condition)
        if not taskGroupCfg then
            realMaxCount = realMaxCount + 1
            goto continue
        end

        local allFinished = true
        for j = 1, taskGroupCfg:TasksLength() do
            local taskId = taskGroupCfg:Tasks(j)
            if not ModuleRefer.QuestModule:IsTaskFinishedAtLocalCache(taskId) then
                allFinished = false
                break
            end
        end

        if allFinished then
            realMaxCount = realMaxCount + 1
        end
        ::continue::
    end
    return realMaxCount
end

---@param cell CityGridCell
---@return number 建筑里的家具数量
function CityFurnitureManager:GetInnerFurniturePlacedNum(cell, mutexId)
    local furnitureList = self:GetRelativeFurniture(cell)
    local placedNum = 0
    for _, v in pairs(furnitureList) do
        if mutexId == ConfigRefer.CityFurnitureLevel:Find(v.configId):Type() then
            placedNum = placedNum + 1
        end
    end
    return placedNum
end

---@param typeId number
---@return number 当前City内此类型的家具数量
function CityFurnitureManager:GetFurniturePlacedCountByTypeId(typeId)
    local count = 0
    if not self.hashMap then return count end
    ---@param v CityFurniture
    for _, v in pairs(self.hashMap) do
        if typeId == v.furType then
            count = count + 1
        end
    end
    return count
end

---@return CityFurniture[]
function CityFurnitureManager:GetPlacedFurnitureList(typeId, ascending)
    local ret = {}
    if not self.hashMap then return ret end
    ---@param v CityFurniture
    for _, v in pairs(self.hashMap) do
        if typeId == v.furType then
            table.insert(ret, v)
        end
    end

    if ascending then
        table.sort(ret, function(l, r)
            return l.level < r.level
        end)
    else
        table.sort(ret, function(l, r)
            return l.level > r.level
        end)
    end
    return ret
end

---直接摆放家具
---@param furniture CityFurniture
function CityFurnitureManager:PlaceFurniture(x, y, furniture)
    if furniture.sizeX == 0 or furniture.sizeY == 0 then
        g_Logger.ErrorChannel("CityFurnitureManager", "PlaceFurniture error, sizeX:%s, sizeY:%s, lvCfgId : %d", furniture.sizeX, furniture.sizeY, furniture.configId)
        return nil
    end

    self:PlaceFurnitureImp(x, y, furniture)
    if furniture:IsMainFurniture() then
        self.mainFurniture = furniture
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_PLACE_FURNITURE, self.city, x, y)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_ADD_FOR_PET, self.city, furniture)
    return furniture
end

---@param furniture CityFurniture
function CityFurnitureManager:PlaceFurnitureImp(x, y, furniture)
    furniture:SetPos(x, y)
    furniture:UpdateObjectAxis()
    furniture:UpdateNavmeshData()
    for i = x, x + furniture.sizeX - 1 do
        for j = y, y + furniture.sizeY - 1 do
            self.placed:Add(i, j, furniture)
        end
    end
    self.hashMap[furniture.singleId] = furniture
    furniture:RegisterInteractPoints()
    self:RegisterGridEvent(furniture)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_ADD, self.city, furniture)
end

---直接收纳家具 从地图移除
function CityFurnitureManager:StorageFurniture(x, y)
    local furniture = self:GetPlaced(x, y)
    if not furniture then
        return nil
    end
    local navData = furniture:NavDataPairs()
    self:StorageFurnitureImp(furniture)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_STORAGE_FURNITURE, self.city, x, y, furniture.sizeX, furniture.sizeY, furniture:GetFurnitureType(), navData)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_REMOVE_FOR_PET, self.city, furniture)
    return furniture
end

---@param furniture CityFurniture
function CityFurnitureManager:StorageFurnitureImp(furniture)
    furniture:UnRegisterInteractPoints()
    self:UnRegisterGridEvent(furniture:UniqueId())
    local x, y = furniture.x, furniture.y
    for i = x, x + furniture.sizeX - 1 do
        for j = y, y + furniture.sizeY - 1 do
            self.placed:Delete(i, j)
        end
    end

    furniture:SetPos(nil, nil)
    self.hashMap[furniture.singleId] = nil
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_REMOVE, self.city, furniture)
end

function CityFurnitureManager.IsFurnitureConfigInteractPointsDifferent(configIdA, configIdB)
    if configIdA == configIdB then return false end
    local configA =  ConfigRefer.CityFurnitureLevel:Find(configIdA)
    local configB =  ConfigRefer.CityFurnitureLevel:Find(configIdB)
    if configA:RefInteractPosLength() ~= configB:RefInteractPosLength() then return true end
    local inMapA = {}
    for i = 1, configA:RefInteractPosLength() do
        inMapA[configA:RefInteractPos(i)] = true
    end
    for i = 1, configB:RefInteractPosLength() do
        if not inMapA[configB:RefInteractPos(i)] then return true end
    end
    return false
end

function CityFurnitureManager:UpdateFurnitureCfgId(singleId, cfgId)
    local furniture = self:GetFurnitureById(singleId)
    if not furniture then
        g_Logger.Error("UpdateFurnitureCfgId error, singleId:%s", singleId)
        return
    end
    local needRegisterInteractPoints = CityFurnitureManager.IsFurnitureConfigInteractPointsDifferent(cfgId, furniture.configId)
    if needRegisterInteractPoints then
        furniture:UnRegisterInteractPoints()
    end
    furniture:UpdateConfigId(cfgId)
    furniture:UpdateSize()
    if needRegisterInteractPoints then
        furniture:RegisterInteractPoints()
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_UPDATE_FURNITURE, self.city, furniture, true)
    return furniture
end

---直接移动/旋转家具
function CityFurnitureManager:MovingRotateFurniture(city, oriX, oriY, newInfo)
    if self.city ~= city then return end
    local furniture = self:GetPlaced(oriX, oriY)
    if not furniture then
        return
    end

    local oldSizeX, oldSizeY = furniture.sizeX, furniture.sizeY
    local newX, newY = newInfo.Pos.X, newInfo.Pos.Y
    self:StorageFurnitureImp(furniture)
    furniture.direction = newInfo.Dir or furniture.direction
    furniture:UpdateSize()
    self:PlaceFurnitureImp(newX, newY, furniture)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_MOVING_FURNITURE, city, oriX, oriY, newX, newY, furniture.singleId, oldSizeX, oldSizeY)
end

---批量移动家具
---@param batching wds.CastleFurniture[][]
function CityFurnitureManager:BatchMovingRotateFurniture(city, batching)
    if self.city ~= city then return end

    local furnitureIdMap = {}
    local map = {}
    for i, v in ipairs(batching) do
        local furniture = self:GetPlaced(v[1].Pos.X, v[1].Pos.Y)
        self:StorageFurniture(v[1].Pos.X, v[1].Pos.Y)
        map[i] = furniture
        furnitureIdMap[furniture:UniqueId()] = furniture
    end

    for i, v in ipairs(batching) do
        map[i].direction = v[2].Dir or map[i].direction
        map[i]:UpdateSize()
        map[i]:UpdateNavmeshData()
        self:PlaceFurniture(v[2].Pos.X, v[2].Pos.Y, map[i])
    end

    g_Game.EventManager:TriggerEvent(EventConst.CITY_BATCH_MOVING_FURNITURE, city, map, furnitureIdMap)
end

---@param cell CityGridCell
---@return CityFurniture[]
function CityFurnitureManager:GetRelativeFurniture(cell)
    local toMoving = {}
    local innerFurniture = self.city:GetCastle().BuildingInfos[cell.tileId].InnerFurniture
    for _, v in pairs(innerFurniture) do
        local furniture = self.hashMap[v]
        if furniture then
            table.insert(toMoving, furniture)
        else
            g_Logger.Error("前端家具数据维护错误:tile:%s, %s", cell.tileId, v)
        end
    end
    return toMoving
end

---@param id number
---@return CityFurniture
function CityFurnitureManager:GetFurnitureById(id)
    return self.hashMap and self.hashMap[id]
end

---@return CityFurniture
function CityFurnitureManager:GetFurnitureByTypeCfgId(typeCfgId)
    if not self.hashMap then return nil end

    for id, fur in pairs(self.hashMap) do
        if fur.furType == typeCfgId then
            return fur
        end
    end
    return nil
end

---@return CityFurniture[]
function CityFurnitureManager:GetFurnituresByTypeCfgId(typeCfgId, orderByLevel)
    ---@type CityFurniture[]
    local ret = {}
    if not self.hashMap then return ret end
    for id, fur in pairs(self.hashMap) do
        if fur.furType == typeCfgId then
            table.insert(ret, fur)
        end
    end

    if orderByLevel then
        table.sort(ret, function(l, r)
            return l.level < r.level
        end)
    end

    return ret
end

---@return wds.CastleFurniture
function CityFurnitureManager:GetCastleFurniture(id)
    local castle = self.city:GetCastle()
    return castle.CastleFurniture[id]
end

function CityFurnitureManager:IsPolluted(id)
    local info = self:GetCastleFurniture(id)
    return info ~= nil and info.Polluted
end

function CityFurnitureManager:GetFurnitureProcess(id)
    local info = self:GetCastleFurniture(id)
    return info.ProcessInfo[1]
end

---@param furnitureId number
---@param fT number
function CityFurnitureManager:IsSpecialFurnitureWorkingNotMovable(furnitureId, fT)
    local city = self.city
    if CityCitizenDefine.CityCollectBoxTypeIds[fT]  then
        local castle = city:GetCastle()
        local furniture = castle.CastleFurniture[furnitureId]
        if not furniture then
            return true
        end
        local working = furniture.AutoProduceInfo and furniture.AutoProduceInfo[1]
        return working and true or false
    end
    return false
end

---@param entity wds.CastleBrief
function CityFurnitureManager:OnStorageCountChanged(entity, changeTable)
    if entity.ID ~= self.city.uid then return end

    self:OnStorageCountDirty(changeTable)
    self:OnStorageNotifyChange(changeTable)
end

function CityFurnitureManager:OnStorageCountDirty(changeTable)
    local typMap = {}
    local lvMap = {}
    local add = changeTable.Add
    if add then
        for id, count in pairs(add) do
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(id)
            if lvCfg then
                local typCfgId = lvCfg:Type()
                self.storageTypeCountMap[typCfgId] = (self.storageTypeCountMap[typCfgId] or 0) + count
                typMap[typCfgId] = true
            end
            lvMap[id] = true
        end
    end
    local remove = changeTable.Remove
    if remove then
        for id, count in pairs(remove) do
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(id)
            if lvCfg then
                local typCfgId = lvCfg:Type()
                self.storageTypeCountMap[typCfgId] = (self.storageTypeCountMap[typCfgId] or 0) - count
                typMap[typCfgId] = true
            end
            lvMap[id] = true
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_STORAGE_COUNT_CHANGE, self.city, lvMap, typMap)
end

function CityFurnitureManager:OnStorageNotifyChange(changeTable)
    local countMap = {}
    local add = changeTable.Add
    if add then
        for id, count in pairs(add) do
            countMap[id] = (countMap[id] or 0) + count
        end
    end
    local remove = changeTable.Remove
    if remove then
        for id, count in pairs(remove) do
            countMap[id] = (countMap[id] or 0) - count
        end
    end

    for id, changeNum in pairs(countMap) do
        local typCfg = ConfigRefer.CityFurnitureTypes:Find(ConfigRefer.CityFurnitureLevel:Find(id):Type())
        if typCfg:HideInConstructionMenu() then goto continue end

        changeNum = math.max(0, changeNum)
        local dynamicNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), NotificationType.CITY_FURNIURE_PLACE_UNIT)
        if dynamicNode == nil then
            dynamicNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), NotificationType.CITY_FURNIURE_PLACE_UNIT)
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(id)
            if lvCfg then
                local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
                if typCfg then
                    local toggleNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUIToggleNotifyName(typCfg:Category()), NotificationType.CITY_FURNIURE_PLACE_TOGGLE)
                    ModuleRefer.NotificationModule:AddToParent(dynamicNode, toggleNode)
                end
            end
        end
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(dynamicNode, changeNum)
        g_Game.PlayerPrefsEx:SetIntByUid(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), changeNum)
        ::continue::
    end
end

function CityFurnitureManager:ClearCategoryFurnitureNotifyData(category)
    local castle = self.city:GetCastle()
    for id, _ in pairs(castle.CastleObjectCount.FurnitureCount) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(id)
        if lvCfg == nil then goto continue end

        local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        if typCfg == nil then goto continue end

        if typCfg:Category() ~= category then goto continue end

        if g_Game.PlayerPrefsEx:HasUidKey(CityFurnitureHelper.GetPlaceUINodeNotifyName(id)) then
            g_Game.PlayerPrefsEx:DeleteKeyByUid(CityFurnitureHelper.GetPlaceUINodeNotifyName(id))
        end
        local dynamicNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), NotificationType.CITY_FURNIURE_PLACE_UNIT)
        if dynamicNode ~= nil then
            ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(dynamicNode, 0)
        end
        ::continue::
    end
end

function CityFurnitureManager:ClearSingleFurnitureNotifyData(id)
    if g_Game.PlayerPrefsEx:HasUidKey(CityFurnitureHelper.GetPlaceUINodeNotifyName(id)) then
        g_Game.PlayerPrefsEx:DeleteKeyByUid(CityFurnitureHelper.GetPlaceUINodeNotifyName(id))
    end
    local dynamicNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(id), NotificationType.CITY_FURNIURE_PLACE_UNIT)
    if dynamicNode ~= nil then
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(dynamicNode, 0)
    end
end

function CityFurnitureManager:LoadFurnitureDoorUnitMoveEvents()
    self.cityUnitMoveGridEventProviderRegister = true
    for singleId, v in pairs(self.hashMap) do
        if not self.doorZoneListeners[singleId] then
            self:RegisterGridEvent(v)
        end
    end
end

function CityFurnitureManager:UnloadFurnitureDoorUnitMoveEvents()
    table.clear(self.doorZoneListeners)
    self.cityUnitMoveGridEventProviderRegister = false
end

---@param furniture CityFurniture
function CityFurnitureManager:RegisterGridEvent(furniture)
    if not self.cityUnitMoveGridEventProviderRegister then
        return
    end
    if not furniture then
        return
    end
    local typeConfig = ConfigRefer.CityFurnitureTypes:Find(furniture:GetFurnitureType())
    if not typeConfig or typeConfig:DefenseType() ~= CityDefenseType.Door then
        return
    end
    local provider = self.city.unitMoveGridEventProvider
    local furnitureId = furniture:UniqueId()
    local x,y,sx,sy = furniture:GetUnitArea()
    ---@type CityUnitMoveGridEventProvider.Listener
    local listenerTrack = {}
    listenerTrack.count = 0
    listenerTrack.onEnter = function(_, _, l)
        listenerTrack.count = l.count
        self:NotifyDoorOpenStatus(furnitureId,l.count > 0)
    end
    listenerTrack.onExit = function(_, _, l)
        listenerTrack.count = l.count
        self:NotifyDoorOpenStatus(furnitureId,l.count > 0)
    end
    local listener = provider:AddListener(x, y, sx, sy, listenerTrack.onEnter, listenerTrack.onExit)
    listenerTrack.listener = listener
    self.doorZoneListeners[furnitureId] = listenerTrack
end

function CityFurnitureManager:UnRegisterGridEvent(furnitureId)
    local tracker = self.doorZoneListeners[furnitureId]
    if not tracker then
        return
    end
    local provider = self.city.unitMoveGridEventProvider
    provider:RemoveListener(tracker)
end

---@param furnitureId number
---@return boolean
function CityFurnitureManager:GetFurnitureDoorOpenStatus(furnitureId)
    local tracked = self.doorZoneListeners[furnitureId]
    return tracked and tracked.count > 0 or false
end

function CityFurnitureManager:NotifyDoorOpenStatus(furnitureId, open)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_DOOR_OPEN_STATUS_CHANGED, self.city.uid, furnitureId, open)
end

function CityFurnitureManager:RequestPlaceFurniture(lvCfgId, x, y, direction, lockable, callback)
    local msg = CastleAddFurnitureParameter.new()
    msg.args.ConfigId = lvCfgId
    msg.args.X = x
    msg.args.Y = y
    msg.args.Dir = direction
    local legoBuilding = self.city.legoManager:GetLegoBuildingAt(x, y)
    msg.args.BuildingId = legoBuilding and legoBuilding.id or 0

    if callback ~= nil then
        g_Logger.Error(callback ~= nil)
        msg:SendOnceCallback(lockable, nil, true, callback)
    else
        msg:Send(lockable, nil, true)
    end
end

---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function CityFurnitureManager:RequestClaimFurnitureLevelUp(furnitureId, lockable, callback)
    if not self:GetFurnitureById(furnitureId) then return end

    local param = CastleFurnitureLvUpConfirmParameter.new()
    param.args.FurnitureId = furnitureId
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback)
    else
        param:Send(lockable, nil, true)
    end
end

function CityFurnitureManager:RequestLevelUpImmediately(furnitureId, workCfgId, citizenId, lockable, callback, errorHandle)
    if not self:GetFurnitureById(furnitureId) then return end

    local param = CastleDirectFinishWorkByCashParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.WorkCfgId = workCfgId

    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, errorHandle)
    else
        param:Send(lockable, nil, true, errorHandle)
    end
end

function CityFurnitureManager:NeedLoadData()
    return true
end

---@return CityFurniture
function CityFurnitureManager:GetMaxLevelFurnitureByType(typ)
    local ret = nil
    if not self.hashMap then return ret end
    for id, furniture in pairs(self.hashMap) do
        if furniture.furType == typ then
            if ret == nil or ret.level < furniture.level then
                ret = furniture
            end
        end
    end
    return ret
end

---@return wds.CastleFurniture
function CityFurnitureManager:GetMaxLevelFurnitureByTypeInWds(typ)
    ---@type wds.CastleFurniture
    local ret = nil
    local castle = self.city:GetCastle()
    for id, castleFurniture in pairs(castle.CastleFurniture) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
        if lvCfg and lvCfg:Type() == typ then
            if ret == nil then
                ret = castleFurniture
            else
                local retFurCfg = ConfigRefer.CityFurnitureLevel:Find(ret.ConfigId)
                if retFurCfg:Level() < lvCfg:Level() then
                    ret = castleFurniture
                end
            end
        end
    end
    return ret
end

function CityFurnitureManager:GetStrongholdFurniture()
    return self:GetFurnitureByTypeCfgId(1001)
end

function CityFurnitureManager:GetStorageFurnitureMap()
    return self.city:GetCastle().CastleObjectCount.FurnitureCount
end

function CityFurnitureManager:GetFurnitureCountByLvCfgId(lvCfgId, excludePlaced, excludeStorage)
    local count = 0
    if not excludePlaced then
        if self.hashMap then
            ---@param v CityFurniture
            for _, v in pairs(self.hashMap) do
                if lvCfgId == v.furnitureCell:Id() then
                    count = count + 1
                end
            end
        end
    end
    if not excludeStorage then
        local map = self:GetStorageFurnitureMap()
        count = count + (map[lvCfgId] or 0)
    end
    return count
end

function CityFurnitureManager:HasFurnitureByTypeCfgId(typCfgId, excludePlaced, excludeStorage)
    if not excludePlaced then
        if self.hashMap then
            ---@param v CityFurniture
            for _, v in pairs(self.hashMap) do
                if v.furType == typCfgId then
                    return true
                end
            end
        end
    end

    if not excludeStorage then
        return (self.storageTypeCountMap[typCfgId] or 0) > 0
    end

    return false
end

function CityFurnitureManager:GetFurnitureCountByTypeCfgId(typCfgId, excludePlaced, excludeStorage)
    local count = 0
    if not excludePlaced then
        if self.hashMap then
            ---@param v CityFurniture
            for _, v in pairs(self.hashMap) do
                if v.furType == typCfgId then
                    count = count + 1
                end
            end
        end
    end

    if not excludeStorage then
        count = count + (self.storageTypeCountMap[typCfgId] or 0)
    end
    return count
end

function CityFurnitureManager:GetFurniturePlacedLimitCount(lvCfgId)
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    if lvCfg == nil then return 0 end

    return self:GetFurniturePlacedLimitCountByTypeCfgId(lvCfg:Type())
end

function CityFurnitureManager:GetFurnitureGlobalLimitCount(lvCfgId)
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    if lvCfg == nil then return 0 end

    return self:GetFurnitureMaxOwnCount(lvCfg:Type())
end

---@return number, boolean @还可以造多少个；是否到达版本限制上限
function CityFurnitureManager:GetFurnitureCanProcessCount(lvCfgId)
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    if lvCfg == nil then return 0, true, 0 end

    return self:GetFurnitureCanProcessCountByTypeCfgId(lvCfg:Type())
end

---@return number, boolean @还可以造多少个；是否到达版本限制上限
function CityFurnitureManager:GetFurnitureCanProcessCountByTypeCfgId(typCfgId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(typCfgId)
    if typCfg == nil then return 0, true end

    local current = self:GetFurnitureCountByTypeCfgId(typCfgId)
    local limit = self:GetFurnitureMaxOwnCount(typCfgId)
    local versionLimit = typCfg:VersionMaxCount()
    if current >= limit then
        return 0, limit >= versionLimit, versionLimit
    else
        return limit - current, false, versionLimit
    end
end

---@return CityFurniture
function CityFurnitureManager:GetAnyCanLevelUpFurniture(ignoreResourceCheck, orderByTypId)
    ---@type CityFurniture[]
    local orderList = {}
    for _, furniture in pairs(self.hashMap) do
        if self:IsFunitureCanUpgrade(furniture.singleId, ignoreResourceCheck) then
            if not orderByTypId then
                return furniture
            else
                table.insert(orderList, furniture)
            end
        end
    end

    if orderByTypId then
        table.sort(orderList, function(l, r)
            return l.furType < r.furType
        end)
        return orderList[1]
    end

    return nil
end

function CityFurnitureManager:NeedShowLevelUpPackage()
    if not ModuleRefer.ActivityShopModule:IsActivityShopOpen() then
        return false
    end

    local payGoodsGroupCfgId = ConfigRefer.CityConfig:UpgradeQueuePackageId()
    if payGoodsGroupCfgId == 0 then
        return false
    end

    local isOpen = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(payGoodsGroupCfgId)
    if not isOpen then
        return false
    end

    local payGoodsGroupCfg = ConfigRefer.PayGoodsGroup:Find(payGoodsGroupCfgId)
    if payGoodsGroupCfg == nil then
        return false
    end

    if payGoodsGroupCfg:GoodsLength() == 0 then
        return false
    end

    for i = 1, payGoodsGroupCfg:GoodsLength() do
        local payGoodsCfgId = payGoodsGroupCfg:Goods(i)
        if ModuleRefer.ActivityShopModule:IsGoodsSoldOut(payGoodsCfgId) then
            return false
        end
    end

    return true
end

function CityFurnitureManager:OnAutoStartAnyWorkFailed(msgId, errorCode, jsonTable)
    self:TryShowFailedReasonToast()
end

---@param request wrpc.PushAddFurnitureRequest
function CityFurnitureManager:OnPushNeedAutoStartWorkFurniture(isSuccess, request)
    local furnitureId = request.FurnitureId
    local furniture = self:GetFurnitureById(furnitureId)
    if furniture == nil then return end
    if furniture:IsLocked() then return end

    self:TryStartFurnitureAutoWork(furniture)
end

---@param furniture CityFurniture
function CityFurnitureManager:TryStartFurnitureAutoWork(furniture)
    local furTypeCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
    if not furTypeCfg:DefaultWork() then return end

    local castleFurniture = furniture:GetCastleFurniture()
    if furniture:CanDoCityWork(CityWorkType.Process) then
        if castleFurniture.WorkType2Id[CityWorkType.Process] == 0 or castleFurniture.WorkType2Id[CityWorkType.Process] == nil then
            local processWorkId, firstProcess, NeedFreeCitizen = CityFurnitureHelper.GetAutoStartProcessInfo(furniture.furnitureCell)
            if processWorkId > 0 and firstProcess > 0 then
                if NeedFreeCitizen then
                    local freeCitizen = self.city.cityCitizenManager:GetFreeCitizen()
                    if freeCitizen == nil then
                        local idx = castleFurniture.ProcessInfo:Count()
                        self.city.cityWorkManager:StartProcessWork(furniture.singleId, firstProcess, idx, 1, processWorkId, 0, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                    else
                        local idx = castleFurniture.ProcessInfo:Count()
                        self.city.cityWorkManager:StartProcessWork(furniture.singleId, firstProcess, idx, 1, processWorkId, freeCitizen._data._id, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                    end
                else
                    local idx = castleFurniture.ProcessInfo:Count()
                    self.city.cityWorkManager:StartProcessWork(furniture.singleId, firstProcess, idx, 1, processWorkId, 0, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                end
            end
        end
    elseif furniture:CanDoCityWork(CityWorkType.ResourceGenerate) then
        if castleFurniture.WorkType2Id[CityWorkType.ResourceGenerate] == 0 or castleFurniture.WorkType2Id[CityWorkType.ResourceGenerate] == nil then
            local produceWorkId, firstProcess, NeedFreeCitizen = CityFurnitureHelper.GetAutoStartProduceInfo(furniture.furnitureCell)
            if produceWorkId > 0 and firstProcess > 0 then
                if NeedFreeCitizen then
                    local freeCitizen = self.city.cityCitizenManager:GetFreeCitizen()
                    if freeCitizen == nil then
                        self.city.cityWorkManager:StartResGenProcess(furniture.singleId, produceWorkId, 0, firstProcess, 1, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                    else
                        self.city.cityWorkManager:StartResGenProcess(furniture.singleId, produceWorkId, freeCitizen._data._id, firstProcess, 1, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                    end
                else
                    self.city.cityWorkManager:StartResGenProcess(furniture.singleId, produceWorkId, 0, firstProcess, 1, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                end
            end
        end
    elseif furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) then
        if castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] == 0 or castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] == nil then
            local collectWorkId, firstProcess, NeedFreeCitizen = CityFurnitureHelper.GetAutoStartFurnitureCollect(furniture.furnitureCell)
            if collectWorkId > 0 and firstProcess > 0 then
                if NeedFreeCitizen then
                    local freeCitizen = self.city.cityCitizenManager:GetFreeCitizen()
                    if freeCitizen == nil then
                        self.city.cityWorkManager:StartCollectWork(collectWorkId, furniture.singleId, 0, firstProcess, 1, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                    else
                        self.city.cityWorkManager:StartCollectWork(collectWorkId, furniture.singleId, freeCitizen._data._id, firstProcess, 1, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                    end
                else
                    self.city.cityWorkManager:StartCollectWork(collectWorkId, furniture.singleId, 0, firstProcess, 1, true, nil, nil, Delegate.GetOrCreate(self, self.OnAutoStartAnyWorkFailed))
                end
            end
        end
    elseif furniture:CanDoCityWork(CityWorkType.MilitiaTrain) then
        if castleFurniture.WorkType2Id[CityWorkType.MilitiaTrain] == 0 or castleFurniture.WorkType2Id[CityWorkType.MilitiaTrain] == nil then
            local param = CastleMilitiaTrainingSwitchParameter.new()
            param.args.Fid = furniture:UniqueId()
            param.args.WorkCfgId = ModuleRefer.TrainingSoldierModule:GetWorkId(furniture.furnitureCell:Id())
            param.args.On = true
            param:Send()
        end
    end
end

---@param furniture CityFurniture
function CityFurnitureManager:TryContinueFurnitureAutoWork(furniture)
    local castleFurniture = furniture:GetCastleFurniture()
    if furniture:CanDoCityWork(CityWorkType.Process) then
        local needContinue = false
        local workCfgId = 0
        if castleFurniture.ProcessInfo:Count() > 0 then
            for i, v in ipairs(castleFurniture.ProcessInfo) do
                if v.Auto then
                    needContinue = true
                    workCfgId = v.WorkCfgId
                    break
                elseif v.LeftNum > 0 then
                    needContinue = true
                    workCfgId = v.WorkCfgId
                    break
                end
            end

            if needContinue then
                self.city.cityWorkManager:StartWorkImp(furniture.singleId, workCfgId, 0, 0)
            end
        end
    elseif furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) then
        local needContinue = false
        local workCfgId = 0
        if castleFurniture.FurnitureCollectInfo:Count() > 0 then
            for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
                if v.Auto then
                    needContinue = true
                    workCfgId = v.WorkCfgId
                    break
                elseif not v.Finished then
                    needContinue = true
                    workCfgId = v.WorkCfgId
                    break
                end
            end

            if needContinue then
                self.city.cityWorkManager:StartWorkImp(furniture.singleId, workCfgId, 0, 0)
            end
        end
    elseif furniture:CanDoCityWork(CityWorkType.ResourceGenerate) then
        local needContinue = false
        local workCfgId = 0
        if castleFurniture.ResourceGenerateInfo.GeneratePlan:Count() > 0 then
            for i, v in ipairs(castleFurniture.ResourceGenerateInfo.GeneratePlan) do
                if v.Auto then
                    needContinue = true
                    workCfgId = v.WorkCfgId
                    break
                end
            end

            if needContinue then
                self.city.cityWorkManager:StartWorkImp(furniture.singleId, workCfgId, 0, 0)
            end
        end
    elseif furniture:CanDoCityWork(CityWorkType.FurnitureLevelUp) then
        local needContinue = false
        local workCfgId = 0
        if castleFurniture.LevelUpInfo.TargetProgress ~= 0 and castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress then
            needContinue = true
            workCfgId = castleFurniture.LevelUpInfo.WorkCfgId
        end

        if needContinue then
            self.city.cityWorkManager:StartWorkImp(furniture.singleId, workCfgId, 0, 0)
        end
    end
end

function CityFurnitureManager:IsFunitureCanUpgrade(furnitureId, ignoreResourceCheck)
    local furniture = self:GetFurnitureById(furnitureId)
    if furniture == nil then return false end

    if furniture:IsLocked() then return false end
    if furniture:IsPolluted() then return false end
    if furniture:IsFogMask() then return false end

    return furniture:CanUpgrade(ignoreResourceCheck)
end

---@param furniture CityFurniture
---@param pointConfig CityInteractionPointConfigCell
---@param rotation number
---@param rangeMinX,rangeMinY,rangeMaxX,rangeMaxY number
function CityFurnitureManager:OnFurnitureRegisterInteractPoint(furniture, pointConfig, rotation, building, rangeMinX, rangeMinY, rangeMaxX, rangeMaxY, sx, sy)
    local x = furniture.x
    local y = furniture.y
    ---@type CityCitizenTargetInfo
    local ownerInfo = {}
    ownerInfo.id = furniture:UniqueId()
    ownerInfo.type = CityWorkTargetType.Furniture
    local point = self.city.cityInteractPointManager.MakePoint(self.city, pointConfig, self.city.gridConfig.cellsX ,x, y, rotation, nil, ownerInfo, sx, sy)
    if rangeMinX and rangeMinY and rangeMaxX and rangeMaxY then
        if point.gridX <= rangeMinX or point.gridX >= rangeMaxX then return end
        if point.gridY <= rangeMinY or point.gridY >= rangeMaxY then return end
    end
    if self.city.legoManager:GetLegoBuildingAt(point.gridX, point.gridY) ~= building then return end
    local index = self.city.cityInteractPointManager:DoAddInteractPoint(point)
    furniture.interactPoints[#furniture.interactPoints + 1] = index
end

---@param furniture CityFurniture
function CityFurnitureManager:OnFurnitureUnRegisterInteractPoint(furniture)
    local mgr = self.city.cityInteractPointManager
    for _, pointIndex in pairs(furniture.interactPoints) do
        mgr:RemoveInteractPoint(pointIndex)
    end
end

function CityFurnitureManager:OnAnyFurnitureLockedChange(city, batchEvt)
    if city ~= self.city then return end
    ModuleRefer.GuideModule:CallGuide(35)

    local Change = batchEvt.Change
    for id, flag in pairs(Change) do
        if flag then
            g_Logger.ErrorChannel("CityFurnitureManager", "家具[%d]从未锁定状态变成了锁定状态", id)
        else
            local furniture = self:GetFurnitureById(id)
            if not furniture then
                g_Logger.ErrorChannel("CityFurnitureManager", "找不到家具%d", id)
            else
                self:PlayUnlockVfx(furniture)
                self:PlayUnlockSfx(furniture)
                self:TryStartFurnitureAutoWork(furniture)
            end
        end
    end
end

---@param furniture CityFurniture
function CityFurnitureManager:PlayUnlockVfx(furniture)
    local lvCfg = furniture.furnitureCell
    local city = self.city
    local path, scale = ArtResourceUtils.GetItemAndScale(lvCfg:UnlockVfx())
    if scale <= 0 then
        scale = 1
    end
    if not string.IsNullOrEmpty(path) then
        local vfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
        local pos = city:GetCenterWorldPositionFromCoord(furniture.x, furniture.y, furniture.sizeX, furniture.sizeY)
        self.inQueueUnloadVfx[vfxHandle] = vfxHandle
        vfxHandle:Create(path, "city_npc_unload_vfx", city:GetRoot().transform, function(success, obj, handle)
            if success then
                local trans = handle.Effect.transform
                trans.position = pos
                if path == "vfx_common_build" then
                    trans.localScale = CS.UnityEngine.Vector3(furniture.sizeX * 0.28, 1, furniture.sizeY * 0.28) * scale
                else
                    trans.localScale = CS.UnityEngine.Vector3.one * scale
                end
            end
        end, nil, 0, false, false, function(userData)
            self.inQueueUnloadVfx[vfxHandle] = nil
        end)
    end
    local i18n = lvCfg:UnlockVfxI18N()
    if not string.IsNullOrEmpty(i18n) then
        local vfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
        self.inQueueUnloadVfx[vfxHandle] = vfxHandle
        local furnitureTile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
        local pos = city:GetCenterWorldPositionFromCoord(furniture.x, furniture.y, furniture.sizeX, furniture.sizeY)
        if furnitureTile ~= nil then
            local mainAssets = furnitureTile.tileView:GetMainAssets()
            local mainAsset, _ = next(mainAssets)
            if mainAsset ~= nil then
                _, pos = mainAsset:TryGetAnchorPos()
            end
        end
        vfxHandle:Create(ManualResourceConst.ui3d_bubble_building_repaired, "city_npc_unload_vfx", city:GetRoot().transform, function(success, obj, handle)
            if success then
                ---@type CS.UnityEngine.GameObject
                local go = handle.Effect.gameObject
                ---@type CityNPCUnloadLangContentVfx
                local logic = go:GetLuaBehaviour("CityNPCUnloadLangContentVfx").Instance
                logic:SetLangContent(i18n)
                local trans = handle.Effect.transform
                trans.position = pos
                trans.localScale = CS.UnityEngine.Vector3.one
            end
        end, nil, 0, false, false, function(userData)
            self.inQueueUnloadVfx[vfxHandle] = nil
        end)
    end
end

---@param furniture CityFurniture
function CityFurnitureManager:PlayUnlockSfx(furniture)
    local furnitureTile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    if furnitureTile ~= nil and furnitureTile.tileView then
        local mainAssets = furnitureTile.tileView:GetMainAssets()
        local mainAsset, _ = next(mainAssets)
        if mainAsset and Utils.IsNotNull(furnitureTile.tileView.gameObjs[mainAsset]) then
            g_Game.SoundManager:Play("sfx_building_repair", furnitureTile.tileView.gameObjs[mainAsset])
        end
    else
        g_Game.SoundManager:Play("sfx_building_repair")
    end
end

---@param evt {Event:string, furnitureId:number}
function CityFurnitureManager:OnFurnitureStartLevelUp(city, evt)
    if city ~= self.city then return end
    
    local furniture = self:GetFurnitureById(evt.furnitureId)
    if furniture == nil then return end

    self:PlayStartLevelUpSfx(furniture)
end

---@param furniture CityFurniture
function CityFurnitureManager:PlayStartLevelUpSfx(furniture)
    local furnitureTile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    if furnitureTile ~= nil and furnitureTile.tileView then
        local mainAssets = furnitureTile.tileView:GetMainAssets()
        local mainAsset, _ = next(mainAssets)
        if mainAsset and Utils.IsNotNull(furnitureTile.tileView.gameObjs[mainAsset]) then
            g_Game.SoundManager:Play("sfx_ui_putup", furnitureTile.tileView.gameObjs[mainAsset])
        end
    else
        g_Game.SoundManager:Play("sfx_ui_putup")
    end
end

function CityFurnitureManager:TryShowFailedReasonToast()
    if self.city.showed then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CityWorkI18N.Toast_AutoStartFailed))
    end
end

---@param furniture CityFurniture
function CityFurnitureManager:PlayPutDownVfx(furniture)
    local handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    handle:Create("vfx_w_common_city_jiaju_fangzhi", "CityFurnitureManager", self.city.CityRoot.transform, function(flag, obj, tHandle)
        if not flag then return end
        tHandle.Effect.transform.position = self.city:GetCenterWorldPositionFromCoord(furniture.x, furniture.y, furniture.sizeX, furniture.sizeY)
        tHandle.Effect.transform.localScale = CS.UnityEngine.Vector3(furniture.sizeX * 0.1, 1, furniture.sizeY * 0.1)
        g_Game.SoundManager:Play("sfx_world_place", tHandle.Effect.gameObject)
    end)
end

function CityFurnitureManager:IsNonFurnitureCanLevelUp()
    if next(self.hashMap) == nil then return false end

    for _, furniture in pairs(self.hashMap) do
        if not furniture:NotFullLevel() then
            return false
        end
    end

    return true
end

function CityFurnitureManager:OnFurniturePollutedOut(id)
    local furniture = self:GetFurnitureById(id)
    if not furniture then
        -- self:TryContinueFurnitureAutoWork(furniture)
    end
end

---@param city City
---@param batchEvt {Add:table<number, boolean>}
function CityFurnitureManager:OnBuildingBatchUpdate(city, batchEvt)
    if city ~= self.city then return end

    local Add = batchEvt.Add
    for id, flag in pairs(Add) do
        local legoBuilding = self.city.legoManager:GetLegoBuilding(id)
        for i, furnitureId in ipairs(legoBuilding.payload.InnerFurnitureIds) do
            local furniture = self:GetFurnitureById(furnitureId)
            if furniture then
                furniture:UnRegisterInteractPoints()
                furniture:RegisterInteractPoints()
            end
        end
    end
end

function CityFurnitureManager:CreateUpgradePetCountdownTimeU2D(furnitureId)
    if not self.city.petManager:IsDataReady() then return end

    local info = self.city.petManager:GetUpgradeTimeCountdownInfo()
    if info == nil then return end

    local handle = CityUpgradePetEffectU2DHolder.new(self, furnitureId, info)
    handle:Create()
    self.activePetEffectHandles[handle] = handle
end

function CityFurnitureManager:GetPetEffectU2DRemainTime()
    return 3
end

function CityFurnitureManager:HasFurnitureCountByCityWorkType(workType)
    if not self.hashMap then return false end
    for id, furniture in pairs(self.hashMap) do
        if furniture:CanDoCityWork(workType) then
            return true
        end
    end
    return false
end

function CityFurnitureManager:OnSetLocalNotification(callback)
    self:TrySetCookingNotification(callback)
    self:TrySetResourceProduceNotification(callback)
    self:TrySetMaterialProcessNotification(callback)
    self:TrySetFurnitureProcessNotification(callback)
    self:TrySetHatchEggNotification(callback)
    self:TrySetStoreroomNotification(callback)
end

function CityFurnitureManager:TrySetCookingNotification(callback)
    local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
    local furniture = self:GetFurnitureByTypeCfgId(CityFurnitureTypeNames["1001201"])
    if furniture == nil then return end

    local castleFurniture = furniture:GetCastleFurniture()
    if castleFurniture == nil then return end
    if castleFurniture.WorkType2Id[CityWorkType.Process] == nil then return end
    if castleFurniture.ProcessInfo.LeftNum == 0 then return end

    local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
    local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.city, castleFurniture.ProcessInfo)
    local processCfg = ConfigRefer.CityWorkProcess:Find(castleFurniture.ProcessInfo.ConfigId)
    local outputItem = ConfigRefer.Item:Find(processCfg:Output())
    local petIdsMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
    local petId = next(petIdsMap)

    local PushConsts = require("PushConsts")
    local pushCfg = ConfigRefer.Push:Find(PushConsts['35'])
    local notifyId = tonumber(pushCfg:Id())
    local title = I18N.Get(pushCfg:Title())
    local subtitle = I18N.Get(pushCfg:SubTitle())
    local content = I18N.GetWithParams(pushCfg:Content(), I18N.Get(outputItem:NameKey()), ModuleRefer.PetModule:GetPetName(petId) or "")
    callback(notifyId, title, subtitle, content, remainTime)
end

function CityFurnitureManager:TrySetResourceProduceNotification(callback)
    if not self.hashMap then return end
    for id, furniture in pairs(self.hashMap) do
        if furniture:CanDoCityWork(CityWorkType.ResourceProduce) then
            local castleFurniture = furniture:GetCastleFurniture()
            local workId = castleFurniture.WorkType2Id[CityWorkType.ResourceProduce] or 0
            if workId > 0 then
                local CityWorkProduceWdsHelper = require("CityWorkProduceWdsHelper")
                local remainTime = CityWorkProduceWdsHelper.GetProduceRemainTime(castleFurniture)
                if remainTime > 0 then
                    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.ResourceProduce))
                    local resProduceCfg = ConfigRefer.CityWorkProduceResource:Find(workCfg:ResProduceCfg())
                    local output = ConfigRefer.Item:Find(resProduceCfg:ResType())
                    local PushConsts = require("PushConsts")
                    local pushCfg = ConfigRefer.Push:Find(PushConsts['36'])
                    local notifyId = tonumber(pushCfg:Id())
                    local title = I18N.Get(pushCfg:Title())
                    local subtitle = I18N.Get(pushCfg:SubTitle())
                    
                    local petIdsMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
                    local petId = next(petIdsMap)
                    local content = I18N.GetWithParams(pushCfg:Content(), furniture:GetName(), I18N.Get(output:NameKey()), ModuleRefer.PetModule:GetPetName(petId) or "")
                    callback(notifyId, title, subtitle, content, remainTime)
                end
            end
        end
    end
end

function CityFurnitureManager:TrySetMaterialProcessNotification(callback)
    if not self.hashMap then return end
    for id, furniture in pairs(self.hashMap) do
        if furniture:CanDoCityWork(CityWorkType.MaterialProcess) then
            local castleFurniture = furniture:GetCastleFurniture()
            local workId = castleFurniture.WorkType2Id[CityWorkType.MaterialProcess] or 0
            if workId > 0 and castleFurniture.ProcessInfo.LeftNum > 0 then
                local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
                local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.city, castleFurniture.ProcessInfo)
                local processCfg = ConfigRefer.CityWorkProcess:Find(castleFurniture.ProcessInfo.ConfigId)
                local outputItem = ConfigRefer.Item:Find(processCfg:Output())
                local petIdsMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
                local petId = next(petIdsMap)

                local PushConsts = require("PushConsts")
                local pushCfg = ConfigRefer.Push:Find(PushConsts['37'])
                local notifyId = tonumber(pushCfg:Id())
                local title = I18N.Get(pushCfg:Title())
                local subtitle = I18N.Get(pushCfg:SubTitle())
                local content = I18N.GetWithParams(pushCfg:Content(), I18N.Get(outputItem:NameKey()), ModuleRefer.PetModule:GetPetName(petId) or "")
                callback(notifyId, title, subtitle, content, remainTime)
            end
        end     
    end
end

function CityFurnitureManager:TrySetFurnitureProcessNotification(callback)
    local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
    local furniture = self:GetFurnitureByTypeCfgId(CityFurnitureTypeNames["1003401"])
    if furniture == nil then return end

    local castleFurniture = furniture:GetCastleFurniture()
    if castleFurniture == nil then return end
    if castleFurniture.WorkType2Id[CityWorkType.Process] == nil then return end
    if castleFurniture.ProcessInfo.LeftNum == 0 then return end

    local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
    local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.city, castleFurniture.ProcessInfo)
    local processCfg = ConfigRefer.CityWorkProcess:Find(castleFurniture.ProcessInfo.ConfigId)
    local outputItem = ConfigRefer.Item:Find(processCfg:Output())
    local name = I18N.Get(outputItem:NameKey())
    local CityProcessUtils = require("CityProcessUtils")
    if CityProcessUtils.IsFurnitureRecipe(processCfg) then
        local lvCfgId = checknumber(outputItem:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        name = I18N.Get(typeCfg:Name())
    end

    local petIdsMap = self.city.petManager:GetPetIdByWorkFurnitureId(furniture.singleId)
    local petId = next(petIdsMap)

    local PushConsts = require("PushConsts")
    local pushCfg = ConfigRefer.Push:Find(PushConsts['38'])
    local notifyId = tonumber(pushCfg:Id())
    local title = I18N.Get(pushCfg:Title())
    local subtitle = I18N.Get(pushCfg:SubTitle())
    local content = I18N.GetWithParams(pushCfg:Content(), name, ModuleRefer.PetModule:GetPetName(petId) or "")
    callback(notifyId, title, subtitle, content, remainTime)
end

function CityFurnitureManager:TrySetHatchEggNotification(callback)
    if not self.hashMap then return end
    for id, furniture in pairs(self.hashMap) do
        if furniture:CanDoCityWork(CityWorkType.Incubate) then
            local castleFurniture = furniture:GetCastleFurniture()
            local workId = castleFurniture.WorkType2Id[CityWorkType.Incubate] or 0
            if workId > 0 and castleFurniture.ProcessInfo.LeftNum > 0 then
                local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
                local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.city, castleFurniture.ProcessInfo)

                local PushConsts = require("PushConsts")
                local pushCfg = ConfigRefer.Push:Find(PushConsts['34'])
                local notifyId = tonumber(pushCfg:Id())
                local title = I18N.Get(pushCfg:Title())
                local subtitle = I18N.Get(pushCfg:SubTitle())
                local content = I18N.Get(pushCfg:Content())
                callback(notifyId, title, subtitle, content, remainTime)
            end
        end
    end
end

function CityFurnitureManager:TrySetStoreroomNotification(callback)
    local storeroomFurniture = self:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
    local hotSpringFurniture = self:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:HotSpringFurniture())

    if storeroomFurniture == nil or hotSpringFurniture == nil then return end
    local petIdMap = self.city.petManager:GetPetIdByWorkFurnitureId(hotSpringFurniture.singleId)
    if petIdMap == nil or next(petIdMap) == nil then return end

    local detailCfg = ConfigRefer.HotSpringDetail:Find(hotSpringFurniture.furnitureCell:HotSpringDetailInfo())
    if detailCfg == nil then return end

    local isActive = false
    for i = 1, detailCfg:AdditionProductsLength() do
        local addition = detailCfg:AdditionProducts(i)
        local needWorkType = addition:PetWorkType()
        for petId, flag in pairs(petIdMap) do
            if self.city.petManager:IsPetCanDoWork(petId, needWorkType) then
                isActive = true
                break
            end
        end

        if isActive then
            break
        end
    end

    if not isActive then return end
    local CityAttrType = require("CityAttrType")
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastOfflineIncomeTime = self.city:GetCastle().GlobalData.OfflineData.LastGetOfflineBenefitTime.ServerSecond
    local offlineSumTime = math.max(0, now - lastOfflineIncomeTime)
    local maxTime = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime)
    local remainTime = maxTime - offlineSumTime

    local PushConsts = require("PushConsts")
    local pushCfg = ConfigRefer.Push:Find(PushConsts['40'])
    local notifyId = tonumber(pushCfg:Id())
    local title = I18N.Get(pushCfg:Title())
    local subtitle = I18N.Get(pushCfg:SubTitle())
    local content = I18N.Get(pushCfg:Content())
    callback(notifyId, title, subtitle, content, remainTime)
end

function CityFurnitureManager:GetUpgradeQueueMaxCount()
    return ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.ConstructQueueCount)
end

---@return CityFurniture[]
function CityFurnitureManager:GetFurnituresByWorkType(workType)
    if not self.hashMap then return {} end

    local ret = {}
    for _, furniture in pairs(self.hashMap) do
        if furniture:CanDoCityWork(workType) then
            table.insert(ret, furniture)
        end
    end
    return ret
end

---@param nextLvCell CityFurnitureLevelConfigCell
function CityFurnitureManager:GetFurnitureUpgradeCostTime(nextLvCell)
    local configTime = ConfigTimeUtility.NsToSeconds(nextLvCell:LevelUpTime())
    local percent = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.BuildingReduceTimePercent)
    local fixed = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.BuildingReduceTime)
    return math.max(0, (configTime * (1 - percent) - fixed) - self.city:GetCastle().GlobalData.BuildingReduceTime)
end

---@return fun():number,CityFurniture,CityUnitMoveGridEventProvider.Listener
function CityFurnitureManager:PairsOfDoorListenerFurniture()
    local furnitureId, listener = nil, nil
    return function()
        furnitureId, listener = next(self.doorZoneListeners, furnitureId)
        if furnitureId and listener then
            return furnitureId, self:GetFurnitureById(furnitureId), listener
        end
    end
end

--- 礼包id写死了，有问题问赵薏寒
function CityFurnitureManager:GetUpgradeGoodGroupId()
    return 1011
end

function CityFurnitureManager:GetUpgradeGoodIds()
    return {0, 44, 45, 46}
end

function CityFurnitureManager:FunctionName()
    
end

function CityFurnitureManager:OnPaySuccess()
    local FPXSDKBIDefine = require("FPXSDKBIDefine")
    local lastPurchasedGoodId = ModuleRefer.ActivityShopModule.lastPurchasedGoodId
    if lastPurchasedGoodId and lastPurchasedGoodId > 0 then
        local goods = self:GetUpgradeGoodIds()
        for _, goodId in ipairs(goods) do
            if goodId > 0 and goodId == lastPurchasedGoodId then
                local keyMap = FPXSDKBIDefine.ExtraKey.build_pay
                local extraDict = {}
                extraDict[keyMap.IAP_PRODUCT_NAME] = lastPurchasedGoodId
                ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.build_pay, extraDict)
                break
            end
        end
    end
end

return CityFurnitureManager