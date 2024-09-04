local CityManagerBase = require("CityManagerBase")
---@class CityWorkManager:CityManagerBase
---@field new fun():CityWorkManager
local CityWorkManager = class("CityWorkManager", CityManagerBase)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CastleAssignProcessPlanParameter = require("CastleAssignProcessPlanParameter")
local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CastleStopWorkParameter = require("CastleStopWorkParameter")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local CityCitizenWorkData = require("CityCitizenWorkData")
local CityWorkHelper = require("CityWorkHelper")
local PushConsts = require("PushConsts")
local CityWorkTargetType = require("CityWorkTargetType")
local CastleCitizenAssignProcessWorkParameter = require("CastleCitizenAssignProcessWorkParameter")
local CastleAddFurnitureCollectProcessParameter = require("CastleAddFurnitureCollectProcessParameter")
local CastleDelFurnitureCollectProcessParameter = require("CastleDelFurnitureCollectProcessParameter")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local CastleAddFurnitureResGenProcessParameter = require("CastleAddFurnitureResGenProcessParameter")
local CastleDelFurnitureResGenProcessParameter = require("CastleDelFurnitureResGenProcessParameter")
local CastleDirectFinishWorkByCashParameter = require("CastleDirectFinishWorkByCashParameter")
local CityWorkProduceResGenGridAgent = require("CityWorkProduceResGenGridAgent")
local CityPetUtils = require("CityPetUtils")
local CityWorkType = require("CityWorkType")
local CityGridLayerMask = require("CityGridLayerMask")
local CityWorkFormula = require("CityWorkFormula")
local CastleSpeedUpByCashParameter = require("CastleSpeedUpByCashParameter")
local NotificationType = require("NotificationType")
local TimerUtility = require("TimerUtility")
local CityWorkData = require("CityWorkData")
local LoadState = CityManagerBase.LoadState
local EnableTraceReddot = false

function CityWorkManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)

    ---@type table<number, CityWorkData>
    self._workData = {}
    ---@type table<number, number>
    self._work2CitizenId = {}
    ---@type table<number, CityCitizenWorkData>
    self._citizenWork = {}
    ---@type number[]
    self._canCollectingFurnitureId = {}
    ---@type table<number, CityWorkProduceResGenGridAgent>
    self._furnitureResGenGridAgents = {}
end

function CityWorkManager:NeedLoadData()
    return true
end

function CityWorkManager:DoDataLoad()
    self:InitCityWorkBasicData()
    self:InitCollectingFurnitureIdCache()
    self._manualCollectCitizenIdMap = {}
    self._manualCollectResourceIdMap = {}
    self._delayTimers = {}
    self:AddEventListeners()
    return self:DataLoadFinish()
end

function CityWorkManager:DoDataUnload()
    self:RemoveEventListeners()
    self:StopAllDelayTimers()
    self._workData = {}
    self._citizenWork = {}
    self._work2CitizenId = {}
    self._furnitureResGenGridAgents = {}
    self._manualCollectCitizenIdMap = {}
    self._manualCollectResourceIdMap = {}
end

function CityWorkManager:InitCityWorkBasicData()
    local CastleWork = self.city:GetCastle().CastleWork
    for id, work in pairs(CastleWork) do
        self._workData[id] = CityWorkData.new()
        self._workData[id]:UpdateFromCastleWork(id, work)
    end
end

function CityWorkManager:InitCollectingFurnitureIdCache()
    if not self.city.furnitureManager.hashMap then return end
    for id, furniture in pairs(self.city.furnitureManager.hashMap) do
        if furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) then
            self._canCollectingFurnitureId[id] = true
        end
    end
end

function CityWorkManager:AddEventListeners()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleElements.InProgressResource.MsgPath, Delegate.GetOrCreate(self, self.OnCastleResourceWorkProgressChanged))
end

function CityWorkManager:RemoveEventListeners()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleElements.InProgressResource.MsgPath, Delegate.GetOrCreate(self, self.OnCastleResourceWorkProgressChanged))
end

function CityWorkManager:OnViewLoadFinish()
    g_Game.EventManager:AddListener(EventConst.CITY_CLICK_RESOURCE, Delegate.GetOrCreate(self, self.OnCityClickResource))
