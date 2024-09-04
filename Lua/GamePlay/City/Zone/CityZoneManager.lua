local CityManagerBase = require("CityManagerBase")
---@class CityZoneManager:CityManagerBase
---@field new fun():CityZoneManager
---@field zoneIdMap table<number, CityZone>
---@field city City
---@field zoneCoordMap RectDyadicMap
local CityZoneManager = class("CityZoneManager", CityManagerBase)
local RectDyadicMap = require("RectDyadicMap")
local ConfigRefer = require("ConfigRefer")
local CityZone = require("CityZone")
local CityZoneGroup = require("CityZoneGroup")
local CastleZoneRecoverParameter = require("CastleZoneRecoverParameter")
local ModuleRefer = require("ModuleRefer")
local TaskType = require("TaskType")
local TaskCondType = require("TaskCondType")
local I18N = require("I18N")
local CityStaticObjectTileZoneBubble = require("CityStaticObjectTileZoneBubble")
local CityStaticObjectTileHeroRescueBubble = require('CityStaticObjectTileHeroRescueBubble')
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local OnChangeHelper = require("OnChangeHelper")
local CityZoneUnlockPreConditionProvider = require("CityZoneUnlockPreConditionProvider")
local CityZoneStatus = require("CityZoneStatus")
local CityWorkHelper = require("CityWorkHelper")
local UIMediatorNames = require("UIMediatorNames")

function CityZoneManager:DoDataLoad()
    self.config = self.city.gridConfig
    ---@type table<number, CityStaticObjectTileZoneBubble>
    self.zoneBubbleTileMap = {}
    ---@type table<number, CityStaticObjectTileHeroRescueBubble>
    self.heroRescueBubbleTileMap = {}
    self.tempSelectedZone = nil
    ---@type table<number, table<number, number>>
    self.furnitureTypeSubscribeZone = {}
    ---@type table<number, number> @elementId,zoneId
    self.singleExplorerZoneOpenNpc = {}
    ---@type table<number, number> @zoneId,elementId
    self.singleExplorerZoneOpenNpcR = {}

    self:InitBlocks()
    self:InitZoneGroup()
    return self:DataLoadFinish()
end

function CityZoneManager:DoDataUnload()

    self.zoneCoordMap = nil
    self.zoneGroupIdMap = nil
    self.zoneIdMap = nil
    self.config = nil
end

function CityZoneManager:NeedLoadView()
    return true
end

function CityZoneManager:DoViewLoad()
    self:LoadHeroRescueBubbles()
    self:LoadZoneRecoverBubbles()
    return self:ViewLoadFinish()
end

function CityZoneManager:DoViewUnload()
    self:UnloadHeroRescueBubbles()
    self:UnloadZoneRecoverBubbles()
end

function CityZoneManager:OnViewLoadFinish()
    g_Game.EventManager:AddListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.OnBubbleStateChange))
    g_Game.EventManager:AddListener(EventConst.UI_HERO_RESCUE_FIRST_TIME_SHOW_BUBBLE, Delegate.GetOrCreate(self, self.ReloadHeroRescueBubbles))
end

function CityZoneManager:OnViewUnloadStart()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.OnBubbleStateChange))
    g_Game.EventManager:RemoveListener(EventConst.UI_HERO_RESCUE_FIRST_TIME_SHOW_BUBBLE, Delegate.GetOrCreate(self, self.ReloadHeroRescueBubbles))
end

---@private
function CityZoneManager:InitBlocks()
    self.zoneCoordMap = RectDyadicMap.new(self.config.cellsX, self.config.cellsY, {__index = self.city:GetMapData().zoneData})
    self.zoneIdMap = {}
    self.singleExplorerZoneOpenNpc = {}
    self.singleExplorerZoneOpenNpcR = {}

    for _, configCell in ConfigRefer.CityZone:pairs() do
        local id = configCell:Id()
        local blockCell = CityZone.new(self, configCell)
        self.zoneIdMap[id] = blockCell
        local openNpc = configCell:OpenDoorNpc()
        if openNpc ~= 0 then
            self.singleExplorerZoneOpenNpc[openNpc] = id
            self.singleExplorerZoneOpenNpcR[id] = openNpc
        end
    end

    local CastleBrief = self.city:GetCastle()
    local zoneData = CastleBrief.Zones
    if zoneData then
        for id, status in pairs(zoneData) do
            if not self.zoneIdMap[id] then
                g_Logger.Error(("Failed to initialize zone with id : %d, bcz config row not exists"):format(id))
                goto continue
            end

            self.zoneIdMap[id]:UpdateStatus(status)
            ::continue::
        end
    end
