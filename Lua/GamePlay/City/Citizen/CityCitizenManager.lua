local CityManagerBase = require("CityManagerBase")
local UnitActorType = require("UnitActorType")
local UnitMoveManager = require("UnitMoveManager")
local UnitActorFactory = require("UnitActorFactory")
local ModuleRefer = require("ModuleRefer")
local CityCitizenData = require("CityCitizenData")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local CityCitizenResidentFeedbackUIDataProvider = require("CityCitizenResidentFeedbackUIDataProvider")
local CityUnitInfectionVfx = require("CityUnitInfectionVfx")
local CityCitizenDefine = require("CityCitizenDefine")
local Utils = require("Utils")
local TimelineGameEventDefine = require("TimelineGameEventDefine")
local BuildingType = require("BuildingType")
local CityCitizenBubbleManager = require("CityCitizenBubbleManager")
local SlgUtils = require("SlgUtils")
local CityWorkTargetType = require("CityWorkTargetType")
local CitizenBTContext = require("CitizenBTContext")
local CityConst = require("CityConst")
local CitizenBTDefine = require("CitizenBTDefine")
local CityInteractionPointType = require("CityInteractionPointType")
local NpcServiceType = require("NpcServiceType")
local TaskRewardType = require("TaskRewardType")
local PackType = require("PackType")
local ItemType = require("ItemType")
local FunctionClass = require("FunctionClass")
local NpcServiceObjectType = require("NpcServiceObjectType")
local CityWorkType = require("CityWorkType")
local CityCitizenStateHelper = require("CityCitizenStateHelper")
local UIAsyncDataProvider = require("UIAsyncDataProvider")

local CastleAssignHouseParameter = require("CastleAssignHouseParameter")
local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CastleStopWorkParameter = require("CastleStopWorkParameter")
local CastleUpdateWorkParameter = require("CastleUpdateWorkParameter")
local CastleCitizenAwakeParameter = require("CastleCitizenAwakeParameter")
local CastleAssignProcessPlanParameter = require("CastleAssignProcessPlanParameter")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local CastleCitizenReceiveParameter = require("CastleCitizenReceiveParameter")
local CastleCitizenAssignProcessWorkParameter = require("CastleCitizenAssignProcessWorkParameter")
local ManualResourceConst = require("ManualResourceConst")

local Quaternion = CS.UnityEngine.Quaternion

---@class CachedInBuildingAutoFurnitureInfo
---@field buildingId number
---@field config BuildingLevelConfigCell
---@field pos wds.Point2 @buildingPos
---@field furnitureConfig CityFurnitureLevelConfigCell

---@class CityCitizenWorkTargetPair
---@field targetId number
---@field targetType number

---管理表现
---@class CityCitizenManager:CityManagerBase
---@field new fun(city:City):CityCitizenManager
local CityCitizenManager = class('CityCitizenManager', CityManagerBase)
CityCitizenManager.CitizenRevcoverBubblePrefab = ManualResourceConst.ui3d_bubble_btn

---@param city MyCity
function CityCitizenManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    self._isHideAndPause = false
    self._moveManager = UnitMoveManager.new()
    ---@type table<number, CityCitizenData>
    self._citizenData = {}
    ---@type table<number, CS.UnityEngine.Vector3>
    self._useSpawnPos = {}
    ---@type table<number, CityUnitCitizen>
    self._citizenUnit = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("CityCitizenManager")
    self._notifyTargetChanged = {}
    ---@type CityCitizenResidentFeedbackUIDataProvider
    self._inWaitingShowFeedbackProvider = nil
    self._pendingCreateCitizen = {}
    self._gridMinX = nil
    self._gridMinY = nil
    self._gridMaxX = nil
    self._gridMaxY = nil
    self._gridSizeX = nil
    ---@type table<number, CS.DragonReborn.AssetTool.PooledGameObjectHandle>
    self._createdCitizenRecoverBubble = {}
    self._bubbleMgr = CityCitizenBubbleManager.new()
    self._gContext = CitizenBTContext.new()
    self._bubbleLodLevel = nil
    self._delaySetGlobalContext = {}
    ---@type table<number, number>
    self._heroIdConfig2CitizenConfigId = {}
    self._signForUpgradeVillageCitizen = {}
end

function CityCitizenManager:DoDataLoad()
    local city = ModuleRefer.CityModule.myCity
    local serverCastleCitizens = city:GetCastle().CastleCitizens
    for id, data in pairs(serverCastleCitizens) do
        local v = CityCitizenData.CreateWithServerData(self, id, data)
        self._citizenData[id] = v
    end
    table.clear(self._heroIdConfig2CitizenConfigId)
    for _, value in ConfigRefer.Citizen:pairs() do
        self._heroIdConfig2CitizenConfigId[value:HeroId()] = value:Id()
    end
    CityUnitInfectionVfx.InitPoolRootOnce()
    self._bubbleMgr:Init(city)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    g_Game.EventManager:AddListener(EventConst.LuaStateMachineBehaviour, Delegate.GetOrCreate(self, self.OnCitizenAnimatorEvent))
    return self:DataLoadFinish()
end

function CityCitizenManager:DoDataUnload()
    g_Game.EventManager:RemoveListener(EventConst.LuaStateMachineBehaviour, Delegate.GetOrCreate(self, self.OnCitizenAnimatorEvent))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    if self._inWaitingShowFeedbackProvider then
        g_Game.UIManager:CancleOpenCmd(self._inWaitingShowFeedbackProvider._useInMediatorName)
        self._inWaitingShowFeedbackProvider:Release()
        self._inWaitingShowFeedbackProvider = nil
    end
    self._bubbleMgr:Release()
end

function CityCitizenManager:OnCameraSizeChanged(oldSize, newSize)
    local lodLevel = self:GetCameraLodLevel(newSize)
    if self._bubbleLodLevel == lodLevel then return end
    self._bubbleLodLevel = lodLevel
    for i, v in pairs(self._citizenUnit) do
        v._citizenBubble:OnLodChanged(self._bubbleLodLevel)
    end
end

function CityCitizenManager:GetCameraLodLevel(newSize)
    if newSize >= CityConst.NPC_MAX_VIEW_SIZE then
        return CityCitizenDefine.CitizenCameraLodLevel.Off
    elseif newSize >= CityConst.RoofShowCameraSize then
        return CityCitizenDefine.CitizenCameraLodLevel.High
    elseif newSize >= CityConst.CITY_RECOMMEND_CAMERA_SIZE then
        return CityCitizenDefine.CitizenCameraLodLevel.Mid
    end
    return CityCitizenDefine.CitizenCameraLodLevel.Low
end

function CityCitizenManager:SetHideAndPause(isHideAndPause)
    self._isHideAndPause = isHideAndPause
    for _, citizen in pairs(self._citizenUnit) do
        citizen:SetPause(isHideAndPause)
        citizen:SetIsHide(isHideAndPause)
    end
end

