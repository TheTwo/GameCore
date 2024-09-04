local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local MapBuildingType = require("MapBuildingType")
local VillageType = require("VillageType")
local GetBehemothDeviceFirstBuildRewardParameter = require("GetBehemothDeviceFirstBuildRewardParameter")
local AllianceModuleDefine = require("AllianceModuleDefine")
local Delegate = require("Delegate")
local ActivityBehemothConst = require("ActivityBehemothConst")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require("DBEntityPath")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
---@class ActivityBehemothModule : BaseModule
local ActivityBehemothModule = class("ActivityBehemothModule", BaseModule)

function ActivityBehemothModule:OnRegister()
    ---@type FixedMapBuildingConfigCell[]
    self.behemothCageCfgs = {}

    ---@type KmonsterDataConfigCell[]
    self.behemothCfgs = {}

    ---@type TerritoryConfigCell[]
    self.behemothVillageCfgCache = {}

    self:InitBehemothVillageCfgCache()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function ActivityBehemothModule:OnRemove()
    self.behemothCageCfgs = nil
    self.behemothCfgs = nil
    self.behemothVillageCfgCache = nil
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function ActivityBehemothModule:OnSecondTicker()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local battleData = self:GetBattleData(ActivityBehemothConst.BATTLE_CFG_ID)
    if not battleData then return end
    if battleData.Status ~= wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then return end
    local startTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(battleData.ChosenActivity)
    local startTimeSeconds = startTime.Seconds
    local isRegistered = false
    for _, member in pairs(battleData.Members) do
        if member.PlayerId == ModuleRefer.PlayerModule:GetPlayerId() then
            isRegistered = true
            break
        end
    end
    if startTimeSeconds - curTime == 60 * 3 and isRegistered then
        local behemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
        local curDeviceLvl = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
        local cfg = behemoth:GetRefKMonsterDataConfig(curDeviceLvl)
        local _, icon = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(cfg)
        ---@type CommonNotifyPopupMediatorParameter
        local data = {}
        data.title = I18N.Get("alliance_challengeactivity_tips_start")
        data.content = I18N.Get("alliance_challengeactivity_tips_start")
        data.icon = icon
        data.btnText = I18N.Get("alliance_behemoth_button_goto")
        data.duration = 5
        data.acceptAction = function ()
            ModuleRefer.ActivityCenterModule:GotoActivity(ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab())
        end
        ModuleRefer.ToastModule:CustomeAddNoticeToast(data)
    end
end

function ActivityBehemothModule:InitBehemothVillageCfgCache()
    for _, cfg in ConfigRefer.Territory:ipairs() do
        if cfg:VillageType() == VillageType.BehemothCage then
            table.insert(self.behemothVillageCfgCache, cfg)
        end
    end
end

---@return FlexibleMapBuildingConfigCell[]
function ActivityBehemothModule:GetBehemothDeviceCfgs()
    ---@type FlexibleMapBuildingConfigCell[]
    local ret = {}
    for _, v in ConfigRefer.FlexibleMapBuilding:ipairs() do
        if v:Type() == FlexibleMapBuildingType.BehemothDevice then
            table.insert(ret, v)
        end
    end
    return ret
end

---@return FixedMapBuildingConfigCell[]
function ActivityBehemothModule:GetBehemothCageCfgs()
    if #self.behemothCageCfgs > 0 then
        return self.behemothCageCfgs
    end
    ---@type FixedMapBuildingConfigCell[]
    local ret = {}
    for _, v in ConfigRefer.FixedMapBuilding:ipairs() do
        if v:Type() == MapBuildingType.BehemothCage then
            table.insert(ret, v)
        end
    end
    self.behemothCageCfgs = ret
    return ret
end

---@return KmonsterDataConfigCell[]
function ActivityBehemothModule:GetWildBehemothCfgs()
    if #self.behemothCfgs > 0 then
        return self.behemothCfgs
    end
    ---@type KmonsterDataConfigCell[]
    local ret = {}
    ---@type number, FixedMapBuildingConfigCell
    for _, v in self.behemothCageCfgs do
        local cageCfg = ConfigRefer.BehemothCage:Find(v:BehemothCageConfig())
        local behemothCfg = ConfigRefer.KmonsterData:Find(cageCfg:Monster())
        table.insert(ret, behemothCfg)
    end
    self.behemothCfgs = ret
    return ret
end

