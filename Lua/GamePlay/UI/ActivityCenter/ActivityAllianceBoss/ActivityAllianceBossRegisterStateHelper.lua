local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local ActivityAllianceBossRegisterStateHelper = {}

local BTN_STATE_DEFINE = {
    ENABLE = 1,
    DISABLE = 2,
    HIDE = 3,
}

ActivityAllianceBossRegisterStateHelper.BTN_STATE_DEFINE = BTN_STATE_DEFINE

local BTN_FUNCTION_DEFINE = {
    NONE = 0,
    REGISTER = 1,
    START = 2,
    ENTER_BATTLE = 3,
    ENTER_OBSERVE = 4,
    DISABLE_NOT_TIME = 5,
    DISABLE_NOT_READY = 6,
    DISABLE_INSUFF_TROOP = 7,
    DISABLE_NO_AUTH = 8,
    DISABLE_BATTLE_FINISH = 9,
}

ActivityAllianceBossRegisterStateHelper.BTN_FUNCTION_DEFINE = BTN_FUNCTION_DEFINE

local TimeStates = {
    Before = 1,
    In = 2,
    After = 3,
    None = 0
}

ActivityAllianceBossRegisterStateHelper.TimeStates = TimeStates

---@param cfgId number
---@return wds.AllianceActivityBattleInfo
function ActivityAllianceBossRegisterStateHelper.GetBattleData(cfgId)
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then return nil end
    for _, battleData in pairs(myAllianceData.AllianceActivityBattles.Battles) do
        if battleData.CfgId == cfgId then
            return battleData
        end
    end
    return {}
end

---@param activityTemplateId number
---@return boolean
function ActivityAllianceBossRegisterStateHelper.IsTimeReached(activityTemplateId)
    if not activityTemplateId or activityTemplateId == 0 then
        return false
    end
    local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
    local startSec = startTime.Seconds
    local endSec = endTime.Seconds
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    return curTimeSec >= startSec and curTimeSec <= endSec
end

---@param activityTemplateId number
---@return number @TimesStates
function ActivityAllianceBossRegisterStateHelper.GetTimeState(activityTemplateId)
    if not activityTemplateId or activityTemplateId == 0 then
        return TimeStates.None
    end
    local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityTemplateId)
    local startSec = startTime.Seconds
    local endSec = endTime.Seconds
    local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    if curTimeSec < startSec then
        return TimeStates.Before
    elseif curTimeSec > endSec then
        return TimeStates.After
    else
        return TimeStates.In
    end
end

---@param cfgId number
---@return boolean
function ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(cfgId)
    local battleData = ActivityAllianceBossRegisterStateHelper.GetBattleData(cfgId)
    local myPlayerId = ModuleRefer.PlayerModule.playerId
    for _, member in pairs(battleData.Members or {}) do
        if member.PlayerId == myPlayerId then
            return true
        end
    end
    return false
end

---@param battleData wds.AllianceActivityBattleInfo
---@return boolean
function ActivityAllianceBossRegisterStateHelper.IsTroopCountReached(battleData)
    local cfgId = battleData.CfgId
    local needed = ConfigRefer.AllianceBattle:Find(cfgId):RequiredMemberCount()
    local cur = 0
    for _, _ in pairs(battleData.Members) do
        cur = cur + 1
    end
    return cur >= needed
end

function ActivityAllianceBossRegisterStateHelper.GetBattleStatus(cfgId)
    local battleData =  ActivityAllianceBossRegisterStateHelper.GetBattleData(cfgId)
    if battleData then
        return battleData.Status
    end
    return 0
end

function ActivityAllianceBossRegisterStateHelper.GetCurUIRole(cfgId)
    local isAboveR4 = ModuleRefer.AllianceModule:IsAtOrAboveRank(AllianceModuleDefine.OfficerRank) -- todo: 改用权限控制
    local isAboveR3 = ModuleRefer.AllianceModule:IsAtOrAboveRank(AllianceModuleDefine.R3Rank)
    local battleData = ActivityAllianceBossRegisterStateHelper.GetBattleData(cfgId)
    local battleStatus = ActivityAllianceBossRegisterStateHelper.GetBattleStatus(cfgId)
    if battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
        if not ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(battleData) then
            return ActivityAllianceBossConst.ROLE.NOT_PARTICIPATED
        end
    end
    if isAboveR4 then
        return ActivityAllianceBossConst.ROLE.R4
    elseif isAboveR3 then
        return ActivityAllianceBossConst.ROLE.R3
    else
        return ActivityAllianceBossConst.ROLE.R3
    end
end

function ActivityAllianceBossRegisterStateHelper.GetCurUIState(cfgId)
    local battleStatus = ActivityAllianceBossRegisterStateHelper.GetBattleStatus(cfgId)
    local previewId = ConfigRefer.AllianceBattle:Find(cfgId):PreviewActivity()
    if ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(previewId) or
        battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusClose then
        return ActivityAllianceBossConst.BATTLE_STATE.PREVIEW
    elseif battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusOpen or
    battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
        return ActivityAllianceBossConst.BATTLE_STATE.REGISTER
    elseif battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusWaiting then
        return ActivityAllianceBossConst.BATTLE_STATE.WAITING
    elseif battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
        return ActivityAllianceBossConst.BATTLE_STATE.BATTLE
    elseif battleStatus == wds.AllianceActivityBattleStatus.AllianceBattleStatusFinished then
        return ActivityAllianceBossConst.BATTLE_STATE.END
    end
end

function ActivityAllianceBossRegisterStateHelper.GetRegisterTemplateId(cfgId)
    local battleCfg = ConfigRefer.AllianceBattle:Find(cfgId)
    return battleCfg:SignInActivity()
end

function ActivityAllianceBossRegisterStateHelper.GetPreviewTemplateId(cfgId)
    local battleCfg = ConfigRefer.AllianceBattle:Find(cfgId)
    return battleCfg:PreviewActivity()
end

function ActivityAllianceBossRegisterStateHelper.GetChosenTimeTemplateId(cfgId)
    local battleData = ActivityAllianceBossRegisterStateHelper.GetBattleData(cfgId)
    return battleData.ChosenActivity
end

return ActivityAllianceBossRegisterStateHelper