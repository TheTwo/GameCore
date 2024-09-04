local FeatureFlag = true
local CityManagerBase = require("CityManagerBase")
---@class CityPetManager:CityManagerBase
---@field new fun():CityPetManager
local CityPetManager = class("CityPetManager", CityManagerBase)
local CityPetDatum = require("CityPetDatum")
local UnitActorFactory = require("UnitActorFactory")
local UnitActorType = require("UnitActorType")
local UnitMoveManager = require("UnitMoveManager")
local Delegate = require("Delegate")
local OnChangeHelper = require("OnChangeHelper")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local CityPetBuildMasterInfo = require("CityPetBuildMasterInfo")
local DBEntityPath = require("DBEntityPath")
local ProtocolId = require("ProtocolId")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkType = require("CityWorkType")
local PetWorkType = require("PetWorkType")
local Utils = require("Utils")
local CityUtils = require("CityUtils")
local PetModifyNameParameter = require("PetModifyNameParameter")
local CityPetUtils = require("CityPetUtils")
local CityHatchEggOpenUIParameter = require("CityHatchEggOpenUIParameter")
local CityPetI18N = require("CityPetI18N")
local CastleAddPetParameter = require("CastleAddPetParameter")
local CityPetCountdownUpgradeTimeInfo = require("CityPetCountdownUpgradeTimeInfo")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local CityPetEatFoodUIParametor = require("CityPetEatFoodUIParametor")
local CityPetAnimTriggerEvent = require("CityPetAnimTriggerEvent")
local HatchEggGotoContentProvider = require("HatchEggGotoContentProvider")

---handles
local LumbermillDramaHandle = require("LumbermillDramaHandle")
local FarmDramaHandle = require("FarmDramaHandle")
local PastureDramaHandle = require("PastureDramaHandle")
local MineDramaHandle = require("MineDramaHandle")
local CookDramaHandle = require("CookDramaHandle")
local CommonMaterialProduceDramaHandle = require("CommonMaterialProduceDramaHandle")


function CityPetManager:DoDataLoad()
    ---@type table<number, CityPetDatum>
    self.cityPetData = {}
    ---@type table<number, boolean>
    self.pendingSpawnPetUnits = {}
    ---@type UnitMoveManager
    self.unitMoveManager = UnitMoveManager.new()
    ---@type table<number, CityUnitPet>
    self.unitMap = {}
    ---@type table<number, table<number, boolean>>
    self.furToPet = {}
    ---@type boolean
    self.aotuAssignWork = false

    local castle = self.city:GetCastle()
    for id, wds in pairs(castle.CastlePets) do
        local pet = CityPetDatum.new(self, id)
        pet:Initialize(wds)
        self.cityPetData[id] = pet
        
        if wds.FurnitureId > 0 then
            self.furToPet[wds.FurnitureId] = self.furToPet[wds.FurnitureId] or {}
            self.furToPet[wds.FurnitureId][id] = true
        end
    end

    self:InitPetLandFactor()
	
    self:InitBuildMaster()
    self:AddEventListeners()
    return self:DataLoadFinish()
end

function CityPetManager:DoDataUnload()
    self:RemoveEventListeners()
end

function CityPetManager:NeedLoadData()
    return FeatureFlag
end

function CityPetManager:InitPetLandFactor()
    self.factorMap = {}
    for id, factorCfg in ConfigRefer.PetLandFactor:pairs() do
        local landCfgId = factorCfg:CastleLand()
        self.factorMap[landCfgId] = self.factorMap[landCfgId] or {}
        local workLevel = factorCfg:WorkerTypeLevel()
        self.factorMap[landCfgId][workLevel] = factorCfg:Factor()
    end
end

function CityPetManager:IsLandNotFit(workLevel)
    return self:GetLandFactor(workLevel) < self:GetMaxLandFactor(workLevel)
end

function CityPetManager:GetLandFactor(workLevel, landCfgId)
    if landCfgId == nil then
        local landCfg = ModuleRefer.PlayerModule:GetLandLayer()
        if landCfg ~= nil then
            landCfgId = landCfg:Id()
        else
            return 1
        end
    end

    if not self.factorMap[landCfgId] then return 1 end
    return self.factorMap[landCfgId][workLevel] or 1
end

function CityPetManager:GetMaxLandFactor(workLevel)
    local maxFactor = 1
    for landCfgId, factorMap in pairs(self.factorMap) do
        for level, factor in pairs(factorMap) do
            if level == workLevel then
                maxFactor = math.max(maxFactor, factor)
            end
        end
    end
    return maxFactor
end

function CityPetManager:GetBestLandName(workLevel)
    for landCfgId, factorMap in pairs(self.factorMap) do
        for level, factor in pairs(factorMap) do
            if level == workLevel then
                local landCfg = ConfigRefer.Land:Find(landCfgId)
                return I18N.Get(landCfg:Name())
            end
        end
    end
    return string.Empty
end

function CityPetManager:InitBuildMaster()
    ---@type table<number, CityPetBuildMasterInfo>
    self.buildMaster = {}
    for id, castleFurniture in pairs(self.city:GetCastle().CastleFurniture) do
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
        if lvCfg then
            if CityUtils.IsBuildMaster(lvCfg:Type()) then
                self.buildMaster[id] = CityPetBuildMasterInfo.new(self, id)
                self.buildMaster[id]:UpdateTargetInfo()
            end
        end
    end
end

