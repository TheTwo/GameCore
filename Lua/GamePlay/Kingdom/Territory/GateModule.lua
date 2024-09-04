local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local BaseModule = require("BaseModule")
local DBEntityType = require("DBEntityType")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local MapBuildingSubType = require("MapBuildingSubType")
local CancelDeclareWarOnVillageParameter = require("CancelDeclareWarOnVillageParameter")
local VillageSubType = require('VillageSubType')
local ConfigTimeUtility = require("ConfigTimeUtility")
---@class GateModule
local GateModule = class("GateModule", BaseModule)

function GateModule:GetCanSignAttackToast(entity)
    -- 权限检查
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return false, I18N.Get("village_toast_join_the_alliance")
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage) then
        return false, I18N.Get("village_toast_Set_time_3")
    end
    if self:HasDeclareWar(entity.ID) then
        return false, I18N.Get("village_toast_already_declared")
    end

    -- 前置检查 (不可跨级)
    -- 接壤检查 (非首个必须接壤)
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData or not allianceData.MapBuildingBriefs or not allianceData.MapBuildingBriefs.MapBuildingBriefs then
        return false, string.Empty
    end

    local FixedMapBuilding = ConfigRefer.FixedMapBuilding
    local configId = entity.MapBasics.ConfID
    local targetVillageConfig = FixedMapBuilding:Find(configId)
    local targetVillageLv = targetVillageConfig:Level()
    local isCity = targetVillageConfig:SubType() == MapBuildingSubType.City

    local lvCountMap = {}
    local villages = ModuleRefer.VillageModule:GetAllVillageMapBuildingBrief()
    for _, v in pairs(villages) do
        local config = FixedMapBuilding:Find(v.ConfigId)
        if config then
            local curIsCity = config:SubType() == MapBuildingSubType.City
            if curIsCity == isCity then
                local lv = config:Level()
                lvCountMap[lv] = (lvCountMap[lv] or 0) + 1
            end
        end
    end
    if not ModuleRefer.TerritoryModule:IsEntityConnected(entity.ID, DBEntityType.Pass) then
        return false, I18N.Get("village_toast_Set_time_5")
    end
    -- 服务器等级开放要求
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local unlockEntryId = targetVillageConfig:AttackSystemSwitch()
    if unlockEntryId ~= 0 then
        if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockEntryId) then
            return false, ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(unlockEntryId)
        end
    end

    -- 联盟宣战令数量检查
    local needCurrencyId = targetVillageConfig:AllianceDeclareCostCurrencyType()
    local needCount = targetVillageConfig:AllianceDeclareCostCurrencyNum()
    local hasCount = 0
    for currencyId, currencyCount in pairs(allianceData.AllianceCurrency.Currency) do
        if currencyId == needCurrencyId then
            hasCount = hasCount + currencyCount
        end
    end
    if hasCount < needCount then
        return false, I18N.Get("village_toast_Set_time_7")
    end
    -- 保护检查
    if entity.MapStates.StateWrapper.Invincible then
        return false, I18N.Get("village_toast_Set_time_8")
    end
    if entity.MapStates.StateWrapper.ProtectionExpireTime > nowTime then
        return false, I18N.Get("village_toast_Set_time_8")
    end
    -- 占领数量上限检查
    local lvHasCount = lvCountMap[targetVillageLv] or 0

    -- 关隘占领上限
    local limitCount = ModuleRefer.VillageModule:GetVillageOwnCountLimitBySubType(VillageSubType.Gate)
    if lvHasCount >= limitCount then
        return false, I18N.Get("bw_tips_pass_limit")
    end
    return true, string.Empty
end

---@param entity wds.Pass
---@param showToast boolean
---@return boolean
function GateModule:StartSignAttack(entity, showToast)
    local can, toast = self:GetCanSignAttackToast(entity, showToast)
    if can then
        ---@type AllianceDeclareWarMediatorParameter
        local parameter = {}
        parameter.village = entity
        parameter.callback = function(lockTrans, villageId, startTime, callback)
            ModuleRefer.VillageModule:DoStartSignAttackVillage(lockTrans, villageId, startTime, callback)
        end
        g_Game.UIManager:Open(UIMediatorNames.AllianceDeclareWarMediator, parameter)
    end
    return toast
end

