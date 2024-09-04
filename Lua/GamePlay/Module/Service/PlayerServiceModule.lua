local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local NpcServiceUnlockCondType = require("NpcServiceUnlockCondType")
local GuideUtils = require("GuideUtils")
local OnChangeHelper = require("OnChangeHelper")
local NpcServiceObjectType = require("NpcServiceObjectType")
local NpcServiceType = require("NpcServiceType")
local StoryDialogUiOptionCellType = require("StoryDialogUiOptionCellType")
local UIMediatorNames = require("UIMediatorNames")
local TimerUtility = require("TimerUtility")
local SlgBattlePowerHelper = require("SlgBattlePowerHelper")
local RPPType = require("RPPType")
local EventConst = require("EventConst")
local TouchMenuBasicInfoDatumSe = require("TouchMenuBasicInfoDatumSe")
local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")
local UIHelper = require("UIHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TouchMenuHelper = require("TouchMenuHelper")
local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local StoryDialogUIMediatorParameterChoiceProvider = require("StoryDialogUIMediatorParameterChoiceProvider")
local TaskRewardType = require("TaskRewardType")
local Coordinate = require("Coordinate")
local ArtResourceUtils = require("ArtResourceUtils")

local RequestNpcServiceParameter = require("RequestNpcServiceParameter")
local RequestNpcServiceInfoParameter = require("RequestNpcServiceInfoParameter")

local BaseModule = require("BaseModule")

---@class MakeNpcServiceOptionContext
---@field IsPolluted fun(targetId:number):boolean
---@field GetPresetIndexAndTroopId fun(troopPresetIdx:number, teamId:number):number,number
---@field GetPresetIndexAndTroopIdByPreset fun(troopInfo:TroopInfo):number,number
---@field GetCenterWorldPositionFromCoord fun(x:number, y:number, sx:number, sy:number, skipPostProcess:boolean):CS.UnityEngine.Vector3

---@alias ServiceChangeListener fun(entity:wds.Player, changedData:table)

---@class PlayerServiceModule:BaseModule
---@field new fun():BaseModule
---@field super BaseModule
local PlayerServiceModule = class('PlayerServiceModule', BaseModule)

function PlayerServiceModule:ctor()
    PlayerServiceModule.super.ctor(self)
    ---@type table<number, table<number, wds.NpcServiceGroup>>
    self._allService = {}
    ---@type table<number, ServiceChangeListener[]>
    self._typeChangeListener = {}
    self._playerId = nil
    ---@type table<number, {state:number, objectId:number, objectType:number}> @key-npcServiceConfigId,value-state-wds.NpcServiceState
    self._npcServiceStateCacheA = {}
    ---@type table<number, {state:number, objectId:number, objectType:number}> @key-npcServiceConfigId,value-state-wds.NpcServiceState
    self._npcServiceStateCacheB = {}
end

function PlayerServiceModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.NpcServices.ServicesMap.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerServiceChanged))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
end

function PlayerServiceModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.NpcServices.ServicesMap.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerServiceChanged))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
end

---@param cache table<number, {state:number, objectId:number, objectType:number}>
---@param npcServiceConfigId number
---@param objectId number
---@param state number
---@param objectType number
function PlayerServiceModule.ProcessNpcServiceAdd(cache, npcServiceConfigId ,objectId, state, objectType)
    local data = cache[npcServiceConfigId]
    if data then
        local msg = string.format("npc service 重复:%s objectId:%s,%s objectType:%s,%s", npcServiceConfigId, data.objectId, objectId, data.objectType, objectType)
        if UNITY_EDITOR and not CS.LogicRepoUtils.IsSsrLogicRepoExist() then
            require("WarningToolsForDesigner").DisplayGameViewAndSceneViewNotification(msg)
        end
        g_Logger.Error(msg)
    end
    data = { objectId = objectId, state = state, objectType = objectType}
    cache[npcServiceConfigId] = data
    return data
end

---@param entity wds.Player
function PlayerServiceModule:OnPlayerDataReady(entity)
    if not entity then return end
    self._playerId = entity.ID
    table.clear(self._allService)
    table.clear(self._npcServiceStateCacheA)
    table.clear(self._npcServiceStateCacheB)
    local servicesMap = entity.PlayerWrapper2.NpcServices.ServicesMap
    for objectType, v in pairs(servicesMap) do
        local t = table.getOrCreate(self._allService, objectType)
        for objectId, serviceGroup in pairs(v.Npcs) do
            t[objectId] = serviceGroup
            for npcServiceConfigId, serviceInfo in pairs(serviceGroup.Services) do
                PlayerServiceModule.ProcessNpcServiceAdd(self._npcServiceStateCacheA, npcServiceConfigId, objectId, serviceInfo.State, objectType)
            end
        end
    end
end

---@param a google.protobuf.Timestamp
---@param b google.protobuf.Timestamp
---@return boolean
function PlayerServiceModule.TimestampEqual(a, b)
    return a.timeSeconds == b.timeSeconds and a.nanos == b.nanos
end

---@param a wds.NpcServiceInfo
---@param b wds.NpcServiceInfo
---@return boolean
function PlayerServiceModule.NpcServiceInfoEqual(a, b)
    if a.State ~= b.State then return false end
    local countA = 0
    for i, v in pairs(a.ItemCount) do
        local vB = b.ItemCount[i]
        if not vB or vB ~= v then return false end
        countA = countA + 1
    end
    for i, _ in pairs(b.ItemCount) do
        if not a.ItemCount[i] then return false end
        countA = countA - 1
    end
    return countA == 0
end

