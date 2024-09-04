local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local Utils = require("Utils")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local TimerUtility = require("TimerUtility")
local EventConst = require("EventConst")
local NumberFormatter = require("NumberFormatter")
local SELogger = require("SELogger")
local SEEnvironmentModeType = require("SEEnvironmentModeType")

--local BATTLE_TYPE_NORMAL = 0
--local BATTLE_TYPE_BOSS = 1
local BATTLE_TYPE_PET = 2
local BATTLE_TYPE_NPC = 3

local SP_HERO_BACK_IMG_PREFIX = "sp_hero_frame_circle_"

local SHOW_PET_TIME = 3
local SHOW_CARD_TIME = 1.2

---@class SEHudBattlePanel : BaseUIComponent
---@field super BaseUIComponent
local SEHudBattlePanel = class('SEHudBattlePanel',BaseUIComponent)

SEHudBattlePanel.CardItemCompNodeNames = {
	[1] = "p_btn_skill",
	[2] = "p_btn_skill_1",
	[3] = "p_btn_skill_2",
}

function SEHudBattlePanel:ctor()
    BaseUIComponent.ctor(self)
    self._enemyRoundCurr = 0
    self._enemyRoundTotal = 0
	---@type Timer
	self._showPetTimer = nil
	---@type Timer
	self._showPetTimerEnemy = nil
	---@type table<number, Timer>
	self._showCardTimer = {}
	self._tmpBattleSpeed = 1
	self._noCardMode = false
	self._noAutoMode = false
end

function SEHudBattlePanel:OnCreate(param)
    self:InitObjects(param.type)
end

function SEHudBattlePanel:OnShow(param)
	self._env = require("SEEnvironment").Instance(true)
	local autoEntryId = ConfigRefer.ConstSe:SeAutoUnlock()
	local isAutoBattleUnlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(autoEntryId)
	self._autoBattleNode:SetActive(true and not self._noAutoMode)
	--self._autoBattleButtonNode:SetActive(isAutoBattleUnlocked)
	self._autoBattleButtonNode:SetActive(false)
	self._autoBattleSpeedNode:SetActive(isAutoBattleUnlocked)
	self._btnSpeedOn.gameObject:SetActive(true)
	self._btnSpeedOn2.gameObject:SetActive(false)
	self._btnSpeedOn1.gameObject:SetActive(true)
	self._btnSpeedOff.gameObject:SetActive(false)
	self._btnSpeedOff1:SetActive(false)
	self._btnSpeedOff2:SetActive(false)

	g_Game.EventManager:AddListener(EventConst.SE_TIMELINE_START, Delegate.GetOrCreate(self, self.OnTimelineStart))
	g_Game.EventManager:AddListener(EventConst.SE_TIMELINE_END, Delegate.GetOrCreate(self, self.OnTimelineEnd))
	g_Game.EventManager:AddListener(EventConst.SE_BATTLE_SPEED_REFRESH, Delegate.GetOrCreate(self, self.OnBattleSpeedRefresh))
	for _, value in pairs(self._cardEnterEffect) do
		value:SetVisible(false)
	end
	self._node_cardshow_eff:SetActive(true)
	self:OnBattleSpeedRefresh()
end

function SEHudBattlePanel:OnHide(param)
	g_Game.EventManager:RemoveListener(EventConst.SE_TIMELINE_START, Delegate.GetOrCreate(self, self.OnTimelineStart))
	g_Game.EventManager:RemoveListener(EventConst.SE_TIMELINE_END, Delegate.GetOrCreate(self, self.OnTimelineEnd))
	g_Game.EventManager:RemoveListener(EventConst.SE_BATTLE_SPEED_REFRESH, Delegate.GetOrCreate(self, self.OnBattleSpeedRefresh))
	self._env = nil
end

