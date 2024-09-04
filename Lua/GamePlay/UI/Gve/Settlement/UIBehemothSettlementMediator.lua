---scene: scene_league_behemoth_settlement
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local SlgTouchMenuHelper = require('SlgTouchMenuHelper')
local TimerUtility = require('TimerUtility')
---@class UIBehemothSettleMediator : BaseUIMediator
local UIBehemothSettlementMediator = class('UIBehemothSettleMediator', BaseUIMediator)

---@class UIBehemothSettleMediatorParam
---@field isGve boolean @false 则表示slg大地图战斗
---@field isWin boolean
---@field autoClose boolean
---@field startTime number | google.protobuf.Timestamp
---@field endTime number | google.protobuf.Timestamp
---@field soldierRank wrpc.DamagePlayerInfo[] | nil @用于slg伤害信息，gve不用传
---@field gveBehemoth
---@field slgBehemoth BehemothTroopCtrl | nil

function UIBehemothSettlementMediator:ctor()
    self.autoCloseSec = 5
    self.secTickStart = false
end

function UIBehemothSettlementMediator:OnCreate()
    self.goVictory = self:GameObject('p_win')
    self.goDefeat = self:GameObject('p_lose')
    self.textBattleInfo = self:Text('p_text_battle_info', '*p_text_battle_info')

    self.goBehemoth = self:GameObject('p_behemoth')
    self.goRank = self:GameObject('p_ranking')
    self.textLabelTime = self:Text('p_text_time', 'alliance_behemoth_title_wartime')
    self.luatimer = self:LuaObject('child_time')

    self.imgBehemoth = self:Image('p_img_behemoth')
    self.textResult = self:Text('p_text_result')

    self.goTableRank = self:GameObject('p_ranking')
    self.tableRank = self:TableViewPro('p_table_ranking')
    self.luaSelfRankCell = self:LuaObject('p_content_me')

    self.textHeaderRank = self:Text('p_text_title_ranking', 'alliance_behemoth_title_ranknum')
    self.textHeaderPlayer = self:Text('p_text_title_player', 'alliance_behemoth_title_playername')
    self.textHeaderDamage = self:Text('p_text_title_output', 'alliance_behemoth_title_damage')
    self.textHeaderDamageTaken = self:Text('p_text_title_damage', 'alliance_behemoth_title_injured')
    self.textHeaderHealing = self:Text('p_text_title_healing', '*治疗量')

    self.goGroupContinue = self:GameObject('p_group_continue')
    self.textTabToContinue = self:Text('p_text_continue_1', 'alliance_behemoth_war_close')
    self.textAutoClose = self:Text('p_text_continue_2', 'alliance_behemoth_war_close')

    self.btnClose = self:Button('p_finish', Delegate.GetOrCreate(self, self.OnBtnFinishClicked))
    self.vxTrigger = self:AnimTrigger('vx_trigger')

    self.goUpgradeRank = self:GameObject('p_upgrad_rank')
    self.imgBehemothRank = self:Image('p_img_behemoth_1')
    self.textLv1 = self:Text('p_text_lv_2')
    self.textLv2 = self:Text('p_text_lv_3')
end

---@param param UIBehemothSettleMediatorParam
function UIBehemothSettlementMediator:OnOpened(param)
    self.isGve = param.isGve
    self.autoClose = param.autoClose
    self.goRank:SetActive(true)
    self.goVictory:SetActive(param.isWin)
    self.goDefeat:SetActive(not param.isWin)
    self.goGroupContinue:SetActive(true)
    self.textAutoClose.gameObject:SetActive(param.autoClose)
    self.textTabToContinue.gameObject:SetActive(not param.autoClose)
    if self.isGve then
        self:InitInfoFromGve(param)
    else
        self:InitInfoFromSlg(param)
    end
    self.startTime = param.startTime
    self.endTime = param.endTime
    self:InitDuration()
    if param.isWin then
        self:PlayVictoryAnim()
    else
        self:PlayDefeatAnim(not self.noDamage)
    end
end

function UIBehemothSettlementMediator:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function UIBehemothSettlementMediator:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

---@param param UIBehemothSettleMediatorParam
function UIBehemothSettlementMediator:InitInfoFromGve(param)
    self.goUpgradeRank:SetActive(true)
    local damageList, totalDamage, maxplayerDamage, totalDamageTaken, maxDamageTaken = ModuleRefer.GveModule:GetBossDamageDatas()
    local behemothCfg = ConfigRefer.KmonsterData:Find(ModuleRefer.GveModule:GetBossData().MobInfo.MobID)
    local behemothName = I18N.Get(behemothCfg:Name())
    local lvl = ModuleRefer.GveModule:GetBossData().MobInfo.Level
    local _, icon, _, _, _, bodyPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(behemothCfg)
    if param.isWin then
        self.goUpgradeRank:SetActive(true)
        self.textResult.text = I18N.GetWithParams('alliance_behemoth_cage_log4', lvl, behemothName)
        self.textLv1.text = string.format("Lv. %d", lvl)
        self.textLv2.text = string.format("Lv. %d", lvl + 1)
        g_Game.SpriteManager:LoadSprite(icon, self.imgBehemothRank)
    else
        self.goUpgradeRank:SetActive(false)
        self.textResult.text = I18N.Get('alliance_behemoth_war_settlement2')
    end
    g_Game.SpriteManager:LoadSprite(bodyPaint, self.imgBehemoth)
    if totalDamage == 0 and totalDamageTaken == 0 then
        self.goTableRank:SetActive(false)
        self.noDamage = true
        return
    end
    self:FillRankTable(damageList, totalDamage, maxplayerDamage, totalDamageTaken, maxDamageTaken)
