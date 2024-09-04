local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local GotoUtils = require('GotoUtils')
local UIMediatorNames = require("UIMediatorNames")
---@type HeroModule
local HeroModule = ModuleRefer.HeroModule
local ArtResourceUtils = require("ArtResourceUtils")
local SEUnitCategory = require("SEUnitCategory")

--local CARD_GROUP_INDEX = 1
local MAX_HERO_COUNT = 3
--local MAX_PET_CARD_COUNT = 3
local MAX_MONSTER_COUNT = 3
local MONSTER_SCALE_NORMAL = CS.UnityEngine.Vector3.one * 0.9
local MONSTER_SCALE_BOSS = CS.UnityEngine.Vector3.one * 1.3
local PANEL_RIGHT_X_ORG = 327
local PANEL_RIGHT_X_DST = 1573
local PANEL_DETAIL_X_ORG = 327
local PANEL_DETAIL_X_DST = 0
local PANEL_DETAIL_ALPHA_ORG = 0
local PANEL_DETAIL_ALPHA_DST = 1
local PANEL_TRANSITION_TIME = 0.5
local PANEL_MONSTER_TRANSITION_TIME = 0.3
local PANEL_MONSTER_ALPHA_ORG = 1
local PANEL_MONSTER_ALPHA_DST = 0
local PANEL_MONSTER_DELAY = 0.3
local PAGE_DETAIL_BASIC = 0
local PAGE_DETAIL_WORLD = 1
local PAGE_DETAIL_PRODUCTION = 2

---@class SEHudPreviewMediatorParameter
---@field IsEnterSEMode boolean
---@field OverrideEnterBtnClickCallback fun(seId:number,heroIds):boolean @此项非nil 时 点击进入按钮 调用此函数， 返回值为true 时关闭界面
---@field SeId number
---@field fromType SEHudTroopMediatorDefine.FromType
---@field fromPosX number
---@field fromPosY number
---@field petCompId number
---@field petWildId number
---@field troopId number

---@class SEHudPreviewMediator : BaseUIMediator
local SEHudPreviewMediator = class('SEHudPreviewMediator', BaseUIMediator)

function SEHudPreviewMediator:ctor()
    ---@type SEHudPreviewMediatorParameter
    self._param = nil
    ---@type MapInstanceConfigCell
    self._mapCell = nil
    self._teamName = ""
    self._heroList = {}
    --self._petCardList = {}
    self._totalPower = 0
    self._totalCardCount = 0
    self._totalCardEnergy = 0
	self._detailPanelShown = false
	self._petCompId = 0
    self._creepEntityId = 0
	self._petWildId = 0
	self._petWildCell = nil
	self._petCfgCell = nil
end

function SEHudPreviewMediator:OnCreate(param)
    self._param = param
    self._petCompId = self._param.petCompId or 0
    self._creepEntityId = self._param.creepEntityId or 0
	self._petWildId = self._param.petWildId or 0
	self._troopId = self._param.troopId or 0
	self._petWildCell = ConfigRefer.PetWild:Find(self._petWildId)
	if (self._petWildCell) then
		self._param.SeId = ModuleRefer.PetModule:GetSeMapIdByPetWildId(self._petWildId)
		self._petCfgCell = ConfigRefer.Pet:Find(self._petWildCell:PetId())
	end

	if (not self._param or not self._param.SeId or self._param.SeId <= 0) then
        g_Logger.Error("Param is nil!")
        self:CloseSelf()
        return
    end

    self._mapCell = ConfigRefer.MapInstance:Find(self._param.SeId)
    if (not self._mapCell) then
        g_Logger.Error("Cannot find map instance config id %s!", self._param.SeId)
        self:CloseSelf()
        return
    end

    self:InitObjects()
end

function SEHudPreviewMediator:OnShow(param)
    self:InitData()
    self:Refresh()
end

function SEHudPreviewMediator:OnHide(param)

end

function SEHudPreviewMediator:OnClose(data)
	self:ResetPanels()
end