function SEHudBattlePanel:ResetAniState()
	for _, v in pairs(self._heroDeathAnim) do
		v:SetAnimationNormalizedTimeByIndex(0, 0)
		v:Sample()
		v:Stop()
	end
	for _, v in pairs(self._heroHealAnim) do
		v:SetAnimationNormalizedTimeByIndex(0, 0)
		v:Sample()
		v:Stop()
	end
	for _, v in pairs(self._heroWarningOpenAnim) do
		v:StopAll()
		v:ResetAll()
	end
	for _, v in pairs(self._heroWarningCloseAnim) do
		v:StopAll()
		v:ResetAll()
	end
end

function SEHudBattlePanel:OnClose(param)
	--这个ui 会被缓存 所以在OnCLOSE 需要做一些恢复初始状态
	self:ResetAniState()
end

---@param self SEHudBattlePanel
function SEHudBattlePanel:InitObjects(type)
	self.selfGo = self:GameObject("")
	self._timeHint = self:GameObject("p_time_hint")
	self._timeHintText = self:Text("p_text_setimer")

	self._cardAreaBase = self:GameObject("p_card_area_base")

	---@type table<SEHudBattleSkillCardItem>
    self._cardItems = {}
    self._cardItems[1] = self:LuaObject(SEHudBattlePanel.CardItemCompNodeNames[1])
    self._cardItems[2] = self:LuaObject(SEHudBattlePanel.CardItemCompNodeNames[2])
    self._cardItems[3] = self:LuaObject(SEHudBattlePanel.CardItemCompNodeNames[3])

	---@type table<number, CS.UnityEngine.GameObject>
	self._cardEnterEffect = {}
	self._node_cardshow_eff = self:GameObject("node_cardshow_eff")
	self._cardEnterEffect[1] = self:GameObject("node_cardshow_eff_left")
	self._cardEnterEffect[2] = self:GameObject("node_cardshow_eff_mid")
	self._cardEnterEffect[3] = self:GameObject("node_cardshow_eff_right")

    self._innerCancelArea = self:GameObject("p_btn_cancel")
    self._outerCancelArea = self:GameObject("p_base_cancel")
    self._friendCardText = self:Text("p_text_friend", "setroop_petcard_group")

	self._skillTipNode = self:GameObject("p_skill_tip")
    ---@type SEHudTipsSkillCard
    self._tipsSkillCard = self:LuaObject("child_tips_skill_card")

	self._bossHpArea = self:GameObject("p_group_boss_bar")

	---@type table<number, CS.UnityEngine.GameObject>
	self._bossHp = {}
	self._bossHpFront = {}
	self._bossHpBack = {}
	self._bossPhases = {}
	self._bossLevelText = {}
	self._bossName = {}
	self._bossIcon = {}

	self._bossHpFrontNormal = self:Slider("p_progress_fill_b")
	self._bossHpBackNormal = self:Image("p_progress_fill_a")

	self._bossHpFrontPet = self:Slider("p_progress_fill_d")
	self._bossHpBackPet = self:Image("p_progress_fill_c")

	self._bossHpFrontNpc = self:Slider("p_progress_fill_f")
	self._bossHpBackNpc = self:Image("p_progress_fill_e")

    self._bossHp[1] = self:GameObject("p_progress_boss")
    self._bossHpFront[1] = self._bossHpFrontNormal
    self._bossHpBack[1] = self._bossHpBackNormal
    self._bossName[1] = self:Text("p_text_name_boss")
    self._bossPhases[1] = {}
    self._bossPhases[1][1] = self:BindComponent("p_slider_a", typeof(CS.UnityEngine.UI.Slider))
    self._bossPhases[1][2] = self:BindComponent("p_slider_b", typeof(CS.UnityEngine.UI.Slider))
    self._bossPhases[1][3] = self:BindComponent("p_slider_c", typeof(CS.UnityEngine.UI.Slider))
	self._bossLevelText[1] = self:Text("p_text_boss_lv", "")
	self._bossIcon[1] = self:Image("p_img_monster")

	self._bossHp[2] = self:GameObject("p_progress_boss_1")
    self._bossHpFront[2] = self:BindComponent("p_progress_fill_b_1", typeof(CS.UnityEngine.UI.Slider))
    self._bossHpBack[2] = self:Image("p_progress_fill_a_1")
    self._bossName[2] = self:Text("p_text_name_boss_1")
    self._bossPhases[2] = {}
    self._bossPhases[2][1] = self:BindComponent("p_slider_a_1", typeof(CS.UnityEngine.UI.Slider))
    self._bossPhases[2][2] = self:BindComponent("p_slider_b_1", typeof(CS.UnityEngine.UI.Slider))
    self._bossPhases[2][3] = self:BindComponent("p_slider_c_1", typeof(CS.UnityEngine.UI.Slider))
	self._bossLevelText[2] = self:Text("p_text_boss_lv_1", "")
	self._bossIcon[2] = self:Image("p_img_monster_1")

	self._bossHp[3] = self:GameObject("p_progress_boss_2")
    self._bossHpFront[3] = self:BindComponent("p_progress_fill_b_2", typeof(CS.UnityEngine.UI.Slider))
    self._bossHpBack[3] = self:Image("p_progress_fill_a_2")
    self._bossName[3] = self:Text("p_text_name_boss_2")
    self._bossPhases[3] = {}
    self._bossPhases[3][1] = self:BindComponent("p_slider_a_2", typeof(CS.UnityEngine.UI.Slider))
    self._bossPhases[3][2] = self:BindComponent("p_slider_b_2", typeof(CS.UnityEngine.UI.Slider))
    self._bossPhases[3][3] = self:BindComponent("p_slider_c_2", typeof(CS.UnityEngine.UI.Slider))
	self._bossLevelText[3] = self:Text("p_text_boss_lv_2", "")
	self._bossIcon[3] = self:Image("p_img_monster_2")

	self._heroBackImg = {}
	self._heroStatus = {}
	self._heroStatusImg = {}
	self._heroStatusDeadImg = {}
	self._heroStatusHp = {}
	self._heroStatusDeath = {}
	self._heroStatusWarning = {}
	---@type table<number, CS.UnityEngine.Animation>
	self._heroDeathAnim = {}
	---@type table<number, CS.UnityEngine.Animation>
	self._heroHealAnim = {}
	---@type table<number, CS.FpAnimation.FpAnimatorTotalCommander>
	self._heroWarningOpenAnim = {}
	---@type table<number, CS.FpAnimation.FpAnimatorTotalCommander>
	self._heroWarningCloseAnim = {}

	self._heroBackImg[1] = self:Image("p_hero_base_01")
	self._heroBackImg[2] = self:Image("p_hero_base_02")
	self._heroBackImg[3] = self:Image("p_hero_base_03")
	self._heroStatus[1] = self:GameObject("p_hero_01")
	self._heroStatus[2] = self:GameObject("p_hero_02")
	self._heroStatus[3] = self:GameObject("p_hero_03")
	self._heroStatusImg[1] = self:Image("p_img_hero_01")
	self._heroStatusImg[2] = self:Image("p_img_hero_02")
	self._heroStatusImg[3] = self:Image("p_img_hero_03")
	self._heroStatusDeadImg[1] = self:Image("p_img_hero_dead_01")
	self._heroStatusDeadImg[2] = self:Image("p_img_hero_dead_02")
	self._heroStatusDeadImg[3] = self:Image("p_img_hero_dead_03")
	self._heroStatusHp[1] = self:BindComponent("p_progress_hero_01", typeof(CS.UnityEngine.UI.Slider))
	self._heroStatusHp[2] = self:BindComponent("p_progress_hero_02", typeof(CS.UnityEngine.UI.Slider))
	self._heroStatusHp[3] = self:BindComponent("p_progress_hero_03", typeof(CS.UnityEngine.UI.Slider))
	self._heroStatusDeath[1] = self:GameObject("p_status_death_01")
	self._heroStatusDeath[2] = self:GameObject("p_status_death_02")
	self._heroStatusDeath[3] = self:GameObject("p_status_death_03")
	self._heroStatusWarning[1] = self:GameObject("p_status_warning_01")
	self._heroStatusWarning[2] = self:GameObject("p_status_warning_02")
	self._heroStatusWarning[3] = self:GameObject("p_status_warning_03")

	for i = 1, 3 do
		self._heroDeathAnim[i] = self:BindComponent("p_hero_0" .. i, typeof(CS.UnityEngine.Animation))
		self._heroHealAnim[i] = self:BindComponent("p_vx_heal_0" .. i, typeof(CS.UnityEngine.Animation))
		self._heroWarningOpenAnim[i] = self:BindComponent("p_warning_0" .. i, typeof(CS.FpAnimation.FpAnimatorTotalCommander))
		self._heroWarningCloseAnim[i] = self:BindComponent("p_warning_open_0" .. i, typeof(CS.FpAnimation.FpAnimatorTotalCommander))
	end

	self._groupTitle = self:GameObject("p_group_title")
	self._groupTitleText = self:Text("p_text_target")

	self._fullscreenCountdownText = self:Text("p_text_countdown")
	self._p_skill_group = self:GameObject("p_skill_group")
	---@type CS.FpAnimation.FpAnimatorTotalCommander
	self._energyFillGlowTrigger = self:BindComponent("p_energy_fill_glow", typeof(CS.FpAnimation.FpAnimatorTotalCommander))

	self._koNode = self:GameObject("p_ko")
	self._koNode:SetActive(false)

	self._fingerHint = self:GameObject("p_finger_hint")

	self._autoBattleNode = self:GameObject("p_auto")
	self._autoBattleButtonNode = self:GameObject("p_auto_play")
	self._autoBattleSpeedNode = self:GameObject("p_speed")
	self._textAuto = self:Text("p_text_auto", "se_auto")
	self._btnAutoPlayOn = self:Button("p_btn_auto_play_on", Delegate.GetOrCreate(self, self.OnBtnAutoPlayOnClick))
	self._btnAutoPlayOff = self:Button("p_btn_auto_play_off", Delegate.GetOrCreate(self, self.OnBtnAutoPlayOffClick))
	self._btnSpeedOn = self:Button("p_btn_speed_on", Delegate.GetOrCreate(self, self.OnBtnSpeedOnClick))
	self._btnSpeedOn1 = self:GameObject("p_icon_1x_on")
	self._btnSpeedOn2 = self:GameObject("p_icon_2x_on")
	self._btnSpeedOff = self:Button("p_btn_speed_off", Delegate.GetOrCreate(self, self.OnBtnSpeedOffClick))
	self._btnSpeedOff1 = self:GameObject("p_icon_1x_off")
	self._btnSpeedOff2 = self:GameObject("p_icon_2x_off")

	self._targetMiddleNode = self:GameObject("p_target_middle")
	self._targetMiddleText = self:Text("p_text_num_enemy")

	self._skillShowNode = self:GameObject("p_skill_show")
	self._skillShowImg = self:Image("p_img_pet")
	self._skillShowNodeEnemy = self:GameObject("p_skill_show_enemy")
	self._skillShowImgEnemy = self:Image("p_img_pet_enemy")

	self._cardShowNode = {}
	self._cardShowNode[1] = self:GameObject("p_card_skill_01")
	self._cardShowNode[2] = self:GameObject("p_card_skill_02")
	self._cardShowNode[3] = self:GameObject("p_card_skill_03")
	for i = 1, 3 do
		self._cardShowNode[i]:SetVisible(false)
	end

	self._cardShow = {}
	---@type CommonSkillCard
	self._cardShow[1] = self:LuaObject("p_card_show_01")
	---@type CommonSkillCard
	self._cardShow[2] = self:LuaObject("p_card_show_02")
	---@type CommonSkillCard
	self._cardShow[3] = self:LuaObject("p_card_show_03")
	for i = 1, 3 do
		self._cardShow[i]:SetVisible(true)
	end

	self._pvpNode = self:GameObject("p_pvp")
    ---@type PlayerInfoComponent
    self.attackerHeadIcon = self:LuaObject('p_head_attacker')
	self.txtAttackerPower = self:Text('p_text_power_attacker')
    ---@type PlayerInfoComponent
    self.defenderHeadIcon = self:LuaObject('p_head_defender')
	self.txtDefenderPower = self:Text('p_text_power_defender')
	self._tableBuffIcons = self:TableViewPro('p_table_buff')

	for index = 1, 3 do
		local nodeName = SEHudBattlePanel.CardItemCompNodeNames[index]
		self:DragEvent(nodeName,
                Delegate.GetOrCreate(self, self.OnCardItemDragStart),
                Delegate.GetOrCreate(self, self.OnCardItemDrag),
                Delegate.GetOrCreate(self, self.OnCardItemDragEnd),
                false)
        self:PointerDown(nodeName, Delegate.GetOrCreate(self, self.OnCardItemPointerDown))
        self:PointerUp(nodeName, Delegate.GetOrCreate(self, self.OnCardItemPointerUp))
        self:DragCancelEvent(nodeName, Delegate.GetOrCreate(self, self.OnCardItemDragCancel))
	end