end

---@private
function CityZoneManager:InitZoneGroup()
    self.zoneGroupIdMap = {}

    for _, cfgCell in ConfigRefer.CityZoneGroup:pairs() do
        local id = cfgCell:Id()
        local zoneGroup = CityZoneGroup.new(cfgCell)

        for i = 1, cfgCell:ZoneListLength() do
            local zone = self.zoneIdMap[cfgCell:ZoneList(i)]
            zoneGroup:AddReleatedZone(zone)
        end
        self.zoneGroupIdMap[id] = zoneGroup
    end
end

function CityZoneManager:RefreshZonePreCondition()
    table.clear(self.furnitureTypeSubscribeZone)
    local FurnitureLv = ConfigRefer.CityFurnitureLevel
    for zoneId, v in pairs(self.zoneIdMap) do
        local config = v.config
        for index = 1, config:ExplorePreFurnitureLength() do
            local furnLvConfig = FurnitureLv:Find(config:ExplorePreFurniture(index))
            local zoneList = self.furnitureTypeSubscribeZone[furnLvConfig:Type()]
            if not zoneList then
                zoneList = {}
                self.furnitureTypeSubscribeZone[furnLvConfig:Type()] = zoneList
            end
            zoneList[zoneId] = furnLvConfig:Level()
        end
    end
end

function CityZoneManager:OnCityActive()
    if self.city:IsMyCity() then
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureChanged))
    end
end

function CityZoneManager:OnCityInactive()
    if self.city:IsMyCity() then
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureChanged))
    end
end

---@return CityZone
function CityZoneManager:GetZone(x, y)
    return self.zoneIdMap[self.zoneCoordMap:Get(x, y)]
end

CityZoneManager.CityCenterZoneId = 4
CityZoneManager.CittZoneMap = {
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [7] = true,
    [10] = true,
    [11] = true,
    [14] = true,
    [15] = true,
}

function CityZoneManager:SuggestEnterCityCameraLookAtPos()
    ---@type CityZone
    local chooseRecoveredZone = nil
    ---@type CityZone
    local chooseHideFogZone = nil
    local cityRecoveredZone = {}
    for key, value in pairs(CityZoneManager.CittZoneMap) do
        cityRecoveredZone[key] = value
    end
    for _, value in pairs(self.zoneIdMap) do
        if value:Recovered() and CityZoneManager.CittZoneMap[value.id] then
            if not chooseRecoveredZone then
                chooseRecoveredZone = value
            elseif value.id > chooseRecoveredZone.id then
                chooseRecoveredZone = value
            end
            cityRecoveredZone[value.id] = nil
        elseif value:IsHideFog() then
            if not chooseHideFogZone then
                chooseHideFogZone = value
            elseif value.id > chooseHideFogZone.id then
                chooseHideFogZone = value
            end
        end
    end
    if table.nums(cityRecoveredZone) <= 0 then
        chooseRecoveredZone = self:GetZoneById(CityZoneManager.CityCenterZoneId)
    end
    if chooseRecoveredZone then
        return chooseRecoveredZone:WorldCenter()
    elseif chooseHideFogZone then
        return chooseHideFogZone:WorldCenter()
    end
    return self:GetZoneById(1):WorldCenter()
end

---@return table<number, CityZone>
function CityZoneManager:SeExploreZoneChanged(id)
    ---@type table<number, CityZone>
    local ret = {}
    for zoneId, zone in pairs(self.zoneIdMap) do
        if zoneId == id then
            zone:UpdateSingleExploring(true)
            ret[zoneId] = zone
        elseif zone.singleExploring then
            zone:UpdateSingleExploring(false)
            ret[zoneId] = zone
        end
    end
    return ret
end