function CityCitizenManager:Tick(dt)
    if self._isHideAndPause then
        return
    end
    if self.city.cityPathFinding:IsNavMeshReady() then
        for id, _ in pairs(self._pendingCreateCitizen) do
            local data = self._citizenData[id]
            -- self:SpawnOne(data)
            break
        end
    end

    if self._waitTick then
        self._waitTick()
    end
    if #self._notifyTargetChanged > 0 then
        for _, v in ipairs(self._notifyTargetChanged) do
            self:OnWorkTargetChanged(v.id, v.type)
        end
        table.clear(self._notifyTargetChanged)
    end
end

function CityCitizenManager:IgnoreInvervalTicker(dt)
    if self._isHideAndPause then
        return
    end
    self._moveManager:Tick(dt)
    for _, v in ipairs(self._delaySetGlobalContext) do
        self:WriteGlobalContext(v[1], v[2])
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for _, citizen in pairs(self._citizenUnit) do
        citizen:Tick(dt, nowTime)
    end
    for _, v in ipairs(self._delaySetGlobalContext) do
        self:WriteGlobalContext(v[1], nil)
    end
    table.clear(self._delaySetGlobalContext)
end

function CityCitizenManager:AddSignForCoreUpgrade(id)
    self._signForUpgradeVillageCitizen[id] = true
end

function CityCitizenManager:RemoveSignForCoreUpgrade(id)
    self._signForUpgradeVillageCitizen[id] = nil
end

function CityCitizenManager:GetForSignForVillageUpgradeCitizenCount()
    return table.nums(self._signForUpgradeVillageCitizen)
end

function CityCitizenManager:SecTicker(dt)
    if self._isHideAndPause then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for _, citizen in pairs(self._citizenUnit) do
        citizen._data:TickIndicators(nowTime)
    end
end

function CityCitizenManager:SpawnCitizens()
    for id,_ in pairs(self._citizenData) do
        if not self._citizenUnit[id] and not self._pendingCreateCitizen[id] then
            self._pendingCreateCitizen[id] = true
        end
    end
end

---@return number,number,number,number
function CityCitizenManager:GetStrongholdRange()
    local mainFurniture = self.city.furnitureManager:GetMainFurniture()
    if mainFurniture then
        return mainFurniture.x,mainFurniture.y,mainFurniture.sizeX,mainFurniture.sizeY
    end
    -- local BuildingLvConfig = ConfigRefer.BuildingLevel
    -- for _,_,cell in self.city.gridView.grid:pairs() do
    --     if cell:IsBuilding() then
    --         local buildingConfig = BuildingLvConfig:Find(cell.configId)
    --         if buildingConfig then
    --             local buildingTypeConfig = ConfigRefer.BuildingTypes:Find(buildingConfig:Type())
    --             if buildingTypeConfig and buildingTypeConfig:Type() == BuildingType.Stronghold then
    --                 return cell
    --             end
    --         end
    --     end
    -- end
    return nil
end

---@param citizenData CityCitizenData
---@return CS.UnityEngine.Vector3|nil
function CityCitizenManager:GetSpawnPositionByWork(citizenData)
    local workData = citizenData:GetWorkData()
    if not workData then return nil end
    local target,targetType = workData:GetTarget()
    if not target or not targetType then return nil end
    local index,_,workLeftTime = workData:GetCurrentTargetIndexGoToTimeLeftTime()
    if not index or not workLeftTime or workLeftTime <= 0 then return nil end
    ---@type CityCitizenTargetInfo
    local targetInfo = {}
    targetInfo.id = target
    targetInfo.type = targetType
    targetInfo = CityCitizenStateHelper.ProcessFurnitureWorkTarget(targetInfo, citizenData)
    local x,y,sx,sy = self:GetWorkTargetRange(targetInfo.id, targetInfo.type)
    if x and y and sx and sy then
        x = math.max(0, x - 1)
        y = math.max(0, y - 1)
        sx = sx + 2
        sy = sy + 2
        x,y = self.city.cityPathFinding:GridToWalkable(x,y)
        sx,sy = self.city.cityPathFinding:GridToWalkable(sx,sy)
        return self.city.cityPathFinding:RandomPositionInRange(x,y, sx, sy, self.city.cityPathFinding.AreaMask.CityAllWalkable)
    end
    return nil
end

---@param citizenData CityCitizenData
function CityCitizenManager:SpawnOne(citizenData)
    self._pendingCreateCitizen[citizenData._id] = nil
    ---@type CityUnitCitizen
    local unit = UnitActorFactory.CreateOne(UnitActorType.CITY_CITIZEN)
    self._citizenUnit[citizenData._id] = unit
    local targetPos = self._useSpawnPos[citizenData._id] or self:GetSpawnPositionByWork(citizenData) or citizenData:SpawnPosition(self.city.cityPathFinding, self:GetStrongholdRange())
    self._useSpawnPos[citizenData._id] = nil
    local agent = self._moveManager:Create(unit.id, targetPos, Quaternion.identity, citizenData:WalkSpeed())
    local pathHeightFixer = Delegate.GetOrCreate(self.city, self.city.FixHeightWorldPosition)
    unit:Init(citizenData, self._goCreator, agent, citizenData:UnitActorConfigWrapper(), self.city.cityPathFinding, pathHeightFixer, self._gContext)
    unit:LoadModelAsync(self.city.CityWorkerRoot)
    unit:SyncFromData()
    unit:AttachMoveGridListener(self.city.unitMoveGridEventProvider)
end

function CityCitizenManager:DestroyCitizens()
    table.clear(self._pendingCreateCitizen)
    table.clear(self._useSpawnPos)
    for _, v in pairs(self._citizenUnit) do
        if v._data:HasWork() then
            self._useSpawnPos[v._data._id] = v:ReadMoveAgentPos()
        end
        v:Dispose()
    end
    table.clear(self._citizenUnit)
    for _, v in pairs(self._createdCitizenRecoverBubble) do
        v:Delete()
    end
    table.clear(self._createdCitizenRecoverBubble)
end

function CityCitizenManager:OnViewLoadFinish()
    g_Game.EventManager:AddListener(EventConst.CITY_WALKABLE_CHANGE_CHECK, Delegate.GetOrCreate(self, self.OnWalkableChangedCheck))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMove))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnBatchMoveFurniture))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_OPERATION_MOVING_START, Delegate.GetOrCreate(self, self.OnBuildingMovingStart))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_OPERATION_MOVING_STOP, Delegate.GetOrCreate(self, self.OnBuildingMovingStop))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_SELECT_SHOW, Delegate.GetOrCreate(self, self.OnSelectShowCitizen))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_SPAWN_CLICK, Delegate.GetOrCreate(self, self.OnClickCitizenReceiveFurniture))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_GAME_EVENT_START, Delegate.GetOrCreate(self, self.OnTimelineControlEventStart))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_GAME_EVENT_END, Delegate.GetOrCreate(self, self.OnTimelineControlEventEnd))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureLvUpInfoChanged))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTicker))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTicker))
    if UNITY_DEBUG and UNITY_EDITOR then
        g_Game:AddOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    end