end

function CityWorkManager:OnViewUnloadStart()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CLICK_RESOURCE, Delegate.GetOrCreate(self, self.OnCityClickResource))
end

function CityWorkManager:StopAllDelayTimers()
    for _, timer in ipairs(self._delayTimers) do
        timer:Stop()
    end
    self._delayTimers = {}
end

function CityWorkManager:UpdateLevelUpQueueEmptyNotify()
    local max = CityWorkFormula.GetTypeMaxQueueCountByWorkType(CityWorkType.FurnitureLevelUp)
    local cur = 0
    local castleFurniture = self.city:GetCastle().CastleFurniture
    for id, furniture in pairs(castleFurniture) do
        if furniture.LevelUpInfo.Working then
            cur = cur + 1
        end
    end
    if self.city.furnitureManager:IsNonFurnitureCanLevelUp() then
        cur = 0
    end
    local freeNode = ModuleRefer.NotificationModule:GetDynamicNode(CityWorkHelper.GetLevelUpFreeNotifyName(), NotificationType.CITY_FURNITURE_LEVEL_UP_FREE)
    if freeNode ~= nil then
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(freeNode, math.max(0, max - cur))
        self:LogChannel(("CityWorkReddot Init [%d]"):format(g_Game.RealTime.frameCount), "empty upgrade queue +%d", math.max(0, max - cur))
    end
end