---@param a table<number, wds.NpcServiceInfo>
---@param b table<number, wds.NpcServiceInfo>
---@return boolean
function PlayerServiceModule.NpcServiceInfoMapEqual(a, b)
    local countA = 0
    for i, v in pairs(a) do
        local vB = b[i]
        if not vB then return false end
        if not PlayerServiceModule.NpcServiceInfoEqual(v, vB) then return false end
        countA = countA + 1
    end
    for i, _ in pairs(b) do
        if not b[i] then return false end
        countA = countA - 1
    end
    return countA == 0
end

---@param a wds.NpcServiceGroup
---@param b wds.NpcServiceGroup
---@return boolean
function PlayerServiceModule.EqualNpcServiceGroup(a, b)
    repeat
        if a.ID ~= b.ID then break end
        if a.ObjectType ~= b.ObjectType then break end
        if a.ObjectId ~= b.ObjectId then break end
        if a.ServiceGroupTid ~= b.ServiceGroupTid then break end
        if a.IsCoolDown ~= b.IsCoolDown then break end
        if a.EnterCoolDownTimes ~= b.EnterCoolDownTimes then break end
        if not PlayerServiceModule.TimestampEqual(a, b) then break end
        if not PlayerServiceModule.NpcServiceInfoMapEqual(a.Services, b.Services) then break end
        return true
    until true
    return false
end

---@param entity wds.Player
function PlayerServiceModule:OnPlayerServiceChanged(entity, changedData)
    if self._playerId ~= entity.ID then return end
    local currentData = entity.PlayerWrapper2.NpcServices.ServicesMap
    local batchTypeNotify = {}
    local add,remove,change = OnChangeHelper.GenerateMapComponentFieldChangeMap(changedData, wds.ObjectNpcServices)
    if remove then
        for objectType, _ in pairs(remove) do
            local oldT = self._allService[objectType]
            if oldT then
                local notify = table.getOrCreate(batchTypeNotify, objectType)
                local willRemove = table.getOrCreate(notify, "Remove")
                for objectId, serviceGroup in pairs(oldT) do
                    willRemove[objectId] = serviceGroup
                end
                self._allService[objectType] = nil
            end
        end
    end
    if add then
        for objectType, _ in pairs(add) do
            local data = table.getOrCreate(self._allService, objectType)
            local notify = table.getOrCreate(batchTypeNotify, objectType)
            local willAdd = table.getOrCreate(notify, "Add")
            for objectId, serviceGroup in pairs(currentData[objectType].Npcs) do
                data[objectId] = serviceGroup
                willAdd[objectId] = serviceGroup
            end
        end
    end
    if changedData then
        for objectType, changeStruct in pairs(changedData) do
            if changeStruct.Npcs then
                ---@type table<number, wds.NpcServiceGroup>
                local lastData = table.getOrCreate(self._allService, objectType)
                local notify = table.getOrCreate(batchTypeNotify, objectType)
                local inMapAdd,inMapRemove,inMapChange = OnChangeHelper.GenerateMapComponentFieldChangeMap(changeStruct.Npcs, wds.NpcServiceGroup)
                if inMapAdd then
                    local willAdd = table.getOrCreate(notify, "Add")
                    for objectId, serviceGroup in pairs(inMapAdd) do
                        lastData[objectId] = serviceGroup
                        willAdd[objectId] = serviceGroup
                    end
                end
                if inMapRemove then
                    local willRemove = table.getOrCreate(notify, "Remove")
                    for objectId, serviceGroup in pairs(inMapRemove) do
                        lastData[objectId] = nil
                        willRemove[objectId] = serviceGroup
                    end
                end
                if inMapChange then
                    for objectId, _ in pairs(inMapChange) do
                        local serviceGroup = currentData[objectType].Npcs[objectId]
                        notify[objectId] = serviceGroup
                        lastData[objectId] = serviceGroup
                    end
                end
            end
            ::continue::
        end
    end
    local changeStateServices = {}
    table.clear(self._npcServiceStateCacheB)
    for objectType, v in pairs(currentData) do
        for objectId, serviceGroup in pairs(v.Npcs) do
            for npcServiceConfigId, serviceInfo in pairs(serviceGroup.Services) do
                local addData = PlayerServiceModule.ProcessNpcServiceAdd(self._npcServiceStateCacheB, npcServiceConfigId, objectId, serviceInfo.State, objectType)
                local old = self._npcServiceStateCacheA[npcServiceConfigId]
                if old and old.state ~= serviceInfo.State then
                    changeStateServices[npcServiceConfigId] = {old, addData}
                end
            end
        end
    end
    ---@type table<number,{state:number, objectId:number, objectType:number}>
    local removedServices = {}
    for npcServiceConfigId, v in pairs(self._npcServiceStateCacheA) do
        if not self._npcServiceStateCacheB[npcServiceConfigId] then
            removedServices[npcServiceConfigId] = v
        end
    end
    self._npcServiceStateCacheA,self._npcServiceStateCacheB = self._npcServiceStateCacheB,self._npcServiceStateCacheA

    for objectType, generatedChanged in pairs(batchTypeNotify) do
        local listenerList = self._typeChangeListener[objectType]
        if listenerList then
            for _, v in ipairs(listenerList) do
                v(entity, generatedChanged)
            end
        end
    end
    self:CheckServiceTriggerStory(changeStateServices)
    self:CheckServiceRemoveTriggerStory(removedServices)
end