end

function CityCitizenManager:OnViewUnloadStart()
    if UNITY_DEBUG and UNITY_EDITOR then
        g_Game:RemoveOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    end
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_GAME_EVENT_END, Delegate.GetOrCreate(self, self.OnTimelineControlEventEnd))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_GAME_EVENT_START, Delegate.GetOrCreate(self, self.OnTimelineControlEventStart))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_SPAWN_CLICK, Delegate.GetOrCreate(self, self.OnClickCitizenReceiveFurniture))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_SELECT_SHOW, Delegate.GetOrCreate(self, self.OnSelectShowCitizen))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_OPERATION_MOVING_STOP, Delegate.GetOrCreate(self, self.OnBuildingMovingStop))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_OPERATION_MOVING_START, Delegate.GetOrCreate(self, self.OnBuildingMovingStart))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnBatchMoveFurniture))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureMove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_WALKABLE_CHANGE_CHECK, Delegate.GetOrCreate(self, self.OnWalkableChangedCheck))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureLvUpInfoChanged))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTicker))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTicker))
end

function CityCitizenManager:OnCityActive()
    self:SpawnCitizens()
end

function CityCitizenManager:OnCityInactive()
    self:DestroyCitizens()
end

function CityCitizenManager:OnCameraLoaded(camera)
    self.camera = camera
    self.camera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
end

function CityCitizenManager:OnCameraUnload()
    self.camera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.UpdateCamera))
    self.camera = nil
end

---@param entity wds.CastleBrief
function CityCitizenManager:OnCitizenDataChanged(entity, changedData)
    if entity.ID ~= self.city.uid then
        return
    end
    local addMapR = {}
    ---@type table<number, wds.Citizen>
    local AddMap = changedData.Add
    ---@type table<number, wds.Citizen>
    local RemoveMap = changedData.Remove
    ---@type table<number, wds.Citizen[]>
    local ChangedMap = {}

    ---@type table<number, wds.Citizen>
    local needShowAdd = {}

    local needRefreshHouseIdMap = {}

    if RemoveMap then
        for id,_ in pairs(RemoveMap) do
            if AddMap and AddMap[id] and not addMapR[id] then
                if self._citizenData[id] then
                    ChangedMap[id] = AddMap[id]
                    addMapR[id] = true
                end
                goto continue
            end
            local c = self._citizenUnit[id]
            if c then
                c:Dispose()
                self:RemoveCitizenRecoverBubble(id)
            end
            self._citizenUnit[id] = nil
            local data = self._citizenData[id]
            if data._houseId ~= 0 then
                needRefreshHouseIdMap[data._houseId] = true
            end
            self._citizenData[id] = nil
            self._pendingCreateCitizen[id] = nil
            ::continue::
        end
    end

    if AddMap then
        for id,data in pairs(AddMap) do
            if not addMapR[id] then
                local v = CityCitizenData.CreateWithServerData(self, id, data)
                self._citizenData[id] = v
                if v._houseId ~= 0 then
                    needRefreshHouseIdMap[v._houseId] = true
                end
                local citizenConfig = ConfigRefer.Citizen:Find(data.ConfigId)
                if citizenConfig and not citizenConfig:SkipTriggerReceiveUI() then
                    needShowAdd[id] = data
                end
            end
        end
    end
    ---@type table<CityUnitCitizen, number> @exitwork = 1, assignHouse = 2
    local needSync = {}
    if ChangedMap then
        for id,data in pairs(ChangedMap) do
            local c = self._citizenData[id]
            local lastWorkId
            local lastHouseId
            local updateFlag = 0
            if c then
                lastWorkId = c._workId
                lastHouseId = c._houseId
                if c._houseId ~= 0 then
                    needRefreshHouseIdMap[c._houseId] = true
                end
                c:UpdateWithServerData(data)
            end
            if lastHouseId and lastHouseId == 0 and c._houseId ~= 0 then
                updateFlag = updateFlag | 2
                needRefreshHouseIdMap[c._houseId] = true
            end
            if lastWorkId ~=0 then
                updateFlag = updateFlag | 1
            end
            local u = self._citizenUnit[id]
            if u then
                needSync[u] = updateFlag
            end
        end
    end
    ---@type table<number, boolean>
    local needRefreshCitizenId = {}
    for unit, v in pairs(needSync) do
        unit:SyncFromData(v)
        needRefreshCitizenId[unit._data._id] = true
    end
    self:SpawnCitizens()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_DATA_REFRESH, self.city, needRefreshCitizenId)
    if not table.isNilOrZeroNums(needRefreshHouseIdMap) then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_DATA_HOUSE_NEED_REFRESH, self.city, needRefreshHouseIdMap)
    end
    if not self._inWaitingShowFeedbackProvider then
        if not table.isNilOrZeroNums(needShowAdd) then
            local provider = CityCitizenResidentFeedbackUIDataProvider.new(UIMediatorNames.UIOneDaySuccessMediator)
            self._inWaitingShowFeedbackProvider = provider
            provider:Init(self.city.uid, needShowAdd, function()
                self._inWaitingShowFeedbackProvider = nil
            end)
            ---@type UIAsyncDataProvider
            local asyncProvider = UIAsyncDataProvider.new()
            local name = provider._useInMediatorName
            local timing = UIAsyncDataProvider.PopupTimings.AnyTime
            local checkers = UIAsyncDataProvider.CheckTypes
            local check = checkers.DoNotShowOnOtherMediator | checkers.DoNotShowInSE | checkers.DoNotShowInGVE | checkers.DoNotShowInCityZoneRecoverState
            local failStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
            local shouldKeep = false
            local openParam = provider
            asyncProvider:Init(name, timing, check, failStrategy, shouldKeep, openParam)
            asyncProvider:SetOtherMediatorCheckType(0)
            asyncProvider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
            asyncProvider:AddOtherMediatorBlackList(UIMediatorNames.PetCaptureMediator)
            asyncProvider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogUIMediator)
            asyncProvider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogChatUIMediator)
            asyncProvider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogRecordUIMediator)
            asyncProvider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogSkipPopupUIMediator)
            g_Game.UIAsyncManager:AddAsyncMediator(asyncProvider)
            -- g_Game.UIManager:SendOpenCmd(provider._useInMediatorName, provider)
        end
    end
end

---@param tileId number
function CityCitizenManager:OnBuildingMovingStart(tileId)
    local tile = self.city.grid:FindMainCellWithTileId(tileId)
    local toTrans = self.city.gridView:GetCellTile(tile.x, tile.y):GetRoot().transform
    ---@type CityPathFindingGridRange
    local gridRange = {x = tile.x, y = tile.y, xMax = tile.x + tile.sizeX, yMax = tile.y + tile.sizeY}
    for _,v in pairs(self._citizenUnit) do
        if v._data:IsAssignedHouse() and v._data._houseId == tileId and v:CheckSelfPosition(gridRange) then
            v:SetPause(true)
            v:SetParent(toTrans)
        end
    end
