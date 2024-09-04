local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceParameters = require("AllianceParameters")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local MapBuildingType = require("MapBuildingType")
local TimeFormatter = require("TimeFormatter")
local AllianceBehemothDeviceInfo = require("AllianceBehemothDeviceInfo")
local AllianceBehemothSummonerInfo = require("AllianceBehemothSummonerInfo")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local OnChangeHelper = require("OnChangeHelper")
local AllianceBehemoth = require("AllianceBehemoth")
local ConfigTimeUtility = require("ConfigTimeUtility")
local AllianceBattleType = require("AllianceBattleType")
local AllianceBehemothOnMap = require("AllianceBehemothOnMap")
local UIMediatorNames = require("UIMediatorNames")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")
local ToastFuncType = require("ToastFuncType")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local ArtResourceUtils = require("ArtResourceUtils")
local AllianceActivityCellDataGve = require("AllianceActivityCellDataGve")

---@class AllianceModule_Behemoth
---@field new fun(baseModule:AllianceModule):AllianceModule_Behemoth
local AllianceModule_Behemoth = class('AllianceModule_Behemoth')

---@param baseModule AllianceModule
function AllianceModule_Behemoth:ctor(baseModule)
    ---@type AllianceModule
    self.module = baseModule
    ---@private
    ---@type table<number, AllianceBehemoth>
    self._behemothDic = {}
    ---@private
    ---@type AllianceBehemothDeviceInfo
    self._deviceInfo = nil
    ---@type AllianceBehemothSummonerInfo
    self._summonerInfo = nil
    ---@type AllianceBehemothOnMap
    self._onMapBehemoth = nil
    ---@type table<number, wds.MapBuildingBrief>
    self._cages = {}
    ---@type table<number, KmonsterDataConfigCell[]> @key firstLv KmonsterDataId, @value KmonsterDataConfigArray sorted by lv
    self.BehemothGroup2KMonsterData = {}
    ---@type table<number, number> @key KmonsterDataId, @value group firstLv KmonsterDataId
    self.KMonsterData2BehemothGroup = {}
    ---@type AttrDisplayConfigCell[]
    self.BehemothAttrDisplay = {}
    ---@type AllianceBehemoth[]
    self.BehemothDummyAllList = {}
    ---@type table<string, boolean>
    self._recordBehemothMap = {}
    ---@type string[]
    self._recordBehemothSave = {}
end

---@param a KmonsterDataConfigCell
---@param b KmonsterDataConfigCell
function AllianceModule_Behemoth.sortKMonsterDataByLvThenId(a, b)
    local l = a:Level() - b:Level()
    if l < 0 then
        return true
    end
    if l > 0 then
        return false
    end
    return a:Id() < b:Id()
end