function GateModule:GetCountDown(entity, myAllianceID)
    if not self:IsStart(entity) then
        return "village_info_Occupation_time", self:GetStartTime(entity)
    elseif self:IsInDrop(entity, myAllianceID) then
        return "village_info_giving_up", self:GetDropEndTimestamp(entity)
    elseif self:IsInProtection(entity) then
        return "village_info_under_protection", self:GetProtectEndTimestamp(entity)
    else
        local warStatus = self:GetWarStatus(entity.ID, myAllianceID)
        if warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            -- 对我联盟的宣战 or 我联盟的宣战 (第三方不给看）
            if entity.Owner.AllianceID ~= 0 and entity.Owner.AllianceID == myAllianceID or self:GetWarInfo(entity.ID, myAllianceID) then
                return "village_info_preparing", self:GetWarStartTimestamp(entity.ID, myAllianceID)
            end
        elseif warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction or warStatus == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder then
            return "village_info_time_to_end", self:GetWarEndTimestamp(entity.ID, myAllianceID)
        end
    end

    return string.Empty, 0
end

function GateModule:GetStartTime(village)
    local buildingConfig = ConfigRefer.FixedMapBuilding:Find(village.MapBasics.ConfID)
    local entryID = buildingConfig:AttackSystemSwitch()
    if entryID and entryID > 0 then
        local entry = ConfigRefer.SystemEntry:Find(entryID)
        if entry then
            local openTime = entry:UnlockServerOpenTime()
            return ModuleRefer.VillageModule:GetKingdomStartTime(village) + ConfigTimeUtility.NsToSeconds(openTime)
            -- local stage = ModuleRefer.WorldTrendModule:GetStageConfigByStageIndex(entry:UnlockWorldStageIndex())
            -- if stage then
            --     return ModuleRefer.WorldTrendModule:GetStageOpenTime(stage:Id())
            -- end
        end
    end
    return 0
end

function GateModule:GetDropEndTimestamp(entity)
    if entity and entity.OccupyDropInfo then
        return entity.OccupyDropInfo.DropEndTime.Seconds
    end
    return 0
end

function GateModule:GetProtectEndTimestamp(entity)
    if entity and entity.MapStates and entity.MapStates.StateWrapper then
        return entity.MapStates.StateWrapper.ProtectionExpireTime
    end
    return 0
end

function GateModule:GetWarStartTimestamp(villageID, myAllianceID)
    local res = self:GetWarInfo(villageID, myAllianceID) or self:GetEarliestWarInfo(villageID)
    if res then
        return res.StartTime
    end
    return 0
end

function GateModule:GetWarEndTimestamp(villageID, myAllianceID)
    local res = self:GetWarInfo(villageID, myAllianceID) or self:GetEarliestWarInfo(villageID)
    if res then
        return res.EndTime
    end
    return 0
end

function GateModule:IsStart(entity)
    local buildingConfig = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    return ModuleRefer.KingdomModule:IsSystemOpen(buildingConfig:AttackSystemSwitch())
end

function GateModule:IsInProtection(entity)
    return entity and entity.MapStates and entity.MapStates.StateWrapper and entity.MapStates.StateWrapper.ProtectionExpireTime > 0
end

function GateModule:IsInDrop(entity, allianceID)
    if entity and entity.Owner.AllianceID == allianceID then
        return entity.OccupyDropInfo and entity.OccupyDropInfo.IsDrop
    end
    return false
end

function GateModule:GetWarStatus(entityID, myAllianceID)
    local villageWarInfo = self:GetWarInfo(entityID, myAllianceID) or self:GetEarliestWarInfo(entityID)
    if villageWarInfo then
        return villageWarInfo.Status
    end
    return wds.VillageAllianceWarStatus.VillageAllianceWarStatus_None
end

function GateModule:GetWarInfo(entityID, allianceID)
    local entity = g_Game.DatabaseManager:GetEntity(entityID, DBEntityType.Pass)
    if entity and entity.VillageWar and entity.VillageWar.AllianceWar then
        return entity.VillageWar.AllianceWar:Get(allianceID)
    end
    local villageWar = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    return villageWar[entityID]
end

function GateModule:GetEarliestWarInfo(entityID)
    local result
    local startTime = math.huge
    ---@type table<number, wds.VillageAllianceWarInfo> | MapField
    local wars
    local entity = g_Game.DatabaseManager:GetEntity(entityID, DBEntityType.Pass)
    if entity and entity.VillageWar then
        wars = entity.VillageWar.AllianceWar
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

function GateModule:CheckCanCancelDeclare(entity, showToast)
    -- 权限检查
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
    if not self:HasDeclareWar(entity.ID) then
        if showToast then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_not_declare"))
        end
        return false
    end
    return true
end

function GateModule:HasDeclareWar(entityId)
    local war = ModuleRefer.AllianceModule:GetMyAllianceGateWars()
    local warRecord = war[entityId]
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

function GateModule:DoCancelDeclareWar(trans, entityId, callback)
    if not self:HasDeclareWar(entityId) then
        if callback then
            callback(nil, false, nil)
        end
        return false
    end
    local cmd = CancelDeclareWarOnVillageParameter.new()
    cmd.args.VillageID = entityId
    cmd:SendOnceCallback(trans, nil, nil, callback)
    return true
end

function GateModule:HasBeenOccupied(entity)
    return entity and entity.VillageWar and entity.VillageWar.OccupyHistoryFirst and entity.VillageWar.OccupyHistoryFirst.Basic.AllianceId > 0
end

function GateModule:IsInBattle(entityID, myAllianceID)
    local info = self:GetWarInfo(entityID, myAllianceID) or self:GetEarliestWarInfo(entityID)
    if info then
        return info.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder or info.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction
    end
    return false
end

function GateModule:IsInBattleorDeclare(entityID, myAllianceID)
    local info = self:GetWarInfo(entityID, myAllianceID) or self:GetEarliestWarInfo(entityID)
    if info then
        return info.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare or info.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder or info.Status ==
                   wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction
    end
    return false
end

return GateModule