function CityWorkManager:OnCityClickResource(city, elementId)
    if city ~= self.city then return end

    if self.city.elementManager:IsPolluted(elementId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
        return
    end

    if not self:HasAbilityToGatherResource(elementId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_1"))
        return
    end

    if self:IsResourceBeingGathered(elementId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_2"))
        return
    end

    if self:IsResourceFullForTargetElementGather(elementId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_80"))
        return
    end

    local element = self.city.elementManager:GetElementById(elementId)
    if not self.city.zoneManager:IsZoneRecovered(element.x, element.y) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("repair_furniture_tips"))
        return
    end
    
    local worldPos = element:GetWorldPosition()
    local workCfgId = element.resourceConfigCell:CollectWork()
    local freePetId = self.city.petManager:GetFreeMobileUnitPet(element.resourceConfigCell:PetWorkType(), worldPos)
    if freePetId == nil then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("lack_animal_tips", CityPetUtils.GetFeatureName(element.resourceConfigCell:PetWorkType())))
        return
    end

    self:StartWorkImp(elementId, workCfgId, freePetId)
end

function CityWorkManager:DelayClearCache(citizenId, elementId)
    local timer = TimerUtility.DelayExecute(function(param)
        if citizenId then
            self._manualCollectCitizenIdMap[citizenId] = nil
        end
        self._manualCollectResourceIdMap[elementId] = nil
        table.removebyvalue(self._delayTimers, param)
    end, 2, true)
    timer.param = timer
    table.insert(self._delayTimers, timer)
end

function CityWorkManager:IsResourceBeingGathered(elementId)
    if self._manualCollectResourceIdMap[elementId] then
        return true
    end

    for _, v in pairs(self._workData) do
        if v.targetId == elementId and CityWorkHelper.GetWorkTargetType(v.workCfgId) == CityWorkTargetType.Resource then
            return true
        end
    end

    local castleFurnitures = self.city:GetCastle().CastleFurniture
    for id, _ in pairs(self._canCollectingFurnitureId) do
        local castleFurniture = castleFurnitures[id]
        for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
            if not v.Finished and v.CollectingResource == elementId then
                return true
            end
        end
    end

    return false
end

function CityWorkManager:HasAbilityToGatherResource(elementId)
    ---@type CityElementResource
    local element = self.city.elementManager:GetElementById(elementId)
    if element == nil then
        return false
    end
    local resourceConfig = element.resourceConfigCell
    local condition = resourceConfig:Precondition()
    local requireType = condition:CollectAbilityId()
    local requireLv = condition:Level()
    if requireType <= 0 or requireLv <= 0 then
        return true
    end
    if not self.city:HasAbility(requireType, requireLv) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(resourceConfig:PreconditionNotice()))
        return false
    end
    return true
end

function CityWorkManager:IsResourceFullForTargetElementGather(elementId)
    ---@type CityElementResource
    local element = self.city.elementManager:GetElementById(elementId)
    if element == nil then
        return false
    end

    local resourceConfig = element.resourceConfigCell
    local output = ConfigRefer.ItemGroup:Find(resourceConfig:Reward())
    if output == nil then
        return false
    end

    local anyFull = false
    for i = 1, output:ItemGroupInfoListLength() do
        local itemInfo = output:ItemGroupInfoList(i)
        local itemId = itemInfo:Items()
        local totalCount = ModuleRefer.InventoryModule:GetResTypeCountByItemId(itemId)
        if totalCount then
            local resType = ModuleRefer.InventoryModule:GetResTypeByItemId(itemId)
            local resCapacity = ModuleRefer.InventoryModule:GetResItemCapacity(resType)
            if totalCount >= resCapacity then
                anyFull = true
                break
            end
        end
    end
    
    return anyFull    
end

function CityWorkManager:StartCitizenManualCollectWork(targetId, workCfgId, citizenId, lockable, callback, simpleErrorOverride)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg == nil then return false end

    local AllowNoCitizen = workCfg:AllowNoCitizen()
    if not AllowNoCitizen then
        if citizenId == nil then return false end
        if self.city.cityCitizenManager:GetCitizenDataById(citizenId) == nil then return false end
    end

    local wrapCallback = function()
        self._manualCollectCitizenIdMap[citizenId] = nil
        self._manualCollectResourceIdMap[targetId] = nil
        if callback then
            callback()
        end
    end

    if citizenId == nil then
        return self:StartWorkImp(targetId, workCfgId, nil, 0, lockable, wrapCallback, simpleErrorOverride)
    end

    local citizenData = self.city.cityCitizenManager:GetCitizenDataById(citizenId)
    if citizenData == nil then
        return self:StartWorkImp(targetId, workCfgId, nil, 0, lockable, wrapCallback, simpleErrorOverride)
    end

    local lastPos = self.city.cityCitizenManager:GetCitizenPosition(citizenId)
    local targetPos = self.city.cityCitizenManager:GetWorkTargetPosition(targetId, CityWorkHelper.GetWorkTargetType(workCfgId))

    if lastPos == nil or targetPos == nil then
        return self:StartWorkImp(targetId, workCfgId, citizenId, 0, lockable, wrapCallback, simpleErrorOverride)
    end

    self.city.cityPathFinding:FindPath(lastPos, targetPos, self.city.cityPathFinding.AreaMask.CityAllWalkable, function(waypoints)
        local t = 0
        if waypoints and #waypoints > 1 then
            for wI = 1, #waypoints - 1 do
                local p0 = waypoints[wI]
                local p1 = waypoints[wI + 1]
                t = t + (p1-p0).magnitude / citizenData:RunSpeed()
            end
        end
        self:StartWorkImp(targetId, workCfgId, citizenId, math.ceil(t * 1000), lockable, wrapCallback, simpleErrorOverride)
    end)
    return true
end

function CityWorkManager:StartLevelUpWork(targetId, workCfgId, citizenId, lockable, callback, simpleErrorOverride)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg == nil then return end

    local AllowNoCitizen = workCfg:AllowNoCitizen()
    if not AllowNoCitizen then
        if citizenId == nil then return end
        if self.city.cityCitizenManager:GetCitizenDataById(citizenId) == nil then return end
    end

    return self:StartWorkImp(targetId, workCfgId, citizenId or 0, 0, lockable, callback, simpleErrorOverride)
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:StartWorkImp(targetId, workCfgId, citizenId, workTime, lockable, callback, simpleErrorOverride)
    local param = CastleStartWorkParameter.new()
    if citizenId ~= nil and citizenId > 0 then
        param.args.WorkerIds:Add(citizenId)
    end
    param.args.WorkCfgId = workCfgId
    param.args.WorkTarget = targetId

    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
    return true
end

function CityWorkManager:StopWork(workId, lockable, callback, simpleErrorOverride)
    local param = CastleStopWorkParameter.new()
    param.args.WorkId = workId
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
    return true
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:StartProcessWork(furnitureId, processId, idx, times, workCfgId, citizenId, isAuto, lockable, callback, simpleErrorOverride)
    local param = CastleAssignProcessPlanParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.ProcessId = processId
    param.args.QueueIdx:Add(idx)
    param.args.Num = times
    param.args.WorkId = workCfgId
    param.args.CitizenId = citizenId or 0
    param.args.Auto = isAuto or false

    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:RemoveProcessWork(furnitureId, idx, workCfgId, citizenId, lockable, callback, simpleErrorOverride)
    local param = CastleAssignProcessPlanParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.ProcessId = 0
    param.args.QueueIdx:Add(idx)
    param.args.Num = 0
    param.args.WorkId = workCfgId
    param.args.CitizenId = citizenId or 0

    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:StartResGenProcess(furnitureId, workCfgId, citizenId, processId, count, isAuto, lockable, callback, simpleErrorOverride)
    local param = CastleAddFurnitureResGenProcessParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.WorkId = workCfgId
    param.args.CitizenId = citizenId
    param.args.ProcessId = processId
    param.args.Count = count
    param.args.Auto = isAuto
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:RemoveResGenProcessWork(furnitureId, idx, lockable, callback, simpleErrorOverride)
    local param = CastleDelFurnitureResGenProcessParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.QueueIdx = idx
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:AttachCitizenToWork(workId, citizenId, lockable, callback, simpleErrorOverride)
    local workData = self:GetWorkData(workId)
    if workData == nil then return end

    local param = CastleCitizenAssignProcessWorkParameter.new()
    param.args.WorkId = workId
    param.args.CitizenId = citizenId
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:DetachCitizenFromWork(workId, lockable, callback, simpleErrorOverride)
    local workData = self:GetWorkData(workId)
    if workData == nil then return end

    local param = CastleCitizenAssignProcessWorkParameter.new()
    param.args.WorkId = workId
    param.args.CitizenId = 0
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:StartCollectWork(workId, furnitureId, citizenId, processId, times, isAuto, lockable, callback, simpleErrorOverride)
    local param = CastleAddFurnitureCollectProcessParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.WorkId = workId
    param.args.CitizenId = citizenId
    param.args.ProcessId = processId
    param.args.Count = times
    param.args.Auto = isAuto
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:RemoveCollectProcess(furnitureId, idx, lockable, callback, simpleErrorOverride)
    local param = CastleDelFurnitureCollectProcessParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.QueueIdx = idx
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, simpleErrorOverride)
    else
        param:Send(lockable, nil, true, simpleErrorOverride)
    end
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function CityWorkManager:RequestCollectProcessLike(furnitureId, idx, workCfgId, lockable, callback, errorHandle)
    local param = CastleGetProcessOutputParameter.new()
    param.args.FurnitureId = furnitureId
    -- param.args.QueueIdxes:Add(idx)
    param.args.WorkCfgId = workCfgId

    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, errorHandle)
    else
        param:Send(lockable, nil, true, errorHandle)
    end