end

function SEHudBattlePanel:RefreshPvpInfo()
	local attackerPlayerId = g_Game.StateMachine:ReadBlackboard("SE_PVP_ATTACKER_ID", false)
    local defenderPlayerId = g_Game.StateMachine:ReadBlackboard("SE_PVP_DEFENDER_ID", false)

    ---@type wds.ScenePlayer
    local attacker = self._env:GetWdsManager():GetScenePlayer(attackerPlayerId)
	if attacker then
		self.txtAttackerPower.text = NumberFormatter.Normal(attacker.ScenePlayerPreset.Power)
		self.attackerHeadIcon:FeedData(attacker.BasicInfo.PortraitInfo)
	end

    ---@type wds.ScenePlayer
    local defender = self._env:GetWdsManager():GetScenePlayer(defenderPlayerId)
	if defender then
		self.txtDefenderPower.text = NumberFormatter.Normal(defender.ScenePlayerPreset.Power)
		self.defenderHeadIcon:FeedData(defender.BasicInfo.PortraitInfo)
	end
end

---@param iconsList string[]
function SEHudBattlePanel:RefreshPvpBuffIcons(iconsList)
	self._tableBuffIcons:Clear()
	for _, v in ipairs(iconsList) do
		---@type SEBattleBuffIconCellData
		local cellData = {}
		cellData.iconPath = v
		self._tableBuffIcons:AppendData(cellData)
	end