function CityPetManager:ClearAllBuildMaster()
    if not self.buildMaster then return end

    for id, buildMaster in pairs(self.buildMaster) do
        buildMaster:StopBuildMaster()
    end
end

function CityPetManager:GetBuildMasterInfo(furnitureId)
    return self.buildMaster[furnitureId]
end

function CityPetManager:OnCityActive()
    self.tickActive = true
    self:SpawnAllPetUnits()
end

function CityPetManager:OnCityInactive()
    self:DestroyAllPetUnits()
    self:ClearAllBuildMaster()
    self.tickActive = false
end

function CityPetManager:SpawnAllPetUnits()
    if not self.cityPetData then return end

    for id, petDatum in pairs(self.cityPetData) do
        self.pendingSpawnPetUnits[petDatum.id] = true
    end
end

function CityPetManager:DestroyAllPetUnits()
    if not self.unitMap then return end

    for id, unit in pairs(self.unitMap) do
        unit:Dispose()
    end
    self.unitMap = {}
end

function CityPetManager:IgnoreIntervalTick(delta)
    if not self.tickActive then return end

    self.unitMoveManager:Tick(delta)
    for id, unit in pairs(self.unitMap) do
        unit:Tick(delta)
    end
end

function CityPetManager:Tick(delta)
    if not self.tickActive then return end

    local id, flag = next(self.pendingSpawnPetUnits)
    if id then
        if self.cityPetData[id] then
            self:SpawnPetUnit(self.cityPetData[id])
        end
    end

    self:TickForSyncPetPos(delta)
end

function CityPetManager:TickForSyncPetPos(dt)
    self.syncPosTime = self.syncPosTime or 5
    self.syncPosTime = self.syncPosTime - dt
    if self.syncPosTime > 0 then return end

    local ids = {}
    local poses = {}
    for id, unit in pairs(self.unitMap) do
        if unit.stateMachine.currentName == "CityUnitPetStateWalking" then
            local pos = unit._moveAgent._currentPosition
            local x, y = self.city:GetCoordFromPosition(pos)
            if unit.petData.serverPos.X ~= x or unit.petData.serverPos.Y ~= y then
                table.insert(ids, unit.petData.id)
                table.insert(poses, wds.Vector2F.New(x, y))
            end
        end
    end

    if next(ids) ~= nil and next(poses) ~= nil then
        self:PushPetsPosToServer(ids, poses)
    end
    self.syncPosTime = 5
end

---@param petDatum CityPetDatum
function CityPetManager:SpawnPetUnit(petDatum)
    self.pendingSpawnPetUnits[petDatum.id] = nil
    
    if self.unitMap[petDatum.id] then
        return
    end

    ---@type CityUnitPet
    local unit = UnitActorFactory.CreateOne(UnitActorType.CITY_PET)
    local pathHeightFixer = Delegate.GetOrCreate(self.city, self.city.FixHeightWorldPosition)
    local originPos = self.city:GetWorldPositionFromCoord(petDatum.serverPos.X, petDatum.serverPos.Y)
    -- local spawnPos = pathHeightFixer(CS.UnityEngine.Vector3(petDatum.serverPos.X * self.city.scale, 0, petDatum.serverPos.Y * self.city.scale))
    local moveAgent = self.unitMoveManager:Create(petDatum.id, originPos, CS.UnityEngine.Quaternion.identity, petDatum.speed)
    unit:Init(petDatum, self.city.createHelper, moveAgent, petDatum:UnitActorConfigWrapper(), self.city.cityPathFinding, pathHeightFixer)
    unit:AttachMoveGridListener(self.city.unitMoveGridEventProvider)
    unit:SyncFromServer()
    unit:LoadModelAsync(self.city.CityWorkerRoot)

    self.unitMap[petDatum.id] = unit
end

function CityPetManager:AddEventListeners()
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_ADD_FOR_PET, Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_REMOVE_FOR_PET, Delegate.GetOrCreate(self, self.OnFurnitureRemove))
    g_Game.EventManager:AddListener(EventConst.ON_PET_ADD, Delegate.GetOrCreate(self, self.OnPetAdd))
    g_Game.EventManager:AddListener(EventConst.ON_PET_REMOVE, Delegate.GetOrCreate(self, self.OnPetRemove))
    g_Game.EventManager:AddListener(EventConst.CITY_PET_ANIM_EVENT_TRIGGER, Delegate.GetOrCreate(self, self.OnPetAnimEventTrigger))
    g_Game.EventManager:AddListener(EventConst.LuaStateMachineBehaviour, Delegate.GetOrCreate(self, self.OnAnimatorEvent))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.GlobalData.BuildingMasterStatues2Target.MsgPath, Delegate.GetOrCreate(self, self.OnBuildingMasterChanged))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushOpenEggsReward, Delegate.GetOrCreate(self, self.OnOpenEggsPush))
    g_Game.ServiceManager:AddResponseCallback(PetModifyNameParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetModifyName))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushPetEatingInfo, Delegate.GetOrCreate(self, self.OnPetEatingFood))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreIntervalTick))
end

