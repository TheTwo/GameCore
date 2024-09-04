local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local BaseModule = require("BaseModule")
local DBEntityType = require("DBEntityType")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local TimeFormatter = require("TimeFormatter")
local AttrValueType = require("AttrValueType")
local ProtocolId = require("ProtocolId")
local Delegate = require("Delegate")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local NumberFormatter = require("NumberFormatter")
local AllianceCurrencyType = require("AllianceCurrencyType")
local ConfigTimeUtility = require("ConfigTimeUtility")
local MapBuildingSubType = require("MapBuildingSubType")
local EventConst = require("EventConst")
local MapConfigCache = require("MapConfigCache")
local VillageSubType = require("VillageSubType")
local MapBuildingType = require("MapBuildingType")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local VillageType = require("VillageType")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local KingdomMapUtils = require("KingdomMapUtils")
local QueuedTask = require('QueuedTask')
local ManualResourceConst = require("ManualResourceConst")
local UIHelper = require("UIHelper")
local ChatShareUtils = require("ChatShareUtils")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")

local DeclareWarOnVillageParameter = require("DeclareWarOnVillageParameter")
local CancelDeclareWarOnVillageParameter = require("CancelDeclareWarOnVillageParameter")
local DropVillageParameter = require("DropVillageParameter")
local CancelDropVillageParameter = require("CancelDropVillageParameter")
local CancelAllianceAssembleTroopParameter = require("CancelAllianceAssembleTroopParameter")
local LaunchAllianceAssembleTroopParameter = require("LaunchAllianceAssembleTroopParameter")

---@class VillageModule : BaseModule
local VillageModule = class("VillageModule", BaseModule)

function VillageModule:ctor()
    BaseModule.ctor(self)
    ---@type {t:number,p:wrpc.VillageReportParam,endQueueTriggerGuide:number}[]
    self._delayShowQueue = {}
    self._delayTimeSec = 5
    self._globalAutoGrowSpeedTimeCityAttrType = nil
	---@type table<number, table<string, string>>
	self.villageIconNameCache = {}
	---@type table<number, table<string, string>>
	self.villageAllianceCenterIconNameCache = {}
    ---@type table<number, table<number, table<number, FixedMapBuildingConfigCell>>>
    self.villageLevelConfigMap = {}
    self.currentInViewVillageTypeHash = nil
    self.currentInViewVillageId = nil
    self.currentInViewVillageIdIndex = 0
end

function VillageModule:OnRegister()
    self._delayTimeSec = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AllianceVillageOccupyPushReportDelay())
    table.clear(self.villageIconNameCache)
    table.clear(self.villageAllianceCenterIconNameCache)
    table.clear(self.villageLevelConfigMap)
    self._globalAutoGrowSpeedTimeCityAttrType = nil
    local attrType = ConfigRefer.ConstMain:ItemAutoGrowSpeedTime()
    local attrTypeConfig = ConfigRefer.AttrType:Find(attrType)
    if attrTypeConfig then
        self._globalAutoGrowSpeedTimeCityAttrType = attrTypeConfig:CityAttr()
    end
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.OccupyVillageReport, Delegate.GetOrCreate(self, self.OnServerPushOccupyVillageReport))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.NotifyLaunchAllianceAssembleTroop, Delegate.GetOrCreate(self, self.OnServerPushEscrowTroopWillLaunch))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.DelayShowSuccessNotice))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    for _, v in ConfigRefer.FixedMapBuilding:ipairs() do
        if v:Type() == MapBuildingType.Town then
            local subType = v:SubType()
            if subType == MapBuildingSubType.Stronghold or subType == MapBuildingSubType.City then
                local preFix = v:IconPrefix()
                if not string.IsNullOrEmpty(preFix) then
                    local subTypeSet = table.getOrCreate(self.villageLevelConfigMap, subType)
                    local villageSub = v:VillageSub()
                    local lv = v:Level()
                    local lvSet = table.getOrCreate(subTypeSet, villageSub)
                    if not lvSet[lv] then
                        lvSet[lv] = v
                    end
                end
            end
        end
    end
end

function VillageModule:OnRemove()
	table.clear(self.villageIconNameCache)
	table.clear(self.villageAllianceCenterIconNameCache)

    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.OccupyVillageReport, Delegate.GetOrCreate(self, self.OnServerPushOccupyVillageReport))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.NotifyLaunchAllianceAssembleTroop, Delegate.GetOrCreate(self, self.OnServerPushEscrowTroopWillLaunch))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.DelayShowSuccessNotice))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

---@return table<number, wds.MapBuildingBrief>
function VillageModule:GetAllVillageMapBuildingBrief()
    local ret = {}
    local buildings = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for i, v in pairs(buildings) do
        if (v.EntityTypeHash == DBEntityType.Village or v.EntityTypeHash == DBEntityType.Pass)
                and v.Status ~= wds.BuildingStatus.BuildingStatus_None
                and v.Status ~= wds.BuildingStatus.BuildingStatus_GiveUped  then
            ret[i] = v
        end
    end
    return ret
end

function VillageModule:HasDeclareWarOnVillage(villageId)
    local villageWar = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    local warRecord = villageWar[villageId]
    if not warRecord then
        return false
    end
    if warRecord.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_None then
        return false
    end
    if warRecord.EndTime <= g_Game.ServerTime:GetServerTimestampInSeconds() then
        return false
    end
    return true
end

function VillageModule:HasAnyDeclareWarOnVillage()
    local villageWar = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    return not table.isNilOrZeroNums(villageWar)
end

function VillageModule:HasAnyDeclareWarOnCage()
    local cageWar = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()
    return not table.isNilOrZeroNums(cageWar)
end

---@param cage wds.BehemothCage
---@return boolean
function VillageModule:CageHasCanDelareWarTimeRange(cage)
    if table.isNilOrZeroNums(cage.VillageWar.AllianceWar) then
        return true
    end
    local fixedBuildingConfig = ConfigRefer.FixedMapBuilding:Find(cage.BehemothCage.ConfigId)
    local cageConfig = ConfigRefer.BehemothCage:Find(fixedBuildingConfig:BehemothCageConfig())
    local matchCount = 0
    for i = 1, cageConfig:AttackActivityLength() do
        local templateId = cageConfig:AttackActivity(i)
        local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(templateId)
        if endTime and endTime.ServerSecond > 0 then
            local used = false
            for _, value in pairs(cage.VillageWar.AllianceWar) do
                if value.StartTime >= startTime.ServerSecond and value.StartTime <= endTime.ServerSecond then
                    used = true
                    break
                end
                if value.EndTime >= startTime.ServerSecond and value.EndTime <= endTime.ServerSecond then
                    used = true
                    break
                end
            end
            if not used then
                matchCount = matchCount + 1
            end
        end
    end
    return (matchCount > 0)
end

---@return boolean, wds.VillageAllianceWarInfo
function VillageModule:HasDeclareWarOnCage(cageId)
    local cageWar = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()
    local warRecord = cageWar[cageId]
    if not warRecord then
        return false
    end
    if warRecord.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_None then
        return false
    end
    if warRecord.EndTime <= g_Game.ServerTime:GetServerTimestampInSeconds() then
        return false
    end
    return true, warRecord
end

---@return wds.VillageAllianceWarInfos|nil
function VillageModule:OwnCageHasDeclareWar(cageId)
    local cageWar = ModuleRefer.AllianceModule:GetMyAllianceOwnedBehemothCageWar()
    return cageWar[cageId]
end