---@param self SEHudPreviewMediator
function SEHudPreviewMediator:InitObjects()
	self.rightPanel = self:GameObject("p_group_right")
	self.monsterDetailPanel = self:GameObject("p_content_monster_detail")
	self.monsterDetailPanelCanvas = self:BindComponent("p_content_monster_detail", typeof(CS.UnityEngine.CanvasGroup))
	self.monsterDetailTable = self:TableViewPro("p_table_monster")
	self.monsterGroup = self:GameObject("p_group_monster")
	self.monsterGroupCanvas = self:BindComponent("p_group_monster", typeof(CS.UnityEngine.CanvasGroup))
    self.textTitle = self:Text('p_title')
    self.textIntroduction = self:Text('p_text_introduce', I18N.Temp().text_des_se_preview)
    self.monsterList = {}
    self.monsterList[1] = self:Image('p_img_monster_1')
    self.monsterList[2] = self:Image('p_img_monster_2')
    self.monsterList[3] = self:Image('p_img_monster_3')
    self.btnDetail = self:Button('btn_monster_detail', Delegate.GetOrCreate(self, self.OnBtnChildDetailClicked))
	---@type BistateButton
	self.btnEnter = self:LuaObject("child_comp_btn_b")
    --self.textMonsterDetail = self:Text('p_text_detail', '*DETAILS')
    self.textCost = self:Text('p_text_cost')
    self.textName = self:Text('p_text_name')
    --self.btnSetTeam = self:Button('p_btn_set', Delegate.GetOrCreate(self, self.OnBtnSetTeamClicked))
	---@type table<number, HeroInfoItemComponent>
    self.heroInfoList = {}
    self.heroInfoList[1] = self:LuaObject('child_card_hero_m_1')
    self.heroInfoList[2] = self:LuaObject('child_card_hero_m_2')
    self.heroInfoList[3] = self:LuaObject('child_card_hero_m_3')
    self.textPetCards = self:Text('p_text_cards', '*COMPANIONS')
    -- self.petCardList = {}
    -- self.petCardList[1] = self:LuaObject('child_card_skill_1')
    -- self.petCardList[2] = self:LuaObject('child_card_skill_2')
    -- self.petCardList[3] = self:LuaObject('child_card_skill_3')

	self.iconWarning = self:GameObject("icon_arrow")
    self.powerNotEnough = self:GameObject('p_status_a')
    self.textRecommendNotEnough = self:Text('p_text_power_a')
    self.textPowerNotEnough = self:Text('p_text_recommend_a')
    self.powerEnough = self:GameObject('p_status_b')
    self.textRecommendEnough = self:Text('p_text_power_b')
    self.textPowerEnough = self:Text('p_text_recommend_b')
    self.textReward = self:Text('p_text_reward', 'se_chance_get')
    self.tableReward = self:TableViewPro('p_table_reward')
    --self.btnEnter = self:LuaObject('child_comp_btn_b')
    self.textHint = self:Text('p_text_hint')
    self.btnBack = self:Button('p_btn_back', Delegate.GetOrCreate(self, self.OnBtnBackClicked))

	-- 宠物相关
	self.petCatchItemGroup = self:GameObject("p_group_arrest")
	self.textPetCatchItem = self:Text("p_text_arrest")
	self.petCatchItemWarnIcon = self:GameObject("p_icon_arrest")
	self.tablePetCatchItem = self:TableViewPro("p_table_item_arrest")

	self.petDetailPanel = self:GameObject("p_content_pet_detail")
	self.petDetailPanelCanvas = self:BindComponent("p_content_pet_detail", typeof(CS.UnityEngine.CanvasGroup))
	self.textPetName = self:Text("p_text_pet_name")
	self.textPetPreview = self:Text("p_text_preview", I18N.Temp().text_se_preview_property)
	self.petImage = self:Image("p_img_pet")
	---@type CS.PageViewController
	self.detailPageController = self:BindComponent("p_scroll", typeof(CS.PageViewController))
	self.detailPageController.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)

	self.textDetailSETitle = self:Text("p_text_title_basice", I18N.Temp().text_se_property)
	self.textDetailSEContent = self:Text("p_text_detail", I18N.Temp().text_se_property_desc)
	---@type CommonSkillCard
	self.detailSECard = self:LuaObject("child_card_skill")

	self.textDetailWorldTitle = self:Text("p_text_title_map", I18N.Temp().text_se_world_property)
	self.textDetailWorldText = self:Text("p_text_detail_map")

	self.textDetailProductionTitle = self:Text("p_text_title_process", I18N.Temp().text_se_produce_property)
	self.textDetailProductionText = self:Text("p_text_detail_process")

	self.buttonDetailBasicToggle = self:Button("p_btn_01", Delegate.GetOrCreate(self, self.OnDetailBasicToggleButtonClick))
	self.buttonDetailBasicSelected = self:GameObject("p_base_select_01")
	self.buttonDetailWorldToggle = self:Button("p_btn_02", Delegate.GetOrCreate(self, self.OnDetailWorldToggleButtonClick))
	self.buttonDetailWorldSelected = self:GameObject("p_base_select_02")
	self.buttonDetailProductionToggle = self:Button("p_btn_03", Delegate.GetOrCreate(self, self.OnDetailProductionToggleButtonClick))
	self.buttonDetailProductionSelected = self:GameObject("p_base_select_03")