end

function CityCitizenManager:OnBuildingMovingStop()
    local toTrans = self.city:GetRoot().transform
    for _,v in pairs(self._citizenUnit) do
        if v._data:IsAssignedHouse() then
            v:SetParent(toTrans)
            v:SetPause(false)
        end
    end
end

function CityCitizenManager:OnFurnitureMove(city, oriX, oriY, newX, newY, id)
    local v = {id = id, type=CityWorkTargetType.Furniture}
    table.insert(self._notifyTargetChanged, v)
end

---@param city City
---@param movedMap table<number, CityFurniture>
function CityCitizenManager:OnBatchMoveFurniture(city, movedMap)
    for key, _ in pairs(movedMap) do
        local v = {id = key, type=CityWorkTargetType.Furniture}
    table.insert(self._notifyTargetChanged, v)
    end
end

---@param city City
---@param gridRange CityPathFindingGridRange
function CityCitizenManager:OnWalkableChangedCheck(city, gridRange)
    if city.uid ~= self.city.uid then
        return
    end
    if gridRange.buildingId then
        local v = {id = gridRange.buildingId, type=CityWorkTargetType.Building}
        table.insert(self._notifyTargetChanged, v)
    end
    for _,v in pairs(self._citizenUnit) do
        v:OnWalkableChangedCheck(gridRange)
    end
end

---@param param {Event:string, Change:table<number, boolean>}
function CityCitizenManager:OnFurnitureLvUpInfoChanged(city, param)
    if city ~= self.city then return end
    ---@type table<number, number> @furnitureType, level
    local set = {}
    for id, changed in pairs(param.Change) do
        if not changed then goto continue end
        local furniture = self.city.furnitureManager:GetFurnitureById(id)
        if furniture == nil or furniture:GetCastleFurniture().LevelUpInfo.Working then goto continue end
        set[furniture.furType] = furniture.level
        if furniture:IsMainBase() then
            table.clear(self._signForUpgradeVillageCitizen)
        end
        ::continue::
    end
    table.insert(self._delaySetGlobalContext, {CitizenBTDefine.G_ContextKey.cityFurnitureUpgrade, set})
end

---@param id number
---@param targetType number
function CityCitizenManager:OnWorkTargetChanged(id, targetType)
    local relativeCitizenIds = self.city.cityWorkManager:GetRelativeCitizenIds(id, targetType)
    local notifyWorkTargetChangeMap = {}
    for _, citizenId in ipairs(relativeCitizenIds) do
        local citizen = self._citizenUnit[citizenId]
        if citizen then
            --citizen:OnWorkTargetChanged(id, targetType)
            notifyWorkTargetChangeMap[citizenId] = {id=id,targetType=targetType}
        else
            g_Logger.Error("citizen:%d not found", citizenId)
        end
    end
    table.insert(self._delaySetGlobalContext, {CitizenBTDefine.G_ContextKey.cityWorkTargetChange, notifyWorkTargetChangeMap})
end

function CityCitizenManager:OnSelectShowCitizen(citizenId)
    for id, unit in pairs(self._citizenUnit) do
        if id == citizenId then
            unit:SetSelectedShow(true)
        else
            unit:SetSelectedShow(false)
        end
    end
end

function CityCitizenManager:DoMarkSpawnPosThenSendCastleCitizenReceive(citizenId, targetPos)
    self._useSpawnPos[citizenId] = targetPos
    local sendCmd = CastleCitizenReceiveParameter.new()
    sendCmd:SendWithFullScreenLock()
end

---@param cityUid number
---@param furnitureSingleId number
function CityCitizenManager:OnClickCitizenReceiveFurniture(cityUid, furnitureSingleId)
    if not cityUid or not self.city or self.city.uid ~= cityUid then
        return false
    end
    local furniture = self.city.furnitureManager:GetFurnitureById(furnitureSingleId)
    if not furniture then
        return
    end
    local castle = self.city:GetCastle()
    local pathFinding = self.city.cityPathFinding
    local targetPos = pathFinding:NearestWalkableOnGraph(self.city:GetWorldPositionFromCoord(furniture.x, furniture.y), pathFinding.AreaMask.CityGround)
    local furnitureData = castle.CastleFurniture[furnitureSingleId]
    local waitingCitizenQueue = furnitureData and furnitureData.WaitingCitizens or nil
    if waitingCitizenQueue and not table.isNilOrZeroNums(waitingCitizenQueue) then
        self:CheckAndReceiveCitizen(waitingCitizenQueue[1], targetPos)
    end
end

function CityCitizenManager:OnTimelineControlEventStart(args)
    if args[1] == TimelineGameEventDefine.CITY_PAUSE_HIDE_CITIZEN then
        self:SetHideAndPause(true)
    end
end

function CityCitizenManager:OnTimelineControlEventEnd(args)
    if args[1] == TimelineGameEventDefine.CITY_PAUSE_HIDE_CITIZEN then
        self:SetHideAndPause(false)
    end
end

function CityCitizenManager:CheckAndReceiveCitizen(citizenId, targetPos)
    if not citizenId then
        return
    end
    local pop,total = self:GetCitizenPopulationAndCapacity()
    if pop >= total then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_population_max"))
        return
    end
    local cfg = ConfigRefer.Citizen:Find(citizenId)
    if cfg then
        local dialogId = cfg:ReceiveDialog()
        local dialogCfg = ConfigRefer.StoryDialogGroup:Find(dialogId)
        if dialogCfg then
            local parameter = StoryDialogUIMediatorParameter.new()
            local t = parameter:SetDialogGroup(dialogId,
                    function(uiRuntimeId)
                        if uiRuntimeId then
                            g_Game.UIManager:Close(uiRuntimeId)
                        end
                        self:DoMarkSpawnPosThenSendCastleCitizenReceive(citizenId, targetPos)
                    end)
            ModuleRefer.StoryModule:OpenDialogMediatorByType(t, parameter)
            return
        end
    end
    self:DoMarkSpawnPosThenSendCastleCitizenReceive(citizenId, targetPos)
end

---@param citizenData CityCitizenData
---@return number,number,number,number,number @x,z,sX,sZ,areaMask
function CityCitizenManager:GetAssignedArea(citizenData)
    if citizenData._houseId ~= 0 then
        local building = self.city.legoManager:GetLegoBuilding(citizenData._houseId)
        if building then
            local x,z = self.city.cityPathFinding:GridToWalkable(building.x, building.z)
            local sX,sZ = self.city.cityPathFinding:GridToWalkable(building.sizeX, building.sizeZ)
            return x,z,sX,sZ,self.city.cityPathFinding.AreaMask.CityBuildingRoom
        end
    end
end