function PlayerServiceModule:OnReloginSuccess()
    self:OnPlayerDataReady(ModuleRefer.PlayerModule:GetPlayer())
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param objectType number @NpcServiceObjectType
---@param objectId number
---@param serviceId number
---@param deliveryItems table<number, number>
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@param userData any
function PlayerServiceModule:RequestNpcService(lockable, objectType, objectId, serviceId, deliveryItems, callback, userData)
    local sendCmd = RequestNpcServiceParameter.new()
    sendCmd.args.ObjectType = objectType
    sendCmd.args.ObjectId = objectId
    sendCmd.args.ServiceId = serviceId
    if deliveryItems then
        for i, v in pairs(deliveryItems) do
            sendCmd.args.Param.DeliveryItems:Add(i, v)
        end
    end
    local city = ModuleRefer.CityModule:GetMyCity()
    if city and city.cityCitizenManager then
        callback = city.cityCitizenManager:CheckAndPresetCitizenSpwanPos(callback, serviceId, objectType, objectId)
    end
    sendCmd:SendOnceCallback(lockable, userData, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param objectType number @NpcServiceObjectType
---@param objectId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@param userData any
function PlayerServiceModule:RequestNpcServiceInfo(lockable, objectType, objectId, callback, userData)
    local sendCmd = RequestNpcServiceInfoParameter.new()
    sendCmd.args.ObjectType = objectType
    sendCmd.args.ObjectId = objectId
    sendCmd:SendOnceCallback(lockable, userData, nil, callback)
end

---@param objectType number @NpcServiceObjectType
---@param listener ServiceChangeListener
function PlayerServiceModule:AddServicesChanged(objectType, listener)
    local listenerArray = table.getOrCreate(self._typeChangeListener, objectType)
    table.insert(listenerArray, listener)
end

---@param objectType number @NpcServiceObjectType
---@param listener ServiceChangeListener
function PlayerServiceModule:RemoveServicesChanged(objectType, listener)
    local listenerArray = self._typeChangeListener[objectType]
    if not listenerArray then return end
    table.removebyvalue(listenerArray, listener)
end

---@param objectType number @NpcServiceObjectType
---@return table<number, wds.NpcServiceGroup>
function PlayerServiceModule:GetServiceMapByObjectType(objectType)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return {}
    end
    local map = player.PlayerWrapper2.NpcServices.ServicesMap[objectType]
    return map and map.Npcs or {}
end

---@param targetNpcList wds.NpcServiceGroup
---@return boolean,NpcServiceConfigCell|nil
function PlayerServiceModule:HasInteractableService(targetNpcList)
    if not targetNpcList or not targetNpcList.Services then
        return false
    end
    local firstNotShownLockedService = nil
    for serviceId, serviceStateStruct in pairs(targetNpcList.Services) do
        local serviceState = serviceStateStruct.State or wds.NpcServiceState.NpcServiceStateBeLocked
        if serviceState == wds.NpcServiceState.NpcServiceStateCanReceive then
            return true
        end
        if serviceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            local cfg = ConfigRefer.NpcService:Find(serviceId)
            if cfg and cfg:IsShowLockService() then
                return true
            end
            if not firstNotShownLockedService then
                firstNotShownLockedService = cfg
            end
        end
    end
    return false, firstNotShownLockedService
end

---@param targetNpcList wds.NpcServiceGroup
---@param serviceType number @NpcServiceType
---@return boolean, number, wds.NpcServiceState,NpcServiceConfigCell
function PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, serviceType)
    if not targetNpcList or not targetNpcList.Services then
        return false
    end
    local retServiceId
    local retServiceState
    local retServiceCfg
    for serviceId, serviceStateStruct in pairs(targetNpcList.Services) do
        local serviceState = serviceStateStruct.State or wds.NpcServiceState.NpcServiceStateBeLocked
        local cfg = ConfigRefer.NpcService:Find(serviceId)
        if not cfg then
            return false
        end
        if not cfg:IsShowLockService() and serviceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            goto continue
        end
        if serviceState == wds.NpcServiceState.NpcServiceStateFinished then
            goto continue
        end
        if cfg:ServiceType() ~= serviceType then
            return false
        end
        if retServiceId then
            return false
        end
        retServiceId = serviceId
        retServiceState = serviceState
        retServiceCfg = cfg
        ::continue::
    end
    return retServiceId ~= nil, retServiceId, retServiceState, retServiceCfg
end

---@param npcData wds.NpcServiceGroup
function PlayerServiceModule:IsAllServiceCompleteOnNpc(npcData, excludeHiddenLockedService)
    if not npcData then
        return false
    end
    if table.isNilOrZeroNums(npcData.Services) then
        return false
    end
    for serviceId, serviceStateStruct in pairs(npcData.Services) do
        local serviceState = serviceStateStruct.State
        if excludeHiddenLockedService and serviceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            local cfg = ConfigRefer.NpcService:Find(serviceId)
            if cfg and cfg:IsShowLockService() then
                return false
            end
        elseif serviceState ~= wds.NpcServiceState.NpcServiceStateFinished then
            return false
        end
    end
    return true
end

---@param retServiceCfg NpcServiceConfigCell
function PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
    if retServiceCfg then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(retServiceCfg:LockServiceTips()))
        local player = ModuleRefer.PlayerModule:GetPlayer()
        local condCount = retServiceCfg:UnlockCondLength()
        for i = 1, condCount do
            local condition = retServiceCfg:UnlockCond(i)
            if condition then
                local unlockType = condition:UnlockCondType()
                local unlockParameter = condition:UnlockCondParam()
                if unlockType == NpcServiceUnlockCondType.FinishTask and unlockParameter > 0 then
                    local QuestModule = ModuleRefer.QuestModule
                    if not QuestModule:IsInBitMap(unlockParameter, player.PlayerWrapper.Task.FinishedBitMap) then
                        local preTaskConfig = ConfigRefer.Task:Find(unlockParameter)
                        if preTaskConfig then
                            local property = preTaskConfig:Property()
                            if property and property:Goto() > 0 then
                                GuideUtils.GotoByGuide(property:Goto(), false)
                                return
                            end
                        else
                            g_Logger.Error("nil task config for id:%s", unlockParameter)
                        end
                    end
                end
            end
        end
    end
end