function AllianceModule_Behemoth:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnMapBuildingChanged))
    table.clear(self.BehemothGroup2KMonsterData)
    table.clear(self.KMonsterData2BehemothGroup)
    table.clear(self.BehemothDummyAllList)
    for _, v in ConfigRefer.BehemothKMonsterGroup:ipairs() do
        local monsterCount = v:MonstersLength()
        if monsterCount <= 0 then
            goto continue
        end
        ---@type KmonsterDataConfigCell[]
        local g = {}
        for j = 1, monsterCount do
            local monster = ConfigRefer.KmonsterData:Find(v:Monsters(j))
            table.insert(g, monster)
        end
        table.sort(g, AllianceModule_Behemoth.sortKMonsterDataByLvThenId)
        local groupFirstMonster = g[1]
        local groupFirstMonsterId = groupFirstMonster:Id()
        self.BehemothGroup2KMonsterData[groupFirstMonsterId] = g
        local lastLv = nil
        local lastId = nil
        for _, monsterConfig in ipairs(g) do
            local monsterConfigId = monsterConfig:Id()
            if lastLv == monsterConfig:Level() then
                g_Logger.Log("In Group:%s has same lv:%s id is %s,%s", groupFirstMonsterId, lastLv, lastId, monsterConfigId)
            end
            lastLv = monsterConfig:Level()
            lastId = monsterConfigId
            local groupId = self.KMonsterData2BehemothGroup[monsterConfigId]
            if groupId then
                g_Logger.Log("Monster:%s exists in both group:%s and %s", monsterConfigId, groupId, groupFirstMonsterId)
            end
            self.KMonsterData2BehemothGroup[monsterConfigId] = groupFirstMonsterId
        end
        ::continue::
    end
    local groupTemp = {}
    for _, buildingConfig in ConfigRefer.BehemothCage:ipairs() do
        if buildingConfig:InstanceMonsterLength() > 0 and buildingConfig:BehemothTroopMonsterLength() > 0 then
            local monster = buildingConfig:InstanceMonster(1)
            local groupId = self.KMonsterData2BehemothGroup[monster]
            if groupId and not groupTemp[groupId] then
                local dummyBehemoth = AllianceBehemoth.FromKMonsterData(ConfigRefer.KmonsterData:Find(monster), ConfigRefer.KmonsterData:Find(buildingConfig:BehemothTroopMonster(1)))
                table.insert(self.BehemothDummyAllList, dummyBehemoth)
                groupTemp[groupId] = true
            end
        end
    end

    table.clear(self.BehemothAttrDisplay)
    local count = ConfigRefer.AllianceConsts:BehemothAttrDisplayLength()
    for i = 1, count do
        local v = ConfigRefer.AllianceConsts:BehemothAttrDisplay(i)
        self.BehemothAttrDisplay[#self.BehemothAttrDisplay + 1] = ConfigRefer.AttrDisplay:Find(v)
    end
    -- for _, v in ConfigRefer.AttrDisplay:ipairs() do
    --     if v:NeedCalculate() then
    --         table.insert(self.BehemothAttrDisplay, v)
    --     end
    -- end
end

function AllianceModule_Behemoth:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnMapBuildingChanged))
end

---@return number
function AllianceModule_Behemoth:GetBehemothGroupId(kMonsterId)
    return self.KMonsterData2BehemothGroup[kMonsterId]
end

---@return KmonsterDataConfigCell[]
function AllianceModule_Behemoth:GetBehemothGroup(kMonsterId)
    local groupId = self.KMonsterData2BehemothGroup[kMonsterId]
    if not groupId then return nil end
    return self.BehemothGroup2KMonsterData[groupId]
end

function AllianceModule_Behemoth:GetCurrentDeviceBuildingId()
    return self._deviceInfo and self._deviceInfo._building and self._deviceInfo._building.EntityID
end

---@return wds.BuildingStatus
function AllianceModule_Behemoth:GetCurrentDeviceBuildingStatus()
    return self._deviceInfo and self._deviceInfo._building and self._deviceInfo._building.Status
end

function AllianceModule_Behemoth:GetCurrentDeviceLevel()
    return self._deviceInfo and self._deviceInfo._level or nil
end

function AllianceModule_Behemoth:GetCurrentDeviceLevelMax()
    return self._deviceInfo and self._deviceInfo._maxLevel or nil
end

---@return AllianceBehemoth|nil
function AllianceModule_Behemoth:GetCurrentBindBehemoth()
    if not self._deviceInfo then return nil end
    local entityId = self._deviceInfo._bindBehemoth
    if entityId ~= 0 then
        return self._behemothDic[entityId]
    else
        return self._behemothDic[self._deviceInfo._building.EntityID]
    end
end

---@return number|nil
function AllianceModule_Behemoth:GetCurrentBindBehemothSummonConfigId()
    local info = self:GetCurrentBindBehemoth()
    local level = self:GetCurrentDeviceLevel()
    if info and level then
        return info:GetSummonRefKMonsterDataConfig(level):Id()
    end
end

function AllianceModule_Behemoth:GetBehemothByBuildingEntityId(id)
    return self._behemothDic[id]
end