---@param village wds.Village
---@return boolean, string
function VillageModule:GetCanRebuildVillageToast(village)
    --权限检查
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not ModuleRefer.AllianceModule:IsInAlliance() or not allianceData then
        return false, I18N.Get("village_toast_join_the_alliance")
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage) then
        return false, I18N.Get("village_toast_Set_time_3")
    end

    local FixedMapBuilding = ConfigRefer.FixedMapBuilding
    local configId = village.MapBasics.ConfID
    local targetVillageConfig = FixedMapBuilding:Find(configId)
    local targetVillageName = I18N.Get(targetVillageConfig:Name())
    local targetVillageLv = targetVillageConfig:Level()
    local targetVillageSubType = targetVillageConfig:VillageSub()
    local isCity = targetVillageConfig:SubType() == MapBuildingSubType.City

    local lvCountMap, typeCountMap, hasVillage = self:GetLevelAndTypeCountMap(FixedMapBuilding, isCity)

    --初始不能重建
    if not hasVillage then
        return false, I18N.Get("village_toast_starting_point_build")
    end
    
    --接壤检查
    if hasVillage and not ModuleRefer.TerritoryModule:IsEntityConnected(village.ID,DBEntityType.Village) then
        return false,I18N.Get("village_outpost_info_bordering")
    end

    --080版本，去掉乡镇逐级打的限制
    --local levelMatch = false
    --if targetVillageLv <= 1 then
    --    levelMatch = true
    --end
    --if not levelMatch then
    --    if allianceData.AllianceVillageWar.MaxLevel <= 0 then
    --        return false,I18N.Get("village_toast_Set_time_4")
    --    end
    --    if targetVillageLv > (allianceData.AllianceVillageWar.MaxLevel + 1) then
    --        return false,I18N.Get("village_toast_not_occupy_lower")
    --    end
    --end
    

    --服务器等级开放要求
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local unlockEntryId = targetVillageConfig:AttackSystemSwitch()
    if unlockEntryId ~= 0 then
        if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockEntryId) then
            return false, ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(unlockEntryId)
        end
    end

    --联盟建设令数量检查
    local rebuildConfig = ConfigRefer.BuildingRebuildTemplate:Find(targetVillageConfig:RuinRebuild())
    local needCurrencyId = rebuildConfig:StartCostCurrencyType()
    local needCount = rebuildConfig:StartCostCurrencyNum()
    local hasCount = 0
    for currencyId, currencyCount in pairs(allianceData.AllianceCurrency.Currency) do
        if currencyId == needCurrencyId then
            hasCount = hasCount + currencyCount
        end
    end
    if hasCount < needCount then
        return false,I18N.Get("village_outpost_construction_orders_insufficient")
    end
    
    --保护检查
    if village.MapStates.StateWrapper.Invincible then
        return false,I18N.Get("village_toast_Set_time_8")
    end
    if village.MapStates.StateWrapper.ProtectionExpireTime > nowTime then
        return false,I18N.Get("village_toast_Set_time_8")
    end
    
    --占领数量上限检查
    local lvHasCount = lvCountMap[targetVillageLv] or 0
    local limitCount = ModuleRefer.VillageModule:GetVillageOwnCountLimitByLevel(targetVillageLv, isCity) or 0
    if lvHasCount >= limitCount then
        return false,I18N.GetWithParams("village_outpost_info_upper_limit", targetVillageLv, targetVillageName)
    end
    if targetVillageSubType ~= VillageSubType.Undefine then
        local subTypeCount = typeCountMap[targetVillageSubType] or 0
        limitCount = ModuleRefer.VillageModule:GetVillageOwnCountLimitBySubType(targetVillageSubType) or 0
        if subTypeCount >= limitCount then
            return false,I18N.Get("village_toast_Set_time_10")
        end
    end

    return true,string.Empty
end

---@param village wds.Village
---@return boolean, string
function VillageModule:GetCanSignAttackVillageToast(village)
    --权限检查
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not ModuleRefer.AllianceModule:IsInAlliance() or not allianceData then
        return false, I18N.Get("village_toast_join_the_alliance")
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage) then
        return false, I18N.Get("village_toast_Set_time_3")
    end
    if self:HasDeclareWarOnVillage(village.ID) then
        return false,I18N.Get("village_toast_already_declared")
    end
    --前置检查 (不可跨级)
    --接壤检查 (非首个必须接壤)
    local levelMatch = false
    local FixedMapBuilding = ConfigRefer.FixedMapBuilding
    local configId = village.MapBasics.ConfID
    local targetVillageConfig = FixedMapBuilding:Find(configId)
    local targetVillageLv = targetVillageConfig:Level()
    local targetVillageSubType = targetVillageConfig:VillageSub()
    local isCity = targetVillageConfig:SubType() == MapBuildingSubType.City
    
    ----080版本，去掉乡镇逐级打的限制
    --if targetVillageLv <= 1 then
    --    levelMatch = true
    --end
    --if not levelMatch then
    --    if allianceData.AllianceVillageWar.MaxLevel <= 0 then
    --        return false,I18N.Get("village_toast_Set_time_4")
    --    end
    --    if targetVillageLv > (allianceData.AllianceVillageWar.MaxLevel + 1) then
    --        return false,I18N.Get("village_toast_not_occupy_lower")
    --    end
    --end

    local lvCountMap, typeCountMap, hasVillage = self:GetLevelAndTypeCountMap(FixedMapBuilding, isCity)

    if not hasVillage then
        local find 
        for i = 1, ConfigRefer.AllianceConsts:AllianceFirstOccupyVillageTypeLength() do
            if ConfigRefer.AllianceConsts:AllianceFirstOccupyVillageType(i) == village.MapBasics.ConfID then
                find = true
                break
            end
        end
        if not find then
            return false,I18N.Get("village_toast_starting_point_declare")
        end
    end

    if hasVillage and not ModuleRefer.TerritoryModule:IsEntityConnected(village.ID,DBEntityType.Village) then
        return false,I18N.Get("village_toast_Set_time_5")
    end
    --服务器等级开放要求
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local unlockEntryId = targetVillageConfig:AttackSystemSwitch()
    if unlockEntryId ~= 0 then
        if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockEntryId) then
            return false, ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(unlockEntryId)
        end
    end
    --if village.VillageWar.SeasonStartTime then
    --    local leftStartTime = village.VillageWar.SeasonStartTime.Seconds + targetVillageConfig:SeasonBeginLockTime() - nowTime
    --    if leftStartTime > 0 then
    --        return false,I18N.GetWithParams("village_toast_Set_time_6", TimeFormatter.SimpleFormatTimeWithDay(leftStartTime))
    --    end
    --end
    --联盟宣战令数量检查
    local needCurrencyId = targetVillageConfig:AllianceDeclareCostCurrencyType()
    local needCount = targetVillageConfig:AllianceDeclareCostCurrencyNum()
    local hasCount = 0
    for currencyId, currencyCount in pairs(allianceData.AllianceCurrency.Currency) do
        if currencyId == needCurrencyId then
            hasCount = hasCount + currencyCount
        end
    end
    if hasCount < needCount then
        return false,I18N.Get("village_toast_Set_time_7")
    end
    --保护检查
    if village.MapStates.StateWrapper.Invincible then
        return false,I18N.Get("village_toast_Set_time_8")
    end
    if village.MapStates.StateWrapper.ProtectionExpireTime > nowTime then
        return false,I18N.Get("village_toast_Set_time_8")
    end
    --占领数量上限检查
    local lvHasCount = lvCountMap[targetVillageLv] or 0
    local limitCount = ModuleRefer.VillageModule:GetVillageOwnCountLimitByLevel(targetVillageLv, isCity) or 0
    if lvHasCount >= limitCount then
        return false,I18N.Get("village_toast_Set_time_10")
    end
    if targetVillageSubType ~= VillageSubType.Undefine then
        local subTypeCount = typeCountMap[targetVillageSubType] or 0
        limitCount = ModuleRefer.VillageModule:GetVillageOwnCountLimitBySubType(targetVillageSubType) or 0
        if subTypeCount >= limitCount then
            return false,I18N.Get("village_toast_Set_time_10")
        end
    end
    return true,string.Empty
end

---@param cage wds.BehemothCage
---@return boolean, string
function VillageModule:GetCanSignAttackCageToast(cage)
    --权限检查
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false, I18N.Get("alliance_behemoth_Declare_alliance")
    end
    
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareBehemothWar) then
        return false, I18N.Get("alliance_behemoth_Declare_manage")
    end
        --接壤检查
    if not ModuleRefer.TerritoryModule:IsEntityConnected(cage.ID,DBEntityType.BehemothCage) then
        return false,I18N.Get("alliance_behemoth_Declare_near")
    end
    
    if self:HasAnyDeclareWarOnCage() then
        return false,I18N.Get("alliance_behemoth_state_DeclareOther")
    end
    if self:HasDeclareWarOnCage(cage.ID) then
        return false,I18N.Get("village_toast_already_declared")
    end
    -- if not table.isNilOrZeroNums(cage.VillageWar.AllianceWar) then
    --     return false,I18N.Get("alliance_behemoth_state_declared")
    -- end
    if not self:CageHasCanDelareWarTimeRange(cage) then
        return false,I18N.Get("alliance_behemoth_state_declared")
    end
    local FixedMapBuilding = ConfigRefer.FixedMapBuilding
    local configId = cage.BehemothCage.ConfigId
    local targetVillageConfig = FixedMapBuilding:Find(configId)
    --服务器开放要求
    local unlockEntryId = targetVillageConfig:AttackSystemSwitch()
    if unlockEntryId ~= 0 then
        if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockEntryId) then
            return false, ModuleRefer.AllianceModule.Behemoth:GetBehemothUnLockedTips(unlockEntryId)
        end
    end
    
    --080 需求去掉巨兽装置限制
    --if ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingStatus() ~= wds.BuildingStatus.BuildingStatus_Constructed then
    --    return false, I18N.Get("alliance_behemoth_Declare_device")
    --end
    
    --保护检查
    -- if cage.MapStates.StateWrapper.Invincible then
    --     return false,I18N.Get("alliance_behemoth_state_protect")
    -- end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if cage.MapStates.StateWrapper.ProtectionExpireTime > nowTime then
        return false,I18N.Get("alliance_behemoth_state_protect")
    end
    local cageConfig = ConfigRefer.BehemothCage:Find(targetVillageConfig:BehemothCageConfig())
    local cageMonster = cageConfig:InstanceMonster(1)
    local cageMonsterGroupId = ModuleRefer.AllianceModule.Behemoth:GetBehemothGroupId(cageMonster)
    for _, value in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
        if value:GetBehemothGroupId() == cageMonsterGroupId then
            return false, I18N.Get("alliance_behemoth_cage_repeat")
        end
    end
    return true,string.Empty