end

function CityWorkManager:RequestCollectProcessesLike(furnitureId, idxs, workCfgId, lockable, callback, errorHandle)
    local param = CastleGetProcessOutputParameter.new()
    param.args.FurnitureId = furnitureId
    -- param.args.QueueIdxes:AddRange(idxs)
    param.args.WorkCfgId = workCfgId

    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    local castle = self.city:GetCastle()
    local processInfo = castle.CastleFurniture[furnitureId].ProcessInfo
    if processInfo.ConfigId > 0 and workCfg:Type() == CityWorkType.Incubate then
        self.city.petManager:RecordLastHatchRecipe(processInfo.ConfigId)
    end

    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, errorHandle)
    else
        param:Send(lockable, nil, true, errorHandle)
    end
end

function CityWorkManager:RequestSpeedUpWorking(workId, lockable, callback, errorHandle)
    local param = CastleSpeedUpByCashParameter.new()
    param.args.WorkId = workId
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, errorHandle)
    else
        param:Send(lockable, nil, true, errorHandle)
    end
end

function CityWorkManager:RequestDirectFinishWorkByCash(furnitureId, workCfgId, subCfgId, orderCount, lockable, callback, errorHandle)
    local param = CastleDirectFinishWorkByCashParameter.new()
    param.args.FurnitureId = furnitureId
    param.args.WorkCfgId = workCfgId
    param.args.SubCfgId = subCfgId
    param.args.OrderCount = orderCount
    
    if callback then
        param:SendOnceCallback(lockable, nil, true, callback, errorHandle)
    else
        param:Send(lockable, nil, true, errorHandle)
    end