end

function SEHudPreviewMediator:ResetPanels()
	--self.monsterGroup:SetActive(true)
	self.monsterGroupCanvas:DOKill()
	self.monsterGroupCanvas.alpha = PANEL_MONSTER_ALPHA_ORG
	self.rightPanel.transform:DOKill()
	self.rightPanel.transform.localPosition.x = PANEL_RIGHT_X_ORG
	self.monsterDetailPanel.transform:DOKill()
	self.monsterDetailPanel.transform.localPosition.x = PANEL_DETAIL_X_ORG
	self.monsterDetailPanelCanvas:DOKill()
	self.monsterDetailPanelCanvas.alpha = PANEL_DETAIL_ALPHA_ORG
	self.petDetailPanel.transform:DOKill()
	self.petDetailPanel.transform.localPosition.x = PANEL_DETAIL_X_ORG
	self.petDetailPanelCanvas:DOKill()
	self.petDetailPanelCanvas.alpha = PANEL_DETAIL_ALPHA_ORG
end

function SEHudPreviewMediator:OnBtnChildDetailClicked(args)
	if (not self._detailPanelShown) then
		self._detailPanelShown = true
		if (self._petWildId <= 0) then
			local data = {}
			for i = 1, self._mapCell:SeNpcConfLength() do
				local seNpcConf = ConfigRefer.SeNpc:Find(self._mapCell:SeNpcConf(i))
				if (seNpcConf) then
					table.insert(data, {
						image = seNpcConf:MonsterInfoIcon(),
						name = I18N.Get(seNpcConf:Name()),
						detail = I18N.Get(seNpcConf:Des()),
						isBoss = seNpcConf:Category() == SEUnitCategory.Boss,
					})
				end
			end
			self.monsterGroupCanvas:DOKill()
			self.monsterGroupCanvas.alpha = PANEL_MONSTER_ALPHA_DST
			self.monsterDetailTable:Clear()
			for _, item in pairs(data) do
				self.monsterDetailTable:AppendData(item)
			end
			self.monsterDetailTable:RefreshAllShownItem()
			self.monsterDetailPanel.transform:DOKill()
			self.monsterDetailPanel.transform:DOLocalMoveX(PANEL_DETAIL_X_DST, PANEL_TRANSITION_TIME)
			self.monsterDetailPanelCanvas:DOKill()
			self.monsterDetailPanelCanvas:DOFade(PANEL_DETAIL_ALPHA_DST, PANEL_TRANSITION_TIME)
		else
			self.petDetailPanelCanvas:DOKill()
			self.petDetailPanelCanvas:DOFade(PANEL_DETAIL_ALPHA_DST, PANEL_TRANSITION_TIME)
		end

		self.rightPanel.transform:DOKill()
		self.rightPanel.transform:DOLocalMoveX(PANEL_RIGHT_X_DST, PANEL_TRANSITION_TIME)
	else
		self._detailPanelShown = false
		if (self._petWildId <= 0) then
			self.monsterGroupCanvas:DOKill()
			self.monsterGroupCanvas.alpha = PANEL_MONSTER_ALPHA_DST
			self.monsterGroupCanvas:DOFade(PANEL_MONSTER_ALPHA_DST, PANEL_MONSTER_DELAY):OnComplete(function()
				self.monsterGroupCanvas:DOFade(PANEL_MONSTER_ALPHA_ORG, PANEL_MONSTER_TRANSITION_TIME)
			end)
			self.monsterDetailPanel.transform:DOKill()
			self.monsterDetailPanel.transform:DOLocalMoveX(PANEL_DETAIL_X_ORG, PANEL_TRANSITION_TIME)
			self.monsterDetailPanelCanvas:DOKill()
			self.monsterDetailPanelCanvas:DOFade(PANEL_DETAIL_ALPHA_ORG, PANEL_TRANSITION_TIME)
		else
			self.petDetailPanelCanvas:DOKill()
			self.petDetailPanelCanvas:DOFade(PANEL_DETAIL_ALPHA_ORG, PANEL_TRANSITION_TIME)
		end
		self.rightPanel.transform:DOKill()
		self.rightPanel.transform:DOLocalMoveX(PANEL_RIGHT_X_ORG, PANEL_TRANSITION_TIME)