---@param targetId number
---@param targetType number
---@param useCenter boolean
---@param reason CityCitizenDefine.WorkTargetReason
---@return CS.UnityEngine.Vector3|nil
function CityCitizenManager:GetWorkTargetPosition(targetId, targetType, useCenter, reason)
    if targetType == CityWorkTargetType.Building then
        local cell = self.city.grid:FindMainCellWithTileId(targetId)
        if cell then
            local x = cell.x
            local y = cell.y
            if useCenter then
                x = cell.x + 0.5 * cell.sizeX
                y = cell.y + 0.5 * cell.sizeY
            end
            return self.city:GetWorldPositionFromCoord(x, y)
        end
    elseif targetType == CityWorkTargetType.Furniture then
        local cell = self.city.furnitureManager:GetFurnitureById(targetId)
        if cell then
            local x,y
            if useCenter then
                x = cell.x + 0.5 * cell.sizeX
                y = cell.y + 0.5 * cell.sizeY
            else
                x,y = cell:GetCollectPos(reason)
            end
            return self.city:GetWorldPositionFromCoord(x, y)
        end
    elseif targetType == CityWorkTargetType.Resource then
        local element = self.city.elementManager:GetElementById(targetId)
        if element then
            local resourceCfg = element.resourceConfigCell
            local x = element.x
            local y = element.y
            if useCenter then
                x = element.x + 0.5 * element.sizeX
                y = element.y + 0.5 * element.sizeY
            else
                if resourceCfg and resourceCfg:CollectPosLength() > 1 then
                    x = x + resourceCfg:CollectPos(1)
                    y = y + resourceCfg:CollectPos(2)
                else
                    x = element.x + 0.5 * element.sizeX
                    y = element.y + 0.5 * element.sizeY
                end
            end
            return self.city:GetWorldPositionFromCoord(x, y)
        end
    end
    g_Logger.Error("GetWorkTargetPosition:targetType:%d, not supported", targetType)
    return nil
end

---@param targetId number
---@param targetType number
---@param useCenter boolean
---@return number,number,number,number @x,y,sizeX,sizeY
function CityCitizenManager:GetWorkTargetRange(targetId, targetType)
    if targetType == CityWorkTargetType.Building then
        local cell = self.city.grid:FindMainCellWithTileId(targetId)
        if cell then
            return cell.x,cell.y,cell.sizeX,cell.sizeY
        end
    elseif targetType == CityWorkTargetType.Furniture then
        local cell = self.city.furnitureManager:GetFurnitureById(targetId)
        if cell then
            return cell.x,cell.y,cell.sizeX,cell.sizeY
        end
    elseif targetType == CityWorkTargetType.Resource then
        local element = self.city.elementManager:GetElementById(targetId)
        if element then
            return element.x,element.y,element.sizeX,element.sizeY
        end
    end
    g_Logger.Error("GetWorkTargetRange:targetType:%d, not supported", targetType)
    return nil
end

---@return CityInteractPoint_Impl|nil
function CityCitizenManager:AcquireWorkTargetInteractPoint(targetId, targetType, reason)
    ---@type CityCitizenTargetInfo
    local needOwnerInfo = {}
    needOwnerInfo.id = targetId
    needOwnerInfo.type = targetType
    local ret
    if targetType == CityWorkTargetType.Building then
        ret = self.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Upgrade, (~0), needOwnerInfo)
    elseif targetType == CityWorkTargetType.Furniture then
        if reason == CityCitizenDefine.WorkTargetReason.Operate then
            ret = self.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Operate, (~0), needOwnerInfo)
        else
            ret = self.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Upgrade, (~0), needOwnerInfo)
        end
    elseif targetType == CityWorkTargetType.Resource then
        ret = self.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Collect, (~0), needOwnerInfo)
    end
    if not ret then
        g_Logger.Warn("AcquireWorkTargetInteractPoint spectype fallback to Generic id:%s,type:%s,reason:%s", targetId, targetType,reason)
        ret = self.city.cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Generic, (~0), needOwnerInfo)
    end
    if ret then return ret end
    if UNITY_DEBUG then
        g_Logger.Error("AcquireWorkTargetInteractPoint fail, id:%s,targetType:%s,reason:%s,not supported", targetId, targetType, reason)
    end
    return nil
end

---@param targetId number
---@param targetType number
---@param reason CityCitizenDefine.WorkTargetReason
---@return CS.UnityEngine.Vector3
function CityCitizenManager:GetWorkTargetInteractDirPos(targetId, targetType, reason)
    if targetType == CityWorkTargetType.Building then
        local cell = self.city.grid:FindMainCellWithTileId(targetId)
        if cell then
            local x = cell.x
            local y = cell.y
            x = x + 0.5 * cell.sizeX
            y = y + 0.5 * cell.sizeY
            return self.city:GetWorldPositionFromCoord(x, y)
        end
    elseif targetType == CityWorkTargetType.Furniture then
        local cell = self.city.furnitureManager:GetFurnitureById(targetId)
        if cell then
            if reason == CityCitizenDefine.WorkTargetReason.Base then
                local x = cell.x
                local y = cell.y
                x = x + 0.5 * cell.sizeX
                y = y + 0.5 * cell.sizeY
                return self.city:GetWorldPositionFromCoord(x, y)
            else
                local offsetX,offsetY = cell:GetLocalCollectOffset(reason)
                local x = cell.x + offsetX
                local y = cell.y + offsetY
                return self.city:GetWorldPositionFromCoord(x, y)
            end
        end
    elseif targetType == CityWorkTargetType.Resource then
        local element = self.city.elementManager:GetElementById(targetId)
        if element then
            local resourceCfg = element.resourceConfigCell
            local cellX = element.x
            local cellY = element.y
            local x = cellX + 0.5 * element.sizeX
            local y = cellY + 0.5 * element.sizeY
            if resourceCfg:CollectPosLength() > 2 then
                local dir = resourceCfg:CollectPos(3)
                if dir == 1 then
                    x = cellX + resourceCfg:CollectPos(1)
                    y = cellY + resourceCfg:CollectPos(2) + 1
                elseif dir == 2 then
                    x = cellX + resourceCfg:CollectPos(1) - 1
                    y = cellY + resourceCfg:CollectPos(2)
                elseif dir == 3 then
                    x = cellX + resourceCfg:CollectPos(1)
                    y = cellY + resourceCfg:CollectPos(2) - 1
                elseif dir == 4 then
                    x = cellX + resourceCfg:CollectPos(1) + 1
                    y = cellY + resourceCfg:CollectPos(2)
                end
            end
            return self.city:GetWorldPositionFromCoord(x, y)
        end
    end
    g_Logger.Error("GetWorkTargetInteractDirPos:targetType:%d, not supported", targetType)
    return nil
end

---@param workId number
---@return CityCitizenWorkData
function CityCitizenManager:GetWorkData(workId)
    return self.city.cityWorkManager:GetCitizenWorkData(workId)
end

---@param targetId number
---@param targetType number
---@return CityCitizenWorkData
function CityCitizenManager:GetWorkDataByTarget(targetId, targetType)
    return self.city.cityWorkManager:GetCitizenWorkDataByTarget(targetId, targetType)
