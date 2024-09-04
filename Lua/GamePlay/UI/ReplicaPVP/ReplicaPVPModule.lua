local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local UIMediatorNames = require('UIMediatorNames')
local UI3DTroopModelViewHelper = require('UI3DTroopModelViewHelper')
local UITroopHelper = require('UITroopHelper')
local NumberFormatter = require('NumberFormatter')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local TimerUtility = require('TimerUtility')
local SEEnvironment = require('SEEnvironment')
local Utils = require('Utils')

local rapidjson = require('rapidjson')

local BATTLE_RECORD_LAST_CHALLENGE_TIME = 'BATTLE_RECORD_LAST_CHALLENGE_TIME'

local ReplicaPvpModifyPresetParameter = require('ReplicaPvpModifyPresetParameter')
local ReplicaPvpOpenCloseMainUIParameter = require('ReplicaPvpOpenCloseMainUIParameter')
local GetReplicaPvpPlayerInfoParameter = require('GetReplicaPvpPlayerInfoParameter')

---@class ReplicaPVPModule : BaseModule
local ReplicaPVPModule = class('ReplicaPVPModule', BaseModule)

function ReplicaPVPModule:ctor()
    ---@type CS.Notification.NotificationDynamicNode
	self._redDotHonorTab = nil
	---@type CS.Notification.NotificationDynamicNode
	self._redDotHonorDailyReward = nil
end

function ReplicaPVPModule:OnRegister()

end

function ReplicaPVPModule:OnRemove()

end

--- 在SE状态下，打开竞技场页面
function ReplicaPVPModule:EnterReplicaPVPInSE()
    -- 模拟退出场景
    local ins = SEEnvironment.Instance()
    if ins then
        ins:Dispose()
        Utils.FullGC()
        g_Game.UIManager:CloseAll()
    end
    
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPMainMediator)
end

function ReplicaPVPModule:ExitReplicaPVP()
    local backToSceneTid = g_Game.StateMachine:ReadBlackboard("SE_BACK_TO_SCENE_TID") or 0 --新手SLG副本是从大世界进入但是需要退出到城内
    local GotoUtils = require('GotoUtils')
    local exitX = g_Game.StateMachine:ReadBlackboard("SE_FROM_X", true)
	local exitY = g_Game.StateMachine:ReadBlackboard("SE_FROM_Y", true)
    GotoUtils.GotoSceneKingdomWithLoadingUI(backToSceneTid, 0, exitX, exitY)

    g_Game.UIManager:CloseByName(UIMediatorNames.ReplicaPVPMainMediator)
end

function ReplicaPVPModule:OpenAttackTroopEditUI(targetPlayerId)
    -- 强制刷新对手阵容
    local req = GetReplicaPvpPlayerInfoParameter.new()
    req.args.TargetId = targetPlayerId
    req:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            ---@type wrpc.GetReplicaPvpPlayerInfoReply
            local responseData = rsp
            ---@type ReplicaPVPTroopEditMediatorParameter
            local param = {}
            param.isAtk = true
            param.targetBasicInfo = responseData.PlayerInfo
            g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPTroopEditMediator, param)
        end
    end)
end

function ReplicaPVPModule:OpenDefendTroopEditUI()
    ---@type ReplicaPVPTroopEditMediatorParameter
    local param = {}
    param.isAtk = false
    g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPTroopEditMediator, param)
end

---带颜色的积分包括变化信息，形如：
---999(+10)
---999(-10)
---@param newScore number
---@param oldScore number
---@return string
function ReplicaPVPModule:GetScoreAndScoreChangeText(newScore, oldScore)
    if newScore == oldScore then
        return NumberFormatter.Normal(newScore)
    end

    if newScore > oldScore then
        local delta = newScore - oldScore
        return string.format('%s(%s)', newScore, UIHelper.GetColoredText(string.format('+%s', delta), ColorConsts.quality_green))
    end

    local delta = oldScore - newScore
    return string.format('%s(%s)', newScore, UIHelper.GetColoredText(string.format('-%s', delta), ColorConsts.army_red))
end