---@param cfgId number
---@return KmonsterDataConfigCell | nil
function ActivityBehemothModule:GetWildBehemothCfgByFixedMapBuildingCfgId(cfgId)
    local buildingCfg = ConfigRefer.FixedMapBuilding:Find(cfgId)
    if not buildingCfg then return nil end
    local cageCfg = ConfigRefer.BehemothCage:Find(buildingCfg:BehemothCageConfig())
    if not cageCfg then return nil end
    local behemothCfg = ConfigRefer.KmonsterData:Find(cageCfg:Monster())
    return behemothCfg
end

---@return boolean
function ActivityBehemothModule:IsDeviceBuilt()
    local status = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingStatus()
    return status and status == wds.BuildingStatus.BuildingStatus_Constructed
end

---@return boolean
function ActivityBehemothModule:IsDeviceEverBuilt()
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then return false end
    return myAllianceData.MapBuildingBriefs.BehemothDeviceHistoryMaxLevel and myAllianceData.MapBuildingBriefs.BehemothDeviceHistoryMaxLevel > 0
end

function ActivityBehemothModule:GetBehemothCageFirstOccRewards()
end

---@param behemothCageCfgId number
---@param sort boolean
---@return number[]
function ActivityBehemothModule:GetBehemothCageActivityTemplateIds(behemothCageCfgId, sort)
    local ret = {}
    local behemothCageCfg = ConfigRefer.BehemothCage:Find(behemothCageCfgId)
    for i = 1, behemothCageCfg:AttackActivityLength() do
        local activityId = behemothCageCfg:AttackActivity(i)
        table.insert(ret, activityId)
    end
    if sort then
        table.sort(ret, function(a, b)
            local aStartTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(a)
            local bStartTime, _ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(b)
            return aStartTime.Seconds < bStartTime.Seconds
        end)
    end
    return ret
end

---@param behemothCageCfgId number
---@return boolean
function ActivityBehemothModule:IsBehemothCageTimeReached(behemothCageCfgId)
    local templateIds = self:GetBehemothCageActivityTemplateIds(behemothCageCfgId, true)
    if #templateIds == 0 then return false end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    for _, templateId in ipairs(templateIds) do
        local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(templateId)
        if curTime >= startTime.Seconds and curTime <= endTime.Seconds then
            return true
        end
    end
    return false
end

---@param behemothCageCfgId number
---@return number
function ActivityBehemothModule:GetBehemothCageExpectedTime(behemothCageCfgId)
    local warInfos = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()
    if table.isNilOrZeroNums(warInfos) then return 0 end
    local _, warInfo = next(warInfos)
    if warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return warInfo.StartTime
    elseif warInfo.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return warInfo.EndTime
    end
    return 0
end

---@param battleCfgId number
---@return wds.AllianceActivityBattleInfo | nil
function ActivityBehemothModule:GetBattleData(battleCfgId)
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then return nil end
    for _, battleData in pairs(myAllianceData.AllianceActivityBattles.Battles) do
        if battleData.CfgId == battleCfgId then
            return battleData
        end
    end
    return nil
end

---@param battleCfgId number
---@return number @wds.AllianceActivityBattleStatus
function ActivityBehemothModule:GetBattleStatus(battleCfgId)
    local battleData = self:GetBattleData(battleCfgId)
    if battleData then
        return battleData.Status
    end
    return 0
end

---@param battleCfgId number
---@return table<number, number> @playerId, facebookId
function ActivityBehemothModule:GetObserverInfos(battleCfgId)
    local battleData = self:GetBattleData(battleCfgId)
    if battleData then
        return battleData.CurrentPeerPlayers
    end
    return nil
end

---@param battleCfgId number
---@return number
function ActivityBehemothModule:GetObserverNum(battleCfgId)
    local observers = self:GetObserverInfos(battleCfgId)
    local res = 0
    if observers then
        for _, _ in pairs(observers) do
            res = res + 1
        end
    end
    return res
end

---@param battleCfgId number
---@return number
function ActivityBehemothModule:GetBattleRegisteredNum(battleCfgId)
    local battleData = self:GetBattleData(battleCfgId)
    local res = 0
    if battleData then
        for _, _ in pairs(battleData.Members) do
            res = res + 1
        end
    end
    return res
end