end

---@param FixedMapBuilding FixedMapBuildingConfig
function VillageModule:GetLevelAndTypeCountMap(FixedMapBuilding, isCity)
    local lvCountMap = {}
    local typeCountMap = {}
    local hasVillage = false
    local villages = self:GetAllVillageMapBuildingBrief()
    for _, v in pairs(villages) do
        local config = FixedMapBuilding:Find(v.ConfigId)
        if config then
            hasVillage = true
            typeCountMap[config:VillageSub()] = (typeCountMap[config:VillageSub()] or 0 ) + 1
            local curIsCity = config:SubType() == MapBuildingSubType.City
            if curIsCity == isCity then
                local lv = config:Level()
                lvCountMap[lv] = (lvCountMap[lv] or 0) + 1
            end
        end
    end
    return lvCountMap, typeCountMap, hasVillage
end

---@param village wds.Village
---@param showToast boolean
---@return boolean
function VillageModule:CheckCanCancelDeclare(village, showToast )
    --权限检查
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_26003"))
        end
        return false
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_NoPermission_toast"))
        end
        return false
    end
    if not self:HasDeclareWarOnVillage(village.ID) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_not_declare"))
        end
        return false
    end
    return true
end

---@param behemoth wds.BehemothCage
---@param showToast boolean
---@return boolean
function VillageModule:CheckCanCancelDeclareOnBehemothCage(behemoth, showToast)
    --权限检查
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_26003"))
        end
        return false
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareBehemothWar) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_NoPermission_toast"))
        end
        return false
    end
    local has, warInfo = self:HasDeclareWarOnCage(behemoth.ID)
    if not has then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_not_declare"))
        end
        return false
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if warInfo.StartTime <= nowTime and warInfo.EndTime >= nowTime then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_battle_has_begun"))
        end
        return false
    end
    if warInfo.Status ~= wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_unable_declare"))
        end
        return false
    end
    return true
end

---@param village wds.Village
---@param showToast boolean
---@return boolean
function VillageModule:CheckCanDropVillage(village, showToast )
    --权限检查
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_26003"))
        end
        return false
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_NoPermission_toast"))
        end
        return false
    end
    local villageWarStatus = ModuleRefer.VillageModule:GetVillageWarStatus(village.ID, ModuleRefer.AllianceModule:GetAllianceId())
    if villageWarStatus ~= wds.VillageAllianceWarStatus.VillageAllianceWarStatus_None then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_already_declared"))
        end
        return false
    end
    return true
end

---@param village wds.Village
---@param showToast boolean
---@return boolean
function VillageModule:CheckCanCancelDropVillage(village, showToast )
    --权限检查
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_26003"))
        end
        return false
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_NoPermission_toast"))
        end
        return false
    end
    if not ModuleRefer.VillageModule:IsVillageInDrop(village, ModuleRefer.AllianceModule:GetAllianceId()) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_NotGivingUp_toast"))
        end
        return false
    end
    return true
end

---@param cage wds.BehemothCage
---@param showToast boolean
---@return boolean
function VillageModule:StartSignAttackBehemothCage(cage, showToast)
    local can,toast = self:GetCanSignAttackCageToast(cage, showToast)
    if can then
        ---@type AllianceDeclareWarMediatorParameter
        local parameter = {}
        parameter.behemothCage = cage
        parameter.callback = function(lockTrans,villageId, startTime, callback)
            self:DoStartSignAttackVillage(lockTrans, villageId, startTime, callback)
        end
        g_Game.UIManager:Open(UIMediatorNames.AllianceDeclareWarMediator, parameter)
    elseif showToast and not string.IsNullOrEmpty(toast) then
        ModuleRefer.ToastModule:AddSimpleToast(toast)
    end
    return can
end

---@param village wds.Village
---@param showToast boolean
---@return boolean
function VillageModule:StartSignAttackVillage(village, showToast)
    local can,toast = self:GetCanSignAttackVillageToast(village, showToast)
    if can then
        ---@type AllianceDeclareWarMediatorParameter
        local parameter = {}
        parameter.village = village
        parameter.callback = function(lockTrans,villageId, startTime, callback)
            self:DoStartSignAttackVillage(lockTrans, villageId, startTime, callback)
        end
        g_Game.UIManager:Open(UIMediatorNames.AllianceDeclareWarMediator, parameter)
    elseif showToast and not string.IsNullOrEmpty(toast) then
        ModuleRefer.ToastModule:AddSimpleToast(toast)
    end
    return can
end

---@param trans CS.UnityEngine.Transform
---@param villageId number
---@param startTime number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function VillageModule:DoStartSignAttackVillage(trans, villageId, startTime, callback)
    if self:HasDeclareWarOnVillage(villageId) then
        if callback then
            callback(nil, true, nil)
        end
        return true
    end
    local cmd = DeclareWarOnVillageParameter.new()
    cmd.args.VillageID = villageId
    cmd.args.StartTime = startTime
    cmd:SendOnceCallback(trans, nil, nil, callback)
    return true
end

---@param trans CS.UnityEngine.Transform
---@param villageId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function VillageModule:DoCancelDeclareWarOnVillage(trans, villageId, callback)
    if not self:HasDeclareWarOnVillage(villageId) and not self:HasDeclareWarOnCage(villageId) then
        if callback then
            callback(nil, false, nil)
        end
        return false
    end
    local cmd = CancelDeclareWarOnVillageParameter.new()
    cmd.args.VillageID = villageId
    cmd:SendOnceCallback(trans, nil, nil, callback)
    return true
end

---@param trans CS.UnityEngine.Transform
---@param villageId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function VillageModule:DoDropVillage(trans, villageId, callback)
    local cmd = DropVillageParameter.new()
    cmd.args.VillageID = villageId
    cmd:SendOnceCallback(trans, nil, nil, callback)
end

---@param trans CS.UnityEngine.Transform
---@param villageId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function VillageModule:DoCancelDropVillage(trans, villageId, callback)
    local cmd = CancelDropVillageParameter.new()
    cmd.args.VillageID = villageId
    cmd:SendOnceCallback(trans, nil, nil, callback)
end