---@return table<number, CityZone>
function CityZoneManager:LocalAddSeExploreZone(id)
    ---@type table<number, CityZone>
    local ret = {}
    for zoneId, zone in pairs(self.zoneIdMap) do
        if zoneId == id and not zone.singleExploring then
            zone:UpdateSingleExploring(true)
            ret[zoneId] = zone
        end
    end
    return ret
end

---@return CityZone
function CityZoneManager:GetZoneById(id)
    return self.zoneIdMap[id]
end

function CityZoneManager:IsZoneRecovered(x, y)
    local block = self:GetZone(x, y)
    return block ~= nil and block:Recovered()
end

function CityZoneManager:IsZoneExploredOrRecovered(x, y)
    local block = self:GetZone(x, y)
    return block ~= nil and (block:Explored() or block:Recovered())
end

function CityZoneManager:IsZoneHideFog(x, y)
    local block = self:GetZone(x, y)
    return block ~= nil and block:IsHideFog()
end

function CityZoneManager:IsZoneNotExplored(x, y)
    local block = self:GetZone(x, y)
    return block ~= nil and block:NotExplore()
end

function CityZoneManager:IsZoneRecoveredById(id)
    local block = self:GetZoneById(id)
    return block ~= nil and block:Recovered()
end

function CityZoneManager:IsZoneGroupAllRecovered(zoneGroupId)
    if self.zoneGroupIdMap[zoneGroupId] then
        return self.zoneGroupIdMap[zoneGroupId]:IsAllRecovered()
    end

    return false
end

---@param elementDataId number
---@return number floatingnumber
function CityZoneManager:GetRecoverProgressByElementDataId(elementDataId)
    local elementCfg = ConfigRefer.CityElementData:Find(elementDataId)
    if not elementCfg then
        return 0
    end

    for _, cell in ConfigRefer.CityZoneRecover:pairs() do
        if cell:CityElement() == elementDataId then
            return self:GetRecoverProgressByZoneRecoverCfg(cell)
        end
    end
    return 0
end

---@param cell CityZoneRecoverConfigCell
---@return number floatingnumber
function CityZoneManager:GetRecoverProgressByZoneRecoverCfg(cell)
    if not cell then return 0 end
    local tasks = self:GetRecoverTasksFromZoneRecover(cell)
    local cur, max = 0, #tasks
    if max == 0 then
        return 0
    end

    for i = 1, max do
        local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(tasks[i]:Id())
        if state == wds.TaskState.TaskStateCanFinish or state == wds.TaskState.TaskStateFinished then
            cur = cur + 1
        end
    end
    return cur / max
end

---@param cfg CityZoneRecoverConfigCell
---@return TaskConfigCell[]
function CityZoneManager:GetRecoverTasksFromZoneRecover(cfg)
    local ret = {}
    local mainTask = ConfigRefer.Task:Find(cfg:RecoverTasks())
    local taskType = mainTask:Property():TaskType()
    if taskType == TaskType.ZoneRecover then
        local branch = mainTask:FinishBranch(1)
        local conditionCollection = branch:BranchCondition()
        for i = 1, conditionCollection:FixedConditionLength() do
            local condition = conditionCollection:FixedCondition(i)
            if condition:Typ() ~= TaskCondType.TaskFinished then
                goto continue
            end

            local subTaskId = checknumber(condition:Param())
            local subTask = ConfigRefer.Task:Find(subTaskId)
            table.insert(ret, subTask)
            ::continue::
        end
    else
        table.insert(ret, mainTask)
    end
    return ret
end

function CityZoneManager:GetCurrentZoneCameraSize()
    if not self.zoneIdMap then return nil, nil end
    local min, max
    for _, zone in pairs(self.zoneIdMap) do
        if not zone:IsHideFog() then goto continue end

        if not min then
            min = zone.config:CityCameraHeightMin()
        elseif min > zone.config:CityCameraHeightMin() then
            min = zone.config:CityCameraHeightMin()
        end

        if not max then
            max = zone.config:CityCameraHeightMax()
        elseif max < zone.config:CityCameraHeightMax() then
            max = zone.config:CityCameraHeightMax()
        end

        ::continue::
    end
    return min, max
end