end
end

function SEHudPreviewMediator:OnBtnSetTeamClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.SEHudTroopMediator, {
        onClose = Delegate.GetOrCreate(self, self.OnTroopPanelClose),
    })
end

function SEHudPreviewMediator:OnTroopPanelClose(param)
    self:Refresh()
end

function SEHudPreviewMediator:OnBtnBackClicked(args)
    self:CloseSelf()
end

function SEHudPreviewMediator:OnBtnEnterClicked(args)
	g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", self._param.fromType)
	g_Game.StateMachine:WriteBlackboard("SE_FROM_X", self._param.fromPosX)
	g_Game.StateMachine:WriteBlackboard("SE_FROM_Y", self._param.fromPosY)
	if ModuleRefer.PetModule:CheckIsFullPet() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_amout_limit"))
        return
    end
	-- 宠物抓捕
	if (self._petCompId and self._petCompId > 0) then
		GotoUtils.GotoScenePetCatch(self._param.SeId, self._heroList, self._troopId, self._petCompId)
		self:CloseSelf()
		return
	end

    -- 清除菌毯毒瘤
    if (self._creepEntityId and self._creepEntityId > 0) then
        GotoUtils.GotoSceneClearCreepTumor(self._param.SeId, self._troopId, self._creepEntityId)
        self:CloseSelf()
        return
    end

	-- 普通SE
    if (self._param.OverrideEnterBtnClickCallback) then
        if (self._param.OverrideEnterBtnClickCallback(self._param.SeId, self._heroList)) then
            self:CloseSelf()
        end
    else
        GotoUtils.GotoSceneSe(self._param.SeId, self._heroList)
        self:CloseSelf()
    end
end

---@param self SEHudPreviewMediator
function SEHudPreviewMediator:InitData()
    self.btnEnter:FeedData({
        onClick = Delegate.GetOrCreate(self, self.OnBtnEnterClicked),
    })
end

---@param self SEHudPreviewMediator
function SEHudPreviewMediator:Refresh()
    self:RefreshData()
    self:RefreshUI()
end

function SEHudPreviewMediator:RefreshData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    g_Logger.Assert(player ~= nil, "Player is nil!")
    if (not player) then return end

	-- 全部改为硬读表 -_-;;;
	self._heroList = {}
    self._totalPower = 0
    self._totalCardCount = 0
    self._totalCardEnergy = 0
	--for i = 1, self._mapCell:SeFixHerosLength() do
	--	self._heroList[i] = self._mapCell:SeFixHeros(i)
	--	self._totalPower = self._totalPower + HeroModule:CalcHeroPower(self._heroList[i])
	--end
	--for i = 1, self._mapCell:SeFixCardsLength() do
	--	local card = ConfigRefer.Card:Find(self._mapCell:SeFixCards(i))
	--	if (card) then
	--		self._totalCardCount = self._totalCardCount + 1
	--		self._totalCardEnergy = self._totalCardEnergy + card:Energy()
	--	end
	--end