function CityPetManager:RemoveEventListeners()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreIntervalTick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.GlobalData.BuildingMasterStatues2Target.MsgPath, Delegate.GetOrCreate(self, self.OnBuildingMasterChanged))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushOpenEggsReward, Delegate.GetOrCreate(self, self.OnOpenEggsPush))
    g_Game.ServiceManager:RemoveResponseCallback(PetModifyNameParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetModifyName))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushPetEatingInfo, Delegate.GetOrCreate(self, self.OnPetEatingFood))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_ADD_FOR_PET, Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_REMOVE_FOR_PET, Delegate.GetOrCreate(self, self.OnFurnitureRemove))
    g_Game.EventManager:RemoveListener(EventConst.ON_PET_ADD, Delegate.GetOrCreate(self, self.OnPetAdd))
    g_Game.EventManager:RemoveListener(EventConst.ON_PET_REMOVE, Delegate.GetOrCreate(self, self.OnPetRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_PET_ANIM_EVENT_TRIGGER, Delegate.GetOrCreate(self, self.OnPetAnimEventTrigger))
    g_Game.EventManager:RemoveListener(EventConst.LuaStateMachineBehaviour, Delegate.GetOrCreate(self, self.OnAnimatorEvent))
end

function CityPetManager:OnViewLoadFinish()
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_GAME_EVENT_START, Delegate.GetOrCreate(self, self.OnTimelineControlEventStart))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_GAME_EVENT_END, Delegate.GetOrCreate(self, self.OnTimelineControlEventEnd))
end

function CityPetManager:OnViewUnloadStart()
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_GAME_EVENT_START, Delegate.GetOrCreate(self, self.OnTimelineControlEventStart))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_GAME_EVENT_END, Delegate.GetOrCreate(self, self.OnTimelineControlEventEnd))
end

---@param castleBrief wds.CastleBrief
function CityPetManager:OnCastlePetsChanged(castleBrief, changeTable)
    -- g_Logger.ErrorChannel("CityPetManager", FormatTable(changeTable))
    if castleBrief ~= self.city:GetCastleBrief() then return end

    local addMap, removeMap, changeMap = OnChangeHelper.GenerateMapComponentFieldChangeMap(changeTable, wds.CastlePet)
    -- g_Logger.TraceChannel("CityPetManager", "changeTable:%s", FormatTable(changeTable))
    -- g_Logger.TraceChannel("CityPetManager", "AddMap:%s", FormatTable(addMap))
    -- g_Logger.TraceChannel("CityPetManager", "RemoveMap:%s", FormatTable(removeMap))
    -- g_Logger.TraceChannel("CityPetManager", "ChangeMap:%s", FormatTable(changeMap))

    local batchEvt = {Event = EventConst.CITY_BATCH_WDS_CASTLE_PET_UPDATE, Add = {}, Remove = {}, Change = {}, RelativeFurniture = {}}
    if removeMap then
        for id, wds in pairs(removeMap) do
            local oldFurnitureId = self.cityPetData[id].furnitureId
            self.cityPetData[id] = nil
            self.pendingSpawnPetUnits[id] = nil

            local unit = self.unitMap[id]
            if unit then
                unit:Dispose()
                self.unitMap[id] = nil
            end

            for furId, petIdMap in pairs(self.furToPet) do
                petIdMap[id] = nil
            end
            batchEvt.Remove[id] = true
            if oldFurnitureId > 0 then
                batchEvt.RelativeFurniture[oldFurnitureId] = true
            end
        end
    end

    if addMap then
        for id, _ in pairs(addMap) do
            local wds = castleBrief.Castle.CastlePets[id]
            if wds then
                local pet = CityPetDatum.new(self, id)
                pet:Initialize(wds)
                self.cityPetData[id] = pet

                if wds.FurnitureId > 0 then
                    self.furToPet[wds.FurnitureId] = self.furToPet[wds.FurnitureId] or {}
                    self.furToPet[wds.FurnitureId][id] = true
                end

                if self.tickActive then
                    self.pendingSpawnPetUnits[id] = true
                end
                batchEvt.Add[id] = true
                if wds.FurnitureId > 0 then
                    batchEvt.RelativeFurniture[wds.FurnitureId] = true
                end
            end
        end
    end

    if changeMap then
        for id, change in pairs(changeMap) do
            local pet = self.cityPetData[id]
            local oldFurnitureId = pet.furnitureId
            local wds = castleBrief.Castle.CastlePets[id]
            local needSync = false
            if pet then
                needSync = pet:SyncDataFromWds(wds, change)
            end

            local unit = self.unitMap[id]
            if unit then
                if needSync then
                    unit:SyncFromServer()
                end
                unit:UpdateStatusHandle()
            end

            local newFurId = wds.FurnitureId
            if oldFurnitureId > 0 then
                local petIdMap = self.furToPet[oldFurnitureId]
                if petIdMap then
                    petIdMap[id] = nil
                else
                    g_Logger.ErrorChannel("CityPetManager", "trace exception : %s", FormatTable(changeTable))
                end
            end

            if newFurId > 0 then
                self.furToPet[newFurId] = self.furToPet[newFurId] or {}
                self.furToPet[newFurId][id] = true
            end

            batchEvt.Change[id] = true
            batchEvt.RelativeFurniture[newFurId] = true
            if oldFurnitureId > 0 then
                batchEvt.RelativeFurniture[oldFurnitureId] = true
            end
            if newFurId > 0 then
                batchEvt.RelativeFurniture[newFurId] = true
            end
        end
    end

    return batchEvt
end

---@param petId number
---@param x number
---@param y number
function CityPetManager:PushCurrentPositionToServer(petId, x, y)
    local param = require("CastleSyncPetPosParameter").new()
    param.args.PetId = petId
    param.args.Pos.X = x
    param.args.Pos.Y = y
    param:SendWithFullScreenLock()