end

function SEHudBattlePanel:ChangeBossType(type)
	if (type == BATTLE_TYPE_PET) then
		self._bossHpFront[1] = self._bossHpFrontPet
		self._bossHpBack[1] = self._bossHpBackPet
		self._bossHpFrontPet.gameObject:SetActive(true)
		self._bossHpBackPet.gameObject:SetActive(true)
		self._bossHpFrontNormal.gameObject:SetActive(false)
		self._bossHpBackNormal.gameObject:SetActive(false)
		self._bossHpFrontNpc.gameObject:SetActive(false)
		self._bossHpBackNpc.gameObject:SetActive(false)
	elseif (type == BATTLE_TYPE_NPC) then
		self._bossHpFront[1] = self._bossHpFrontNpc
		self._bossHpBack[1] = self._bossHpBackNpc
		self._bossHpFrontPet.gameObject:SetActive(false)
		self._bossHpBackPet.gameObject:SetActive(false)
		self._bossHpFrontNormal.gameObject:SetActive(false)
		self._bossHpBackNormal.gameObject:SetActive(false)
		self._bossHpFrontNpc.gameObject:SetActive(true)
		self._bossHpBackNpc.gameObject:SetActive(true)
	else
		self._bossHpFront[1] = self._bossHpFrontNormal
		self._bossHpBack[1] = self._bossHpBackNormal
		self._bossHpFrontPet.gameObject:SetActive(false)
		self._bossHpBackPet.gameObject:SetActive(false)
		self._bossHpFrontNormal.gameObject:SetActive(true)
		self._bossHpBackNormal.gameObject:SetActive(true)
		self._bossHpFrontNpc.gameObject:SetActive(false)
		self._bossHpBackNpc.gameObject:SetActive(false)
	end
