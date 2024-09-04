local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local ActivityCategory = require("ActivityCategory")
local ActivityCenterConst = require("ActivityCenterConst")
---@class ActivityCenter_TabOpenChecker
local ActivityCenter_TabOpenChecker = class("ActivityCenter_TabOpenChecker")

function ActivityCenter_TabOpenChecker:ctor()
    self.CommonCheckerRegistry = {
        self.CheckActivityRewardOpen,
        self.CheckAllianceBattleOpen,
        self.CheckSystemEntryOpen,
    }
    self.CustomCheckerRegistry = {
        [ActivityCenterConst.BehemothGve] = {self.CheckDeviceBuilt, self.CheckTypeRegular},
        [ActivityCenterConst.WorldEvent] = {self.CheckWorldEventTimeByLands},
        [ActivityCenterConst.WorldEvent2] = {self.CheckWorldEventTimeByLands},
        [ActivityCenterConst.WorldEvent3_1] = {self.CheckWorldEventTimeDefault},
    }
end

function ActivityCenter_TabOpenChecker:Release()
    table.clear(self.CommonCheckerRegistry)
    table.clear(self.CustomCheckerRegistry)
end

function ActivityCenter_TabOpenChecker:AddChecker(id, checker)
    if not self.CustomCheckerRegistry[id] then
        self.CustomCheckerRegistry[id] = {}
    end
    table.insert(self.CustomCheckerRegistry[id], checker)
end

---@param tab ActivityCenterTabsConfigCell
---@return boolean
function ActivityCenter_TabOpenChecker:Check(tab)
    local checkers = self.CommonCheckerRegistry
    for _, checker in ipairs(checkers) do
        if not checker(self, tab) then
            return false
        end
    end
    local customCheckers = self.CustomCheckerRegistry[tab:Id()] or {}
    for _, checker in ipairs(customCheckers) do
        if not checker(self, tab) then
            return false
        end
    end
    return true
end

function ActivityCenter_TabOpenChecker:CheckActivityRewardOpen(tab)
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdom then return false end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then return false end

    local actRewardId = tab:RefActivityReward()
    if not actRewardId or actRewardId == 0 then return true end

    local tempId = ConfigRefer.ActivityRewardTable:Find(actRewardId):OpenActivity()
    local activityEntry = kingdom.ActivityInfo.Activities[tempId]
    local actReward = player.PlayerWrapper2.PlayerAutoReward.Rewards[actRewardId]
    local actSysSwitchId = ConfigRefer.ActivityRewardTable:Find(actRewardId):SystemSwitch()
    if actSysSwitchId and actSysSwitchId > 0 then
        if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(actSysSwitchId) then
            self.Log("活动页面Id=%d未开启: SystemEntry %d未解锁(所属ActivityReward %d)", tab:Id(), actSysSwitchId, actRewardId)
            return false
        end
    end
    if activityEntry then
        if not activityEntry.Open then
            self.Log("活动页面Id=%d未开启: ActivityTemplate %d未开启(所属ActivityReward %d)", tab:Id(), tempId, actRewardId)
            return false
        end
    end
    if actReward then
        if not actReward.Open then
            self.Log("活动页面Id=%d未开启: ActivityReward %d未开启", tab:Id(), actRewardId)
            return false
        end
    end
    return true
end

---@param tab ActivityCenterTabsConfigCell
---@return boolean
function ActivityCenter_TabOpenChecker:CheckAllianceBattleOpen(tab)
    local allianceBattleId = tab:RefAllianceBattle()
    if not allianceBattleId or allianceBattleId == 0 then return true end
    local allianceData = ActivityAllianceBossRegisterStateHelper.GetBattleData(allianceBattleId)
    if not allianceData then
        self.Log("活动页面Id=%d未开启: AllianceBattle %d数据不存在", tab:Id(), allianceBattleId)
        return false
    end
    local battleCfg = ConfigRefer.AllianceBattle:Find(allianceBattleId)
    local previewId = battleCfg:PreviewActivity()
    local open = (allianceData.Status >= wds.AllianceActivityBattleStatus.AllianceBattleStatusOpen) or
                    ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(previewId)
    if not open then
        self.Log("活动页面Id=%d未开启: AllianceBattle %d未开启", tab:Id(), allianceBattleId)
        return false
    end
    return true
end

---@param tab ActivityCenterTabsConfigCell
---@return boolean
function ActivityCenter_TabOpenChecker:CheckSystemEntryOpen(tab)
    local sysEntryId = tab:SystemUnlock()
    if not sysEntryId or sysEntryId == 0 then return true end
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysEntryId) then
        self.Log("活动页面Id=%d未开启: SystemEntry %d未解锁", tab:Id(), sysEntryId)
        return false
    end
    return true
end

function ActivityCenter_TabOpenChecker:CheckDeviceBuilt(tab)
    if not ModuleRefer.ActivityBehemothModule:IsDeviceBuilt() then
        self.Log("活动页面Id=%d未开启: 联盟设施未建造", tab:Id())
        return false
    end
end

function ActivityCenter_TabOpenChecker:CheckTypeRegular(tab)
    if ModuleRefer.ActivityCenterModule:GetActivityCategory(tab:Id()) == ActivityCategory.Regular then
        self.Log("活动页面Id=%d未开启: 活动类型为Regular时隐藏活动", tab:Id())
        return false
    end
    return true
end

function ActivityCenter_TabOpenChecker:CheckWorldEventTimeByLands(tab)
    local allianceExpeditions = {}
    for i = 1, tab:RefAllianceActivityExpeditionLength() do
        allianceExpeditions[i] = tab:RefAllianceActivityExpedition(i)
    end
    local cfgId = ModuleRefer.WorldEventModule:GetAllianceExpeditionCfgByLands(allianceExpeditions)
    return ActivityCenter_TabOpenChecker:CheckWorldEventTimeImpl(tab, cfgId)
end

function ActivityCenter_TabOpenChecker:CheckWorldEventTimeDefault(tab)
    local cfgId = tab:RefAllianceActivityExpedition(1)
    return ActivityCenter_TabOpenChecker:CheckWorldEventTimeImpl(tab, cfgId)
end

function ActivityCenter_TabOpenChecker:CheckWorldEventTimeImpl(tab, eventCfgId)
    local cfgId = eventCfgId
    if not cfgId or cfgId == 0 then
        self.Log("活动页面Id=%d未开启: WorldEvent CfgId不存在", tab:Id())
        return false
    end
    local startT, endT, remainT = ModuleRefer.WorldEventModule:GetAllianceEventTime(cfgId, true)
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    -- 预告时间默认开启
    if not (curT > startT and curT < endT) then
    -- 正常活动时间
        startT, endT, remainT = ModuleRefer.WorldEventModule:GetAllianceEventTime(cfgId, false)
        if curT > startT and curT < endT then
            return true
        else
            self.Log("活动页面Id=%d未开启: WorldEvent %d未开启", tab:Id(), cfgId)
            return false
        end
    end
    return true
end

function ActivityCenter_TabOpenChecker.Log(str, ...)
    if UNITY_EDITOR and UNITY_DEBUG then
        g_Logger.LogChannel("ActivityCenter_TabOpenChecker", str, ...)
    end
end

return ActivityCenter_TabOpenChecker