end

function CityCitizenManager:IsCitizenFree(citizenId)
    local citizenData = self._citizenData[citizenId]
    return citizenData and not citizenData:HasWork()
end

---@return fun():number,CityCitizenData,CityCitizenWorkData
function CityCitizenManager:pairsCitizenData()
    local id
    local value
    return function()
        id, value = next(self._citizenData, id)
        if id and value then
            return id, value, self:GetWorkData(value._workId)
        end
    end
end

function CityCitizenManager:GetCitizenIdByWorkId(workId)
    return self.city.cityWorkManager:GetWorkData(workId).CitizenId
end

function CityCitizenManager:GetCitizenWorkDataByCitizenId(citizenId)
    return self.city.cityWorkManager:GetCitizenWorkDataByCitizenId(citizenId)
end

function CityCitizenManager:GetCitizenDataById(citizenId)
    return self._citizenData[citizenId]
end

function CityCitizenManager:GetCitizenCountByHouse(houseId)
    local ret = 0
    for _, data in pairs(self._citizenData) do
        if data._houseId == houseId then
            ret = ret + 1
        end
    end
    return ret
end

function CityCitizenManager:GetCitizenDataLastUpdateTime(citizenId)
    if not self._citizenData[citizenId] then
        return 0
    end
    return self.city:GetCastle().LastWorkUpdateTime.ServerSecond
end

function CityCitizenManager:IsTargetInfection(targetId, targetType)
    if targetType == CityWorkTargetType.Building then
        return self.city.buildingManager:IsPolluted(targetId)
    elseif targetType == CityWorkTargetType.Furniture then
        return self.city.furnitureManager:IsPolluted(targetId)
    elseif targetType == CityWorkTargetType.Resource then
        return self.city.elementManager:IsPolluted(targetId)
    end
    return false
end

function CityCitizenManager:GetCitizenSlotByHouse(houseId)
    local ret = 0
    local castle = self.city:GetCastle()
    local buildingInfo = castle.BuildingInfos[houseId]
    local furnitureMap = castle.CastleFurniture
    for _, id in ipairs(buildingInfo.InnerFurniture) do
        local info = furnitureMap[id]
        local furnitureLvCell = ConfigRefer.CityFurnitureLevel:Find(info.ConfigId)
        ret = ret + CityCitizenDefine.GetFurnitureBedCount(furnitureLvCell)
    end
    return ret
end

function CityCitizenManager:GetTotalCitizenSlotInCity()
    local ret = 0
    local castle = self.city:GetCastle()
    local furnitureMap = castle.CastleFurniture
    for _, buildingInfo in pairs(castle.BuildingInfos) do
        for _, id in ipairs(buildingInfo.InnerFurniture) do
            local info = furnitureMap[id]
            local furnitureLvCell = ConfigRefer.CityFurnitureLevel:Find(info.ConfigId)
            if furnitureLvCell then
                ret = ret + CityCitizenDefine.GetFurnitureBedCount(furnitureLvCell)
            end
        end
    end
    return ret
end

function CityCitizenManager:GetHomelessCitizenCount()
    local count = 0
    for _, citizenData in pairs(self._citizenData) do
        if citizenData._houseId == 0 then
            count = count + 1
        end
    end
    return count
end

function CityCitizenManager:GetFreeCitizen(pos)
    return self:GetFreeWorkableCitizen(pos) or self:GetFreeHomelessCitizen(pos)
end

---@return CityUnitCitizen
function CityCitizenManager:GetFreeWorkableCitizen(pos)
    local ret
    local distanceSqr
    for _, citizen in pairs(self._citizenUnit) do
        if not citizen._data:HasWork() and citizen._data:IsAssignedHouse() and not citizen._data:IsFainting() then
            if not pos then
                return citizen
            end
            if not ret then
                ret = citizen
                distanceSqr = (citizen._moveAgent._currentPosition - pos).sqrMagnitude
            else
                local distance = (citizen._moveAgent._currentPosition - pos).sqrMagnitude
                if distance < distanceSqr then
                    distanceSqr = distance
                    ret = citizen
                end
            end
        end
    end
    return ret
end

function CityCitizenManager:GetFreeHomelessCitizen(pos)
    local ret
    local distanceSqr
    for _, citizen in pairs(self._citizenUnit) do
        if not citizen._data:HasWork() and not citizen._data:IsAssignedHouse() and not citizen._data:IsFainting()  then
            if not pos then
                return citizen
            end
            if not ret then
                ret = citizen
                distanceSqr = (citizen._moveAgent._currentPosition - pos).sqrMagnitude
            else
                local distance = (citizen._moveAgent._currentPosition - pos).sqrMagnitude
                if distance < distanceSqr then
                    distanceSqr = distance
                    ret = citizen
                end
            end
        end
    end
    return ret
end

function CityCitizenManager:GetFreeCitizenCount()
    local count = 0
    if self._citizenUnit then
        for _, citizen in pairs(self._citizenUnit) do
            if citizen and citizen._data and not citizen._data:HasWork() then
                count = count + 1
            end
        end
    end
    return count
end

---@return number, number @
function CityCitizenManager:GetCitizenPopulationAndCapacity()
    local city = ModuleRefer.CityModule.myCity
    local castle = city:GetCastle()
    local citizens = castle.CastleCitizens
    local _,usage = table.IsNullOrEmpty(citizens)
    local total = castle.GlobalAttr.CitizenCapacity
    return usage,total
end

---@return CS.UnityEngine.Vector3
function CityCitizenManager:GetCitizenPosition(citizenId)
    local unit = self._citizenUnit[citizenId]
    return unit and unit._moveAgent._currentPosition or nil
end

---@return CS.UnityEngine.Transform|nil, CitizenBubbleState
function CityCitizenManager:GetCitizenTaskBubbleTrans(citizenId)
    local unit = self._citizenUnit[citizenId]
    ---@type CitizenBubbleState
    local bubbleState = unit._citizenBubble._stateMachine.currentState
    if bubbleState then
        return bubbleState:GetCurrentBubbleTrans(), bubbleState
    end
    return nil, nil
end

function CityCitizenManager:CreateCitizenRecoverBubble(citizenId)
    local citizen = self._citizenUnit[citizenId]
    if not citizen then
        return
    end
    if self._createdCitizenRecoverBubble[citizenId] then
        return
    end
    local citizenPos = citizen._moveAgent._currentPosition
    local userData = {
        Id = citizenId,
        WorldPos = citizenPos,
    }
    self._goCreator:Create(CityCitizenManager.CitizenRevcoverBubblePrefab, self.city:GetRoot().transform, Delegate.GetOrCreate(self, self.OnCitizenRecoverBubbleCreated), userData)
end

function CityCitizenManager:RemoveCitizenRecoverBubble(citizenId)
    local handle = self._createdCitizenRecoverBubble[citizenId]
    if not handle then
        return
    end
    self._createdCitizenRecoverBubble[citizenId] = nil
    handle:Delete()
end