function AllianceModule_Behemoth:GetCurrentBehemothActivityWar()
    local battles = self.module:GetMyAllianceData().AllianceActivityBattles.Battles
    for _, v in pairs(battles) do
        if v.CfgId ~= 0 then
            local config = ConfigRefer.AllianceBattle:Find(v.CfgId)
            if config:Type() == AllianceBattleType.BehemothBattle then
                return v
            end
        end
    end 
    return nil 
end

function AllianceModule_Behemoth:GetSummonerInfo()
    return self._summonerInfo
end

function AllianceModule_Behemoth:IsCurrentBehemothInSummon()
    if not self._summonerInfo then return false end
    return self._onMapBehemoth ~= nil and self._onMapBehemoth:GetVanishTime() > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

---@return AllianceBehemothOnMap|nil
function AllianceModule_Behemoth:GetCurrentInSummonBehemothInfo()
    return self._onMapBehemoth
end

---@return boolean, AllianceCurrencyConfigCell, number
function AllianceModule_Behemoth:CheckHasEnoughCurrencyForSummon()
    local costBuildingConfig = ConfigRefer.FlexibleMapBuilding:Find(ConfigRefer.AllianceConsts:SummonBehemothRefFlexibleMapBuilding())
    local currencyCost = costBuildingConfig:CostAllianceCurrency()
    local currencyCostCount = costBuildingConfig:CostAllianceCurrencyCount()
    local currencyConfig = ConfigRefer.AllianceCurrency:Find(currencyCost)
    local hasCount = ModuleRefer.AllianceModule:GetAllianceCurrencyById(currencyCost)
    return hasCount >= currencyCostCount, currencyConfig, currencyCostCount
end

---@return fun():number,AllianceBehemoth
function AllianceModule_Behemoth:PairsOfBehemoths()
    local entityId, behemoth = nil, nil
    return function()
        entityId, behemoth = next(self._behemothDic, entityId)
        if entityId and behemoth then
            return entityId, behemoth
        end
    end
end

function AllianceModule_Behemoth:OnAllianceDataReady()
    self._deviceInfo = nil
    table.clear(self._behemothDic)
    if not self.module:IsInAlliance() then return end
    local behemothMobileFortressId = ConfigRefer.AllianceConsts:SummonBehemothRefFlexibleMapBuilding()
    local mapBuilding = self.module:GetMyAllianceDataMapBuildingBriefs()
    for _, v in pairs(mapBuilding) do
        if v.EntityTypeHash == DBEntityType.BehemothCage then
            local fixedMapBuild = ConfigRefer.FixedMapBuilding:Find(v.ConfigId)
            if fixedMapBuild and fixedMapBuild:Type() == MapBuildingType.BehemothCage then
                self._behemothDic[v.EntityID] = AllianceBehemoth.FromCageBuilding(v)
            end
        elseif v.EntityTypeHash == DBEntityType.CommonMapBuilding then
            local flexibleBuilding = ConfigRefer.FlexibleMapBuilding:Find(v.ConfigId)
            if flexibleBuilding then
                if flexibleBuilding:Type() == FlexibleMapBuildingType.BehemothDevice then
                    self._deviceInfo = AllianceBehemothDeviceInfo.new(v)
                    self._behemothDic[v.EntityID] = AllianceBehemoth.FromDeviceDefault(v)
                end
                if flexibleBuilding:Type() == FlexibleMapBuildingType.BehemothSummoner then
                    self._summonerInfo = AllianceBehemothSummonerInfo.new(v)
                end
            end
        elseif v.EntityTypeHash == DBEntityType.MobileFortress then
            if v.ConfigId == behemothMobileFortressId then
                self._onMapBehemoth = AllianceBehemothOnMap.new(v)
            end
        end
    end
end