---带颜色的积分变化信息，形如：
--- +10
--- -10
---@param delta number
---@return string
function ReplicaPVPModule:GetScoreChangedText(delta)
    if delta == 0 then
        return NumberFormatter.Normal(delta)
    end

    if delta > 0 then
        return UIHelper.GetColoredText(string.format('+%s', delta), ColorConsts.quality_green)
    end

    return UIHelper.GetColoredText(string.format('%s', delta), ColorConsts.army_red)
end

---@return number @Item cfgId
function ReplicaPVPModule:GetTicketItemId()
    local itemGroupId = ConfigRefer.ReplicaPvpConst:CostItemGroup()
    local itemGroup = ConfigRefer.ItemGroup:Find(itemGroupId)
    local itemGroupInfo = itemGroup:ItemGroupInfoList(1)
    return itemGroupInfo:Items()
end

function ReplicaPVPModule:CheckIsUnlock()
    local sysIndex = ConfigRefer.ReplicaPvpConst:SystemUnlock()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex)
end

---@param titleStageCfgId number @PvpTitleStageConfigCell Id
function ReplicaPVPModule:IsTopmostTitle(titleStageCfgId)
    local titleStageCfgCell = ConfigRefer.PvpTitleStage:Find(titleStageCfgId)
    return titleStageCfgCell:RankMin() > 0 and titleStageCfgCell:RankMax() > 0
end

function ReplicaPVPModule:EntryCityFurnitureId()
    return ConfigRefer.ReplicaPvpConst:FurnitureID()
end

function ReplicaPVPModule:GetEntryIconPath()
    return ArtResourceUtils.GetUIItem(ConfigRefer.ReplicaPvpConst:EntryPic())
end

---@return wds.PlayerReplicaPvp
function ReplicaPVPModule:GetMyPvpData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData
end

---@return PvpTitleStageConfigCell
function ReplicaPVPModule:GetMyPVPTitleStageConfigCell()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return ConfigRefer.PvpTitleStage:Find(pvpData.Title)
end

---@return number
function ReplicaPVPModule:GetMyPoints()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.Score
end

---@return number
function ReplicaPVPModule:GetMyRank()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.Rank
end

---@return number
function ReplicaPVPModule:GetMyTitleStageTid()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.Title
end

---@return number
function ReplicaPVPModule:GetMyHighestTitleStageTid()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.SeasonMaxTitle
end

function ReplicaPVPModule:CanChallengeTimes()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.CanChallengeTimes
end

---@return wds.ReplicaPvpBattleRecordInfo[] | RepeatedField
function ReplicaPVPModule:GetBattleRecords()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.BattleRecord
end

---@return wds.ReplicaPvpPlayerBasicInfo[] | RepeatedField
function ReplicaPVPModule:GetChallengeList()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.DefenderInfos
end

---@return number
function ReplicaPVPModule:GetChallengeRefreshCD()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    local canRefreshTimestamp = pvpData.NextCanRefreshTime.Seconds
    local delta = canRefreshTimestamp - g_Game.ServerTime:GetServerTimestampInSeconds()
    return math.max(0, delta)
end

---@return number
function ReplicaPVPModule:GetTitleRewardProgressValue()
    local score = self:GetMyPoints()
    local maxTitleStageTid = self:GetMyHighestTitleStageTid()
    local maxTitleId = ConfigRefer.PvpTitleStage:Find(maxTitleStageTid):Rank()
    maxTitleId = math.min(maxTitleId, 5) -- 钻石(id:5)以上不再有积分上限
    local maxTitleCell = ConfigRefer.PvpTitle:Find(maxTitleId)
    local maxScore = maxTitleCell:IntegralMax()
    local minScore = maxTitleCell:IntegralMin()
    if score <= minScore then
        return 0, maxScore
    end
    return score, maxScore
end