---@param go CS.UnityEngine.GameObject
---@param userData table
function CityCitizenManager:OnCitizenRecoverBubbleCreated(go,userData)
    if Utils.IsNull(go) then
        return
    end
    local citizenId = userData.Id
    local citizenPos = userData.WorldPos
    go.transform.position = citizenPos
    local buttonBehaviour = go:GetLuaBehaviour("UI3DButton")
    if Utils.IsNull(buttonBehaviour) then
        return
    end
    ---@type UI3DButton
    local button = buttonBehaviour.Instance
    if not button then
        return
    end
    button:SetIcon("sp_city_icon_recover")
    button:SetOnTrigger(function()
        self:SendRecoverCitizen(citizenId)
        self:RemoveCitizenRecoverBubble(citizenId)
    end)
    button:EnableTrigger(true)
end

---@param citizenId number
---@param houseId number
---@param lockTrans CS.UnityEngine.Transform
function CityCitizenManager:AssignCitizenToHouse(citizenId, houseId, lockTrans)
    local msg = CastleAssignHouseParameter.new()
    msg.args.CitizenId = citizenId
    msg.args.HouseId = houseId
    if Utils.IsNotNull(lockTrans) then
        msg:Send(lockTrans)
    else
        msg:SendWithFullScreenLock()
    end
end

---@param citizenId number
---@param workId number
---@param targets number[]
---@param targetsTime number[]
---@param workPosX number
---@param workPosY number
---@param lockTrans CS.UnityEngine.Transform
function CityCitizenManager:StartWorkImpl(citizenId, workId, targets, targetsTime, workPosX, workPosY, lockTrans)
    local msg = CastleStartWorkParameter.new()
    msg.args.CitizenId = citizenId
    msg.args.WorkId = workId
    msg.args.Targets:AddRange(targets)
    msg.args.TimeSegments:AddRange(targetsTime)
    msg.args.WorkPos = wds.Vector2F.New(workPosX, workPosY)
    if Utils.IsNotNull(lockTrans) then
        msg:Send(lockTrans)
    else
        msg:SendWithFullScreenLock()
    end
end

---@param citizenId number
function CityCitizenManager:StopWorkImpl(citizenId, lockTrans)
    local msg = CastleStopWorkParameter.new()
    msg.args.CitizenId = citizenId
    if Utils.IsNotNull(lockTrans) then
        msg:Send(lockTrans)
    else
        msg:SendWithFullScreenLock()
    end
end

---@param workId number
---@param targetsTime number[]
function CityCitizenManager:UpdateWorkImpl(workId, targetsTime)
    local msg = CastleUpdateWorkParameter.new()
    msg.args.WorkId = workId
    local tmp = {}
    for i, v in ipairs(targetsTime) do
        tmp[i] = math.floor(v + 0.5)
    end
    msg.args.TimeSegments:AddRange(tmp)
    msg:Send()
end

---@param citizenId number
---@param lockTrans CS.UnityEngine.Transform
function CityCitizenManager:SendRecoverCitizen(citizenId, lockTrans)
    local msg = CastleCitizenAwakeParameter.new()
    msg.args.CitizenId = citizenId
    msg:Send(lockTrans)
end

local function GetTypes(target, f, l)
    local ret = {}
    for i = 1, l do
        local t = f(target, i)
        ret[t] = t
    end
    return ret
end

local function AddArrayToStringFunc(array)
    setmetatable(array, {
        __index = {
            __tostring = function(self, indent)
                if #self <= 0 then
                    return indent .. 'emptyArray'
                end
                local ret = indent .. '[' .. tostring(self[1])
                for index = 2, #self do
                    ret = ret .. ',' .. tostring(self[index])
                end
                ret = ret .. ']'
                return ret
            end
        }
    })
end

---@param citizenId number
---@param targetId number
---@param targetType number
---@param lockTrans CS.UnityEngine.Transform
function CityCitizenManager:StartWork(citizenId, targetId, targetType, lockTrans)
    self.city.cityWorkManager:TryAttachCitizenToWorkTarget(citizenId, targetId, targetType, lockTrans)
end

---@param citizenId number
---@param lockTrans CS.UnityEngine.Transform
function CityCitizenManager:StopWork(citizenId, lockTrans)
    self:StopWorkImpl(citizenId, lockTrans)
end

---@param workId number
---@param targetsTime number[]
function CityCitizenManager:UpdateWork(workId, targetsTime)
    AddArrayToStringFunc(targetsTime)
    self:UpdateWorkImpl(workId, targetsTime)
end

---@param furnitureId number
---@param processId number
---@param num number
---@param callBack fun(context, isSuccess:boolean, data)
---@param context any
function CityCitizenManager:AssignProcessPlan(furnitureId, processId, num, callBack, context)
    local sendCmd = CastleAssignProcessPlanParameter.new()
    sendCmd.args.FurnitureId = furnitureId
    sendCmd.args.ProcessId = processId
    sendCmd.args.QueueIdx:Add(0)
    sendCmd.args.Num = num
    sendCmd:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if callBack then
            callBack(context, isSuccess, rsp)
        end
    end, nil)
end

---@param lockable CS.UnityEngine.Transform
---@param furnitureId number
---@param queueIndex number[]
---@param processId number
---@param num number
---@param callBack fun(context, isSuccess:boolean, data)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityCitizenManager:ModifyProcessPlan(lockable, furnitureId, queueIndex, processId, num, callBack, simpleErrorOverride)
    local cmd = CastleAssignProcessPlanParameter.new()
    cmd.args.FurnitureId = furnitureId
    cmd.args.QueueIdx:AddRange(queueIndex)
    cmd.args.ProcessId = processId
    cmd.args.Num = num
    cmd:SendOnceCallback(lockable, nil, nil, callBack, simpleErrorOverride)
end

---@param lockable CS.UnityEngine.Transform|nil
---@param workId number
---@param citizenId number|nil @ - 0 or nil means discharge citizen
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function CityCitizenManager:AssignProcessWorkCitizen(lockable, workId, citizenId, callback)
    local sendCmd = CastleCitizenAssignProcessWorkParameter.new()
    sendCmd.args.WorkId = workId
    sendCmd.args.CitizenId = citizenId or 0
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

---@param lockable CS.UnityEngine.Transform
---@param furnitureId number
---@param callBack fun(context, isSuccess:boolean, data)
---@param canGetIndex number[]|nil
---@param matchFirst boolean
---@param context any
function CityCitizenManager:GetProcessOutput(lockable, furnitureId, callBack, canGetIndex, matchFirst, context)
    local castle = self.city:GetCastle()
    local furniture = castle and castle.CastleFurniture and castle.CastleFurniture[furnitureId]
    if not furniture then
        if callBack then
            callBack(nil, false)
        end
        return
    end
    if not canGetIndex then
        canGetIndex = {}
        local process = furniture.ProcessInfo or {}
        for i = 1, #process do
            local p = process[i]
            if p and p.FinishNum > 0 then
                table.insert(canGetIndex, i-1)
                if matchFirst then
                    break
                end
            end
        end
        if #canGetIndex <= 0 then
            if callBack then
                callBack(nil, false)
            end
            return
        end
    end
    local cmd = CastleGetProcessOutputParameter.new()
    cmd.args.FurnitureId = furnitureId
    cmd.args.QueueIdxes:AddRange(canGetIndex)
    cmd:SendOnceCallback(lockable, nil, nil, callBack, function(msgId, errorCode, jsonTable)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_resource_full"))
        return true
    end)