function CityZoneManager:GetCurrentZoneCityBorder()
    if not self.zoneIdMap then return nil end

    local minX, minY, maxX, maxY
    for _, zone in pairs(self.zoneIdMap) do
        if not zone:IsHideFog() then goto continue end
        if zone.config:CityBorderLength() == 0 then goto continue end

        local bl = zone.config:CityBorder(1)
        local tr = zone.config:CityBorder(2)

        local x1, y1, x2, y2 = bl:X(), bl:Y(), tr:X(), tr:Y()
        local _minX, _maxX = math.min(x1, x2), math.max(x1, x2)
        local _minY, _maxY = math.min(y1, y2), math.max(y1, y2)

        if minX == nil or minX > _minX then
            minX = _minX
        end

        if maxX == nil or maxX < _maxX then
            maxX = _maxX
        end

        if minY == nil or minY > _minY then
            minY = _minY
        end

        if maxY == nil or maxY < _maxY then
            maxY = _maxY
        end
        ::continue::
    end
    return minX, minY, maxX, maxY
end

function CityZoneManager:ReloadHeroRescueBubbles()
    self:UnloadHeroRescueBubbles()
    self:LoadHeroRescueBubbles()
end

function CityZoneManager:LoadHeroRescueBubbles()
    for zoneId, cityZone in pairs(self.zoneIdMap) do
        if self:IsCanShowHeroRescueBubble(cityZone) then
            local tile = CityStaticObjectTileHeroRescueBubble.new(self.city.gridView, zoneId, cityZone.config)
            self.heroRescueBubbleTileMap[zoneId] = tile
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, tile)
        end
    end
end

function CityZoneManager:UnloadHeroRescueBubbles()
    for i, tile in pairs(self.heroRescueBubbleTileMap) do
        g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, tile)
        tile:Release()
    end
    table.clear(self.heroRescueBubbleTileMap)
end

function CityZoneManager:LoadZoneRecoverBubbles()
    self:RefreshZonePreCondition()
    for zoneId, cityZone in pairs(self.zoneIdMap) do
        if self:IsCanShowUnlockBubbleWithoutFurnitureCheck(cityZone) then
            local tile = CityStaticObjectTileZoneBubble.new(self.city.gridView, zoneId, cityZone.config)
            self.zoneBubbleTileMap[zoneId] = tile
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, tile)
        end
    end
    self.bubbleLoaded = true
end

function CityZoneManager:UnloadZoneRecoverBubbles()
    for i, tile in pairs(self.zoneBubbleTileMap) do
        g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, tile)
        tile:Release()
    end
    table.clear(self.zoneBubbleTileMap)
    self.bubbleLoaded = false
end

function CityZoneManager:InTempSelected(zoneId)
    return self.tempSelectedZone == zoneId
end

function CityZoneManager:TempSelectedZone(zoneId)
    if self.tempSelectedZone == zoneId then
        return
    end
    self.tempSelectedZone = zoneId
    for _, v in pairs(self.zoneBubbleTileMap) do
        v:OnTempZoneHideChanged(self.city.uid)
    end
end

---@param zone CityZone
---@param lastStatus number
---@param currentStatus number
function CityZoneManager:OnZoneChangedStatus(zone, lastStatus, currentStatus)
    if zone:IsHideFog() then
        if self:InTempSelected(zone.id) then
            self:TempSelectedZone(nil)
        end
        local tile = self.zoneBubbleTileMap[zone.id]
        self.zoneBubbleTileMap[zone.id] = nil
        if tile then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, tile)
            tile:Release()
        end
    end

    if currentStatus >= CityZoneStatus.Explored and lastStatus < CityZoneStatus.Explored then
        local zoneCfg = zone.config
        if zoneCfg and zoneCfg:ChangeGuide() > 0 then
            ModuleRefer.GuideModule:CallGuide(zoneCfg:ChangeGuide())
        end
    end
end