end

function CityPetManager:PushPetsPosToServer(petIds, poses)
    local param = require("CastleSyncMultiPetPosParameter").new()
    param.args.PetId:AddRange(petIds)
    param.args.Pos:AddRange(poses)
    param:SendWithFullScreenLock()
end

function CityPetManager:AssignPetToFurnitureSlot(petId, furnitureId, lockable, callback)
    local param = require("CastleAddPetParameter").new()
    param.args.PetId = petId
    param.args.FurnitureId = furnitureId
    if callback == nil then
        param:Send(lockable)
    else
        param:SendOnceCallback(lockable, nil, true, callback)
    end
end

---@param petId number
---@param petWorkType number
function CityPetManager:IsPetCanDoWork(petId, petWorkType)
    local petDatum = self.cityPetData[petId]
    if petDatum then
        return petDatum:CanDoWorkType(petWorkType)
    else
        local pet = ModuleRefer.PetModule:GetPetByID(petId)
        if pet then
            local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
            for i = 1, petCfg:PetWorksLength() do
                local petWork = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
                if petWork:Type() == petWorkType then
                    return true
                end
            end
        else
            return false
        end
    end
end

---@param city City
---@param furniture CityFurniture
function CityPetManager:OnFurnitureAdd(city, furniture)
    if CityUtils.IsBuildMaster(furniture.furnitureCell:Type()) then
        self.buildMaster[furniture.singleId] = CityPetBuildMasterInfo.new(self, furniture.singleId)
    end

    if not self.aotuAssignWork then return end
    if city ~= self.city then return end

    local furTypeCfg = ConfigRefer.CityFurnitureTypes:Find(furniture:GetFurnitureType())
    local limits = {}
    for i = 1, furTypeCfg:PetWorkTypeLimitLength() do
        limits[furTypeCfg:PetWorkTypeLimit(i)] = true
    end

    local assignedPets = {}
    for _, petIdMap in pairs(self.furToPet) do
        for petId, _ in pairs(petIdMap) do
            assignedPets[petId] = true
        end
    end

    for id, pet in pairs(ModuleRefer.PetModule:GetPetList()) do
        if assignedPets[id] then goto continue end

        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        if petCfg == nil then goto continue end

        for i = 1, petCfg:PetWorksLength() do
            local workCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            if workCfg and limits[workCfg:Type()] then
                self:AssignPetToFurnitureSlot(id, furniture.singleId)
            end
        end
        ::continue::
    end
end

---@param city City
---@param furniture CityFurniture
function CityPetManager:OnFurnitureRemove(city, furniture)
    if city ~= self.city then return end

    self.furToPet[furniture.singleId] = nil
    self.buildMaster[furniture.singleId] = nil
end

function CityPetManager:OnPetAdd(petId)
    if not self.aotuAssignWork then return end
    if not self.city:IsMyCity() then return end
    if not self.city.furnitureManager:IsDataReady() then return end

    for furnitureId, furniture in pairs(self.city.furnitureManager.hashMap) do
        if self.furToPet[furnitureId] ~= nil then goto continue end
        local furTypCfg = ConfigRefer.CityFurnitureTypes:Find(furniture:GetFurnitureType())
        local limits = {}
        for i = 1, furTypCfg:PetWorkTypeLimitLength() do
            limits[furTypCfg:PetWorkTypeLimit(i)] = true
        end

        local pet = ModuleRefer.PetModule:GetPetByID(petId)
        local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
        for i = 1, petCfg:PetWorksLength() do
            local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
            if petWorkCfg and limits[petWorkCfg:Type()] then
                self:AssignPetToFurnitureSlot(petId, furnitureId)
                break
            end
        end
        ::continue::
    end
end

function CityPetManager:OnPetRemove(petId)
    -- if not self.city:IsMyCity() then return end
    -- if not self.cityPetData[petId] then return end
    
    -- local petDatum = self.cityPetData[petId]
    -- if petDatum.furnitureId > 0 then
    --     self.furToPet[petDatum.furnitureId] = nil
    -- end
    -- self.cityPetData[petId] = nil
end

function CityPetManager:OnAnimatorEvent(eventTable)
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

---@param attachPointHolder CS.FXAttachPointHolder
---@param eventName string
function CityPetManager:OnPetAnimEventTrigger(attachPointHolder, eventName)
    if Utils.IsNull(attachPointHolder) then return end

    for _, unitPet in pairs(self.unitMap) do
        if unitPet._attachPointHolder == attachPointHolder then
            self:DoPetAnimEventTrigger(unitPet, eventName)
            return
        end
    end
end

---@param unitPet CityUnitPet
---@param eventName string
function CityPetManager:DoPetAnimEventTrigger(unitPet, eventName)
    if eventName == CityPetAnimTriggerEvent.WOOD_CUTTING then
        local datum = self.cityPetData[unitPet.petData.id]
        if datum.workId > 0 then
            local workData = self.city.cityWorkManager:GetWorkData(datum.workId)
            if workData ~= nil and workData.workCfg:Type() == CityWorkType.ResourceCollect and workData.targetId > 0 then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_RESOURCE_BE_HIT, workData.targetId)
            end
        end
    end
end