end

function CityWorkManager:IsProcessVisibleByCfgId(processId)
    local processCfg = ConfigRefer.CityProcess:Find(processId)
    return self:IsProcessVisible(processCfg)
end

---@param processCfg CityProcessConfigCell
function CityWorkManager:IsProcessVisible(processCfg)
    local questModule = ModuleRefer.QuestModule
    for i = 1, processCfg:VisibleConditionLength() do
        local taskId = processCfg:VisibleCondition(i)
        local status = questModule:GetQuestFinishedStateLocalCache(taskId)
        if status ~= wds.TaskState.TaskStateFinished and status ~= wds.TaskState.TaskStateCanFinish then
            return false
        end
    end
    return true
end

function CityWorkManager:IsProcessEffectiveByCfgId(processId)
    local processCfg = ConfigRefer.CityProcess:Find(processId)
    return self:IsProcessEffective(processCfg)
end

---@param processCfg CityProcessConfigCell
function CityWorkManager:IsProcessEffective(processCfg)
    return CityWorkHelper.IsProcessEffective(processCfg)
end

function CityWorkManager:IsWorkEffectiveByCfgId(workCfgId)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    return workCfg ~= nil and self:IsWorkEffective(workCfg)
end

function CityWorkManager:GetFreeCitizen(worldPos)
    local ret
    local distanceSqr
    local citizenUnit = self.city.cityCitizenManager._citizenUnit
    for _, citizen in pairs(citizenUnit) do
        if self._manualCollectCitizenIdMap[citizen._data._id] then
            goto continue
        end
        if not citizen._data:HasWork() then
            if not worldPos then
                return citizen
            end
            if not ret then
                ret = citizen
                distanceSqr = (citizen._moveAgent._currentPosition - worldPos).sqrMagnitude
            else
                local distance = (citizen._moveAgent._currentPosition - worldPos).sqrMagnitude
                if distance < distanceSqr then
                    distanceSqr = distance
                    ret = citizen
                end
            end
        end
        ::continue::
    end
    return ret
end

---@param workCfg CityWorkConfigCell
function CityWorkManager:IsWorkEffective(workCfg)
    return true
end

---@param entity wds.CastleBrief
function CityWorkManager:OnCastleWorkChanged(entity, changeTable)
    if entity.ID ~= self.city.uid then return end

    local batchEvt = {Event = EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Add = {}, Remove = {}, Change = {}}
    local add, remove, change = OnChangeHelper.GenerateMapFieldChangeMap(changeTable, wds.CastleWork)
    remove, change = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleWork, remove, change)

    if add then
        for id, work in pairs(add) do
            self._workData[id] = CityWorkData.new()
            self._workData[id]:UpdateFromCastleWork(id, work)
            batchEvt.Add[id] = true

            if self:GetWorkTypeByCfgId(self._workData[id].workCfgId) == CityWorkType.ResourceCollect then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_RESOURCE_UPDATE_COLLECTED_BUBBLE, self.city, self._workData[id].targetId)
            end
        end
    end

    if remove then
        for id, _ in pairs(remove) do
            local oldWork = self._workData[id]
            self._workData[id] = nil
            batchEvt.Remove[id] = true
            
            if self:GetWorkTypeByCfgId(oldWork.workCfgId) == CityWorkType.ResourceCollect then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_RESOURCE_UPDATE_COLLECTED_BUBBLE, self.city, oldWork.targetId)
            end
        end
    end

    if change then
        for id, fromto in pairs(change) do
            self._workData[id]:UpdateFromCastleWork(id, fromto[2])
            batchEvt.Change[id] = true
        end
    end
    return batchEvt