function CityZoneManager:RefreshZonePops()
    if not self.city:IsMyCity() then
        return
    end
    if not self.bubbleLoaded then return end

    local needShowPop = {}
    for zoneId, zone in pairs(self.zoneIdMap) do
        if not zone:IsHideFog() then
            if self:IsCanShowUnlockBubbleWithoutFurnitureCheck(zone) then
                needShowPop[zoneId] = zone
            end
        end
    end
    for zoneId, tile in pairs(self.zoneBubbleTileMap) do
        if not needShowPop[zoneId] then
            self.zoneBubbleTileMap[zoneId] = nil
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_REMOVE, self.city, tile)
            tile:Release()
        end
    end
    for zoneId, zone in pairs(needShowPop) do
        if not self.zoneBubbleTileMap[zoneId] then
            local tile = CityStaticObjectTileZoneBubble.new(self.city.gridView, zoneId, zone.config)
            self.zoneBubbleTileMap[zoneId] = tile
            g_Game.EventManager:TriggerEvent(EventConst.CITY_STATIC_TILE_ADD, self.city, tile)
        else
            self.zoneBubbleTileMap[zoneId]:RefreshBubbleCheckStatus()
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ZONE_BUBBLE_STATUS_CHANGE)
        end 
    end
end

---@param zone CityZone
---@param showToast boolean
---@return boolean
function CityZoneManager:CheckZonePreZoneCondition(zone, showToast)
    local zoneId = zone.config:ExplorePreZone()
    if zoneId > 0 then
        local preZone = self.zoneIdMap[zoneId]
        if preZone then
            if preZone.status < zone.config:ExplorePreZoneStatus() then
                if showToast then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_pre_zone_not_explored"))
                end
                return false
            end
        else
            g_Logger.Error("需求的前区域%s 找不到", zoneId)
            return false
        end
    end
    return true
end

---@param zone CityZone
---@param set table<number, CityZone>
---@return CityZone|nil
function CityZoneManager:WalkCheckFirstZonePreZone(zone, set, requireZoneStatus)
    if not zone then
        return
    end
    requireZoneStatus = requireZoneStatus or CityZoneStatus.Recovered
    if zone.status >= requireZoneStatus then
        return
    end
    if set[zone.id] then
        return
    end
    set[zone.id] = set
    local zoneId = zone.config:ExplorePreZone()
    if zoneId > 0 then
        local preZone = self.zoneIdMap[zoneId]
        if preZone then
            local t = self:WalkCheckFirstZonePreZone(preZone, set, zone.config:ExplorePreZoneStatus())
            if t then
                return t
            end
        end
    end
    return zone
end

---@param zone CityZone
---@return boolean, number
function CityZoneManager:IsCanShowHeroRescueBubble(zone)
    if not self.city:IsMyCity() then
        return false
    end
    if not zone then
        return false
    end

    if not ModuleRefer.HeroRescueModule:IsItemZone(zone.id) then
        return false
    end

    if not zone:NotExplore() then
        return false
    end


    return true
end

---@param zone CityZone
---@return boolean, number
function CityZoneManager:IsCanShowUnlockBubbleWithoutFurnitureCheck(zone)
    if not self.city:IsMyCity() then
        return false
    end
    if not zone then
        return false
    end
    if zone:IsHideFog() then
        return false
    end
    if not self:IsPreZoneMeetUnlockRequirement(zone) then
        return false
    end
    if not self:IsPreTaskMeetUnlockRequirement(zone, true) then
        return false
    end
    return true
end

---@param zone CityZone
---@return boolean, number
function CityZoneManager:IsCanShowUnlockBubble(zone)
    if not self.city:IsMyCity() then
        return false
    end
    if not zone then
        return false
    end
    if zone:IsHideFog() then
        return false
    end
    if not self:IsPreZoneMeetUnlockRequirement(zone) then
        return false
    end
    if not self:IsPreTaskMeetUnlockRequirement(zone) then
        return false
    end
    if not self:IsPreFurnitureMeetUnlockRequirement(zone) then
        return false
    end
    return true
end

---@param zone CityZone
function CityZoneManager:IsPreZoneMeetUnlockRequirement(zone)
    if not zone then return false end
    if zone.config:ExplorePreZone() > 0 then
        local preZone = self.zoneIdMap[zone.config:ExplorePreZone()]
        if preZone and preZone.status < zone.config:ExplorePreZoneStatus() then
            return false
        end
    end
    return true
end

---@param zone CityZone
function CityZoneManager:IsPreTaskMeetUnlockRequirement(zone, matchOne)
    if not zone then return false end
    if matchOne then
        for i = 1, zone.config:ExplorePreTaskLength() do
            local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(zone.config:ExplorePreTask(i))
            if state == wds.TaskState.TaskStateCanFinish and state == wds.TaskState.TaskStateFinished then
                return true
            end
        end
    else
        for i = 1, zone.config:ExplorePreTaskLength() do
            local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(zone.config:ExplorePreTask(i))
            if state ~= wds.TaskState.TaskStateCanFinish and state ~= wds.TaskState.TaskStateFinished then
                return false
            end
        end
    end
    return true