end

function SEHudBattlePanel:OnEnemyRoundClick()
	self._env:GetUiBattlePanel():ShowEnemyRoundVx(nil, true)
end

function SEHudBattlePanel:OnCardItemDragStart(go, eventData)
	local battlePanel = self._env and self._env.GetUiBattlePanel and self._env:GetUiBattlePanel()
	if not battlePanel then return end
	battlePanel:OnCardItemDragStart(go, eventData)
end

function SEHudBattlePanel:OnCardItemDrag(go, eventData)
	local battlePanel = self._env and self._env.GetUiBattlePanel and self._env:GetUiBattlePanel()
	if not battlePanel then return end
	battlePanel:OnCardItemDrag(go, eventData)
end

function SEHudBattlePanel:OnCardItemDragEnd(go, eventData)
	local battlePanel = self._env and self._env.GetUiBattlePanel and self._env:GetUiBattlePanel()
	if not battlePanel then return end
	battlePanel:OnCardItemDragEnd(go, eventData)
end

function SEHudBattlePanel:OnCardItemPointerDown(go, eventData)
	local battlePanel = self._env and self._env.GetUiBattlePanel and self._env:GetUiBattlePanel()
	if not battlePanel then return end
	battlePanel:OnCardItemPointerDown(go, eventData)