end

---@param entity wds.CastleBrief
function CityWorkManager:OnCastleResourceWorkProgressChanged(entity, changeTable)
    if entity.ID ~= self.city.uid then return end
    local _, remove, change = OnChangeHelper.GenerateMapFieldChangeMap(changeTable, wds.CastleResourceInfo)
    remove, change = OnChangeHelper.PostFixChangeMap(entity.Castle.CastleElements.InProgressResource, remove, change)
    if not remove then return end
    for i, v in pairs(remove) do
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, self.city.uid, i, v, v.WorkId)
    end
end

function CityWorkManager:GetCitizenWorkData(workId)
    return self._citizenWork[workId]
end

function CityWorkManager:GetCitizenWorkDataByCitizenId(citizenId)
    local workId = self:GetCitizenRelativeWorkId(citizenId)
    return self._citizenWork[workId]
end

---@return CityWorkData
function CityWorkManager:GetWorkData(workId)
    return self._workData[workId]
end

---@return number, wds.CastleWork
function CityWorkManager:GetWorkDataByTargetId(targetId, workCfgId)
    for id, v in pairs(self._workData) do
        if v.targetId == targetId and v.workCfgId == workCfgId then
            return id, v
        end
    end
end

function CityWorkManager:GetWorkDataByTargetIdAndWorkType(targetId, workType)
    for id, v in pairs(self._workData) do
        if v.targetId == targetId and self:GetWorkTypeByCfgId(v.workCfgId) == workType then
            return id, v
        end
    end
end

function CityWorkManager:GetCitizenRelativeWorkId(targetCitizen)
    for workId, citizenId in pairs(self._work2CitizenId) do
        if citizenId == targetCitizen then
            return workId
        end
    end
    return 0
end

function CityWorkManager:GetCitizenWorkDataByTarget(targetId, targetType)
    for _, v in pairs(self._citizenWork) do
        if v._target == targetId and CityWorkHelper.GetWorkTargetTypeByCfg(v._config) == targetType then
            return v
        end
    end
end

---@param targetType number @CityWorkTargetType
function CityWorkManager:GetRelativeCitizenIds(instId, targetType)
    local citizenIds = {}
    for _, v in pairs(self._workData) do
        if v.targetId == instId and CityWorkHelper.GetWorkTargetType(v.workCfgId) == targetType then
            table.insert(citizenIds, v.CitizenId)
        end
    end
    return citizenIds
end

---@param setFunc fun(id:number, title:string, subtitle:string, content:string, delay:number, userData:string)
function CityWorkManager:OnSetLocalNotification(setFunc)
    if not setFunc then
        return
    end
    if not self.city then
        return
    end
    local castle = self.city:GetCastle()
    if not castle then
        return
    end
    local workMap = self._workData
    if table.isNilOrZeroNums(workMap) then
        return
    end
    local furnitureMap = castle.CastleFurniture
    if table.isNilOrZeroNums(furnitureMap) then
        return
    end
    local productionFinishCfg = ConfigRefer.Push:Find(PushConsts.production_finish)
    if not productionFinishCfg then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    for furnitureId, castleFurniture in pairs(furnitureMap) do
        -- local notifyId = tonumber(productionFinishCfg:Id() .. tostring(furnitureId))
        -- local title = I18N.Get(productionFinishCfg:Title())
        -- local subtitle = I18N.Get(productionFinishCfg:SubTitle())
        -- local content = I18N.GetWithParams(productionFinishCfg:Content(), I18N.Get(item:NameKey()))
        -- setFunc(notifyId, title, subtitle, content, delay, nil)
    end
end

function CityWorkManager:TryAttachCitizenToWorkTarget(citizenId, targetId, targetType, lockTrans)
    
end