--- 寻找一个距离 联盟中心 -> 盟主主城 -> 玩家主城 最近的巨兽巢穴
---@param cfgId number
---@param findAttackableTarget boolean
---@return CS.UnityEngine.Vector3
function ActivityBehemothModule:GetNearestBehemothCagePosByBehemothCageCfgId(cfgId, findAttackableTarget)
    local ret = CS.UnityEngine.Vector3.zero
    local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local myAllianceMemberDic = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    for _, member in pairs(myAllianceMemberDic) do
        if member.Rank == AllianceModuleDefine.LeaderRank then
            myCityCoord = member.BigWorldPosition
            break
        end
    end
    local allianceCenterVillage = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    if allianceCenterVillage then
        myCityCoord = allianceCenterVillage.Pos
    end
    if findAttackableTarget then
        local dist = math.huge
        for _, id in pairs(ModuleRefer.TerritoryModule.allianceVillageNeighborCache) do
            local villageCfg = ConfigRefer.Territory:Find(id)
            if villageCfg and villageCfg:VillageType() == VillageType.BehemothCage then
                local fixedMapBuildingCfg = ConfigRefer.FixedMapBuilding:Find(villageCfg:VillageId())
                if fixedMapBuildingCfg and fixedMapBuildingCfg:BehemothCageConfig() == cfgId then
                    local pos = CS.UnityEngine.Vector3(villageCfg:VillagePosition():X(), villageCfg:VillagePosition():Y(), 0)
                    local d = CS.UnityEngine.Vector3.Distance(myCityCoord, pos)
                    if d < dist then
                        dist = d
                        ret = pos
                    end
                end
            end
        end
        return ret
    else
        local dist = math.huge
        for _, cfg in pairs(self.behemothVillageCfgCache) do
            local fixedMapBuildingCfg = ConfigRefer.FixedMapBuilding:Find(cfg:VillageId())
            if fixedMapBuildingCfg and fixedMapBuildingCfg:Id() == cfgId then
                ---@type CS.UnityEngine.Vector3
                local pos = CS.UnityEngine.Vector3(cfg:VillagePosition():X(), cfg:VillagePosition():Y(), 0)
                local myPos = CS.UnityEngine.Vector3(myCityCoord.X, myCityCoord.Y, 0)
                local d = CS.UnityEngine.Vector3.Distance(myPos, pos)
                if d < dist then
                    dist = d
                    ret = pos
                end
            end
        end
        return ret
    end
end

---@param cfgId number @FixedMapBuilding CfgId
function ActivityBehemothModule:IsCageDeployed(cfgId)
    if not self.behemothVillageCfgCache or #self.behemothVillageCfgCache == 0 then
        return false
    end
    for _, cfg in pairs(self.behemothVillageCfgCache) do
        local fixedMapBuildingCfg = ConfigRefer.FixedMapBuilding:Find(cfg:VillageId())
        if fixedMapBuildingCfg and fixedMapBuildingCfg:Id() == cfgId then
            return true
        end
    end
    return false
end

function ActivityBehemothModule:IsDeviceBuildRewardCanClaim()
    local allianceData= ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData then return false end
    local hasReward = allianceData.MapBuildingBriefs.BehemothDeviceFirstBuildReward
    local claimed = self:IsDeviceBuildRewardClaimed()
    return hasReward and not claimed
end

function ActivityBehemothModule:IsDeviceBuildRewardClaimed()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local buildRewardClaimStatusIndex = wds.enum.MisCellIndex.MisCellBehemothDeviceBuildReward
    local claimed = player.MisCell.Normal.Values[buildRewardClaimStatusIndex] ~= nil
    return claimed
end

---@param cfgId number
---@return boolean
function ActivityBehemothModule:IsOwnCageType(cfgId)
    for _, v in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
        if v:GetBuilding().ConfigId == cfgId then
            return true
        end
    end
end

---@param cfgId number
---@return number, number
function ActivityBehemothModule:GetMyAllianceOwnedCagePos(cfgId)
    ---@type _, AllianceBehemoth
    for _, v in ModuleRefer.AllianceModule.Behemoth:PairsOfBehemoths() do
        if v:GetBuilding().ConfigId == cfgId then
            return v:GetMapLocation()
        end
    end
    return 0, 0
end

function ActivityBehemothModule:ClaimFirstBuildReward(lockable, callback)
    local msg = GetBehemothDeviceFirstBuildRewardParameter.new()
    msg:SendOnceCallback(lockable, nil, nil, function (_, isSuccess, _)
        if isSuccess then
            if callback then callback() end
        end
    end)
end

function ActivityBehemothModule:GotoBehemothActivity()
    local state = ActivityAllianceBossRegisterStateHelper.GetCurUIState(ActivityBehemothConst.BATTLE_CFG_ID)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_activity_tips1"))
    elseif not self:IsDeviceBuilt() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_system_vacant"))
    elseif state == ActivityAllianceBossConst.BATTLE_STATE.PREVIEW or state == ActivityAllianceBossConst.BATTLE_STATE.END then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_challenge_state1"))
    else
        g_Game.UIManager:Open(UIMediatorNames.ActivityBehemothRegisterMediator)
    end
end

return ActivityBehemothModule