end

function SEHudBattlePanel:OnCardItemPointerUp(go, eventData)
	local battlePanel = self._env and self._env.GetUiBattlePanel and self._env:GetUiBattlePanel()
	if not battlePanel then return end
	battlePanel:OnCardItemPointerUp(go, eventData)
end

function SEHudBattlePanel:OnCardItemDragCancel(go, eventData)
	local battlePanel = self._env and self._env.GetUiBattlePanel and self._env:GetUiBattlePanel()
	if not battlePanel then return end
	battlePanel:OnCardItemDragCancel(go, eventData)
end

---@param self SEHudBattlePanel
---@param index number
---@return SEHudBattleSkillCardItem
function SEHudBattlePanel:GetCardItem(index)
    return self._cardItems[index]
end

---@param self SEHudBattlePanel
---@return table<number, SEHudBattleSkillCardItem>
function SEHudBattlePanel:GetCardItems()
    return self._cardItems
end

---@param self SEHudBattlePanel
---@param show boolean
function SEHudBattlePanel:ShowInnerCancelArea(show)
    self._innerCancelArea:SetActive(show)
end

---@param self SEHudBattlePanel
---@param cancelling boolean
function SEHudBattlePanel:ShowOuterCancelArea(cancelling)
    self._outerCancelArea:SetActive(cancelling)
end

---@param self SEHudBattlePanel
---@return UnityEngine.Rect
function SEHudBattlePanel:GetCancelAreaScreenRect()
    return self._innerCancelArea.transform:GetScreenRect(g_Game.UIManager:GetUICamera())
end

---@param slef SEHudBattlePanel
---@param cardConfigId number
---@param level number
function SEHudBattlePanel:ShowCardTips(cardConfigId, level)
    if (self._tipsSkillCard) then
		self._skillTipNode:SetActive(true and not self._noCardMode)
        self._tipsSkillCard:ShowSECardTips(cardConfigId, self._env:GetUnitManager(), false, false, level)
    end
end

---@param self SEHudBattlePanel
function SEHudBattlePanel:HideCardTips()
	self._skillTipNode:SetActive(false)
end