---@param workCfg CityWorkConfigCell
function CityWorkManager:GetWorkBuffIconForCitizen(workCfg)
    local length = workCfg:CitizenAttrBonusLength()
    if length == 0 then
        return string.Empty
    end

    for i = 1, length do
        local attrDisplayCfgId = workCfg:CitizenAttrBonus(i)
        if attrDisplayCfgId == 0 then
            goto continue
        end

        local clientKey = ConfigRefer.AttrDisplay:Find(attrDisplayCfgId):BaseAttrTypeId()
        if attrDisplayCfgId == 0 then
            goto continue
        end

        local attrCell = ConfigRefer.AttrElement:Find(clientKey)
        local icon = attrCell:Icon()
        if not string.IsNullOrEmpty(icon) then
            return icon
        end
        ::continue::
    end

    return string.Empty
end

---@param workCfg CityWorkConfigCell
---@param citizenData CityCitizenData
function CityWorkManager:GetWorkBuffValueFromCitizen(workCfg, citizenData)
    local heroId = citizenData._config:HeroId()
    local heroData = ModuleRefer.HeroModule:FindHeroDB(heroId)
    local props = heroData.Props
    local ret = 0
    for i = 1, workCfg:CitizenAttrBonusLength() do
        local displayAttrId = workCfg:CitizenAttrBonus(i)
        ret = ret + (props[displayAttrId] or 0)
    end

    if heroData.BindPetId > 0 then
        for i = 1, workCfg:CitizenAttrBonusLength() do
            local displayAttrId = workCfg:CitizenAttrBonus(i)
            local value = ModuleRefer.PetModule:GetPetAttrDisplayValue(heroData.BindPetId, displayAttrId)
            ret = ret + (value or 0)
        end
    end

    return ret
end

function CityWorkManager:GetWorkBuffValueFromCitizenId(workCfg, citizenId)
    if citizenId == nil then return 0 end
    local citizenData = self.city.cityCitizenManager:GetCitizenDataById(citizenId)
    return self:GetWorkBuffValueFromCitizen(workCfg, citizenData)
end

---@return CityWorkProduceResGenUnit
function CityWorkManager:GetResGenUnit(furnitureId)
    local agent = self._furnitureResGenGridAgents[furnitureId]
    if agent then
        return agent.generating
    end
end

function CityWorkManager:GetWorkTypeByCfgId(workCfgId)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    return workCfg and workCfg:Type()
end

---@param furnitureId number
---@param workCfg CityWorkConfigCell
---@param eleResCfg CityElementResourceConfigCell
function CityWorkManager:GetResGenAreaInfo(workCfg, furnitureId, citizenId, eleResCfg)
    local agent = self._furnitureResGenGridAgents[furnitureId]
    if agent == nil then
        return 0, 0
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
    if furniture == nil then
        return 0, 0
    end

    local castleFurniture = furniture:GetCastleFurniture()
    if castleFurniture == nil then
        return 0, 0
    end
    
    local generatePosList = ConfigRefer.CityRelPosList:Find(workCfg:GeneratePosList())
    if generatePosList == nil then
        return 0, 0
    end

    local cur = castleFurniture.ResourceGenerateInfo.GeneratedResourceIds:Count()
    local max = 0
    local x, y = furniture.x, furniture.y
    local gridLayer = self.city.gridLayer
    local slotSizeX, slotSizeY = eleResCfg:SizeX(), eleResCfg:SizeY()
    
    local baseX, baseY = x, y
    local axisX, axisY = {x = 1, y = 0}, {x = 0, y = 1}
    if furniture.direction == 90 then
        baseX, baseY = x, y + furniture.sizeY
        axisX.x, axisX.y = 0, -1
        axisY.x, axisY.y = 1, 0
    elseif furniture.direction == 180 then
        baseX, baseY = x + furniture.sizeX, y + furniture.sizeY
        axisX.x, axisX.y = -1, 0
        axisY.x, axisY.y = 0, -1
    elseif furniture.direction == 270 then
        baseX, baseY = x + furniture.sizeX, y
        axisX.x, axisX.y = 0, 1
        axisY.x, axisY.y = -1, 0
    end

    local cfgMax = CityWorkFormula.GetResGenMaxCount(workCfg, nil, furnitureId, citizenId)
    local buildingId = furniture:GetCastleFurniture().BuildingId
    ---@type CityLegoBuilding
    local legoBuilding = nil
    if buildingId > 0 then
        legoBuilding = self.city.legoManager:GetLegoBuilding(buildingId)
    end

    for i = 1, math.min(generatePosList:PosListLength(), cfgMax) do
        if castleFurniture.ResourceGenerateInfo.GeneratedResourceIds[i-1] == nil then
            local pos = generatePosList:PosList(i)
            local ox, oy = pos:X(), pos:Y()
 
            local startX = baseX + ox * axisX.x + oy * axisY.x
            local startY = baseY + ox * axisX.y + oy * axisY.y

            local endX = startX + slotSizeX * axisX.x + slotSizeY * axisY.x
            local endY = startY + slotSizeY * axisX.y + slotSizeY * axisY.y

            local minX, maxX = math.min(startX, endX), math.max(startX, endX)
            local minY, maxY = math.min(startY, endY), math.max(startY, endY)

            local empty = true
            for x = minX, maxX - 1 do
                for y = minY, maxY - 1 do
                    local mask = gridLayer:Get(x, y)
                    if CityGridLayerMask.IsPlacedWithoutLegoFlagAndGeneratingRes(mask) then
                        empty = false
                        break
                    end
                    if not self.city:IsLocationValid(x, y) then
                        empty = false
                        break
                    end
                    if self.city:IsCloseToPolluted(x, y) then
                        empty = false
                        break
                    end
                    if legoBuilding then
                        if not CityGridLayerMask.IsInLego(mask) or not legoBuilding:FloorContains(x, y) then
                            empty = false
                            break
                        end
                    else
                        if CityGridLayerMask.IsInLego(mask) then
                            empty = false
                            break
                        end
                    end
                end
                if not empty then
                    break
                end
            end

            if empty then
                max = max + 1
            end
        else
            max = max + 1
        end
    end
    
    max = math.min(max, cfgMax)
    return cur, max