end

---@param zone CityZone
function CityZoneManager:IsPreFurnitureIdMeetUnlockRequirement(zone, furnitueLvId)
    if not zone then return false end
    local match = false
    local FurnitureLevel = ConfigRefer.CityFurnitureLevel
    local furnitureConfig = FurnitureLevel:Find(furnitueLvId)
    local requireType = furnitureConfig:Type()
    local requireLv = furnitureConfig:Level()
    local castle = self.city:GetCastle()
    for _, furniture in pairs(castle.CastleFurniture) do
        local furnitureCfg = FurnitureLevel:Find(furniture.ConfigId)
        if furnitureCfg:Type() == requireType and furnitureCfg:Level() >= requireLv then
            match = true
            break
        end
    end
    if not match then
        return false
    end
    return true
end

---@param zone CityZone
function CityZoneManager:IsPreFurnitureMeetUnlockRequirement(zone)
    if not zone then return false end
    if zone.config:ExplorePreFurnitureLength() > 0 then
        for index = 1, zone.config:ExplorePreFurnitureLength() do
            local match = false
            local FurnitureLevel = ConfigRefer.CityFurnitureLevel
            local furnitureConfig = FurnitureLevel:Find(zone.config:ExplorePreFurniture(index))
            local requireType = furnitureConfig:Type()
            local requireLv = furnitureConfig:Level()
            local castle = self.city:GetCastle()
            for _, furniture in pairs(castle.CastleFurniture) do
                local furnitureCfg = FurnitureLevel:Find(furniture.ConfigId)
                if furnitureCfg:Type() == requireType and furnitureCfg:Level() >= requireLv then
                    match = true
                    break
                end
            end
            if not match then
                return false
            end
        end
    end
    return true
end

---@param zone CityZone
---@return boolean,number|nil
function CityZoneManager:IsReadyForUnlock(zone)
    if not self:IsCanShowUnlockBubble(zone) then
        if zone.config:RecoverGuideLength() > 0 then
            return false, zone.config:RecoverGuide(1)
        end
        return false,0
    end
    return true
end

---@param zone CityZone
---@return number, number, number, boolean
function CityZoneManager:GetZoneRequiredItem(zone)
    if zone then
        local config = zone.config
        if config:Cost() > 0 then
            local itemGroupConfig = ConfigRefer.ItemGroup:Find(config:Cost())
            if itemGroupConfig:ItemGroupInfoListLength() > 0 then
                local itemInfo = itemGroupConfig:ItemGroupInfoList(1)
                local itemID = itemInfo:Items()
                local itemCount = itemInfo:Nums()
                local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemID)
                return itemID, ownCount, itemCount, ownCount >= itemCount
            end
        end
    end
    return 0, 0, 0, true
end

---@param zone CityZone
---@return string
function CityZoneManager:GetZoneRecoverFirstNotMatchPreConditionContent(zone)
    local config = zone.config
    local city = self.city
    local furnitureRequire = true
    local castle = city:GetCastle()
    if config:ExplorePreFurnitureLength() > 0 then
        furnitureRequire = false
        local requireType,requireLv
        local FurnitureLevel = ConfigRefer.CityFurnitureLevel
        for index = 1, config:ExplorePreFurnitureLength() do
            local furnitureConfig = FurnitureLevel:Find(config:ExplorePreFurniture(index))
            requireType = furnitureConfig:Type()
            requireLv = furnitureConfig:Level()
            for _, furniture in pairs(castle.CastleFurniture) do
                local furnitureCfg = FurnitureLevel:Find(furniture.ConfigId)
                if furnitureCfg:Type() == requireType and furnitureCfg:Level() >= requireLv then
                    furnitureRequire = true
                    break
                end
            end
        end
        if not furnitureRequire then
			return I18N.GetWithParams("mist_needfurniture", tostring(requireLv), I18N.Get(ConfigRefer.CityFurnitureTypes:Find(requireType):Name()))
        end
    end
    return string.Empty
end