---@param self SEHudBattlePanel
---@param show boolean
---@param hideMiddle boolean
function SEHudBattlePanel:ShowGroupTitleText(show, hideMiddle)
	if (Utils.IsNotNull(self._targetMiddleNode)) then
		if (hideMiddle) then
			self._targetMiddleNode:SetActive(false)
		else
			self._targetMiddleNode:SetActive(show and not self._noCardMode)
		end
	end
	if (Utils.IsNotNull(self._groupTitle)) then
		self._groupTitle:SetActive(show)
	end
	if (Utils.IsNotNull(self._groupTitleText)) then
		self._groupTitleText.gameObject:SetActive(show)
	end
end

---@param self SEHudBattlePanel
---@param current number
---@param total number
function SEHudBattlePanel:UpdateGroupTitleText(current, total)
    if (not current or current < 0) then
        current = self._enemyRoundCurr
    else
        self._enemyRoundCurr = current
    end
    if (not total or total < 0) then
        total = self._enemyRoundTotal
    else
        self._enemyRoundTotal = total
    end
    if (not total or total <= 0) then
        self:ShowGroupTitleText(false)
        return
    end
	if self._env and self._env:GetEnvMode() == SEEnvironmentModeType.CityScene then
		self:ShowGroupTitleText(false)
		return
	end
    self:ShowGroupTitleText(true)
	self._targetMiddleText.text = string.format("%s/%s", current, total)
    self._groupTitleText.text = string.format("%s/%s", current, total)
	self._groupTitleText.text = I18N.GetWithParams("se_target_wave", current, total)
end

---@param self SEHudBattleEnergyComponent
---@param index number
---@param icon number
function SEHudBattlePanel:LoadBossIcon(index, icon)
	if (Utils.IsNull(self._bossIcon[index])) then return end
	self:LoadSprite(icon, self._bossIcon[index])
end

function SEHudBattlePanel:LoadHeroStatusIcon(index, icon)
	if (Utils.IsNotNull(self._heroStatusImg[index])) then
		self:LoadSprite(icon, self._heroStatusImg[index])
	end
	if (Utils.IsNotNull(self._heroStatusDeadImg[index])) then
		self:LoadSprite(icon, self._heroStatusDeadImg[index])
	end
end

function SEHudBattlePanel:LoadHeroBackImg(index, quality)
	if (Utils.IsNotNull(self._heroBackImg[index])) then
		g_Game.SpriteManager:LoadSprite(SP_HERO_BACK_IMG_PREFIX .. (quality + 2), self._heroBackImg[index])
	end
end

function SEHudBattlePanel:ShowFingerHint(show)
	if (Utils.IsNotNull(self._fingerHint)) then
		self._fingerHint:SetActive(show)
	end
end

function SEHudBattlePanel:OnBtnAutoPlayOnClick()
	self._env:SendAutoCastPetCardRequest(false)
end

function SEHudBattlePanel:OnBtnAutoPlayOffClick()
	self._env:SendAutoCastPetCardRequest(true)
end

function SEHudBattlePanel:UpdateAutoBattleButton()
	-- SELogger.LogError('UpdateAutoBattleButton: %s', self._env:IsAutoBattle())
	if not self._env then return end -- 进入爬塔se后，SEUiBattlePaneld的监听调用另一个已经hide的SEHudBattlePanel实例，此处临时处理
	if (self._env:IsAutoBattle()) then
		self._btnAutoPlayOn.gameObject:SetActive(true)
		self._btnAutoPlayOff.gameObject:SetActive(false)
	else
		self._btnAutoPlayOn.gameObject:SetActive(false)
		self._btnAutoPlayOff.gameObject:SetActive(true)
	end
end

-- bugfix: 播放timeline的时候希望恢复到1倍速
function SEHudBattlePanel:OnTimelineStart()
	self._tmpBattleSpeed = self._env:GetBattleSpeed()
	self:OnBtnSpeedOffClick()
end