---@param village wds.Village
---@param myAllianceID number
---@return string
---@return number
function VillageModule:GetVillageCountDown(village, myAllianceID)
    if self:IsVillageRuined(village) then
        return "village_info_open_time", self:GetVillageStartTime(village)
    elseif not self:IsVillageStart(village) then
        return "village_info_Occupation_time", self:GetVillageStartTime(village)
    elseif self:IsVillageInDrop(village, myAllianceID) then
        return "village_info_giving_up", self:GetVillageDropEndTimestamp(village)
    elseif self:IsVillageRuinRebuilding(village) then
        return "village_outpost_info_under_construction_2", self:GetVillageRebuildEndTime(village)
    elseif self:IsVillageInProtection(village) then
        return "village_info_under_protection", self:GetVillageProtectEndTimestamp(village)
    else
        local villageWarStatus = self:GetVillageWarStatus(village.ID, myAllianceID)
        if villageWarStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            --对我联盟的宣战 or 我联盟的宣战 (第三方不给看）
            if village.Owner.AllianceID ~= 0 and village.Owner.AllianceID == myAllianceID or self:GetVillageWarInfo(village.ID, myAllianceID) then
                return "village_info_preparing", self:GetVillageWarStartTimestamp(village.ID, myAllianceID)
            end
        elseif villageWarStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction
                or villageWarStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder then
            return "village_info_time_to_end", self:GetVillageWarEndTimestamp(village.ID, myAllianceID)
        end
    end
	if village.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusProcessing then
		return I18N.Get("alliance_center_title") .. ":{1}",  self:GetTransformToAllianceCenterEndTime(village)
	end
    return string.Empty, 0
end

---@param entity wds.Village
---@return number
---@return number
function VillageModule:GetVillageNpcTroopHP(entity)
    local hp = 0
    local maxHP = 0
    if entity.Army.DummyTroopIDs then
        for _, armyMemberInfo in pairs(entity.Army.DummyTroopIDs) do
            hp = hp + armyMemberInfo.Hp
            maxHP = maxHP + armyMemberInfo.HpMax
        end
    end
    return hp, maxHP
end

---@param entity wds.Village
---@return number
---@return number
function VillageModule:GetVillageHP(entity)
    local hp = 0
    local maxHP = 0
    if entity.Army.DummyTroopIDs then
        for _, armyMemberInfo in pairs(entity.Army.DummyTroopIDs) do
            hp = hp + armyMemberInfo.Hp
            maxHP = maxHP + armyMemberInfo.HpMax
        end
    end
    if entity.Army.PlayerTroopIDs then
        for _, armyMemberInfo in pairs(entity.Army.PlayerTroopIDs) do
            hp = hp + armyMemberInfo.Hp
            maxHP = maxHP + armyMemberInfo.HpMax
        end
    end
    return hp, maxHP
end

--判断守军是否死完
function VillageModule:IsVillageTroopDead(entity)
    --切lod时，守军未初始化
    if entity.Army.DummyTroopInitFinish == false then
        return false
    end

    if entity.Army.DummyTroopIDs then
        for _, v in pairs(entity.Army.DummyTroopIDs) do
            if v.Hp ~= 0 then
                return false
            end
        end
    end
    -- 目前只考虑被污染的守军
    -- if entity.Army.PlayerTroopIDs then
    --     for _, v in pairs(entity.Army.PlayerTroopIDs) do
    --         if v.Hp ~= 0 then
    --             return true
    --         end
    --     end
    -- end
    return true
end
---@param villageID number
---@param myAllianceID number
function VillageModule:GetVillageWarStatus(villageID, myAllianceID)
    local villageWarInfo = self:GetVillageWarInfo(villageID, myAllianceID) or self:GetEarliestVillageWarInfo(villageID)
    if villageWarInfo then
        return villageWarInfo.Status
    end
    return wds.VillageAllianceWarStatus.VillageAllianceWarStatus_None
end

---@param villageID number
---@param myAllianceID number
function VillageModule:GetVillageWarDeclaredTimestamp(villageID, myAllianceID)
    local villageWarInfo = self:GetVillageWarInfo(villageID, myAllianceID) or self:GetEarliestVillageWarInfo(villageID)
    if villageWarInfo then
        return villageWarInfo.DeclareTime
    end
    return 0
end

---@param villageID number
---@param myAllianceID number
function VillageModule:GetVillageWarStartTimestamp(villageID, myAllianceID)
    local villageWarInfo = self:GetVillageWarInfo(villageID, myAllianceID) or self:GetEarliestVillageWarInfo(villageID)
    if villageWarInfo then
        return villageWarInfo.StartTime
    end
    return 0
end

---@param villageID number
---@param myAllianceID number
function VillageModule:GetVillageWarEndTimestamp(villageID, myAllianceID)
    local villageWarInfo = self:GetVillageWarInfo(villageID, myAllianceID) or self:GetEarliestVillageWarInfo(villageID)
    if villageWarInfo then
        return villageWarInfo.EndTime
    end
    return 0
end

---@param village wds.Village
---@param nowTime number
function VillageModule:GetGetTransformToAllianceCenterBuildProgress(village, nowTime)
	if not nowTime then nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() end
	local value = village.VillageTransformInfo.CurBuildValue
	local targetValue = village.VillageTransformInfo.TargetBuildValue
	local speed = village.VillageTransformInfo.Speed
	local interval = village.VillageTransformInfo.Interval
	local lastUpdateTime = village.VillageTransformInfo.LastUpdateTime.ServerSecond
	local passTime = nowTime - lastUpdateTime
	if speed <= 0 or passTime <= 0 or interval <= 0 then
		return value, targetValue, math.inverseLerp(0, targetValue, value)
	end
	value = math.min(value + passTime / interval * speed, targetValue)
	return value, targetValue, math.inverseLerp(0, targetValue, value)
end

---@param village wds.Village
function VillageModule:GetTransformToAllianceCenterEndTime(village)
	local value = village.VillageTransformInfo.CurBuildValue
	local targetValue = village.VillageTransformInfo.TargetBuildValue
	local speed = village.VillageTransformInfo.Speed
	local interval = village.VillageTransformInfo.Interval
	local lastUpdateTime = village.VillageTransformInfo.LastUpdateTime.ServerSecond
	if speed <= 0 then
		return 0
	end
	return lastUpdateTime + (targetValue - value) / speed * interval
end

---@param allianceID number
---@param villageID number
---@return wds.VillageAllianceWarInfo
function VillageModule:GetVillageWarInfo(villageID, allianceID)
    ---@type wds.Village
    local village = g_Game.DatabaseManager:GetEntity(villageID, DBEntityType.Village)
    if village and village.VillageWar and village.VillageWar.AllianceWar then
        return village.VillageWar.AllianceWar:Get(allianceID)
    end
    local villageWar = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    return villageWar[villageID]
end

---@param villageID number
---@return wds.VillageAllianceWarInfo
function VillageModule:GetEarliestVillageWarInfo(villageID)
    local result
    local startTime = math.huge
    ---@type table<number, wds.VillageAllianceWarInfo> | MapField
    local wars
    ---@type wds.Village
    local village = g_Game.DatabaseManager:GetEntity(villageID, DBEntityType.Village)
    if village and village.VillageWar then
        wars = village.VillageWar.AllianceWar
    end
    if wars then
        ---@param warInfo wds.VillageAllianceWarInfo
        for _, warInfo in pairs(wars) do
            if warInfo.StartTime < startTime then
                startTime = warInfo.StartTime
                result = warInfo
            end
        end
    end
    return result
end

---@param entity wds.Village
function VillageModule:IsVillageStart(entity)
    local buildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    return ModuleRefer.KingdomModule:IsSystemOpen(buildingConfig:AttackSystemSwitch())
end

---@param village wds.Village
function VillageModule:GetVillageStartTime(village)
    local buildingConfig = ConfigRefer.FixedMapBuilding:Find(village.MapBasics.ConfID)
    local entryID = buildingConfig:AttackSystemSwitch()
    if entryID and entryID > 0 then
        local entry = ConfigRefer.SystemEntry:Find(entryID)
        if entry then
            local openTime = entry:UnlockServerOpenTime()
            return self:GetKingdomStartTime(village) + ConfigTimeUtility.NsToSeconds(openTime)
            -- local stage = ModuleRefer.WorldTrendModule:GetStageConfigByStageIndex(entry:UnlockWorldStageIndex())
            -- if stage then
            --     return ModuleRefer.WorldTrendModule:GetStageOpenTime(stage:Id())
            -- end
        end
    end
    return 0
end

---@param village wds.Village
function VillageModule:GetKingdomStartTime(village)
    if village and village.VillageWar then
        local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
        if kingdom then
            return kingdom.KingdomBasic.OsTime.ServerSecond
        end
    end
    return 0
end

---@param entity wds.Village
function VillageModule:IsVillageInProtection(entity)
    return entity and entity.MapStates and entity.MapStates.StateWrapper and entity.MapStates.StateWrapper.ProtectionExpireTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

---@param villageID number
---@param myAllianceID number
function VillageModule:IsVillageInBattle(villageID, myAllianceID)
    local villageWarInfo = self:GetVillageWarInfo(villageID, myAllianceID) or self:GetEarliestVillageWarInfo(villageID)
    if villageWarInfo then
        return villageWarInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder
                or villageWarInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction
    end
    return false
end

function VillageModule:IsVillageInBattleorDeclare(villageID, myAllianceID)
    local villageWarInfo = self:GetVillageWarInfo(villageID, myAllianceID) or self:GetEarliestVillageWarInfo(villageID)
    if villageWarInfo then
        return villageWarInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder
                or villageWarInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction
                or villageWarInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare
    end
    return false
end

---@param entity wds.Village
function VillageModule:GetVillageProtectEndTimestamp(entity)
    if entity and entity.MapStates and entity.MapStates.StateWrapper then
        return entity.MapStates.StateWrapper.ProtectionExpireTime
    end
    return 0
end

---@param entity wds.Village
---@param allianceID number
function VillageModule:IsVillageInDrop(entity, allianceID)
    if entity and entity.Owner.AllianceID == allianceID then
        return entity.Village and entity.Village.IsDrop
    end
    return false
end

---@param entity wds.Village
function VillageModule:GetVillageDropEndTimestamp(entity)
    if entity and entity.Village then
        return entity.Village.DropEndTime.Seconds
    end
    return 0
end

---@param entity wds.Village
function VillageModule:IsVillageRuined(entity)
    return entity and entity.MapStates and entity.MapStates.StateWrapper2.Ruin and not entity.MapStates.StateWrapper2.RuinRebuild
end

---@param entity wds.Village
function VillageModule:IsVillageRuinRebuilding(entity)
    return entity and entity.MapStates and entity.MapStates.StateWrapper2.RuinRebuild
end

---@param entity wds.Village
function VillageModule:GetVillageRebuildEndTime(entity)
    if entity and entity.Battle and entity.Construction and entity.BuildingRuinRebuild.StartTime then
        local leftDurability = entity.Battle.MaxDurability - entity.Battle.Durability
        local buildSpeed = math.max(entity.Construction.BuildSpeed, 0.001)
        local time = leftDurability / buildSpeed
        return entity.Construction.LastSettleTime.Seconds + time
    end
end

---@param entity wds.Village
function VillageModule:CanStopRebuild(entity)
    return ModuleRefer.AllianceModule:IsInAlliance() 
            and ModuleRefer.AllianceModule:IsAllianceR4Above() 
            and self:IsVillageRuinRebuilding(entity)
end

---@param entity wds.Village
function VillageModule:StartRebuild(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    local num = 1
    local level = config:Level()
    local name = I18N.Get(config:Name())
    local content = I18N.GetWithParams("village_outpost_rebuild_double_check", num, level, name)
    local confirm = function()
        local param = require("StartRuinRebuildParameter").new()
        param.args.BuildingId = entity.ID
        param:SendWithFullScreenLock()
    end
    UIHelper.ShowConfirm(content, nil, confirm)
end

---@param entity wds.Village
function VillageModule:StopRebuild(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    local num = 1
    local level = config:Level()
    local name = I18N.Get(config:Name())
    local content = I18N.GetWithParams("village_outpost_info_double_check", num, level, name)
    local confirmLabel = I18N.Get("village_outpost_info_double_check_cancel")
    local cancelLabel = I18N.Get("village_btn_Abandon")
    local cancel = function()
        local param = require("CancelRuinRebuildParameter").new()
        param.args.BuildingId = entity.ID
        param:SendWithFullScreenLock()
    end
    UIHelper.ShowConfirm(content, nil, nil, cancel, confirmLabel, cancelLabel)
end

---@param entity wds.Village
function VillageModule:JoinRebuild(entity)
    --local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    --local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
    KingdomTouchInfoOperation.SendTroopToEntityQuickly(entity)
end

---@param entity wds.Village
function VillageModule:SummonAllianceMembers(entity)
    local allianceSession = ModuleRefer.ChatModule:GetAllianceSession()
    local dbType = ChatShareUtils.TypeTrans(entity.TypeHash)
    local configID = entity.MapBasics.ConfID

    ---@type ShareConfirmParam
    local param = {}
    param.sessionID = allianceSession.SessionId
    param.type = dbType
    param.configID = configID
    param.x = entity.MapBasics.Position.X
    param.y = entity.MapBasics.Position.Y
    param.z = entity.MapBasics.Position.Z
    param.payload = {}
    param.payload.content = math.round(entity.Battle.Durability / entity.Battle.MaxDurability * 100)
    g_Game.UIManager:Open(UIMediatorNames.ShareConfirmMediator, param)
end

---@return table<number, wds.RuinRebuildBuildingInfo>
function VillageModule:GetMyRebuildVillages()
    if ModuleRefer.AllianceModule:IsInAlliance() then
        local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
        if allianceData and allianceData.AllianceWrapper and allianceData.AllianceWrapper.BuilderRuinRebuild then
            return allianceData.AllianceWrapper.BuilderRuinRebuild.Buildings
        end
    end
    return nil
end

---@return boolean
function VillageModule:HasRebuildVillage()
    local rebuildVillages = self:GetMyRebuildVillages()
    return rebuildVillages and table.nums(rebuildVillages) > 0
end

--据点
VillageModule.AllianceVillageLimitAttrDisplay = {
    [1] = 2015,
    [2] = 2016,
    [3] = 2017,
    [4] = 2035,
    [5] = 2036,
    [6] = 2037,
    [7] = 2038,
    [8] = 2039,
    [9] = 2040,
    [10] = 2041,
    [11] = 2042,
    [12] = 2043,
    [13] = 2044,
    [14] = 2045,
    [15] = 2046,
}

--城市
VillageModule.AllianceVillageCityAttrDisplay = {
    [1] = 2018,
    [2] = 2019,
    [3] = 2020,
    [4] = 2021,
    [5] = 2022,
    [6] = 2023,
    [7] = 2047,
    [8] = 2048,
    [9] = 2049,
    [10] = 2050,
    [11] = 2051,
    [12] = 2052,
    [13] = 2053,
    [14] = 2054,
    [15] = 2055,
}

--城市
VillageModule.AllianceVillageCitySubTypeAttrDisplay  = {
    [VillageSubType.Military] = 2056,
    [VillageSubType.Economy] = 2057,
    [VillageSubType.PetZoo] = 2058,
    [VillageSubType.Gate] = 2059,
}

---@return number|nil
function VillageModule:GetVillageOwnCountLimitByLevel(level, isCity)
    local attrDisplayId = isCity and VillageModule.AllianceVillageCityAttrDisplay[level] or VillageModule.AllianceVillageLimitAttrDisplay[level]
    if not attrDisplayId then
        return nil
    end
    local myAllianceData = ModuleRefer.AllianceTechModule:GetMyTechData()
    if not myAllianceData then
        return nil
    end
    return myAllianceData.AttrDisplay[attrDisplayId] or 0
end

---@param villageSubType number @VillageSubType
---@return number|nil
function VillageModule:GetVillageOwnCountLimitBySubType(villageSubType)
    local attrDisplayId = VillageModule.AllianceVillageCitySubTypeAttrDisplay[villageSubType]
    if not attrDisplayId then
        return nil
    end
    local myAllianceData = ModuleRefer.AllianceTechModule:GetMyTechData()
    if not myAllianceData then
        return nil
    end
    return myAllianceData.AttrDisplay[attrDisplayId] or 0
end

---@param attrTypeAndValue AttrTypeAndValue
---@param addToTable {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string}}[]
function VillageModule.ParseAttrInfo(attrTypeAndValue, addToTable, processAllianceCurrencySpeed)
    local typeId = attrTypeAndValue:TypeId()
    local value = attrTypeAndValue:Value()
    local needConvertToSpeed
    local needConvertToSpeedCurrencyType
    if processAllianceCurrencySpeed then
        needConvertToSpeed,needConvertToSpeedCurrencyType = ModuleRefer.AllianceModule:IsAllianceRelativeSpeedAttrId(typeId)
    end
    local attrElement = ConfigRefer.AttrElement:Find(typeId)
    if attrElement then
        local cellData = {}
        cellData.strLeft = I18N.Get(attrElement:Name())
        cellData.icon = attrElement:Icon()
        local valueType = attrElement:ValueType()
        if valueType == AttrValueType.Fix then
            local originValue = value
            if needConvertToSpeed then
                local ins
                if needConvertToSpeed == 1 then
                    ins = ModuleRefer.AllianceModule:GetAllianceCurrencyAutoAddTimeInterval(needConvertToSpeedCurrencyType)
                elseif needConvertToSpeed == 2 then
                    local cityAttr = ModuleRefer.VillageModule._globalAutoGrowSpeedTimeCityAttrType
                    if cityAttr then
                        ins = ModuleRefer.CastleAttrModule:SimpleGetValue(cityAttr)
                    end
                end
                if ins then
                    if ins > 0 then
                        if needConvertToSpeedCurrencyType == AllianceCurrencyType.WarCard then
                            value = I18N.GetWithParams("alliance_xuanzhanchanchu", NumberFormatter.NumberAbbr(math.floor(value * (1 / ins) + 0.5), true))
                        else
                            value = I18N.GetWithParams("alliance_resource_xiaoshi", NumberFormatter.NumberAbbr(math.floor(value * (3600 / ins)), true))
                        end
                    else
                        value = I18N.GetWithParams("alliance_resource_xiaoshi", "0")
                    end
                end
            end
            if originValue >= 0 then
                cellData.strRight = ("+%s"):format(value)
            else
                cellData.strRight = ("%s"):format(value)
            end
        elseif valueType == AttrValueType.OneTenThousand then
            if value > 0 then
                cellData.strRight = ("+%d%%"):format(math.floor(value/100))
            else
                cellData.strRight = ("%d%%"):format(math.floor(value/100))
            end
        elseif valueType == AttrValueType.Percentages then
            if value > 0 then
                cellData.strRight = ("+%d%%"):format(value)
            else
                cellData.strRight = ("%d%%"):format(value)
            end
        else
            cellData.strRight = tostring(value)
        end
        local addCell = {prefabIdx=2, cellData=cellData}
        table.insert(addToTable, addCell)
    end
end

---@param oldValue AttrTypeAndValue
---@param attrTypeAndValueTo AttrTypeAndValue
---@param addToTable {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string,strRightOrigin:string}}[]
function VillageModule.ParseChangeAttrInfo(oldValue, attrTypeAndValueTo, addToTable, processAllianceCurrencySpeed)
	local typeId = attrTypeAndValueTo:TypeId()
	local value = attrTypeAndValueTo:Value()
	local needConvertToSpeed
	local needConvertToSpeedCurrencyType
	if processAllianceCurrencySpeed then
		needConvertToSpeed,needConvertToSpeedCurrencyType = ModuleRefer.AllianceModule:IsAllianceRelativeSpeedAttrId(typeId)
	end
	local attrElement = ConfigRefer.AttrElement:Find(typeId)
	if attrElement then
		local cellData = {}
		cellData.strLeft = I18N.Get(attrElement:Name())
		cellData.icon = attrElement:Icon()
		local valueType = attrElement:ValueType()
		if valueType == AttrValueType.Fix then
			local originValue = value
			if needConvertToSpeed then
				local ins
				if needConvertToSpeed == 1 then
					ins = ModuleRefer.AllianceModule:GetAllianceCurrencyAutoAddTimeInterval(needConvertToSpeedCurrencyType)
				elseif needConvertToSpeed == 2 then
					local cityAttr = ModuleRefer.VillageModule._globalAutoGrowSpeedTimeCityAttrType
					if cityAttr then
						ins = ModuleRefer.CastleAttrModule:SimpleGetValue(cityAttr)
					end
				end
				if ins then
					if ins > 0 then
						if needConvertToSpeedCurrencyType == AllianceCurrencyType.WarCard then
							value = I18N.GetWithParams("alliance_xuanzhanchanchu", NumberFormatter.NumberAbbr(math.floor(value * (1 / ins) + 0.5), true))
							oldValue = I18N.GetWithParams("alliance_xuanzhanchanchu", NumberFormatter.NumberAbbr(math.floor(oldValue * (1 / ins) + 0.5), true))
						else
							value = I18N.GetWithParams("alliance_resource_xiaoshi", NumberFormatter.NumberAbbr(math.floor(value * (3600 / ins)), true))
							oldValue = I18N.GetWithParams("alliance_resource_xiaoshi", NumberFormatter.NumberAbbr(math.floor(oldValue * (3600 / ins)), true))
						end
					else
						value = I18N.GetWithParams("alliance_resource_xiaoshi", "0")
						oldValue = I18N.GetWithParams("alliance_resource_xiaoshi", "0")
					end
				end
			end
			if originValue >= 0 then
				cellData.strRight = ("+%s"):format(value)
				cellData.strRightOrigin = ("+%s"):format(oldValue)
			else
				cellData.strRight = ("%s"):format(value)
				cellData.strRightOrigin = ("%s"):format(oldValue)
			end
		elseif valueType == AttrValueType.OneTenThousand then
			if value > 0 then
				cellData.strRight = ("+%d%%"):format(math.floor(value/100))
				cellData.strRightOrigin = ("+%d%%"):format(math.floor(oldValue/100))
			else
				cellData.strRight = ("%d%%"):format(math.floor(value/100))
				cellData.strRightOrigin = ("%d%%"):format(math.floor(oldValue/100))
			end
		elseif valueType == AttrValueType.Percentages then
			if value > 0 then
				cellData.strRight = ("+%d%%"):format(value)
				cellData.strRightOrigin = ("+%d%%"):format(oldValue)
			else
				cellData.strRight = ("%d%%"):format(value)
				cellData.strRightOrigin = ("%d%%"):format(oldValue)
			end
		else
			cellData.strRight = tostring(value)
			cellData.strRightOrigin = tostring(oldValue)
		end
		local addCell = {prefabIdx=2, cellData=cellData}
		table.insert(addToTable, addCell)
	end
end

---@param isSuccess boolean
---@param reply wrpc.OccupyVillageReportRequest
function VillageModule:OnServerPushOccupyVillageReport(isSuccess, reply)
    if not isSuccess or not reply then
        return
    end
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene or scene:GetName() ~= "KingdomScene" then
        return
    end
    local buildingType = self:GetVillageMapBuildingTypeByTerritoryId(reply.Param.TerritoryId)
    if buildingType == MapBuildingType.Town then
        if reply.Param.Success then
            local needTriggerGuide = false
            if ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter) then
                if g_Game.PlayerPrefsEx:GetIntByUid("GUIDE_6251", 0) == 0 then
                    needTriggerGuide = true
                    g_Game.PlayerPrefsEx:SetIntByUid("GUIDE_6251", 1)
                    g_Game.PlayerPrefsEx:Save()
                end
            end
            if scene:IsInCity() then
                ---@type AllianceVillageOccupationNoticeMediatorParameter
                local param = {}
                param.payload = reply.Param
                if needTriggerGuide then
                    param.endQueueTriggerGuide = 6251
                end
                g_Game.UIManager:Open(UIMediatorNames.AllianceVillageOccupationNoticeMediator, param)
            else
                local addToQueue = {t = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + self._delayTimeSec, p = reply.Param}
                table.insert(self._delayShowQueue, addToQueue)
                if needTriggerGuide then
                    addToQueue = {endQueueTriggerGuide = 6251}
                    for i = #self._delayShowQueue, 1, -1 do
                        if self._delayShowQueue[i].endQueueTriggerGuide then
                            table.remove(self._delayShowQueue, i)
                        end 
                    end
                    table.insert(self._delayShowQueue, addToQueue)
                end
            end
        else
            ---@type WorldConquerFailTipMediatorParameter
            local toast = {}
            local t = ConfigRefer.Territory:Find(reply.Param.TerritoryId)
            local v = ConfigRefer.FixedMapBuilding:Find(t:VillageId())
            local pos = t:VillagePosition()
            local villageConfig = ConfigRefer.FixedMapBuilding:Find(t:VillageId())
            toast.icon = v:Image()
            toast.mainContent = I18N.Get("village_info_Capture_failed") .. ("Lv.%s %s(%s,%s)"):format(villageConfig:Level(), I18N.Get(v:Name()), pos:X(), pos:Y())
            toast.subContent = I18N.Get("village_info_notime")
            ModuleRefer.ToastModule:AddWorldConquerFailTip(toast)
        end
    elseif buildingType == MapBuildingType.BehemothCage then
        ---@type BehemothTroopCtrl
        local focusBoss = ModuleRefer.SlgModule:GetFocusBoss()
        local hasMyDamageInfo = false
        for _, v in pairs(reply.Param.SoldierRank) do
            local playerID = ModuleRefer.PlayerModule:GetPlayerId()
            if v.PlayerId == playerID then
                hasMyDamageInfo = true
                break
            end
        end
        if not hasMyDamageInfo then
            return
        end
        if (((focusBoss or {}).cageEntity or {}).BehemothCage or {}).VID == reply.Param.TerritoryId then
            ---@type UIBehemothSettleMediatorParam
            local data = {}
            data.isGve = false
            data.isWin = reply.Param.Success
            data.soldierRank = reply.Param.SoldierRank
            data.startTime = reply.Param.WarStartTime
            data.endTime = reply.Param.WarEndTime
            data.slgBehemoth = focusBoss
            data.autoClose = true
            ---@type UIAsyncDataProvider
            local provider = UIAsyncDataProvider.new()
            local name = UIMediatorNames.UIBehemothSettlementMediator
            local timing = nil
            local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
            local failStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
            local shouldKeep = false
            local openParam = data
            provider:Init(name, timing, check, failStrategy, shouldKeep, openParam)
            g_Game.UIAsyncManager:AddAsyncMediator(provider)
        end
    end