---@param changed table<number, {state:number, objectId:number, objectType:number}[]>
function PlayerServiceModule:CheckServiceTriggerStory(changed)
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not changed or not scene or scene:GetName() ~= "KingdomScene" or not scene:IsInMyCity() then return false end
    for id, oldAndNew in pairs(changed) do
        local oldStatus = oldAndNew[1].state or wds.NpcServiceState.NpcServiceStateBeLocked
        local newStatus = oldAndNew[2].state or wds.NpcServiceState.NpcServiceStateBeLocked
        if oldStatus and oldStatus ~= newStatus and newStatus == wds.NpcServiceState.NpcServiceStateFinished then
            local config = ConfigRefer.NpcService:Find(id)
            if config then
                local triggerStoryTask = config:TriggerStoryWhenFinish()
                if triggerStoryTask and triggerStoryTask > 0 then
                    local storyTaskConfig = ConfigRefer.StoryTask:Find(triggerStoryTask)
                    if storyTaskConfig then
                        ModuleRefer.StoryModule:StoryStart(triggerStoryTask, function(storyId, result)
                            g_Logger.Log("NpcService Finish Trigger Story:%s, result:%s", storyId, result)
                        end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

---@param changed table<number, {state:number, objectId:number, objectType:number}[]>
function PlayerServiceModule:CheckServiceRemoveTriggerStory(removed)
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not removed or not scene or scene:GetName() ~= "KingdomScene" or not scene:IsInMyCity() then return false end
    for serviceConfigId, _ in pairs(removed) do
        local config = ConfigRefer.NpcService:Find(serviceConfigId)
        if config and config.TriggerStoryWhenRemove then
            local triggerStoryTask = config:TriggerStoryWhenRemove()
            if triggerStoryTask and triggerStoryTask > 0 then
                local storyTaskConfig = ConfigRefer.StoryTask:Find(triggerStoryTask)
                if storyTaskConfig then
                    ModuleRefer.StoryModule:StoryStart(triggerStoryTask, function(storyId, result)
                        g_Logger.Log("NpcService Finish Trigger Story:%s, result:%s", storyId, result)
                    end)
                    return true
                end
            end
        end
    end
    return false
end

---@return number|nil @wds.NpcServiceState
function PlayerServiceModule:GetNpcServiceState(npcServiceConfigId)
    local cache = self._npcServiceStateCacheA[npcServiceConfigId]
    return cache and cache.state or nil
end


---@param objectType number @NpcServiceObjectType
---@param objectId number
---@return boolean, NpcServiceConfigCell|nil
function PlayerServiceModule:HasInteractableServiceOnObject(objectType, objectId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local map = player.PlayerWrapper2.NpcServices.ServicesMap[objectType]
    if not map or not map.Npcs then return false end
    local serviceList = map.Npcs[objectId]
    if not serviceList then return false end
    return self:HasInteractableService(serviceList)
end

---@param targetNpcList wds.NpcServiceGroup
---@param targetId number
---@param npcCfg CityElementNpcConfigCell
---@param troopId number|nil
---@param troopPresetIdx number|nil
---@param contextProvider MakeNpcServiceOptionContext
---@return boolean
function PlayerServiceModule:OnSingleSEEntryService(objectType,targetNpcList, targetId, npcCfg, troopId, troopPresetIdx, contextProvider)
    local ret, seServiceId, retServiceState, retServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.EnterScene)
    if not ret then
        ret, seServiceId, retServiceState, retServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CatchPet)
        if not ret then
            return false
        end
    end

    if retServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
        self:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
        return true
    end

    local npcPos,npcName,npcIcon,elePos,needTeam = self:GetObjectTargetInfo(objectType, targetId)
    if not needTeam then
        troopPresetIdx, troopId = contextProvider and contextProvider.GetPresetIndexAndTroopId(troopPresetIdx, troopId)
        if troopPresetIdx then
            -- 需要使用部队，如SE
            if contextProvider and contextProvider.IsPolluted(targetId) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
                return true
            end

            local function RequestNpcService()
                local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity(troopId or 0, elePos, seServiceId, targetId, troopPresetIdx)
                self:RequestNpcService(targetId, seServiceId, function(success, rsp)
                    if success then
                        if continueEnterScene then
                            continueEnterScene()
                        end
                    end
                end)
            end

            local isPetCatch,costPPP, recommendPower, itemHas = ModuleRefer.SEPreModule.GetNpcServiceBattleInfo(seServiceId)
            --检查体力
            if costPPP > 0  then
                local player = ModuleRefer.PlayerModule:GetPlayer()
                local curPPP = player and player.PlayerWrapper2.Radar.PPPCur or 0
                if curPPP < costPPP then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_tilibuzu"))
                    return true
                end
            end

            --检查战力
            local troopPower = ModuleRefer.SlgModule:GetTroopPowerByPresetIndex(troopPresetIdx)
            if troopPower < recommendPower then
                SlgBattlePowerHelper.ShowRaisePowerPopup(RPPType.Se,RequestNpcService,troopPresetIdx)
            else
                RequestNpcService()
            end
        else
            -- 不需要使用部队，如抓宠
            local onMenuGotToClick= function()
                ---@type HUDSelectTroopListData
                local selectTroopData = {}
                selectTroopData.filter = function(troopInfo)
                    return troopInfo ~= nil and troopInfo.preset ~= nil
                end

                selectTroopData.overrideItemClickGoFunc = function(troopItemData)
                    local idx, troopId = contextProvider and contextProvider.GetPresetIndexAndTroopIdByPreset(troopItemData.troopInfo)
                    if idx then
                        local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity(troopId or 0, elePos, seServiceId, targetId, idx)
                        self:RequestNpcService(targetId, seServiceId, function(success, rsp)
                            if success then
                                if continueEnterScene then
                                    continueEnterScene()
                                end
                            end
                        end)
                    else
                        g_Logger.Error("No troop here")
                    end
                end

                local isPetCatch,costPPP, recommendPower, itemHas = ModuleRefer.SEPreModule.GetNpcServiceBattleInfo(seServiceId)
                selectTroopData.isSE = true
                selectTroopData.catchPet = isPetCatch
                if isPetCatch then
                    local enterPetCatch = function()
                        local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity( 0, elePos, seServiceId, targetId, 1)
                        if continueEnterScene then
                            continueEnterScene()
                        end
                    end
                    local compareResult = (itemHas >= recommendPower) and 1 or 2
                    if compareResult == 2 then
                        SlgBattlePowerHelper.ShowRaisePowerPopup(RPPType.Pet,enterPetCatch)
                    else
                        enterPetCatch()
                    end
                else
                    selectTroopData.needPower = recommendPower
                    selectTroopData.recommendPower = recommendPower
                    selectTroopData.costPPP = costPPP
                    require("HUDTroopUtils").StartMarch(selectTroopData)
                end
            end

            ---@type CreateTouchMenuForCityContext
            local context = {}
            context.npcId = seServiceId
            context.troopId = nil
            context.troopPresetIdx = nil
            context.worldPos = npcPos
            context.overrideGoToFunc = onMenuGotToClick
            context.elementId = targetId
            context.cityPos = elePos
            context.isGoto = false
            if contextProvider and contextProvider.IsPolluted(targetId) then
                context.targetIsPolluted = true
                context.pollutedHint = I18N.Get("creep_clean_needed")
            end
            ModuleRefer.SEPreModule:CreateTouchMenuForCity(context)
        end
        return true
    else
        troopPresetIdx, troopId = self:GetPresetIndexAndTroopId(troopPresetIdx, troopId)
        ---@type CreateTouchMenuForCityContext
        local context = {}
        context.npcId = seServiceId
        context.troopId = troopId
        context.troopPresetIdx = troopPresetIdx
        context.worldPos = npcPos
        context.overrideGoToFunc = nil
        context.elementId = targetId
        context.cityPos = elePos
        context.isGoto = false
        context.preSendEnterSceneOverride = function(continueEnterScene)
            self:RequestNpcService(targetId, seServiceId, function(success, rsp)
                if success then
                    if continueEnterScene then
                        continueEnterScene()
                    end
                end
            end)
        end
        if contextProvider and contextProvider.IsPolluted(targetId) then
            context.targetIsPolluted = true
            context.pollutedHint = I18N.Get("creep_clean_needed")
        end
        ModuleRefer.SEPreModule:CreateTouchMenuForCity(context)
    end
    return true