---@return number
function ReplicaPVPModule:GetTitleRewardProgress()
    local score = self:GetMyPoints()
    local maxTitleStageTid = self:GetMyHighestTitleStageTid()
    local maxTitleId = ConfigRefer.PvpTitleStage:Find(maxTitleStageTid):Rank()
    local maxTitleCell = ConfigRefer.PvpTitle:Find(maxTitleId)
    local maxScore = maxTitleCell:IntegralMax()
    local minScore = maxTitleCell:IntegralMin()
    if score <= minScore then
        return 0
    end
    return math.clamp01((score - minScore) / (maxScore - minScore))
end

---@param score number
---@return boolean, number
function ReplicaPVPModule:GetStageProgress(score)
    for _, cell in ConfigRefer.PvpTitleStage:ipairs() do
        if score >= cell:IntegralMin() and score <= cell:IntegralMax() then
            if not self:ShowScoresProgress(cell) then
                return false, 0
            end

            local total = cell:IntegralMax() - cell:IntegralMin()
            local current = score - cell:IntegralMin()
            return true, math.clamp01(current / total)
        end
    end
end

---@return boolean 是否显示积分进度条
function ReplicaPVPModule:ShowScoresProgress(pvpTitleStageCfgCell)
    local isShow = pvpTitleStageCfgCell:IntegralMin() < ConfigRefer.ReplicaPvpConst:ProgressHide()
    -- g_Logger.Error('ShowScoresProgress %s', isShow)
    return isShow
end

function ReplicaPVPModule:GetMapInstanceId()
    return ConfigRefer.ReplicaPvpConst:InstanceConfig()
end

---@return wds.ReplicaPvpPresetBrief
function ReplicaPVPModule:GetAttackPresets()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.AtkPreset
end

---@return wds.ReplicaPvpPresetBrief
function ReplicaPVPModule:GetDefendPresets()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local pvpData = player.PlayerWrapper3.PlayerReplicaPvp
    return pvpData.DefPreset
end

function ReplicaPVPModule:GetLastChallengeTime()
    return g_Game.PlayerPrefsEx:GetLongByUid(BATTLE_RECORD_LAST_CHALLENGE_TIME, -1)
end

function ReplicaPVPModule:UpdateLastChallengeTime()
    local lastChallengeTimestamp = self:GetLastChallengeTime()
    local battleRecords = self:GetBattleRecords()
    for i = 1, battleRecords:Count() do
        local record = battleRecords[i]
        if record.BattleTime.Seconds > lastChallengeTimestamp then
            lastChallengeTimestamp = record.BattleTime.Seconds
        end
    end
    g_Game.PlayerPrefsEx:SetLongByUid(BATTLE_RECORD_LAST_CHALLENGE_TIME, lastChallengeTimestamp)
end

---@return boolean
function ReplicaPVPModule:HasNewerChallengeRecord()
    local lastChallengeTimestamp = self:GetLastChallengeTime()
    local battleRecords = self:GetBattleRecords()
    for i = 1, battleRecords:Count() do
        local record = battleRecords[i]
        if (record.BattleTime.Seconds > lastChallengeTimestamp) and (not record.IsAttacker) then
            return true
        end
    end
    return false
end

function ReplicaPVPModule:SendRefreshPvpLeaderboard()
    local pvpTid = ConfigRefer.ReplicaPvpConst:RefTopList()
    ModuleRefer.LeaderboardModule:SendGetTopList(pvpTid, 1, 100)
end

---@param isOpen boolean
function ReplicaPVPModule:NotifyPvpMainState(isOpen)
    local req = ReplicaPvpOpenCloseMainUIParameter.new()
    req.args.Open = isOpen
    req:Send()
end

function ReplicaPVPModule:OpenPVPShop()
    local tabId = ConfigRefer.ReplicaPvpConst:ShopID()
	g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator, {tabIndex = tabId})
end

--- 创建PVP部队编辑的上下文
---@param isAtk boolean
function ReplicaPVPModule:EditPvpTroopStart(isAtk)
    self.isAtk = isAtk
    ---@type number[]
    self.selectedHeroes = {}
    ---@type table<number, number> @key: heroCfgId, value: petCompId
    self.hero2PetMap = {}
    ---@type table<number, number> @key: petCompId, value: heroCfgId
    self.pet2HeroMap = {}

    self.isPVPTroopEdit = true