end

---@param isSuccess boolean
---@param reply wrpc.NotifyLaunchAllianceAssembleTroopRequest
function VillageModule:OnServerPushEscrowTroopWillLaunch(isSuccess, reply)
    if isSuccess and reply then
        if not reply.NeedConfirm then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_already_proxy"))
            return
        end
        local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
        if not allianceData then
            return
        end
        local targetInfos = allianceData.AllianceAssembleInfo.TargetAssembleInfo
        for i, v in pairs(targetInfos) do
            if v.TargetInfo.Id == reply.TargetId then
                local targetId = reply.TargetId
                local leftTime = math.max(0, v.TargetInfo.WarStartTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
                local queueIndex = reply.QueueIndex
                ---@type CommonConfirmPopupMediatorParameter
                local parameter = {}
                parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
                parameter.confirmLabel = I18N.Get("village_btn_confirm_proxy")
                parameter.cancelLabel = I18N.Get("village_btn_cancel_proxy")
                parameter.content = I18N.GetWithParams("village_check_inwar", tostring(reply.QueueIndex + 1), TimeFormatter.SimpleFormatTime(leftTime))
                parameter.onConfirm = function()
                    local cmd = LaunchAllianceAssembleTroopParameter.new()
                    cmd.args.TargetId = targetId
                    cmd.args.QueueIndex = queueIndex
                    cmd.args.LaunchOrCancel = true
                    cmd:Send()
                    return true
                end
                parameter.onCancel = function()
                    local cmd = LaunchAllianceAssembleTroopParameter.new()
                    cmd.args.TargetId = targetId
                    cmd.args.QueueIndex = queueIndex
                    cmd.args.LaunchOrCancel = false
                    cmd:Send()
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
                return
            end
        end
    end
end

function VillageModule:OnLeaveAlliance(allianceId)
    table.clear(self._delayShowQueue)
end

---@param queueIndexes number[]
---@param callback fun(batchRet:table<number, {ret:boolean, rsp:any}>)
function VillageModule:CancelEscrowTroop(queueIndexes, callback)
    local targetIds = {}
    for _, index in pairs(queueIndexes) do
        local troopInfo = ModuleRefer.SlgModule.troopManager:GetTroopInfoByPresetIndex(index)
        if troopInfo and troopInfo.preset and troopInfo.preset.TrusteeshipInfo then
            local target = troopInfo.preset.TrusteeshipInfo.TargetId
            local indexArray = targetIds[target]
            if not indexArray then
                indexArray = {}
                targetIds[target] = indexArray
            end
            table.insert(indexArray, index)
        end
    end
    if table.isNilOrZeroNums(targetIds) then
        if callback then
            callback()
        end
        return
    end

    ---@type table<number, CancelAllianceAssembleTroopParameter>
    local sendCmdBatch = {}

    ---@type fun(cmd:CancelAllianceAssembleTroopParameter, isSuccess:boolean, rsp:any)
    local oneCmdCallback
    if callback then
        ---@type table<number, {ret:boolean, rsp:any}>
        local batchCallbackValue = {}
        oneCmdCallback = function(cmd, isSuccess, rsp)
            local targetId = cmd.msg.userdata
            if not targetIds[targetId] then return end
            targetIds[targetId] = nil
            batchCallbackValue[targetId] = {ret = isSuccess, rsp = rsp}
            if table.isNilOrZeroNums(targetIds) then
                callback(batchCallbackValue)
            end
        end
    else
        oneCmdCallback = nil
    end

    for targetId, indexArray in pairs(targetIds) do
        local cmd = CancelAllianceAssembleTroopParameter.new()
        cmd.args.TargetId = targetId
        for _, index in ipairs(indexArray) do
            cmd.args.QueueIndexes:Add(index - 1)
        end
        sendCmdBatch[targetId] = cmd
    end
    for targetId, cmd in pairs(sendCmdBatch) do
        cmd:SendOnceCallback(nil, targetId, nil, oneCmdCallback)
    end
end

---@param village wds.Village
function VillageModule:HasBeenOccupied(village)
    return village and village.VillageWar and village.VillageWar.OccupyHistoryFirst and village.VillageWar.OccupyHistoryFirst.Basic.AllianceId > 0
end

function VillageModule:DelayShowSuccessNotice(dt)
    if #self._delayShowQueue <= 0 then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local inQueueCount = #self._delayShowQueue
    local p = self._delayShowQueue[1]
    local endQueueTriggerGuide = nil
    if p.t and nowTime > p.t then
        if inQueueCount == 2 and self._delayShowQueue[2].endQueueTriggerGuide then
            endQueueTriggerGuide = self._delayShowQueue[2].endQueueTriggerGuide
            table.remove(self._delayShowQueue, 2)
        end
        table.remove(self._delayShowQueue, 1)
    else
        if p.endQueueTriggerGuide then
            table.remove(self._delayShowQueue, 1)
            ModuleRefer.GuideModule:CallGuide(p.endQueueTriggerGuide)
        end
        return
    end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene or scene:GetName() ~= "KingdomScene" then
        return
    end
    ---@type AllianceVillageOccupationNoticeMediatorParameter
    local param = {}
    param.payload = p.p
    param.endQueueTriggerGuide = endQueueTriggerGuide
    g_Game.UIManager:Open(UIMediatorNames.AllianceVillageOccupationNoticeMediator, param)
end

---@param villageEntity wds.Village
function VillageModule:IsAllianceCenter(villageEntity)
	return villageEntity.VillageTransformInfo and villageEntity.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusDone or false
end

---@param mapBuildingSubType number @MapBuildingSubType
---@param villageSubType number @VillageSubType
---@param lv number
function VillageModule:GetVillageIconPrefixByTypeSubTypeLevel(mapBuildingSubType, villageSubType, lv)
    local map = self.villageLevelConfigMap[mapBuildingSubType]
    if not map then return "sp_icon_slg_village_lv1_" end
    local set = map[villageSubType]
    if not set then
        for _, v in pairs(map) do
            return v[lv] and v[lv]:IconPrefix() or "sp_icon_slg_village_lv1_"
        end
    end
    return set[lv] and set[lv]:IconPrefix() or "sp_icon_slg_village_lv1_"
end

function VillageModule:GetVillageIconRaw(format, friendly, neutral, isAllianceCenter, isCreepInfected)
    local faction
    if friendly then
        faction = 3
    elseif neutral then
        if isCreepInfected then
            faction = 5
        else
            faction = 4
        end
    else
        faction = 2
    end

    local cacheMap = isAllianceCenter and self.villageAllianceCenterIconNameCache or self.villageIconNameCache
    local cache = cacheMap[format]
    if not cache then
        cache = {}
        cacheMap[format] = cache
    end
    local iconName = cache[faction]
    if not iconName then
        iconName = ("%s%s"):format(format, faction)
        cache[faction] = iconName
    end
    local icon = ArtResourceUtils.GetUIItem(ArtResourceUIConsts[iconName])
    if string.IsNullOrEmpty(icon) then
        g_Logger.Warn("can't find village icon: %s", iconName)
        icon = iconName
    end
    return icon
end

function VillageModule:GetVillageIcon(allianceID, playerID, villageConfigID, isAllianceCenter, isCreepInfected)
    local friendly = ModuleRefer.PlayerModule:IsFriendlyById(allianceID, playerID)
    local neutral = false
    if not friendly then
        neutral = ModuleRefer.PlayerModule:IsNeutral(allianceID)
    end
    local iconPrefix
    if isAllianceCenter then
        iconPrefix = "sp_icon_slg_league_center_"
    else
        iconPrefix = MapConfigCache.GetFixedIconPrefix(villageConfigID)
    end
    return self:GetVillageIconRaw(iconPrefix, friendly, neutral, isAllianceCenter, isCreepInfected)
end

function VillageModule:GetVillageLevelBaseSprite(villageConfigID)
    return MapConfigCache.GetFixedLevelBase(villageConfigID)
end


---@param cage wds.BehemothCage
---@return number,number @startTimestemp, endTimestemp
function VillageModule:GetBehemothCageActivityTimestamp(cage)
    local cageBuildingCfg = ConfigRefer.FixedMapBuilding:Find(cage.BehemothCage.ConfigId)
    local cageCfg = ConfigRefer.BehemothCage:Find(cageBuildingCfg:BehemothCageConfig())
        
    local length = cageCfg:AttackActivityLength()
    local startTimestemp = -1
    local endTimestemp = -1
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    
    for i = 1, length do
        local activityID = cageCfg:AttackActivity(i)
        local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityID)

        if startTime.ServerSecond > 0 then
            if startTime.ServerSecond >= serverTime or endTime.ServerSecond >= serverTime then

                if startTimestemp > 0 and startTimestemp > startTime.ServerSecond then
                    startTimestemp = startTime.ServerSecond
                    endTimestemp = endTime.ServerSecond
                else
                    startTimestemp = startTime.ServerSecond
                    endTimestemp = endTime.ServerSecond
                end
            end
        end
    end

    return startTimestemp, endTimestemp