---@param entity wds.CastleBrief
---@param changedData table
function CityZoneManager:OnFurnitureChanged(entity, changedData)
    if entity.ID ~= self.city.uid then
        return
    end
    local add,_,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.CastleFurniture)
    local needCheckZone = {}
    local FurnitureLv = ConfigRefer.CityFurnitureLevel
    if add then
        for _, v in pairs(add) do
            local cfg = FurnitureLv:Find(v.ConfigId)
            local inList = self.furnitureTypeSubscribeZone[cfg:Type()]
            if inList then
                local fLv = cfg:Level()
                for zoneId, requireLv in pairs(inList) do
                    if fLv >= requireLv then
                        needCheckZone[zoneId] = true
                    end
                end
            end
        end
    end
    if changed then
        for _, v in pairs(changed) do
            if v[2] then
                local cfg = FurnitureLv:Find(v[2].ConfigId)
                local inList = self.furnitureTypeSubscribeZone[cfg:Type()]
                if inList then
                    local fLv = cfg:Level()
                    for zoneId, requireLv in pairs(inList) do
                        if fLv >= requireLv then
                            needCheckZone[zoneId] = true
                        end
                    end
                end
            end
        end
    end
    for zoneId, _ in pairs(needCheckZone) do
        local zone = self.zoneIdMap[zoneId]
        if zone and not zone:IsHideFog() then
            self:RefreshZonePops()
            return
        end
    end
end

function CityZoneManager:GetCanExploreZone()
    local priority = math.mininteger
    local result
    for id, zone in pairs(self.zoneIdMap) do
        if zone and zone.config:ShowHint()
            and self:CheckZonePreZoneCondition(zone)
            and self:IsCanShowUnlockBubbleWithoutFurnitureCheck(zone)
            and self:IsReadyForUnlock(zone) then
            if zone.config:HintPriority() > priority then
                priority = zone.config:HintPriority()
                result = zone
            end
        end
    end
    return result
end

function CityZoneManager:GetNextZone()
    for id, zone in pairs(self.zoneIdMap) do
        --返回第一个没收复的区域
        if zone.status ~= CityZoneStatus.Recovered then
            return zone
        end
    end
    return nil
end

---@param zone CityZone
---@return RaisePowerPopupParam
function CityZoneManager:GetZoneUnlockUIParam(zone)
    ---@type RaisePowerPopupParam
    local ret = {}
    ret.overrideDefaultProvider = CityZoneUnlockPreConditionProvider.new(self, zone)
    return ret
end

function CityZoneManager:NeedLoadData()
    return true
end

function CityZoneManager:OnBubbleStateChange()
    local showBubble = not ModuleRefer.RadarModule:IsInRadar()
        and not self.city:IsEditMode()
        and not ModuleRefer.StoryModule:IsStoryTimelineOrDialogPlaying()
        and not CityWorkHelper.IsRelativeUiOpened()
        and not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityFurniturePlaceUIMediator)
    if showBubble then
        self:UnloadHeroRescueBubbles()
        self:LoadHeroRescueBubbles()

        self:UnloadZoneRecoverBubbles()
        self:LoadZoneRecoverBubbles()
    else
        self:UnloadHeroRescueBubbles()
        self:UnloadZoneRecoverBubbles()
    end
end

---@return boolean,CityZone|nil
function CityZoneManager:IsInSingleSeExplorerZone(x, y)
    local zone = self:GetZone(x, y)
    if not zone then return false,nil end
    return zone:SingleSeExplorerOnly(),zone
end

function CityZoneManager:GetOpenNpcLinkZoneId(elementId)
    return self.singleExplorerZoneOpenNpc[elementId]
end

function CityZoneManager:IsSingleExplorerOpenNpcLink(elementId)
    local zoneId = self:GetOpenNpcLinkZoneId(elementId)
    if not zoneId or zoneId == 0 then return false end
    local zone = self:GetZoneById(zoneId)
    return zone ~= nil, zoneId
end

function CityZoneManager:IsAllZoneRecoverd()
    for _, zone in pairs(self.zoneIdMap) do
        if not zone:Recovered() then
            return false
        end
    end
    return true
end

function CityZoneManager:GetZoneIdMap()
    return self.zoneIdMap
end

return CityZoneManager