function AllianceModule_Behemoth:GenerateNotify()
    local notificationModule = ModuleRefer.NotificationModule
    local behemothListNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.BehemothListEntry, NotificationType.ALLIANCE_BEHEMOTH_LIST_ENTRY)
    notificationModule:RemoveAllChildren(behemothListNode)
    table.clear(self._recordBehemothMap)
    table.clear(self._recordBehemothSave)
    local idString = g_Game.PlayerPrefsEx:GetStringByUid("ALLIANCE_BEHEMOTH_RECORD")
    if not string.IsNullOrEmpty(idString) then
        local values = string.split(idString, ';')
        for _, v in ipairs(values) do
            self._recordBehemothMap[v] = true
            table.insert(self._recordBehemothSave, v)
        end
    end
    for _, v in pairs(self._behemothDic) do
        self:AddOnBehemothNotify(v)
    end
end

---@param behemoth AllianceBehemoth
function AllianceModule_Behemoth:AddOnBehemothNotify(behemoth)
    local id = tostring(behemoth:GetBuildingEntityId())
    if self._recordBehemothMap[id] then return end
    local notificationModule = ModuleRefer.NotificationModule
    local behemothListNode = notificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.BehemothListEntry, NotificationType.ALLIANCE_BEHEMOTH_LIST_ENTRY)
    local key = AllianceModuleDefine.GetNotifyKeyForBehemoth(behemoth)
    local node = notificationModule:GetOrCreateDynamicNode(key, NotificationType.ALLIANCE_BEHEMOTH_NEW)
    notificationModule:AddToParent(node, behemothListNode)
    notificationModule:SetDynamicNodeNotificationCount(node, 1)
end

---@param behemoth AllianceBehemoth
function AllianceModule_Behemoth:MarkBehemothNotify(behemoth, remove)
    local id = tostring(behemoth:GetBuildingEntityId())
    if remove then
        if not self._recordBehemothMap[id] then return end
        self._recordBehemothMap[id] = nil
        table.removebyvalue(self._recordBehemothSave, id, true)
    else
        if self._recordBehemothMap[id] then return end
        self._recordBehemothMap[id] = true
        table.insert(self._recordBehemothSave, id)
    end
    local notificationModule = ModuleRefer.NotificationModule
    local behemothListNode = notificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.BehemothListEntry, NotificationType.ALLIANCE_BEHEMOTH_LIST_ENTRY)
    if behemothListNode then
        local key = AllianceModuleDefine.GetNotifyKeyForBehemoth(behemoth)
        local node = notificationModule:GetDynamicNode(key, NotificationType.ALLIANCE_BEHEMOTH_NEW)
        if node then
            notificationModule:SetDynamicNodeNotificationCount(node, 0)
            notificationModule:RemoveFromParent(node, behemothListNode)
        end
    end
    local saved = table.concat(self._recordBehemothSave, ';')
    g_Game.PlayerPrefsEx:SetStringByUid("ALLIANCE_BEHEMOTH_RECORD", saved)
    g_Game.PlayerPrefsEx:Save()
end