end

---@param cage wds.BehemothCage
---@return wds.VillageAllianceWarInfo
function VillageModule:GetBehemothCageWarInfo(cage, myAllianceID)
    if cage and cage.VillageWar and cage.VillageWar.AllianceWar then
        ---@type wds.VillageAllianceWarInfo
        local warInfo = cage.VillageWar.AllianceWar:Get(myAllianceID)
        return warInfo
    end
    return nil
end

---@param cage wds.BehemothCage
---@return string,number,string|nil @tip string, startTimestamp or endTimestamp,colorStr
function VillageModule:GetBehemothCountDown(cage, myAllianceID)
    local startTimestamp, _ = self:GetBehemothCageActivityTimestamp(cage)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if startTimestamp <= 0 then
        return string.Empty, 0
    else
        if ModuleRefer.PlayerModule:IsFriendly(cage.Owner) then
            if cage.VillageWar.AllianceWar then
                local startTime = nil
                local endTime = nil
                for _, v in pairs(cage.VillageWar.AllianceWar) do
                    if v.StartTime <= nowTime and v.EndTime > nowTime then
                        if not endTime or endTime > v.EndTime then
                            endTime = v.EndTime
                        end
                    end
                    if v.StartTime > nowTime then
                        if not startTime or startTime > v.StartTime then
                            startTime = v.StartTime
                        end
                    end
                end 
                if endTime then
                    return "alliance_behemoth_state_warring", endTime
                elseif startTime then
                    return "alliance_behemoth_state_declared", startTime
                elseif cage.MapStates.StateWrapper.ProtectionExpireTime > nowTime then
                    return "village_info_under_protection", cage.MapStates.StateWrapper.ProtectionExpireTime, "#325693"
                -- elseif cage.MapStates.StateWrapper.Invincible then
                --     return "alliance_behemoth_state_protect", 0,"#325693"
                end
            end
        else
            local villageWarStatusInfo = self:GetBehemothCageWarInfo(cage, myAllianceID)
            if not villageWarStatusInfo then return string.Empty end
            if villageWarStatusInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                return "alliance_behemoth_state_WarOpen", villageWarStatusInfo.StartTime
            elseif (cage.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInLocked) ~= 0 then
                local config = ConfigRefer.FixedMapBuilding:Find(cage.BehemothCage.ConfigId)
                local cageConfig = ConfigRefer.BehemothCage:Find(config:BehemothCageConfig())
                return "alliance_behemoth_state_cdtime", cage.BehemothCage.StartLockTimestamp + ConfigTimeUtility.NsToSeconds(cageConfig:AttackFailLockDuration()),"#325693"
            elseif villageWarStatusInfo.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                return "alliance_behemoth_state_WarTime", villageWarStatusInfo.EndTime
            elseif cage.MapStates.StateWrapper.ProtectionExpireTime > nowTime then
                return "village_info_under_protection", cage.MapStates.StateWrapper.ProtectionExpireTime,"#325693"
            -- elseif cage.MapStates.StateWrapper.Invincible then
            --     return "alliance_behemoth_state_protect", 0,"#325693"
            end
        end
    end
    return string.Empty, 0