---@return CityPetCountdownUpgradeTimeInfo
function CityPetManager:GetUpgradeTimeCountdownInfo()
    if self.city:GetCastle().GlobalData.BuildingReduceTime == 0 then
        return nil
    end

    local petIds = {}
    for i = 1, ConfigRefer.CityConfig:BuildingMasterStatuesLength() do
        local furType = ConfigRefer.CityConfig:BuildingMasterStatues(i)
        local furniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(furType)
        if furniture then
            local petIdMap = self.furToPet[furniture.singleId] or {}
            for petId, _ in pairs(petIdMap) do
                table.insert(petIds, petId)
            end
        end
    end

    local icon1 = string.Empty
    if #petIds >= 0 then
        local pet = ModuleRefer.PetModule:GetPetByID(petIds[1])
        if pet then
            local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
            if petCfg then
                icon1 = ArtResourceUtils.GetUIItem(petCfg:TinyIcon())
            end
        end
    end

    local icon2 = string.Empty
    if #petIds == 2 then
        local pet = ModuleRefer.PetModule:GetPetByID(petIds[2])
        if pet then
            local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
            if petCfg then
                icon2 = ArtResourceUtils.GetUIItem(petCfg:TinyIcon())
            end
        end
    end

    local info = CityPetCountdownUpgradeTimeInfo.new(icon1, icon2, #petIds, self.city:GetCastle().GlobalData.BuildingReduceTime)
    return info
end

---@param feature number @enum-PetWorkType
function CityPetManager:GetFeatureIcon(feature)
    return CityPetUtils.GetFeatureIcon(feature)
end

---@param furnitureId number
function CityPetManager:GetPetIdByWorkFurnitureId(furnitureId)
    return self.furToPet[furnitureId]
end

function CityPetManager:GetPetCountByWorkFurnitureId(furnitureId)
    local petIdMap = self.furToPet[furnitureId]
    if not petIdMap then return 0 end

    return table.nums(petIdMap)
end

function CityPetManager:GetAssignedPetCount()
    local count = 0
    for _, petIdMap in pairs(self.furToPet) do
        count = count + table.nums(petIdMap)
    end
    return count
end

---@return boolean
function CityPetManager:IsResourceCanClaimByPet(petId, elementDataId)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if not pet then return false end

    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    if not petCfg then return false end

    ---@type CityElementResource
    local elementResource = self.city.elementManager:GetElementById(elementDataId)
    if elementResource == nil then return false end
    if self.city.elementManager:IsPolluted(elementDataId) then return false end
    if not elementResource:IsResource() then return false end
    local cityWork = ConfigRefer.CityWork:Find(elementResource.resourceConfigCell:CollectWork())
    if not cityWork then return false end
    for i = 1, petCfg:PetWorksLength() do
        local petWork = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWork and petWork:Type() == cityWork:RequireWorkerType() then
            return true, cityWork:Id()
        end
    end
    return false
end

function CityPetManager:IsWorking(petId)
    local petDatum = self.cityPetData[petId]
    if petDatum == nil then
        return false
    end

    return petDatum.workId > 0
end

function CityPetManager:IsAssignedOnFurniture(petId)
    local petDatum = self.cityPetData[petId]
    if petDatum == nil then
        return false
    end

    return petDatum.furnitureId > 0
end

function CityPetManager:GetWorkLevel(petId, petWorkType)
    local petDatum = self.cityPetData[petId]
    if petDatum ~= nil then
        return petDatum:GetWorkLevel(petWorkType)
    end

    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet == nil then
        return 0
    end

    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    if petCfg == nil then
        return 0
    end

    for i = 1, petCfg:PetWorksLength() do
        local petWork = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWork and petWork:Type() == petWorkType then
            return petWork:Level()
        end
    end

    return 0
end

function CityPetManager:GetWorkPosition(petId)
    local troopId = self:GetPetTroopId(petId)
    if troopId ~= nil then
        return I18N.Get("animal_queue_"..troopId)
    end

    local petDatum = self.cityPetData[petId]
    if petDatum == nil then
        return string.Empty
    end
    local furniture = self.city.furnitureManager:GetFurnitureById(petDatum.furnitureId)
    if furniture == nil then
        return I18N.Get("#未知地区")
    end

    return furniture:GetName()
end

---@param workCfg CityWorkConfigCell
function CityPetManager:GetWorkAnimNameByWorkCfg(workCfg)
    return workCfg:PetWorkAnim()
end

---@param furnitureType number @ref-CityFurnitureTypes
function CityPetManager:GetWorkAnimNameByFurnitureType(furnitureType)
    if furnitureType == ConfigRefer.CityConfig:TemperatureBooster() then
        return "fire"
    end
    return nil
end

---@param castleBrief wds.CastleBrief
function CityPetManager:OnBuildingMasterChanged(castleBrief, changeTable)
    if castleBrief.ID ~= self.city.uid then return end

    for k, v in pairs(self.buildMaster) do
        v:UpdateTargetInfo()
    end
end

---@param request wrpc.PushOpenEggsRewardRequest
function CityPetManager:OnOpenEggsPush(isSuccess, request)
    ---@type CatchPetResultMediatorParameter
    local resultParam = {}
    resultParam.result = request.Reward
    resultParam.isEgg = true
    local param = CityHatchEggOpenUIParameter.new(resultParam, self.lastHatchRecipeId)
    g_Game.UIManager:Open(UIMediatorNames.CityHatchEggOpenUIMediator, param)
end

---@param petUnit CityUnitPet
function CityPetManager:GetCustomDramaHandle(petUnit)
    local petDatum = petUnit.petData
    if petDatum.workId == 0 then return nil end

    local workData = self.city.cityWorkManager:GetWorkData(petDatum.workId)
    if workData == nil then return nil end
    local workCfgType = workData.workCfg:Type()
    local requireWorkerType = workData.workCfg:RequireWorkerType()
    if workCfgType == CityWorkType.ResourceProduce then -- 产资源
        if requireWorkerType == PetWorkType.Woodcutting then
            return LumbermillDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.Collect then
            return FarmDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.AnimalHusbandry then
            return PastureDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.Mining then
            return MineDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.Watering then
            return FarmDramaHandle.new(petUnit)
        end
    elseif workCfgType == CityWorkType.Process then -- 制造
        if requireWorkerType == PetWorkType.Fire then
            return CookDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.Handwork then
            return CommonMaterialProduceDramaHandle.new(petUnit)
        end
    elseif workCfgType == CityWorkType.MaterialProcess then -- 原料加工
        if requireWorkerType == PetWorkType.Watering then
            return CommonMaterialProduceDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.Handwork then
            return CommonMaterialProduceDramaHandle.new(petUnit)
        elseif requireWorkerType == PetWorkType.Fire then
            return CommonMaterialProduceDramaHandle.new(petUnit)
        end
    end
    return nil
end

function CityPetManager:OnTimelineControlEventStart()
    for id, unit in pairs(self.unitMap) do
        unit:Dispose()
    end
    self.unitMap = {}
end

function CityPetManager:OnTimelineControlEventEnd()
    self:SpawnAllPetUnits()
end

function CityPetManager:GetFreeMobileUnitPet(petWorkType, worldPos)
    ---@type CityUnitPet[]
    local ret = {}
    for id, unit in pairs(self.unitMap) do
        local isMobileUnit = false
        if unit.petData.furnitureId == 0 then
            isMobileUnit = true
        else
            local furniture = self.city.furnitureManager:GetFurnitureById(unit.petData.furnitureId)
            if furniture:IsHotSpring() then
                isMobileUnit = true
            end
        end
        
        if isMobileUnit then
            if unit.petData:Preemptible() and unit.petData:CanDoWorkType(petWorkType) then
                if worldPos == nil then
                    return unit.petData.id
                end
                table.insert(ret, unit)
            end
        end
    end
    
    if #ret == 0 then return nil end

    local minDis = 999999
    local minUnit = nil
    for i, unit in ipairs(ret) do
        local dis = CS.UnityEngine.Vector3.Distance(unit._moveAgent._currentPosition, worldPos)
        if dis < minDis then
            minDis = dis
            minUnit = unit
        end
    end
    return minUnit.petData.id
end

function CityPetManager:GetPetTroopId(petId)
    local castleBrief = self.city:GetCastleBrief()
    for index, v in pairs(castleBrief.TroopPresets.Presets) do
        for _, hero in pairs(v.Heroes) do
            if petId == hero.PetCompId then
                return index
            end
        end
    end
    return nil
end

function CityPetManager:IsPetInTroopWork(petId)
    local presetIdx = self:GetPetTroopId(petId) 
    return presetIdx ~= nil
    -- if presetIdx == nil then
    --     return false
    -- end

    -- local castleBrief = self.city:GetCastleBrief()
    -- local preset = castleBrief.TroopPresets.Presets[presetIdx]
    -- if preset.Status ~= wds.TroopPresetStatus.TroopPresetIdle and preset.Status ~= wds.TroopPresetStatus.TroopPresetInHome then
    --     return true
    -- end

    -- return self.city.cityExplorerManager:GetTeamByPresetIndex(presetIdx-1) ~= nil
end

function CityPetManager:GetDecreaseHpAmountPerTime()
    if ConfigRefer.CityConfig:PetDecreaseHpByMainFurLength() == 0 then
        return 1
    end

    local mainFurniture = self.city.furnitureManager:GetMainFurniture()
    if mainFurniture == nil then
        return ConfigRefer.CityConfig:PetDecreaseHpByMainFur(1)
    end

    local level = mainFurniture.level
    if level <= 0 then
        return ConfigRefer.CityConfig:PetDecreaseHpByMainFur(1)
    elseif level > ConfigRefer.CityConfig:PetDecreaseHpByMainFurLength() then
        return ConfigRefer.CityConfig:PetDecreaseHpByMainFur(ConfigRefer.CityConfig:PetDecreaseHpByMainFurLength())
    else
        return ConfigRefer.CityConfig:PetDecreaseHpByMainFur(level)
    end
end

function CityPetManager:GetForceKeepFoodCount()
    if ConfigRefer.CityConfig:HPlevelLimitedFoodLength() == 0 then
        return 0
    end

    local mainFurniture = self.city.furnitureManager:GetMainFurniture()
    if mainFurniture == nil then
        return 0
    end

    local level = mainFurniture.level
    if level <= 0 then
        return 0
    elseif level > ConfigRefer.CityConfig:HPlevelLimitedFoodLength() then
        return ConfigRefer.CityConfig:HPlevelLimitedFood(ConfigRefer.CityConfig:HPlevelLimitedFoodLength())
    else
        return ConfigRefer.CityConfig:HPlevelLimitedFood(level)
    end
end

function CityPetManager:GetAllFood()
    local stockFurniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:StockRoomFurniture())
    if stockFurniture == nil then
        return 0
    end

    local foodCount = 0
    for id, blood in pairs(stockFurniture:GetCastleFurniture().StockRoomInfo.FoodInfo) do
        foodCount = blood + foodCount
    end
    return foodCount