---@param entity wds.Alliance
function AllianceModule_Behemoth:OnMapBuildingChanged(entity, changedData)
    if not self.module:IsInAlliance() then return end
    if entity.ID ~= self.module:GetAllianceId() then return end
    local behemothMobileFortressId = ConfigRefer.AllianceConsts:SummonBehemothRefFlexibleMapBuilding() 
    local add, remove, changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.MapBuildingBrief)
    if add then
        for _, v in pairs(add) do
            if v.EntityTypeHash == DBEntityType.BehemothCage then
                local fixedMapBuild = ConfigRefer.FixedMapBuilding:Find(v.ConfigId)
                if fixedMapBuild and fixedMapBuild:Type() == MapBuildingType.BehemothCage then
                    self._behemothDic[v.EntityID] = AllianceBehemoth.FromCageBuilding(v)
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_ADD, v.EntityID)
                end
            elseif v.EntityTypeHash == DBEntityType.CommonMapBuilding then
                local flexibleBuilding = ConfigRefer.FlexibleMapBuilding:Find(v.ConfigId)
                if flexibleBuilding then
                    if flexibleBuilding:Type() == FlexibleMapBuildingType.BehemothDevice then
                        self._deviceInfo = AllianceBehemothDeviceInfo.new(v)
                        local behemoth = AllianceBehemoth.FromDeviceDefault(v)
                        self._behemothDic[v.EntityID] = behemoth
                        self:AddOnBehemothNotify(behemoth)
                        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_DEVICE_ADD, v.EntityID)
                        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_ADD, v.EntityID)
                        self:OnAddBehemothDevice(v)
                    elseif flexibleBuilding:Type() == FlexibleMapBuildingType.BehemothSummoner then
                        self._summonerInfo = AllianceBehemothSummonerInfo.new(v)
                        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_SUMMONER_ADD, v.EntityID)
                        self:OnAddBehemothSummor(v)
                    end
                end
            elseif v.EntityTypeHash == DBEntityType.MobileFortress then
                if v.ConfigId == behemothMobileFortressId then
                    self:AddOrUpdateBehemothOnMap(v)
                end
            end
        end
    end
    if remove then
        for _, v in pairs(remove) do
            if self._behemothDic[v.EntityID] then
                g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_PRE_REMOVE, v.EntityID)
                local oldBehemoth = self._behemothDic[v.EntityID]
                self._behemothDic[v.EntityID] = nil
                g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_REMOVED, v.EntityID)
                if oldBehemoth then
                    self:MarkBehemothNotify(oldBehemoth, true)
                end
            end
            if v.EntityTypeHash == DBEntityType.CommonMapBuilding then
                if self._deviceInfo and self._deviceInfo._building.EntityID == v.EntityID then
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_DEVICE_PRE_REMOVED, v.EntityID)
                    self._deviceInfo = nil
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_DEVICE_REMOVED, v.EntityID)
                end
                if self._summonerInfo and self._summonerInfo._building.EntityID == v.EntityID then
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_SUMMONER_PRE_REMOVED, v.EntityID)
                    self._summonerInfo = nil
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_SUMMONER_REMOVED, v.EntityID)
                end
            elseif v.EntityTypeHash == DBEntityType.MobileFortress then
                if v.ConfigId == behemothMobileFortressId then
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_RPE_REMOVED, v.EntityID)
                    self._onMapBehemoth = nil
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, v.EntityID)
                end
            end
        end
    end
    if changed then
        for _, v in pairs(changed) do
            local oldV = v[1]
            local behemoth = self._behemothDic[oldV.EntityID]
            if behemoth then
                behemoth:UpdateBuildingEntity(v[2])
                g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_UPDATE, oldV.EntityID)
            end
            if oldV.EntityTypeHash == DBEntityType.CommonMapBuilding then
                if self._deviceInfo and self._deviceInfo._building.EntityID == oldV.EntityID then
                    self._deviceInfo:UpdateBuilding(v[2])
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, oldV.EntityID)
                end
                if self._summonerInfo and self._summonerInfo._building.EntityID == oldV.EntityID then
                    self._summonerInfo:UpdateBuilding(v[2])
                    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_SUMMONER_UPDATE, oldV.EntityID)
                end
            elseif oldV.EntityTypeHash == DBEntityType.MobileFortress then
                if oldV.ConfigId == behemothMobileFortressId and v[2].ConfigId == behemothMobileFortressId then
                    self:AddOrUpdateBehemothOnMap(v[2])
                end
            end
        end
    end
end