end

---@param territoryId number
---@return number
function VillageModule:GetVillageMapBuildingTypeByTerritoryId(territoryId)
    local territory = ConfigRefer.Territory:Find(territoryId)
    if territory then
        local villageId = territory:VillageId()
        local village = ConfigRefer.FixedMapBuilding:Find(villageId)
        if village then
            return village:Type()
        end
    end
    return 0
end

function VillageModule:AllianceHasAnyVillage()
    if not ModuleRefer.AllianceModule:IsInAlliance() then return false end
    local allianceMapBuilding = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for i, v in pairs(allianceMapBuilding) do
        if v.EntityTypeHash == DBEntityType.Village then
            return true
        end
    end
    return false
end

---@return number|nil
function VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
    if not ModuleRefer.AllianceModule:IsInAlliance() then return end
    local allianceMapBuilding = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for i, v in pairs(allianceMapBuilding) do
        if v.EntityTypeHash == DBEntityType.Village and v.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
            return v.EntityID
        end
    end
    return nil
end

---@return wds.MapBuildingBrief|nil
function VillageModule:GetCurrentEffectiveAllianceCenterVillage()
    if not ModuleRefer.AllianceModule:IsInAlliance() then return end
    local allianceMapBuilding = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for i, v in pairs(allianceMapBuilding) do
        if v.EntityTypeHash == DBEntityType.Village and v.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
            return v
        end
    end
    return nil