end

---@param objectType number @NpcServiceObjectType
---@param targetNpcList wds.NpcServiceGroup
---@param targetId number
---@param npcCfg CityElementNpcConfigCell
---@return boolean
function PlayerServiceModule:OnSingleCommitItemService(objectType ,targetNpcList, targetId, npcCfg)
    local ret, seServiceId, retServiceState, retServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CommitItem)
    if not ret then
        return false
    end
    if retServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
        self:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
        return true
    end
    if not npcCfg or npcCfg:NoNeedTeamInteract() then
        local tradeModule = ModuleRefer.StoryPopupTradeModule
        local serviceInfo = tradeModule:GetServicesInfo(objectType, targetId, seServiceId)
        local needItems = tradeModule:GetNeedItems(seServiceId)
        local lakeItemMap = {}
        for _, v in pairs(needItems) do
            local itemId = v.id
            local count = v.count
            local addCount = serviceInfo[itemId] or 0
            local lakeCount = math.max(0, count - addCount)
            if lakeCount > 0 then
                lakeItemMap[itemId] = (lakeItemMap[itemId] or 0) + lakeCount
            end
        end
        local InventoryModule = ModuleRefer.InventoryModule
        local openPanel = {}
        for itemId, lakeCount in pairs(lakeItemMap) do
            if InventoryModule:GetAmountByConfigId(itemId) < lakeCount then
                table.insert(openPanel, {id=itemId,num=lakeCount})
            end
        end
        if #openPanel > 0 then
            InventoryModule:OpenExchangePanel(openPanel)
            return true
        end
        self:RequestNpcService(nil, objectType, targetId, seServiceId, lakeItemMap)
        return true
    end
    return false
end

---@param taskCfg TaskConfigCell
---@return boolean,number,number
local function IsSubmitItemTask(taskCfg)
    if taskCfg and taskCfg:FinishBranchLength() > 0 then
        for i = 1, taskCfg:FinishBranchLength() do
            local finishCfg = taskCfg:FinishBranch(i)
            local rewardCount = finishCfg:BranchRewardLength()
            for j = 1, rewardCount do
                local reward = finishCfg:BranchReward(j)
                if reward:Typ() ~= TaskRewardType.RewardDecItem then
                    goto continueBranchRewardCheck
                end
                local param = reward.Param()
                if string.IsNullOrEmpty(param) then
                    goto continueBranchRewardCheck
                end
                local params = string.split(param, ';')
                if #params > 1 then
                    return true,tonumber(param[1]),tonumber(param[2])
                end
                ::continueBranchRewardCheck::
            end
        end
    end
    return false, 0, 0
end