---@param building wds.MapBuildingBrief
function AllianceModule_Behemoth:AddOrUpdateBehemothOnMap(building)
    if self._onMapBehemoth then
        local id = self._onMapBehemoth._building.EntityID
        if id == building.EntityID then
            self._onMapBehemoth:UpdateBuilding(building)
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, building.EntityID)
            return
        else
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_RPE_REMOVED, id)
            self._onMapBehemoth = nil
            g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, id)
        end
    end
    self._onMapBehemoth = AllianceBehemothOnMap.new(building)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, building.EntityID)
    ---@type KingdomScene
    local currentScene = g_Game.SceneManager.current
    if not currentScene or currentScene:GetName() ~= "KingdomScene" or currentScene:IsInCity() then return end
    ---@type wds.MobileFortress
    local mobileFortress = g_Game.DatabaseManager:GetEntity(building.EntityID, building.EntityTypeHash)
    if not mobileFortress then return end
    ---@type AllianceBehemothCallBannerMediatorParameter
    local parameter = {}
    parameter.abbr = mobileFortress.Owner.AllianceAbbr.String
    parameter.allianceName = mobileFortress.Owner.AllianceName.String
    parameter.kMonsterConfig = ConfigRefer.KmonsterData:Find(mobileFortress.BehemothTroopInfo.MonsterTid)
    parameter.level = self:GetCurrentDeviceLevel()
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothCallBannerMediator, parameter)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param posX wds.Vector3F
---@param posY wds.Vector3F
---@param configId number
function AllianceModule_Behemoth:BuildBehemothDevice(lockable, posX, posY, configId)
    local sendCmd = AllianceParameters.BuildBehemothDeviceParameter.new()
    sendCmd.args.Pos.X = posX
    sendCmd.args.Pos.Y = posY
    sendCmd.args.ConfigId = configId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param targetId number
function AllianceModule_Behemoth:RemoveBehemothDevice(lockable, targetId)
    local sendCmd = AllianceParameters.RemoveBehemothDeviceParameter.new()
    sendCmd.args.TargetId = targetId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param posX wds.Vector3F
---@param posY wds.Vector3F
---@param configId number
function AllianceModule_Behemoth:BuildBehemothSummoner(lockable, posX, posY, configId)
    local sendCmd = AllianceParameters.BuildBehemothSummonerParameter.new()
    sendCmd.args.Pos.X = posX
    sendCmd.args.Pos.Y = posY
    sendCmd.args.ConfigId = configId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param targetId number
function AllianceModule_Behemoth:RemoveBehemothSummoner(lockable, targetId)
    local sendCmd = AllianceParameters.RemoveBehemothSummonerParameter.new()
    sendCmd.args.TargetId = targetId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
function AllianceModule_Behemoth:SummonBehemoth(lockable, summonerId, configId, targetId)
    local sendCmd = AllianceParameters.SummonBehemothParameter.new()
    sendCmd.args.SummonerId = summonerId
    sendCmd.args.ConfigId = configId
    sendCmd.args.TargetId = targetId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
function AllianceModule_Behemoth:BindBehemoth(lockable, deviceId, cageId)
    local sendCmd = AllianceParameters.BindBehemothParameter.new()
    sendCmd.args.DeviceId = deviceId
    sendCmd.args.BehemothCageId = cageId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
function AllianceModule_Behemoth:UnbindBehemoth(lockable, deviceId)
    local sendCmd = AllianceParameters.UnbindBehemothParameter.new()
    sendCmd.args.DeviceId = deviceId
    sendCmd:SendOnceCallback(lockable)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param id number
---@param userdata any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule_Behemoth:ReadyBehemothBattleNow(lockable, id , userdata, callback)
    local sendCmd = AllianceParameters.PrepareWarOnVillageParameter.new()
    sendCmd.args.TargetId = id
    sendCmd:SendOnceCallback(lockable, userdata, nil, callback)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param id number
---@param userdata any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function AllianceModule_Behemoth:StartBehemothBattleNow(lockable, id , userdata, callback)
    local sendCmd = AllianceParameters.StartAllianceBattleLevelProcessParameter.new()
    sendCmd.args.Id = id
    sendCmd.args.Type = wrpc.AllianceBattleLevelType.AllianceBattleLevelTypeBehemoth
    sendCmd:SendOnceCallback(lockable, userdata, nil, callback)
end

---@param allianceBehemoth AllianceBehemoth
---@return boolean,SystemEntryConfigCell
function AllianceModule_Behemoth:IsBehemothUnLocked(allianceBehemoth)
	if not allianceBehemoth or not allianceBehemoth._cageBuildingConfig then
        return true, nil
    end

	local unlockEntryId = allianceBehemoth._cageBuildingConfig:AttackSystemSwitch()
	if unlockEntryId == 0 then
        return true, nil
    end

	local lockConfig = ConfigRefer.SystemEntry:Find(unlockEntryId)
    local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockEntryId)
    return unlocked, lockConfig