end

---@return wds.MapBuildingBrief|nil
function VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    if not ModuleRefer.AllianceModule:IsInAlliance() then return nil end
    local allianceMapBuilding = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    for _, v in pairs(allianceMapBuilding) do
        if v.EntityTypeHash == DBEntityType.Village and v.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusProcessing then
            return v
        end
    end
    for _, v in pairs(allianceMapBuilding) do
        if v.EntityTypeHash == DBEntityType.Village and v.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
            return v
        end
    end
    return nil
end

function VillageModule:GetTransformAllianceCenterCdEndTime()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData then return 0 end
    return allianceData.MapBuildingBriefs.LastCenterBuildTime + ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AllianceCenterBuildCd())
end

function VillageModule:GoToNeareastLv1Village()
    local _, _, vx, vy = ModuleRefer.TerritoryModule:GetNearestTerritoryPosition(nil, 1, function(vx, vy, level, territoryConfig, villageConfig)
        return level == 1 and territoryConfig:VillageType() == VillageType.Village
    end)
    if not vx or not vy then return end
    local scene = g_Game.SceneManager.current
    if not scene then
        return
    end
    if scene:IsInCity() then
        local queuedTask = QueuedTask.new()
        queuedTask:WaitEvent(EventConst.HUD_CLOUD_SCREEN_CLOSE, nil, function()
            return true
        end):DoAction(function()
            AllianceWarTabHelper.GoToCoord(vx, vy, true, nil, nil, nil, nil, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize, nil, 0.5)
        end):Start()
        scene:LeaveCity()
        return
    end
    AllianceWarTabHelper.GoToCoord(vx, vy, true)
end

function VillageModule:GotoNeareastCanDeclareVillage()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        local queuedTask = QueuedTask.new()
        queuedTask:WaitEvent(EventConst.HUD_CLOUD_SCREEN_CLOSE, nil, function()
            return true
        end):DoAction(function()
            self:GotoNeareastCanDeclareVillageImpl()
        end):Start()
        scene:LeaveCity()
        return
    else
        self:GotoNeareastCanDeclareVillageImpl()
    end
end

---@private
function VillageModule:GotoNeareastCanDeclareVillageImpl()
    local caches = ModuleRefer.TerritoryModule.allianceVillageNeighborCache
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then return end
    local maxCanDeclareLevel = myAllianceData.AllianceVillageWar.MaxLevel + 1
    local target = nil
    if table.isNilOrZeroNums(caches) then
        ModuleRefer.TerritoryModule:RefreshAllianceVillageNeighborCache()
    end
    for _, tid in pairs(caches) do
        local tCfg = ConfigRefer.Territory:Find(tid)
        local vCfg = ConfigRefer.FixedMapBuilding:Find(tCfg:VillageId())
        if tCfg and tCfg:VillageType() == VillageType.Village and vCfg:Level() <= maxCanDeclareLevel and not vCfg:HideShow() then
            local pos = tCfg:VillagePosition()
            if not ModuleRefer.MapFogModule:IsFogUnlocked(pos:X(), pos:Y()) then
                goto continue
            end
            if not target then
                target = tCfg:VillagePosition()
            else
                local tPos = tCfg:VillagePosition()
                local targetDistance = math.sqrt((target:X() - tPos:X()) ^ 2 + (target:Y() - tPos:Y()) ^ 2)
                local distance = math.sqrt((tPos:X() - target:X()) ^ 2 + (tPos:Y() - target:Y()) ^ 2)
                if distance < targetDistance then
                    target = tPos
                end
            end
        end
        ::continue::
    end
    if not target then
        self:GoToNeareastLv1Village()
    else
        AllianceWarTabHelper.GoToCoord(target:X(), target:Y(), true, nil, nil, nil)
    end
end

function VillageModule:SetCurrentInViewVillage(typeHash, id)
    if not typeHash or not id then return end
    if self.currentInViewVillageTypeHash == typeHash and self.currentInViewVillageId == id then return end
    self.currentInViewVillageIdIndex = self.currentInViewVillageIdIndex + 1
    self.currentInViewVillageTypeHash = typeHash
    self.currentInViewVillageId = id
    return self.currentInViewVillageIdIndex
end

---@param entity wds.Village|wds.Pass
function VillageModule:ReleaseCurrentInViewVillage(index)
    if self.currentInViewVillageIdIndex ~= index then return end
    self.currentInViewVillageTypeHash = nil
    self.currentInViewVillageId = nil
end

function VillageModule:GetCurrentInViewVillage()
    return self.currentInViewVillageId, self.currentInViewVillageTypeHash
end

---@param subType number @VillageSubType
---@return string
function VillageModule.GetVillageSubTypeName(subType)
    if subType == VillageSubType.Military then
        return I18N.Get("bw_city_name_military")
    elseif subType == VillageSubType.Economy then
        return I18N.Get("bw_city_name_trading")
    elseif subType == VillageSubType.PetZoo then
        return I18N.Get("bw_city_name_pet")
    elseif subType == VillageSubType.Gate then
        return I18N.Get("bw_city_name_pass")
    end
    return string.Empty
end

return VillageModule