end

--- 关闭PVP部队编辑的上下文
function ReplicaPVPModule:EditPvpTroopFinish()
    self.isAtk = nil
    self.selectedHeroes = nil
    self.hero2PetMap = nil
    self.pet2HeroMap = nil
    self.isPVPTroopEdit = nil
end

---@return wds.ReplicaPvpPresetBrief
function ReplicaPVPModule:EditGetMyTroopPreset()
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return nil
    end

    ---@type wds.ReplicaPvpPresetBrief
    local myPresets = nil
    if self.isAtk then
        myPresets = ModuleRefer.ReplicaPVPModule:GetAttackPresets()
    else
        myPresets = ModuleRefer.ReplicaPVPModule:GetDefendPresets()
    end

    return myPresets
end

function ReplicaPVPModule:EditRebuildSelectedHeroList()
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return
    end

    self.selectedHeroes = {}
    self.hero2PetMap = {}
    self.pet2HeroMap = {}
    local myPresets = self:EditGetMyTroopPreset()
    if myPresets and myPresets.Brief then
        local count = myPresets.Brief:Count()
        for i = 1, count do
            local brief = myPresets.Brief[i]
            self.selectedHeroes[i] = brief.HeroCfgId
            self.hero2PetMap[brief.HeroCfgId] = brief.PetCompId
            self.pet2HeroMap[brief.PetCompId] = brief.HeroCfgId
            -- g_Logger.Error('update bind hero %s to pet comp %s', brief.HeroCfgId, brief.PetCompId)
        end
    end
end

---@param list UITroopHeroCardData[]
function ReplicaPVPModule:EditUpdateSelectedHeroList(list)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return false
    end

    self.selectedHeroes = {}
    self.hero2PetMap = {}
    self.pet2HeroMap = {}
    for i, heroCardData in ipairs(list) do
        local petCompId = heroCardData.petCompId
        local heroCfgId = heroCardData.heroCfgId
        self.selectedHeroes[i] = heroCfgId

        -- 宠物绑定关系
        if petCompId and petCompId > 0 then
            self.pet2HeroMap[petCompId] = heroCfgId
            self.hero2PetMap[heroCfgId] = petCompId
        end
    end

    self.selectedHeroes = UITroopHelper.SortHeroList(self.selectedHeroes) or {}
    return true
end

function ReplicaPVPModule:EditGetSelectedHeroCount()
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
    end

    return #self.selectedHeroes
end

---@return boolean
function ReplicaPVPModule:EditNeedSavePreset()
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return false
    end

    -- 自己选中的阵容是空
    if table.isNilOrZeroNums(self.selectedHeroes) then
        return false
    end

    local myPresets = self:EditGetMyTroopPreset()
    if myPresets == nil then
        return true
    end

    -- 阵容跟上次服务器保存的有不同
    local selectCount = #self.selectedHeroes
    local presetCount = myPresets.Brief:Count()
    if selectCount ~= presetCount then
        return true
    end

    for i = 1, selectCount do
        local brief = myPresets.Brief[i]
        if self.selectedHeroes[i] ~= brief.HeroCfgId then
            return true
        end

        local petCompId = self.hero2PetMap[self.selectedHeroes[i]] or 0
        if petCompId ~= brief.PetCompId then
            return true
        end
    end

    return false
end

---取自己进攻或防守阵容的3D模型数据
---@return ModelViewData
function ReplicaPVPModule:EditGetMyTroopViewData()
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return nil
    end

    local heroCfgIds = {}
    local petCfgIds = {}
    for i = 1, 3 do
        local heroCfgId = self.selectedHeroes[i]
        if heroCfgId then
            heroCfgIds[i] = heroCfgId
            local petCompId = self.hero2PetMap[heroCfgId] or 0
            local petData = ModuleRefer.PetModule:GetPetByID(petCompId)
            if petData then
                petCfgIds[i] = petData.ConfigId
            else
                petCfgIds[i] = 0
            end
        end
    end

    return UI3DTroopModelViewHelper.CreateTroopViewData(heroCfgIds, petCfgIds)
end