end

function CityWorkManager:GetWorkingCountByType(typ)
    local ret = 0
    for id, workData in pairs(self._workData) do
        local workCfg = ConfigRefer.CityWork:Find(workData.workCfgId)
        if workCfg and workCfg:Type() == typ then
            ret = ret + 1
        end
    end
    return ret
end

function CityWorkManager:LogChannel(channel, ...)
    if not EnableTraceReddot then return end
    g_Logger.TraceChannel(channel, ...)
end

---@param recipe CityProcessConfigCell
function CityWorkManager:GetProcessRecipeOutputFurnitureLvCfgId(recipe)
    if recipe == nil then return 0 end

    local output = ConfigRefer.ItemGroup:Find(recipe:Output())
    if output == nil then
        g_Logger.ErrorChannel("家具制造页显示异常", "配方[%d]的产出ItemGroup[%d]不存在", recipe:Id(), recipe:Output())
        return 0
    end

    if output:ItemGroupInfoListLength() == 0 then
        g_Logger.ErrorChannel("家具制造页显示异常", "配方[%d],ItemGroup[%d]的产出物品种类为0", recipe:Id(), recipe:Output())
        return 0
    end

    local firstItemInfo = output:ItemGroupInfoList(1)
    local itemId = firstItemInfo:Items()
    local lvCfgId = ModuleRefer.CityConstructionModule:GetFurnitureRelative(itemId)
    if lvCfgId == 0 then
        g_Logger.ErrorChannel("家具制造页显示异常", "配方[%d], ItemGroup[%d], Item[%d]没有对应的家具Lv", recipe:Id(), recipe:Output(), itemId)
    end
    return lvCfgId
end

---@param workCfg CityWorkConfigCell
function CityWorkManager:GetBestFreeCitizenForWork(workCfg)
    local citizenMap = self.city.cityCitizenManager._citizenData
    local freeCitizens = {}
    for _, citizen in pairs(citizenMap) do
        if self:GetCitizenWorkDataByCitizenId(citizen._id) == nil then
            table.insert(freeCitizens, citizen._id)
        end
    end

    local powerValue = nil
    local bestCitizenId = nil
    for i, v in ipairs(freeCitizens) do
        local power = CityWorkFormula.GetWorkPower(workCfg, nil, nil, v, true)
        if powerValue == nil or power > powerValue then
            powerValue = power
            bestCitizenId = v
        end
    end

    return bestCitizenId
end

return CityWorkManager