end

function CityPetManager:GetRemainFoodCanAffordTime()
    local willEatFoodPetCount = 0
    for id, pet in pairs(self.cityPetData) do
        if pet.furnitureId ~= 0 then
            willEatFoodPetCount = willEatFoodPetCount + 1
        end
    end

    if willEatFoodPetCount == 0 then return math.maxinteger end

    local foodCount = self:GetAllFood()
    if foodCount == 0 then return 0 end

    local orderList = {}
    for id, pet in pairs(self.cityPetData) do
        local max = pet:GetMaxHp()
        if max > 0 then
            local data = {cur = pet.hp, max = max, percent = pet.hp / max}
            table.insert(orderList, data)
        end
    end

    table.sort(orderList, function(a, b)
        return a.percent < b.percent
    end)

    local forceKeepFoodCount = self:GetForceKeepFoodCount()
    local previewRemain = math.max(0, foodCount - forceKeepFoodCount)
    local remainTime = 0
    local decreaseInterval = ConfigRefer.CityConfig:PetDecreaseHpInterval()
    local decreaseAmount = self:GetDecreaseHpAmountPerTime()
    local maxTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.CityConfig:MaxOfflineWorkTime())

    while (previewRemain > 0) and remainTime < maxTime do
        remainTime = remainTime + decreaseInterval
        for i, v in ipairs(orderList) do
            v.cur = v.cur - decreaseAmount
            if v.cur < 1 then
                v.cur = 1
            end

            if (v.cur / v.max) < 0.4 then
                local offset = math.min(v.max - v.cur, previewRemain)
                previewRemain = previewRemain - offset
                v.cur = v.cur + offset
            end

            if previewRemain < 1 then
                break
            end
        end
    end
    return remainTime