---@param objectType number @NpcServiceObjectType
---@param targetId number
---@param serviceId number
---@param uiMediatorName string
---@param serviceState wds.NpcServiceState
---@param troopId number
---@param troopPresetIdx number
---@param contextProvider MakeNpcServiceOptionContext
---@return StoryDialogUIMediatorParameterChoiceProviderOption
function PlayerServiceModule:MakeNpcServiceOption(objectType, targetId, serviceId, uiMediatorName, serviceState, troopId, troopPresetIdx, contextProvider)
    local cfg = ConfigRefer.NpcService:Find(serviceId)
    if not cfg then
        return nil
    end
    if cfg:ServiceType() == NpcServiceType.Unknown then
        return nil
    end
    serviceState = serviceState or wds.NpcServiceState.NpcServiceStateBeLocked
    if not cfg:IsShowLockService() and serviceState == wds.NpcServiceState.NpcServiceStateBeLocked then
        return nil
    end
    if serviceState == wds.NpcServiceState.NpcServiceStateFinished then
        return nil
    end
    local sT = cfg:ServiceType()
    ---@type fun(o:StoryDialogUIMediatorParameterChoiceProviderOption):boolean
    local checkLockedAndToast = function(o)
        if serviceState ~= wds.NpcServiceState.NpcServiceStateBeLocked then
            if o and o.isOptionShowCreep then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
                return true
            end
            return false
        end
        self:CheckShowTriggerRequireTaskGotoGuide(cfg)
        return true
    end
    ---@type StoryDialogUIMediatorParameterChoiceProviderOption
    local option = {}
    option.showNumberPair = false
    option.showIsOnGoing = false
    option.content = I18N.Get(cfg:Content())
    option.type = StoryDialogUiOptionCellType.enum.None
    option.isOptionShowCreep = contextProvider and contextProvider.IsPolluted(targetId)
    option.onClickOption = function(o, lockable)
        if checkLockedAndToast(o) then
            return false
        end
        local mediator = option.uiRuntimeId and g_Game.UIManager:FindUIMediator(option.uiRuntimeId)
        if mediator then
            self:RequestNpcService(lockable, objectType, targetId, serviceId, nil, function(success, rsp)
                g_Game.UIManager:Close(option.uiRuntimeId)
            end)
            return
        end
        self:RequestNpcService(lockable, objectType, targetId, serviceId)
        return true
    end
    if sT == NpcServiceType.EnterScene then
        local npcPos,_,_,elePos,needTeam  = self:GetObjectTargetInfo(objectType, targetId)
        option.type = StoryDialogUiOptionCellType.enum.SE
        option.onClickOption = function(o)
            if checkLockedAndToast(o) then
                return false
            end
            if not needTeam then
                if contextProvider and contextProvider.IsPolluted(targetId) then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
                    return false
                end
                troopPresetIdx,troopId = contextProvider and contextProvider.GetPresetIndexAndTroopId(troopPresetIdx, troopId)
                if troopPresetIdx then
                    local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity(troopId or 0, elePos, serviceId, targetId, troopPresetIdx)
                    self:RequestNpcService(nil, objectType, targetId, serviceId, function(success, rsp)
                        if success then
                            if continueEnterScene then
                                continueEnterScene()
                            end
                        end
                    end)
                else
                    ---@type HUDSelectTroopListData
                    local selectTroopData = {}
                    selectTroopData.filter = function(troopInfo)
                        return troopInfo and troopInfo.preset
                    end
                    selectTroopData.overrideItemClickGoFunc = function(troopItemData)
                        local idx,troopId = contextProvider and contextProvider.GetPresetIndexAndTroopIdByPreset(troopItemData.troopInfo)
                        local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity(troopId or 0, elePos, serviceId, targetId, idx)
                        self:RequestNpcService(nil, objectType, targetId, serviceId, function(success, rsp)
                            if success then
                                if continueEnterScene then
                                    continueEnterScene()
                                end
                            end
                        end)
                    end
                    local isPetCatch,costPPP, recommendPower, itemHas = ModuleRefer.SEPreModule.GetNpcServiceBattleInfo(serviceId)
                    selectTroopData.isSE = true
                    selectTroopData.isPetCatch = isPetCatch
                    selectTroopData.needPower = isPetCatch and itemHas or recommendPower
                    selectTroopData.recommendPower = recommendPower
                    selectTroopData.costPPP = costPPP
                    require("HUDTroopUtils").StartMarch(selectTroopData)
                end
            else
                troopPresetIdx, troopId = contextProvider and contextProvider.GetPresetIndexAndTroopId(troopPresetIdx, troopId)
                if not troopPresetIdx then
                    return false
                end
                ---@type CreateTouchMenuForCityContext
                local context = {}
                context.npcId = serviceId
                context.troopId = troopId
                context.troopPresetIdx = troopPresetIdx
                context.worldPos = npcPos
                context.overrideGoToFunc = nil
                context.elementId = targetId
                context.cityPos = elePos
                context.isGoto = false
                context.preSendEnterSceneOverride = function(continueEnterScene)
                    self:RequestNpcService(nil, objectType, targetId, serviceId, function(success, rsp)
                        if success then
                            if continueEnterScene then
                                continueEnterScene()
                            end
                        end
                    end)
                end
                if contextProvider and contextProvider.IsPolluted and contextProvider.IsPolluted(targetId) then
                    context.targetIsPolluted = true
                    context.pollutedHint = I18N.Get("creep_clean_needed")
                end
                ModuleRefer.SEPreModule:CreateTouchMenuForCity(context)
            end
            return true
        end
    elseif sT == NpcServiceType.FinishTask then
        option.showIsOnGoing = true
        local unlockCount = cfg:UnlockCondLength()
        for i = 1, unlockCount do
            local unlockCond = cfg:UnlockCond(i)
            local unlockCondType = unlockCond:UnlockCondType()
            if unlockCondType == NpcServiceUnlockCondType.ReceiveTask then
                local taskConfig = ConfigRefer.Task:Find(unlockCond:UnlockCondParam())
                local isSubmitItemTask,requireCount,itemId = IsSubmitItemTask(taskConfig)
                if isSubmitItemTask then
                    option.type = StoryDialogUiOptionCellType.enum.Deal
                    option.showNumberPair = true
                    option.nowNum = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
                    option.requireNum = requireCount
                    option.onClickOption = function(o, lockable)
                        if checkLockedAndToast(o) then
                            return false
                        end
                        local nowCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
                        if nowCount < requireCount then
                            return false
                        end
                        local mediator = option.uiRuntimeId and g_Game.UIManager:FindUIMediator(option.uiRuntimeId)
                        if mediator then
                            self:RequestNpcService(lockable, objectType, targetId, serviceId, nil, function(success, rsp)
                                g_Game.UIManager:Close(option.uiRuntimeId)
                            end)
                            return false
                        end
                        self:RequestNpcService(lockable, objectType, targetId, serviceId)
                        return true
                    end
                    break
                else
                    local queryTaskId = taskConfig:Id()
                    option.onClickOption = function(o, lockable)
                        if checkLockedAndToast(o) then
                            return false
                        end
                        ModuleRefer.QuestModule:GetQuestFinishedState(queryTaskId, function(taskId, finishCount, state)
                            if state ~= wds.TaskState.TaskStateFinished and state ~= wds.TaskState.TaskStateCanFinish then
                                local taskName = ModuleRefer.QuestModule:GetTaskNameByID(taskId)
                                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(string.format("请先完成 任务:%s",I18N.Get(taskName))))
                                g_Game.UIManager:CloseByName(uiMediatorName)
                                return
                            end
                            self:RequestNpcService(lockable, objectType, targetId, serviceId, nil, function(success, rsp)
                                if mediator then
                                    g_Game.UIManager:Close(option.uiRuntimeId)
                                end
                            end)
                        end)
                        return false
                    end
                    break
                end
            end
        end

    elseif sT == NpcServiceType.CommitItem then
        option.onClickOption = function(o)
            if checkLockedAndToast(o) then
                return false
            end
            ---@type StoryPopupTradeMediatorParameter
            local param = {}
            param.objectType = objectType
            param.objectId = targetId
            param.serviceId = serviceId
            g_Game.UIManager:Open(UIMediatorNames.StoryPopupTradeMediator, param)
            return true
        end
    elseif sT == NpcServiceType.PlayStory then
        option.onClickOption = function(o)
            if checkLockedAndToast(o) then
                return false
            end
            TimerUtility.DelayExecuteInFrame(function()
                ModuleRefer.StoryModule:StoryStart(cfg:ServiceParam())
            end, 1, true)
            return true
        end
    end
    return option