-- bugfix: 播放timeline的时候希望恢复到1倍速
function SEHudBattlePanel:OnTimelineEnd()
	if self._tmpBattleSpeed > 1 then
		self:OnBtnSpeedOnClick()
	end
end

function SEHudBattlePanel:OnBattleSpeedRefresh()
	local speed = self._env:GetBattleSpeed()
	local speedIsOne = (math.abs(speed - 1) < 0.001)
	local speedIsTwo = (math.abs(speed - 2) < 0.001)
	self._btnSpeedOn2.gameObject:SetActive(speedIsTwo)
	self._btnSpeedOn1.gameObject:SetActive(speedIsOne)
end

function SEHudBattlePanel:OnBtnSpeedOffClick()
	if (self._env._uiBattlePanel:SpeedUpOff(self._btnSpeedOff.transform)) then
		self._btnSpeedOn2.gameObject:SetActive(false)
		self._btnSpeedOn1.gameObject:SetActive(true)
	end
end

function SEHudBattlePanel:OnBtnSpeedOnClick()
	if (math.abs(self._env:GetBattleSpeed() - 1) < 0.001) then
		if (self._env._uiBattlePanel:SpeedUpOn(self._btnSpeedOn.transform)) then
			self._btnSpeedOn2.gameObject:SetActive(true)
			self._btnSpeedOn1.gameObject:SetActive(false)
		end
	elseif (self._env._uiBattlePanel:SpeedUpOff(self._btnSpeedOn.transform)) then
		self._btnSpeedOn2.gameObject:SetActive(false)
		self._btnSpeedOn1.gameObject:SetActive(true)
	end
end

function SEHudBattlePanel:ShowPet(imageId)
	if (self._showPetTimer) then
		self._showPetTimer:Stop()
	end
	self:LoadSprite(imageId, self._skillShowImg)
	self._skillShowNode:SetActive(true)
	self._showPetTimer = TimerUtility.DelayExecute(function()
		if (Utils.IsNotNull(self._skillShowNode)) then
			self._skillShowNode:SetActive(false)
		end
	end, SHOW_PET_TIME)
end

function SEHudBattlePanel:ShowPetEnemy(imageId)
	if self._showPetTimerEnemy then
		self._showPetTimerEnemy:Stop()
	end
	self:LoadSprite(imageId, self._skillShowImgEnemy)
	self._skillShowNodeEnemy:SetActive(true)
	self._showPetTimerEnemy = TimerUtility.DelayExecute(function()
		if Utils.IsNotNull(self._skillShowNodeEnemy) then
			self._skillShowNodeEnemy:SetActive(false)
		end
	end, SHOW_PET_TIME)
end

function SEHudBattlePanel:ShowCard(index, cardId)
	if (not self._cardShow[index]) then return end
	if (self._showCardTimer[index]) then
		self._showCardTimer[index]:Stop()
	end
	self._cardShow[index]:FeedData({
		cardId = cardId,
		forceHideHeroIcon = true,
	})
	self._cardShowNode[index]:SetVisible(true)
	self._showCardTimer[index] = TimerUtility.DelayExecute(function()
		self._cardShowNode[index]:SetVisible(false)
	end, SHOW_CARD_TIME)
end

function SEHudBattlePanel:ShowCardEnterEffect(tableToShow)
	for _, value in pairs(self._cardEnterEffect) do
		value:SetVisible(false)
	end
	if not tableToShow then return end
	for key, _ in pairs(tableToShow) do
		local g = self._cardEnterEffect[key]
		if Utils.IsNotNull(g) then
			g:SetVisible(true)
		end
	end
end

function SEHudBattlePanel:SetNoCardMode(noCardMode)
	self._noCardMode = noCardMode
	self._p_skill_group:SetVisible(not noCardMode)
end

function SEHudBattlePanel:SetNoAutoMode(noAutoMode)
	self._noAutoMode = noAutoMode
	self._autoBattleNode:SetVisible(not noAutoMode)
end

return SEHudBattlePanel