end

function AllianceModule_Behemoth:GetBehemothUnLockedTips(unlockEntryId)
    local openTime = ModuleRefer.KingdomModule:GetKingdomTime()
    if openTime == 0 then -- 服务器当前小于100人
        return I18N.Get("adornment_castleskin1_recharge_14_name")
    end

    local timeAfterOpenServer = ConfigRefer.SystemEntry:Find(unlockEntryId):UnlockServerOpenTime()
    timeAfterOpenServer = ConfigTimeUtility.NsToSeconds(timeAfterOpenServer)
    timeAfterOpenServer = ModuleRefer.KingdomModule:GetTimeAfterOpenServer(timeAfterOpenServer)
    local timeStr = TimeFormatter.TimeToDateTimeStringUseFormat(timeAfterOpenServer, "MM/dd/yyyy hh:mm:ss")
    timeStr = ("UTC %s"):format(timeStr)
    local tip = I18N.GetWithParams("alliance_behemoth_tipss1", timeStr)
    return tip
end

function AllianceModule_Behemoth:IsBehemothCageInActivityBattle(cageEntityId)
    if not ModuleRefer.AllianceModule:IsInAlliance() then return false end
    local behemoth = self._behemothDic[cageEntityId]
    if not behemoth or (not behemoth:IsFromCage() and not behemoth:IsDeviceDefault()) then return false end
    local data = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not data or not data.AllianceActivityBattles or not data.AllianceActivityBattles.Battles then return false end
    for _, v in pairs(data.AllianceActivityBattles.Battles) do
        local config = ConfigRefer.AllianceBattle:Find(v.CfgId)
        if config and config:Type() == AllianceBattleType.BehemothBattle 
            and (v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated 
                or v.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling) then
            return true
        end
    end
    return false
end

---@param buildingData wds.MapBuildingBrief
function AllianceModule_Behemoth:OnAddBehemothDevice(buildingData)
    if not ModuleRefer.AllianceModule:IsInAlliance() then return false end
    local config = ConfigRefer.FlexibleMapBuilding:Find(buildingData.ConfigId)
    ---@type CommonNotifyPopupMediatorParameter
    local param = {}
    param.funcType = ToastFuncType.BuildingLevelUp
    param.title = I18N.Get("alliance_behemoth_banner_device")
    param.content = I18N.Get("alliance_behemoth_banner_deviceSupport")
    param.textBlood = "0%"
    param.icon = ArtResourceUtils.GetUIItem(config:Image())
    param.btnText = I18N.Get("alliance_behemoth_power_buildDevice")
    param.duration = 5
    param.acceptAction = function()
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.SceneUI)
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
        AllianceWarTabHelper.GoToCoord(buildingData.Pos.X,buildingData.Pos.Y, true)
    end
    ModuleRefer.ToastModule:CustomeAddNoticeToast(param)
end

---@param buildingData wds.MapBuildingBrief
function AllianceModule_Behemoth:OnAddBehemothSummor(buildingData)
    if not ModuleRefer.AllianceModule:IsInAlliance() then return false end
    local config = ConfigRefer.FlexibleMapBuilding:Find(buildingData.ConfigId)
    ---@type CommonNotifyPopupMediatorParameter
    local param = {}
    param.funcType = ToastFuncType.BuildingLevelUp
    param.title = I18N.Get("alliance_behemoth_banner_summon")
    param.content = I18N.Get("alliance_behemoth_banner_SummonSupport")
    param.textBlood = "0%"
    param.icon = ArtResourceUtils.GetUIItem(config:Image())
    param.btnText = I18N.Get("alliance_behemoth_power_buildSummon")
    param.duration = 5
    param.acceptAction = function()
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.SceneUI)
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
        AllianceWarTabHelper.GoToCoord(buildingData.Pos.X,buildingData.Pos.Y, true)
    end
    ModuleRefer.ToastModule:CustomeAddNoticeToast(param)