end

function CityPetManager:IsPetHungry(petId, includeNonCastlePet)
    local petDatum = self.cityPetData[petId]
    if petDatum then
        return petDatum:IsHungry()
    else
        if not includeNonCastlePet then
            return false
        end

        local pet = ModuleRefer.PetModule:GetPetByID(petId)
        if not pet then return false end

        local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()]
        local hp = ModuleRefer.TroopModule:GetTroopPetHp(petId)
        return (hp / maxHp) < (ConfigRefer.CityConfig:PetHungryHp() / 100)
    end
end

function CityPetManager:OnPetModifyName(isSuccess, reply, rpc)
    if not isSuccess then return end

    for petId, unit in pairs(self.unitMap) do
        unit:UpdateName()
    end
end

function CityPetManager:IsPetAssigedOnFurniture(petId)
    return self.cityPetData[petId] ~= nil and self.cityPetData[petId].furnitureId > 0
end

function CityPetManager:RecordLastHatchRecipe(recipeId)
    self.lastHatchRecipeId = recipeId
end

function CityPetManager:GetHp(petId)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet == nil then
        return 0
    end

    local castleBrief = self.city:GetCastleBrief()
    local curHp = castleBrief.TroopPresets.PetHp[petId] or 0
    return curHp
end

function CityPetManager:GetHpPercent(petId)
    local petDatum = self.cityPetData[petId]
    if petDatum then
        return petDatum:GetHpPercent()
    end

    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet == nil then
        return 0
    end

    local maxHp = pet.Props[ConfigRefer.PetConsts:PetAttrHp()] or 1
    local castleBrief = self.city:GetCastleBrief()
    local curHp = castleBrief.TroopPresets.PetHp[petId] or 0

    return math.clamp01(curHp / maxHp)
end

function CityPetManager:TryAssignPetToWorkFurniture(furnitureId, selectedPetsId, callback, onAsyncAssignCallback)
    local flag, names, otherPetIds = self:ContainsOtherWorkPet(selectedPetsId, furnitureId)
    if flag then
        self:TwiceConfirmAssign(names, otherPetIds, furnitureId, selectedPetsId, callback, onAsyncAssignCallback)
        return false
    end

    self:RequestAddPets(furnitureId, selectedPetsId, callback)
    return true
end

function CityPetManager:TwiceConfirmAssign(names, otherPetIds, furnitureId, selectedPetsId, callback, onAsyncAssignCallback)
    local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
    local petNames = {}
    for _, id in ipairs(otherPetIds) do
        local name = ModuleRefer.PetModule:GetPetName(id)
        if not string.IsNullOrEmpty(name) then
            table.insert(petNames, name)
        end
    end

    ---@type CommonConfirmPopupMediatorParameter
    local param = {}
    param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    param.title = I18N.Get(CityPetI18N.UITitle_ConfirmAssign)
    param.content = I18N.GetWithParams("mention_popup_pet_remove", table.concat(petNames, ","), names)
    param.onConfirm = function()
        self:RequestAddPets(furnitureId, selectedPetsId, callback)
        if onAsyncAssignCallback then
            onAsyncAssignCallback(true)
        end
        return true
    end
    param.onCancel = function()
        for _, id in ipairs(otherPetIds) do
            selectedPetsId[id] = nil
        end
        if onAsyncAssignCallback then
            onAsyncAssignCallback(false)
        end
        return true
    end
    param.onClose = function()
        for _, id in ipairs(otherPetIds) do
            selectedPetsId[id] = nil
        end
        if onAsyncAssignCallback then
            onAsyncAssignCallback(false)
        end
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