end

---@param objectType number @NpcServiceObjectType
---@param targetId number
function PlayerServiceModule:InteractWithTarget(objectType, targetId, skipUICheck)
    if not skipUICheck and (g_Game.UIManager:HasAnyDialogUIMediator() or g_Game.UIManager:HaveCullSceneUIMediator()) then
        return
    end
    local targetNpcList = self:GetServiceMapByObjectType(objectType)[targetId]
    if not targetNpcList then
        g_Logger.Error("objectType:%s, targetId:%s has nil wds.NpcServiceGroup", objectType, targetId)
    end
    if not self:HasInteractableService(targetNpcList) then return end
    local isOnlySe,_,retServiceState,retServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.EnterScene)
    if not isOnlySe then
        isOnlySe,_, retServiceState, retServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CatchPet)
    end
    if retServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
        self:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
        return
    end
    local isOnlyCommit,_,commitRetServiceState,commitRetServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CommitItem)
    if isOnlyCommit then
        if commitRetServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            self:CheckShowTriggerRequireTaskGotoGuide(commitRetServiceCfg)
            return
        end
    end
    local isOnlyReceive,serviceId,receiveItemRetServiceState,receiveItemRetServiceCfg = self:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.ReceiveItem)
    if isOnlyReceive then
        if receiveItemRetServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            self:CheckShowTriggerRequireTaskGotoGuide(receiveItemRetServiceCfg)
            return
        end
    end
    if targetNpcList then
        if targetNpcList.IsCoolDown then
            self:CreateWaitRespawnPanel(objectType, targetId)
            return
        end
        g_Game.UIManager:CloseByName(UIMediatorNames.StoryDialogUIMediator)
        if self:OnSingleSEEntryService(objectType, targetNpcList, targetId) then
            return
        end
        if self:OnSingleCommitItemService(objectType, targetNpcList, targetId, nil) then
            return
        end
        if isOnlyReceive then
            self:RequestNpcService(nil, objectType, targetId, serviceId)
            return
        end
        self:BuildGenericTalkDialog(objectType, targetId)
    end
end

function PlayerServiceModule:BuildGenericTalkDialog(objectType, targetId)
    local targetNpcList = self:GetServiceMapByObjectType(objectType)[targetId]
    local uiMediatorName = UIMediatorNames.StoryDialogUIMediator
    local parameter = StoryDialogUIMediatorParameter.new()
    local provider = StoryDialogUIMediatorParameterChoiceProvider.new()
    local _,name,icon = self:GetObjectTargetInfo(objectType, targetId)
    provider:InitCharacterImage(name, icon)
    for serviceId, serviceState in pairs(targetNpcList.Services) do
        local option = self:MakeNpcServiceOption(objectType,targetId, serviceId, uiMediatorName, serviceState.State, nil, nil, nil)
        if option then
            provider:AppendOption(option)
        end
    end
    ---@type StoryDialogUIMediatorParameterChoiceProviderOption
    local exitChoice = {}
    exitChoice.showNumberPair = false
    exitChoice.showIsOnGoing = false
    exitChoice.type = 0
    exitChoice.onClickOption = nil
    exitChoice.isOptionShowCreep = false
    if objectType == NpcServiceObjectType.Citizen then
        exitChoice.content = I18N.Get("npc_service_btn_quit")
    else
        exitChoice.content = I18N.Get("npc_service_btn_quit")
    end
    provider:AppendOption(exitChoice)
    parameter:SetChoiceProvider(provider)
    g_Game.UIManager:Open(uiMediatorName, parameter)
end