end

---@param param UIBehemothSettleMediatorParam
function UIBehemothSettlementMediator:InitInfoFromSlg(param)
    self.goUpgradeRank:SetActive(false)
    local behemoth = param.slgBehemoth
    local behemothBuildingCfg = ConfigRefer.FixedMapBuilding:Find(behemoth.cageEntity.BehemothCage.ConfigId)
    local behemothCageCfg = ConfigRefer.BehemothCage:Find(behemothBuildingCfg:BehemothCageConfig())
    local behemothCfg = ConfigRefer.KmonsterData:Find(behemothCageCfg:Monster())
    local behemothName = I18N.Get(behemothCfg:Name())
    local lvl = behemoth._data.MobInfo.Level
    if param.isWin then
        self.textResult.text = I18N.GetWithParams('alliance_behemoth_cage_log4', lvl, behemothName)
    else
        self.textResult.text = I18N.Get('alliance_behemoth_war_settlement2')
    end
    local _, _, _, _, _, bodyPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(behemothCfg)
    g_Game.SpriteManager:LoadSprite(bodyPaint, self.imgBehemoth)

    local totalDamge = 0
    local maxDamage = 0
    local totalDamageTaken = 0
    local maxDamageTaken = 0
    for _, damage in ipairs(param.soldierRank) do
        totalDamge = totalDamge + damage.damage
        totalDamageTaken = totalDamageTaken + damage.TakeDamage
        if damage.damage > maxDamage then
            maxDamage = damage.damage
        end
        if damage.TakeDamage > maxDamageTaken then
            maxDamageTaken = damage.TakeDamage
        end
    end
    if totalDamge == 0 and totalDamageTaken == 0 then
        self.goTableRank:SetActive(false)
        self.textResult.text = I18N.Get('alliance_behemoth_war_settlement2')
        self.noDamage = true
        return
    end
    self:FillRankTable(param.soldierRank, totalDamge, maxDamage, totalDamageTaken, maxDamageTaken)
end

---@param damageInfos wrpc.DamagePlayerInfo[] | PlayerDamageInfo[]
---@param totalDamage number
---@param maxDamage number
function UIBehemothSettlementMediator:FillRankTable(damageInfos, totalDamage, maxDamage, totalDamageTaken, maxDamageTaken)
    ---@type BehemothSettlementRankCellData
    local selfCellData = nil
    self.tableRank:Clear()
    for i, damage in ipairs(damageInfos) do
        ---@type BehemothSettlementRankCellData
        local cellData = {}
        cellData.index = i
        cellData.isSelf = (damage.PlayerId or damage.playerId) == ModuleRefer.PlayerModule:GetPlayerId()
        cellData.damageInfo = damage
        cellData.allDamage = totalDamage
        cellData.maxPlayerDamage = maxDamage
        cellData.allTakeDamage = totalDamageTaken
        cellData.maxPlayerTakeDamage = maxDamageTaken
        self.tableRank:AppendData(cellData)
        if cellData.isSelf then
            selfCellData = cellData
        end
    end
    if not selfCellData then
        self.luaSelfRankCell:SetVisible(false)
    else
        self.luaSelfRankCell:SetVisible(true)
        self.luaSelfRankCell:FeedData(selfCellData)
    end
end

function UIBehemothSettlementMediator:InitDuration()
    local duration = 0
    if type(self.startTime) == "number" then
        duration = self.endTime - self.startTime
    else
        duration = self.endTime.Seconds - self.startTime.Seconds
    end
    ---@type CommonTimerData
    local data = {}
    data.endTime = g_Game.ServerTime:GetServerTimestampInSeconds() + duration
    data.needTimer = false
    self.luatimer:FeedData(data)
end

function UIBehemothSettlementMediator:OnBtnFinishClicked()
    if ModuleRefer.SlgModule.curScene and ModuleRefer.SlgModule.curScene:GetName() == "SlgScene" then
        ModuleRefer.GveModule:Exit()
    else
        self:CloseSelf()
    end
end

function UIBehemothSettlementMediator:PlayVictoryAnim()
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, Delegate.GetOrCreate(self, self.OnAnimEnd))
end

function UIBehemothSettlementMediator:PlayDefeatAnim(showRank)
    if showRank then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, Delegate.GetOrCreate(self, self.OnAnimEnd))
    else
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, Delegate.GetOrCreate(self, self.OnAnimEnd))
    end
end

function UIBehemothSettlementMediator:OnAnimEnd()
    if self.autoClose then
        self.secTickStart = true
    end
end

function UIBehemothSettlementMediator:OnSecondTick()
    if self.secTickStart then
        self.autoCloseSec = self.autoCloseSec - 1
        if self.autoCloseSec <= 0 then
            self:CloseSelf()
        else
            self.textAutoClose.text = I18N.GetWithParams('alliance_behemoth_war_close', self.autoCloseSec)
        end
    end
end

return UIBehemothSettlementMediator