end

---@return table<number, AllianceWarActivityCell>
function AllianceModule_Behemoth:GenerateActivityCells()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActivityBattleDataChanged))
    self._activityBattleCells = nil
    local deviceStatus = self:GetCurrentDeviceBuildingStatus()
    if not deviceStatus or deviceStatus ~= wds.BuildingStatus.BuildingStatus_Constructed then return nil end
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceActivityBattles or not allianceData.AllianceActivityBattles.Battles then return nil end
    self._activityBattleCells = {}
    for id, value in pairs(allianceData.AllianceActivityBattles.Battles) do
        local config = ConfigRefer.AllianceBattle:Find(value.CfgId)
        if config and config:Type() == AllianceBattleType.BehemothBattle then
            if value.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated or value.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
                local cellData = AllianceActivityCellDataGve.new(id, value)
                self._activityBattleCells[id] = cellData
            end
        end
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActivityBattleDataChanged))
    return self._activityBattleCells
end

function AllianceModule_Behemoth.CheckCall(func, ...)
    if not func then return end
    func(...)
end

---@param entity wds.Alliance
function AllianceModule_Behemoth:OnAllianceActivityBattleDataChanged(entity, changedData)
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not self._activityBattleCells or not entity or not allianceData or entity.ID ~= allianceData then return end
    local add,remove,change = OnChangeHelper.GenerateMapComponentFieldChangeMap(changedData, wds.AllianceActivityBattleInfo)
    if remove then
        for id, _ in pairs(remove) do
            local oldData = self._activityBattleCells[id]
            if oldData then
                self._activityBattleCells[id] = nil
                AllianceModule_Behemoth.CheckCall(self._activityCellDataRemove, oldData)
            end
        end
    end
    if change then
        for id, value in pairs(change) do
            local cellData = self._activityBattleCells[id]
            if cellData then
                if value.Status ~= wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated
                    and value.Status ~= wds.AllianceActivityBattleStatus.AllianceBattleStatusWaiting
                    and value.Status ~= wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling
                then
                    self._activityBattleCells[id] = nil
                    AllianceModule_Behemoth.CheckCall(self._activityCellDataRemove, cellData)
                else
                    cellData = AllianceActivityCellDataGve.new(id, value)
                    self._activityBattleCells[id] = cellData
                    AllianceModule_Behemoth.CheckCall(self._activityCellDataUpdate, cellData)
                end
            else
                g_Logger.Warn("update but not tracked:%s", id)
            end
        end
    end
    if add then
        for id, value in pairs(add) do
            local cellData = self._activityBattleCells[id]
            if cellData then
                g_Logger.Warn("add but tracked:%s", id)
            else
                local config = ConfigRefer.AllianceBattle:Find(value.CfgId)
                if config and config:Type() == AllianceBattleType.BehemothBattle then
                    if value.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated
                        or value.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusWaiting
                        or value.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling
                    then
                        cellData = AllianceActivityCellDataGve.new(id, value)
                        self._activityBattleCells[id] = cellData
                        AllianceModule_Behemoth.CheckCall(self._activityCellDataAdd, cellData)
                    end
                end
            end
        end
    end
end

function AllianceModule_Behemoth:ReleaseActivityCells()
    self._activityBattleCells = nil
    self._activityCellDataAdd = nil
    self._activityCellDataRemove = nil
    self._activityCellDataUpdate = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceActivityBattleDataChanged))
end

---@param onAdd setAllianceActivityCellCallback
---@param onRemove setAllianceActivityCellCallback
---@param onUpdate setAllianceActivityCellCallback
function AllianceModule_Behemoth:SetActivityCellsDataChange(onAdd, onRemove, onUpdate)
    self._activityCellDataAdd = onAdd
    self._activityCellDataRemove = onRemove
    self._activityCellDataUpdate = onUpdate
end

return AllianceModule_Behemoth