function CityPetManager:RequestAddPets(furnitureId, selectedPetsId, callback)
    local param = CastleAddPetParameter.new()
    param.args.FurnitureId = furnitureId
    for id, _ in pairs(selectedPetsId) do
        param.args.PetId:Add(id)
    end
    if callback then
        param:SendWithFullScreenLockAndOnceCallback(nil, true, callback)
    else
        param:SendWithFullScreenLock()
    end
end

---@param selectedPetsId table<number, boolean>
---@param sourceFurnitureId number
function CityPetManager:ContainsOtherWorkPet(selectedPetsId, sourceFurnitureId)
    local names = {}
    local otherPetIds = {}
    local flag = false
    for id, _ in pairs(selectedPetsId) do
        if self.cityPetData[id] and self.cityPetData[id].furnitureId ~= sourceFurnitureId then
            flag = true
            local furniture = self.city.furnitureManager:GetFurnitureById(self.cityPetData[id].furnitureId)
            if furniture then
                table.insert(names, furniture:GetName())
            end
            table.insert(otherPetIds, id)
        end
    end
    return flag, table.concat(names, ","), otherPetIds
end

function CityPetManager:RequestRemovePet(petId, furnitureId, rectTransform, callback)
    local petIdsMap = self:GetPetIdByWorkFurnitureId(furnitureId)
    local newPetIds = {}
    for id, _ in pairs(petIdsMap) do
        if id ~= petId then
            table.insert(newPetIds, id)
        end
    end

    local param = CastleAddPetParameter.new()
    param.args.PetId:AddRange(newPetIds)
    param.args.FurnitureId = furnitureId
    if callback then
        param:SendOnceCallback(rectTransform, nil, true, callback)
    else
        param:Send(rectTransform)
    end
end

function CityPetManager:GetRemainWorkDesc(petId)
    local petDatum = self.cityPetData[petId]
    if petDatum == nil then
        return string.Empty
    end

    local foodRemainTime = self:GetRemainFoodCanAffordTime()
    if foodRemainTime > 8 * 3600 then
        return ">"..TimeFormatter.TimerStringFormat(8*3600)
    end

    local hpRemain = petDatum.hp
    local decreaseAmount = self:GetDecreaseHpAmountPerTime()
    local decreaseInterval = ConfigRefer.CityConfig:PetDecreaseHpInterval()
    local time = math.ceil(hpRemain // decreaseAmount) * decreaseInterval + foodRemainTime
    if time > 8 * 3600 then
        return ">"..TimeFormatter.TimerStringFormat(8*3600)
    end

    return TimeFormatter.TimerStringFormat(time)
end

function CityPetManager:GetDecreaseBuildTime(petId)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet == nil then return 0 end

    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    if petCfg == nil then return 0 end

    local time = 0
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg then
            time = time + (petWorkCfg:BuildingReduceTime() * self:GetLandFactor(petWorkCfg:Level()))
        end
    end
    return time
end

function CityPetManager:BITraceBubbleClick(furnitureId, bubble_desc)
    local keyMap = FPXSDKBIDefine.ExtraKey.pet_work_ui_click
    local extraData = {}
    extraData[keyMap.type] = "bubble_click"
    extraData[keyMap.furniture_id] = furnitureId
    extraData[keyMap.bubble_type] = bubble_desc
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.pet_work_ui_click, extraData)
end

function CityPetManager:BITraceTipsOpen(furnitureId)
    local keyMap = FPXSDKBIDefine.ExtraKey.pet_work_ui_click
    local extraData = {}
    extraData[keyMap.type] = "tips"
    extraData[keyMap.furniture_id] = furnitureId
    extraData[keyMap.bubble_type] = "null"
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.pet_work_ui_click, extraData)
end

function CityPetManager:IsPetOnFurniture(petId)
    local petDatum = self.cityPetData[petId]
    if petDatum == nil then
        return false
    end

    return petDatum.furnitureId > 0
end

function CityPetManager:GetFurnitureIdByPetId(petId)
    local petDatum = self.cityPetData[petId]
    if petDatum == nil then
        return 0
    end

    return petDatum.furnitureId
end

function CityPetManager:GMTestEat(petId)
    local unit = self.unitMap[petId]
    if unit == nil then return end

    unit.stateMachine:ChangeState("CityUnitPetStateEating")
end

function CityPetManager:GotoEarnPetEgg()
    local param = {overrideDefaultProvider = HatchEggGotoContentProvider.new()}
    g_Game.UIManager:Open(UIMediatorNames.UIRaisePowerPopupMediator, param)
end

---@param request wrpc.PushPetEatingInfoRequest
function CityPetManager:OnPetEatingFood(isSuccess, request)
    local infos = request.PetEatingInfo
    local param = CityPetEatFoodUIParametor.new()
    for i, v in ipairs(infos) do
        param:AddPetEat(v.PetId, v.AddHp)
    end

    if param.count > 0 and g_Game.UIManager:FullScreenUIMediatorCount() == 0 then
        g_Game.UIManager:Open(UIMediatorNames.CityPetEatFoodUIMediator, param)
    else
        CityUtils.AsyncOpenUI(UIMediatorNames.CityPetEatFoodUIMediator, param)
    end
end

return CityPetManager