end

function SEHudPreviewMediator:RefreshUI()
	self:ResetPanels()

    -- 名称
    self.textTitle.text = I18N.Get(self._mapCell:Name())

    -- 简介
    self.textIntroduction.text = I18N.Get(self._mapCell:Desc())

    -- 平均费用
    self.textCost.text = tostring(self._totalCardEnergy / self._totalCardCount * 100 // 10 / 10)

    -- 队伍名称
    self.textName.text = self._teamName

    -- 英雄
    for i = 1, MAX_HERO_COUNT do
        if (not self._heroList[i]) then
            self.heroInfoList[i]:SetVisible(false)
        else
            self.heroInfoList[i]:SetVisible(true)
            self.heroInfoList[i]:FeedData(
                { heroData = HeroModule:GetHeroByCfgId(self._heroList[i]) }
            )
        end
    end

	local showDetailButton = false

    -- 怪物预览
	if (self._petWildId <= 0) then
		self.monsterDetailPanel:SetActive(true)
		for i = 1, MAX_MONSTER_COUNT do
			local active = false
			if (i <= self._mapCell:SeNpcConfLength()) then
				local seNpcId = self._mapCell:SeNpcConf(i)
				local seNpcConf = ConfigRefer.SeNpc:Find(seNpcId)
				if (seNpcConf and seNpcConf:MonsterInfoIcon()) then
					local path = ArtResourceUtils.GetUIItem(seNpcConf:MonsterInfoIcon())
					if (path) then
						self.monsterList[i].gameObject:SetActive(true)
						g_Game.SpriteManager:LoadSprite(path, self.monsterList[i])
						if (i == 1) then
						--if (seNpcConf:Category() == SEUnitCategory.Boss) then
							self.monsterList[i].gameObject.transform.localScale = MONSTER_SCALE_BOSS
						else
							self.monsterList[i].gameObject.transform.localScale = MONSTER_SCALE_NORMAL
						end
						active = true
						showDetailButton = true
					end
				end
			end
			self.monsterList[i].gameObject:SetActive(active)
		end
        self.btnEnter:SetButtonText(I18N.Get("se_start_challenge"))
	else
		self.monsterDetailPanel:SetActive(false)
		self.btnEnter:SetButtonText(I18N.Temp().btn_se_challenge)
		showDetailButton = true
	end

	-- 宠物详情
	if (self._petWildId > 0) then
		showDetailButton = true
		self.petDetailPanel:SetActive(true)
		self.textPetName.text = I18N.Get(self._petCfgCell:Name())
		self.detailSECard:FeedData({
			cardId = self._petCfgCell:CardId(),
			onClick = Delegate.GetOrCreate(self, self.OnPetCardClick),
		})
	else
		self.petDetailPanel:SetActive(false)
	end

	self.btnDetail.gameObject:SetActive(showDetailButton)

    -- 奖励预览
    local rewardCount = 0
    self.tableReward:Clear()
	local mapInstanceRewardCfgCell = ConfigRefer.MapInstanceReward:Find(self._mapCell:Rewards())
    for i = 1, mapInstanceRewardCfgCell:RewardsLength() do
		local reward = mapInstanceRewardCfgCell:Rewards(i)
        local rewardItemCfgCell = ConfigRefer.Item:Find(reward:UnitRewardConf())
        if (rewardItemCfgCell) then
            rewardCount = rewardCount + 1
            self.tableReward:AppendData({
                configCell = rewardItemCfgCell,
                showTips = true,
                showCount = false,
                useNoneMask = false,
            })
        end
    end
    self.tableReward:RefreshAllShownItem()
    self.textReward.gameObject:SetActive(rewardCount > 0)

	-- 宠物抓捕道具
	local totalCount = 0
	if (self._petWildId > 0) then
		self.tablePetCatchItem:Clear()
		self.petCatchItemGroup:SetActive(true)
		local list = ModuleRefer.PetModule:GetPetCatchItemCfgList()
		local hasItem = false
		for _, item in pairs(list) do
			local itemCfg = ConfigRefer.Item:Find(item:ItemCfg())
			local count = ModuleRefer.InventoryModule:GetAmountByConfigId(item:ItemCfg())
			totalCount = totalCount + count
			local data = {
				configCell = itemCfg,
				count = count,
				useNoneMask = count <= 0,
				showTips = true,
			}
			hasItem = hasItem or count > 0
			self.tablePetCatchItem:AppendData(data)
		end
		self.tablePetCatchItem:RefreshAllShownItem()
		self.petCatchItemWarnIcon:SetActive(not hasItem)
	else
		self.petCatchItemGroup:SetActive(false)
	end

	-- 道具不足
	local showPower = true
	if (self._petWildId > 0 and totalCount <= 0) then
		showPower = false
		self.iconWarning:SetActive(true)
		self.powerNotEnough:SetActive(true)
		self.powerEnough:SetActive(false)
		self.textPowerNotEnough.text = I18N.Temp().hint_lake_catch_item
		self.textRecommendNotEnough.text = ""
		self.btnEnter:SetEnabled(false)
	end

	-- 战力
	if (showPower) then
		local recommendedPower = self._mapCell:Power()
		if (self._totalPower >= recommendedPower) then
			self.iconWarning:SetActive(false)
			self.powerNotEnough:SetActive(false)
			self.powerEnough:SetActive(true)
			self.textPowerEnough.text = I18N.GetWithParams("se_ce", self._totalPower)
			self.textRecommendEnough.text = I18N.GetWithParams("se_suggest_ce_1", recommendedPower)
		else
			self.iconWarning:SetActive(true)
			self.powerNotEnough:SetActive(true)
			self.powerEnough:SetActive(false)
			self.textPowerNotEnough.text = I18N.GetWithParams("se_ce", self._totalPower)
			self.textRecommendNotEnough.text = I18N.GetWithParams("se_suggest_ce_1", recommendedPower)
		end
		self.btnEnter:SetEnabled(true)
	end
end

--- 切换到指定属性页
---@param self UIPetMediator
---@param page number
---@param scroll boolean
function SEHudPreviewMediator:SwitchToDetailPage(page, scroll)
	if (page == PAGE_DETAIL_BASIC) then
		self.buttonDetailBasicSelected:SetActive(true)
		self.buttonDetailWorldSelected:SetActive(false)
		self.buttonDetailProductionSelected:SetActive(false)
	elseif (page == PAGE_DETAIL_WORLD) then
		self.buttonDetailBasicSelected:SetActive(false)
		self.buttonDetailWorldSelected:SetActive(true)
		self.buttonDetailProductionSelected:SetActive(false)
	elseif (page == PAGE_DETAIL_PRODUCTION) then
		self.buttonDetailBasicSelected:SetActive(false)
		self.buttonDetailWorldSelected:SetActive(false)
		self.buttonDetailProductionSelected:SetActive(true)
	end
	if (scroll) then
		self.detailPageController:ScrollToPage(page)
	end
end

function SEHudPreviewMediator:OnDetailBasicToggleButtonClick(args)
	self:SwitchToDetailPage(PAGE_DETAIL_BASIC, true)
end

function SEHudPreviewMediator:OnDetailWorldToggleButtonClick(args)
	self:SwitchToDetailPage(PAGE_DETAIL_WORLD, true)
end

function SEHudPreviewMediator:OnDetailProductionToggleButtonClick(args)
	self:SwitchToDetailPage(PAGE_DETAIL_PRODUCTION, true)
end

function SEHudPreviewMediator:OnPageChanged(old, new)
	self:SwitchToDetailPage(new)
end

function SEHudPreviewMediator:OnPetCardClick(cardId)
	---@type UICommonPopupCardDetailParam
	local param = {
		type = 1,
		cfgId = cardId,
	}
	g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, param)
end

return SEHudPreviewMediator