---@param index number
function ReplicaPVPModule:EditGetMyHeroCardData(index)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return nil
    end

    local heroCfgId = self.selectedHeroes[index]
    if heroCfgId == nil then
        return nil
    end

    ---@type UITroopHeroCardData
    local data = {}
    -- 英雄信息
    data.heroCfgId = heroCfgId
    local heroCache = ModuleRefer.HeroModule:GetHeroByCfgId(heroCfgId)
    data.heroLevel = heroCache.lv
    data.heroStrengthenLevel = heroCache.star

    -- 宠物信息
    local bindPetId = self.hero2PetMap[heroCfgId] or 0
    local petData = ModuleRefer.PetModule:GetPetByID(bindPetId)
    if petData then
        data.petCompId = petData.ID
        data.petLevel = petData.Level
        data.petRankLevel = petData.RankLevel
        data.petUnlockNum = petData.TemplateIds and petData.TemplateIds:Count() or 0
    end

    return data
end

---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function ReplicaPVPModule:EditSendSaveTroopPreset(callback)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return
    end

    local req = ReplicaPvpModifyPresetParameter.new()
    req.args.Param.IsAtk = self.isAtk
    for _, heroCfgId in ipairs(self.selectedHeroes) do
        ---@type wrpc.ReplicaPvpPresetHero
        local heroInfo = wrpc.ReplicaPvpPresetHero.New()
        heroInfo.HeroCfgId = heroCfgId
        heroInfo.PetCompId = self.hero2PetMap[heroCfgId] or 0
        req.args.Param.HeroInfos:Add(heroInfo)
    end
    req:SendOnceCallback(nil, nil, nil, callback)
end

function ReplicaPVPModule:EditGetSelectHeroList()
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return
    end

    return self.selectedHeroes
end

function ReplicaPVPModule:EditGetHeroLinkPet(heroCfgId)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return 0
    end

    return self.hero2PetMap[heroCfgId] or 0
end

function ReplicaPVPModule:EditGetPetLinkHero(petCompId)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return 0
    end

    return self.pet2HeroMap[petCompId] or 0
end

---@param petType number @ PetConfigCell Type
function ReplicaPVPModule:EditGetAllPetLinkHeros(petType)
    local heroes = {}
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return heroes
    end

    for petCompId, heroCfgId in pairs(self.pet2HeroMap) do
        local petData = ModuleRefer.PetModule:GetPetByID(petCompId)
        if petData then
            local petConfigCell = ConfigRefer.Pet:Find(petData.ConfigId)
            if petConfigCell and petConfigCell:Type() == petType then
                table.insert(heroes, heroCfgId)
            end
        end
    end

    return heroes
end

--- 上阵英雄
---@param heroCfgId number
---@return boolean
function ReplicaPVPModule:EditHeroAdd(heroCfgId)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return false
    end

    if table.ContainsValue(self.selectedHeroes, heroCfgId) then
        g_Logger.Error('尝试上阵已上场的英雄!!!')
        return false
    end

    if #self.selectedHeroes >= 3 then
        g_Logger.Error('尝试上阵超过3个英雄!!!')
        return false
    end

    table.insert(self.selectedHeroes, heroCfgId)
    self.selectedHeroes = UITroopHelper.SortHeroList(self.selectedHeroes) or {}
    return true
end

--- 下阵英雄
---@param heroCfgId number
function ReplicaPVPModule:EditHeroDelete(heroCfgId)
    if not self.isPVPTroopEdit then
        g_Logger.Error('此方法在竞技场编队下才能正常使用!!!')
        return false
    end

    if not table.ContainsValue(self.selectedHeroes, heroCfgId) then
        g_Logger.Error('尝试下阵不在场上的英雄!!!')
        return false
    end

    table.removebyvalue(self.selectedHeroes, heroCfgId)
    local tmp = {}
    local index = 1
    for _, v in pairs(self.selectedHeroes) do
        tmp[index] = v
        index = index + 1
    end
    self.selectedHeroes = UITroopHelper.SortHeroList(tmp) or {}
    return true
end

return ReplicaPVPModule