---@return CS.UnityEngine.Vector3,string,string,{X:fun(), Y:fun()},boolean @pos,name,icon,gridPos,needTeam
function PlayerServiceModule:GetObjectTargetInfo(objectType, objectId)
    local city = ModuleRefer.CityModule:GetMyCity()
    if objectType == NpcServiceObjectType.CityElement then
        local eleConfig = ConfigRefer.CityElementData:Find(objectId)
        local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
        local gridPos = eleConfig:Pos()
        return city:GetCenterWorldPositionFromCoord(gridPos:X(), gridPos:Y(), npcConfig:SizeX(), npcConfig:SizeY()), I18N.Get(npcConfig:Name()), npcConfig:Image(), gridPos, not npcConfig:NoNeedTeamInteract()
    elseif objectType == NpcServiceObjectType.Furniture then
        local furniture = city.furnitureManager:GetFurnitureById(objectId)
        local gridPos = {}
        gridPos.X = function() return furniture.x end
        gridPos.Y = function() return furniture.y end
        return city:GetCenterWorldPositionFromCoord(furniture.x, furniture.y, furniture.sizeX, furniture.sizeY), I18N.Get(furniture.name), furniture.image, gridPos, false
    elseif objectType == NpcServiceObjectType.Citizen then
        local citizenPos = city.cityCitizenManager:GetCitizenPosition(objectId)
        local citizenData =  city.cityCitizenManager:GetCitizenDataById(objectId)
        if citizenPos and citizenData then
            return citizenPos, I18N.Get(citizenData._config:Name()), ArtResourceUtils.GetUIItem(citizenData._config:CharacterImage()), city:GetCoordFromPosition(citizenPos), false
        end
        g_Logger.Error("citizen not found:%s", objectId)
    elseif objectType == NpcServiceObjectType.Building then
        local legoBuilding = city.legoManager:GetLegoBuilding(objectId)
        local buildingPos = legoBuilding:GetWorldCenter()
        local gridPos = {}
        gridPos.X = function() return legoBuilding.x end
        gridPos.Y = function() return legoBuilding.z end
        return buildingPos, I18N.Get(legoBuilding:GetNameI18N()), legoBuilding:GetIcon(), gridPos, false
    else
        g_Logger.Error("GetObjectTargetInfo not supported yet")
    end
end

local InvokeCallback = function(callabck, ...)
    if not callabck then return end
    callabck(...)
end

---@param objectType number @NpcServiceObjectType
---@param targetId number
---@param callback fun(isSuccess:boolean, bubbleTrans:CS.UnityEngine.Transform)
---@param autoClick boolean
function PlayerServiceModule:FocusOnObjectBubble(objectType, targetId, callabck, autoClick)
    local current = g_Game.SceneManager.current
    if not current then
        InvokeCallback(callabck, false)
    end
    local city = ModuleRefer.CityModule.myCity
    if not city then
        InvokeCallback(callabck, false)
        return
    end
    if objectType == NpcServiceObjectType.CityElement then
        city.cityExplorerManager:FocusOnNpcByConfigId(targetId, function(isSuccess, bubbleTrans, bubble)
            if isSuccess then
                if autoClick then
                    if bubble then
                        bubble:OnClickIcon()
                    end
                end
                InvokeCallback(callabck, true, bubbleTrans)
            else
                InvokeCallback(callabck, false)
            end
        end)
    elseif objectType == NpcServiceObjectType.Citizen then
        city.cityCitizenManager:FocusOnCitizen(targetId, function(isSuccess, bubbleTrans, bubbleState)
            if isSuccess then
                if autoClick then
                    if bubbleState then
                        bubbleState:OnClickIcon()
                    end
                end
                InvokeCallback(callabck, true, bubbleTrans)
            else
                InvokeCallback(callabck, false)
            end
        end)
    else
        g_Logger.Error("objectType:%s id:%s not supported yet", objectType, targetId)
    end
end

---@param objectType number @NpcServiceObjectType
---@param targetId number
function PlayerServiceModule:CreateWaitRespawnPanel(objectType, targetId)
    local npcData = self:GetServiceMapByObjectType(objectType)[targetId]
    local npcServiceGroupConfig = ConfigRefer.NpcServiceGroup:Find(npcData.ServiceGroupTid)
    local npcPos,npcName,npcImage = self:GetObjectTargetInfo(objectType, targetId)

    local basicInfo = TouchMenuBasicInfoDatumSe.new()
    basicInfo:SetImage(UIHelper.IconOrMissing(npcImage))
    basicInfo:SetName(npcName)

    local uiPages = {}
    local allowTimes = npcServiceGroupConfig:UpdateTimes()
    if allowTimes > 0 then
        local leftTimes = TouchMenuCellPairDatum.new()
        leftTimes:SetLeftLabel(I18N.Get("city_npc_service_times")):SetRightLabel(("%d/%d"):format(math.max(0, allowTimes - npcData.EnterCoolDownTimes), allowTimes))
        table.insert(uiPages, leftTimes)
    end
    ---@type CommonTimerData
    local timerData = {}
    timerData.needTimer = true
    timerData.endTime = npcData.StartCoolDownTime.ServerSecond + ConfigTimeUtility.NsToSeconds(npcServiceGroupConfig:CoolDown())
    timerData.intervalTime = 1
    local refreshTimeTip = TouchMenuCellPairTimeDatum.new(I18N.Get("city_npc_service_refresh") , timerData)
    table.insert(uiPages, refreshTimeTip)
    -- 打开界面
    local uiDatum = TouchMenuHelper.GetSinglePageUIDatum(basicInfo,
            uiPages, {}, nil, nil, nil, nil)
    if npcPos then
        uiDatum:SetPos(npcPos)
    end
    uiDatum.closeOnTime = timerData.endTime
    g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiDatum)
end

return PlayerServiceModule