end

function CityCitizenManager:UpdateCamera(basicCamera)
    if not self.city:IsMyCity() then return end
    if not self.city.showed then return end
    if not self._bubbleMgr:Initialized() then return end
    self._bubbleMgr:UpdateCamera(basicCamera)
end

---@param citizen CityUnitCitizen
---@return boolean
function CityCitizenManager:CheckIsEnemyEffectRange(citizen)
    local pos = citizen._moveAgent._currentPosition
    if not pos then
        return false
    end
    local city = self.city
    local scale = city.scale
    local gridConfig = city.gridConfig
    local range = ConfigRefer.CityConfig:CitizenEscapeCheckRange()
    local worldRange = range * scale * (gridConfig.unitsPerCellY + gridConfig.unitsPerCellX) * 0.5
    local p = city.unitPositionQuadTree:SearchAny(pos.x - worldRange, pos.z - worldRange, worldRange*2,worldRange*2)
    for _, v in pairs(p) do
        if v.value >= SlgUtils.TroopType.Monster then
            return true
        end
    end
    return false
end

function CityCitizenManager:OnDrawGizmos()
    for _, v in pairs(self._citizenUnit) do
        if v then
            v:OnDrawGizmos()
        end
    end
end

function CityCitizenManager:NeedLoadData()
    return true
end

---@param eventTable LuaStateMachineBehaviourParameter
function CityCitizenManager:OnCitizenAnimatorEvent(eventTable)
    if not eventTable or not eventTable.instanceId or not eventTable.eventId or string.IsNullOrEmpty(eventTable.stringParam) then
        return
    end
    if eventTable.stringParam == "citizen_work_tool" then
        local shortNameHash = eventTable.shortNameHash
        ---@type CS.UnityEngine.Animator
        local animator = CS.UnityEngine.Resources.InstanceIDToObject(eventTable.instanceId)
        if Utils.IsNotNull(animator) then
            if eventTable.eventId == 1 then
                local allScripts = {}
                animator.gameObject:GetLuaBehavioursInChildren("CityCitizenPrefabLoader", allScripts, true)
                for i, luaScript in ipairs(allScripts) do
                    if Utils.IsNotNull(luaScript) then
                        if luaScript.Instance:MatchNameHash(shortNameHash) then
                            luaScript.gameObject:SetActive(false)
                        end
                    end
                end
            elseif eventTable.eventId == 0 then
                local allScripts = {}
                animator.gameObject:GetLuaBehavioursInChildren("CityCitizenPrefabLoader", allScripts, true)
                for i, luaScript in ipairs(allScripts) do
                    if Utils.IsNotNull(luaScript) then
                        if luaScript.Instance:MatchNameHash(shortNameHash) then
                            luaScript.gameObject:SetActive(true)
                        end
                    end
                end
            end
        end
    end
end

function CityCitizenManager:WriteGlobalContext(name, value)
    self._gContext:Write(name, value)
end

---@param callback fun(isSuccess:boolean, bubbleTrans:CS.UnityEngine.Transform, bubbleState:CitizenBubbleState)
function CityCitizenManager:FocusOnCitizen(citizenId, callback)
    local pos = self:GetCitizenPosition(citizenId)
    if pos then
        ---@type CS.UnityEngine.Vector3
        local viewPortPos = CS.UnityEngine.Vector3(0.5, 0.5, 0.0)
        self.city.camera:ForceGiveUpTween()
        self.city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, pos, nil, function()
            if callback then
                local citizenBubbleTrans, bubbleState = self:GetCitizenTaskBubbleTrans(citizenId)
                if Utils.IsNotNull(citizenBubbleTrans) then
                    callback(true, citizenBubbleTrans, bubbleState)
                else
                    callback(true, nil, bubbleState)
                end
            end
        end)
    else
        if callback then
            callback(false, nil, nil)
        end
    end
end

---@param serviceId number @NpcService
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@return fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function CityCitizenManager:CheckAndPresetCitizenSpwanPos(callback, serviceId, objectType, objectId)
    if objectType ~= NpcServiceObjectType.CityElement then return callback end
    local config = ConfigRefer.NpcService:Find(serviceId)
    if not config or config:ServiceType() ~= NpcServiceType.FinishTask then return callback end
    local taskConfig = ConfigRefer.Task:Find(config:ServiceParam())
    if not taskConfig then return callback end
    local eleConfig = ConfigRefer.CityElementData:Find(objectId)
    if not eleConfig then return callback end
    local elePos = eleConfig:Pos()
    local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
    if not npcConfig then return callback end
    local pos = self.city:GetCenterWorldPositionFromCoord(elePos:X(), elePos:Y(), npcConfig:SizeX(), npcConfig:SizeY())
    if not pos then return callback end
    local currentHasCitizen = {}
    for key, _ in pairs(self._citizenData) do
        currentHasCitizen[key] = true
    end
    local needProcessCitizen = {}
    for i = 1, taskConfig:FinishBranchLength() do
        local branckReward = taskConfig:FinishBranch(i)
        for j = 1, branckReward:BranchRewardLength() do
            local reward = branckReward:BranchReward(j)
            if reward:Typ() == TaskRewardType.RewardItem then
                local item = tonumber(reward:Param())
                if item then
                    local itemGroup = ConfigRefer.ItemGroup:Find(item)
                    if itemGroup and itemGroup:ItemGroupInfoListLength() > 0 then
                        local heroItem = itemGroup:ItemGroupInfoList(1)
                        local itemConfig = ConfigRefer.Item:Find(heroItem:Items())
                        if itemConfig 
                            and itemConfig:Type() == ItemType.Resource
                            and itemConfig:Class() == PackType.Hero
                            and itemConfig:FunctionClass() == FunctionClass.AddHero
                            and itemConfig:UseParamLength() > 0
                        then
                            local heroId = tonumber(itemConfig:UseParam(1))
                            if heroId then
                                local citizenId = self._heroIdConfig2CitizenConfigId[heroId]
                                if citizenId and not currentHasCitizen[citizenId] then
                                    needProcessCitizen[citizenId] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    for key, _ in pairs(needProcessCitizen) do
        self._useSpawnPos[key] = pos
    end
    return function(cmd,isSuccess,rsp)
        if not isSuccess then
            for key, _ in pairs(needProcessCitizen) do
                self._useSpawnPos[key] = nil
            end
        end
        if callback then
            callback(cmd, isSuccess, rsp)
        end
    end
end

return CityCitizenManager