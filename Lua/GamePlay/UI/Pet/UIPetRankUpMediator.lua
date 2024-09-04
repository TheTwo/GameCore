local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require("ConfigRefer")
local CommonDropDown = require("CommonDropDown")
local UIMediatorNames = require("UIMediatorNames")
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

---@class UIPetRankUpMediator : BaseUIMediator
local UIPetRankUpMediator = class('UIPetRankUpMediator', BaseUIMediator)

local INDEX_SE_SKILL = 1
local INDEX_SLG_SKILL = 2
local INDEX_SOC_SKILL = 3

local PET_FILTER_QUALITY_GREEN = 1
local PET_FILTER_QUALITY_BLUE = 2

local PET_QUALITY_WARNING = 4
local PET_RANK_WARNING = 2

local ATTR_DISP_ID_ATTACK = 21
local ATTR_DISP_RANK_BOOST = 40
local PET_FEED_COUNT_MAX = 6
local PREFAB_INDEX_PET = 0
local PREFAB_INDEX_EMPTY = 1

local I18N_UPGRADE_RANK = "skill_rank_upgrade_name"
local I18N_ADD_RANK_EXP = "skill_rank_upgrade_name"
local I18N_ADD_PET_FEED = "pet_rank_up_mtrl_lack_des"
local I18N_GOTO_SKILL = "pet_skill_rankup_goto_name"
local I18N_UPGRADE_LOWEST_FIRST = "pet_skill_rankup_goto_des"
local I18N_UPGRADE_SUCCESS = "pet_skill_rankup_scc_des"
local I18N_UPGRADE_HINT = "pet_rank_up_cndt_des"
local I18N_GLOBAL_ATTR_DESC = "base_pet_rank_attr_des"

local MAX_RANK = 5
local MAX_RANK_DIFF = 2

local COLOR_ATTR_UP = UIHelper.TryParseHtmlString(ColorConsts.quality_green)
local COLOR_ATTR_DOWN = UIHelper.TryParseHtmlString(ColorConsts.warning)
local COLOR_ATTR_SAME = UIHelper.TryParseHtmlString("#242630")

local SP_PET_FRAME_PREFIX = "sp_hero_frame_circle_"

local INHERIT_NEED_ITEM_COUNT = 1

local VX_UPGRADE_TIME = 1.3
local VX_INHERIT_TIME = 1.5

function UIPetRankUpMediator:ctor()
	self._petId = -1
	---@type wds.PetInfo
	self._petInfo = nil
	---@type PetConfigCell
	self._petCfg = nil
	---@type table
	self._petAttrList = nil
	self._inheritMode = false
	self._selectedFilter = PET_FILTER_QUALITY_BLUE
	self._selectedSkillIndex = INDEX_SE_SKILL
	---@type table<number, UIPetIconData>
	self._petDataListForUpgrade = nil
	self._newSkillLevel = 0
	self._addedExp = 0
	self._addedPetFeedList = {}
	self._addedPetFeedCount = 0
	self._lowestRankSkillIndex = 0
	self._lowestRank = 99999999
	self._highestRank = -1
	self._allowedHighestRank = -1
	self._nextRankNeedExp = 0
	self._allowedMaxFeedExpFor1 = 0
	self._allowedMaxFeedExpFor2 = 0
	self._inheirtSelectedPetId = -1
	self._rankAttrList = {}
	self._rankDispAttr = nil
	self._inheritItemHasAmount = 0
	self._inhertiItemId = 0
	self._exceedMaxExpOnce = false
	self._inheritRankExceed = false
	self._emptyPetFeedData = {}
end

function UIPetRankUpMediator:OnCreate()
	MAX_RANK_DIFF = ConfigRefer.PetConsts.PetMaxSkillLevelDiff and ConfigRefer.PetConsts:PetMaxSkillLevelDiff() or MAX_RANK_DIFF
	ATTR_DISP_ID_ATTACK = ConfigRefer.PetConsts.PetSeSkillAtk and ConfigRefer.PetConsts:PetSeSkillAtk() or ATTR_DISP_ID_ATTACK
	ATTR_DISP_RANK_BOOST = ConfigRefer.PetConsts.PetRankAllElemBoost and ConfigRefer.PetConsts:PetRankAllElemBoost() or ATTR_DISP_RANK_BOOST

	self:InitObjects()
end

function UIPetRankUpMediator:InitObjects()
	---@type CommonBackButtonComponent
	self.backButton = self:LuaObject("child_common_btn_back")

	---@type CommonChildTabLeftBtn
	self.tabUpgrade = self:LuaObject("p_btn_side_tab_upgrade")
	---@type CommonChildTabLeftBtn
	self.tabInherit = self:LuaObject("p_btn_side_tab_inherit")

	self.rankUpGroup = self:GameObject("p_group_upgrade")
	self.inheritGroup = self:GameObject("p_group_inherit")

	self.iconNode = self:GameObject("p_icon_strengthen")
	self.rankText = self:Text("p_text_strengthen")
	self.skillHintText = self:Text("p_text_up")
	self.skillHintInfoText = self:Text("p_text_skill_hint")

	---@type HeroInfoItemComponent
	self.petHeroComp = self:LuaObject("p_pet_hero")

	self.tipsGroupButton = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnTipsGroupButtonClick))
	self.tipsGroup = self:GameObject("p_group_tips")
	self.tipsGroupCloseButton = self:Button("p_btn", Delegate.GetOrCreate(self, self.OnTipsGroupCloseClick))
	self.tipsGroupTitle = self:Text("p_text_item_name", "pet_rank_preview_name")
	self.tipsGroupTable = self:TableViewPro("p_table_view")

	---@type CommonSkillCard
	self.seSkillCard = self:LuaObject("p_se_skill_card")
	self.seSkillExpSlider = self:Slider("p_progress_card")
	self.seSkillExpAddSlider = self:Image("p_progress_card_add")
	self.seSkillMask = self:GameObject("p_se_card_mask")
	self.seSkillButton = self:Button("p_btn_card", Delegate.GetOrCreate(self, self.OnSeCardClick))
	self.seSkillLvText = self:Text("p_text_lv_now_card")
	self.seSkillLvNew = self:GameObject("p_lv_next_card")
	self.seSkillLvTextNew = self:Text("p_text_lv_next_card")

	---@type BaseSkillIcon
	self.slgSkill = self:LuaObject("child_item_skill_1")
	self.slgSkillExpSlider = self:Slider("p_progress_skill_1")
	self.slgSkillExpAddSlider = self:Image("p_progress_skill_add_1")
	self.slgSkillMask = self:GameObject("p_slg_skill_mask")
	self.slgSkillButton = self:Button("p_btn_skill_1", Delegate.GetOrCreate(self, self.OnSlgSkillClick))
	self.slgSkillLvText = self:Text("p_text_lv_now_skill_1")
	self.slgSkillLvNew = self:GameObject("p_lv_next_skill_1")
	self.slgSkillLvTextNew = self:Text("p_text_lv_next_skill_1")

	---@type BaseSkillIcon
	self.socSkill = self:LuaObject("child_item_skill_2")
	self.socSkillExpSlider = self:Slider("p_progress_skill_2")
	self.socSkillExpAddSlider = self:Image("p_progress_skill_add_2")
	self.socSkillMask = self:GameObject("p_soc_skill_mask")
	self.socSkillButton = self:Button("p_btn_skill_2", Delegate.GetOrCreate(self, self.OnSocSkillClick))
	self.socSkillLvText = self:Text("p_text_lv_now_skill_2")
	self.socSkillLvNew = self:GameObject("p_lv_next_skill_2")
	self.socSkillLvTextNew = self:Text("p_text_lv_next_skill_2")

	---@type CommonDropDown
	self.filterDropDown = self:LuaObject("child_dropdown")
	self.buttonPut = self:Button("p_btn_put", Delegate.GetOrCreate(self, self.OnButtonPutClick))
	self.textPut = self:Text("p_text_put", "pet_recycle_button0")

	self.skillNameText = self:Text("p_text_skill_name")
	self.skillText = self:Text("p_text_skill")
	self.skillTextNow = self:Text("p_text_skill_now")
	self.skillTextNext = self:Text("p_text_skill_next")

	---@type UIPetSelectPopupComponent
	self.petSelectPanel = self:LuaObject("child_pet_popup_select")

	self.feedArea = self:GameObject("p_quantity")
	self.tablePetList = self:TableViewPro("p_table_pet")
	self.tablePetButton = self:Button("p_btn_pet", Delegate.GetOrCreate(self, self.OnTablePetButtonClick))
	self.tablePetPutButton = self:Button("p_btn_put", Delegate.GetOrCreate(self, self.OnTablePetPutButtonClick))
	self.fullText = self:Text("p_text_full", "pet_skill_rank_max_des")

	self.upgradeHintText = self:Text("p_text_hint_upgrade")
	self.btnUpgrade = self:Button("p_btn_upgrade", Delegate.GetOrCreate(self, self.OnBtnUpgradeClick))
	self.btnUpgradeText = self:Text("p_text_btn_upgrade", I18N_UPGRADE_RANK)

	self.inheritAddNode = self:GameObject("p_status_add_pet")
	self.inheritAddButton = self:Button("p_btn_add_inherit", Delegate.GetOrCreate(self, self.OnInheritAddButtonClick))
	self.inheritHintText1 = self:Text("p_text_add_hint", "pet_inherit_fill_des")
	self.inheritHintText2 = self:Text("p_text_add_hint_1", "pet_inherit_rule_des")

	self.inheritInfoNode = self:GameObject("p_status_add_info")
	self.inheritLevelNow = self:Text("p_text_strengthen_now")
	self.inheritLevelNext = self:Text("p_text_strengthen_next")
	self.inheritLevelArrow = self:Image("icon_arrow_card_1")

	self.inheritGlobalAttrDesc = self:Text("p_text_skill_detail")
	self.inheritGlobalAttrValueNow = self:Text("p_text_inherit_now")
	self.inheritGlobalAttrValueNext = self:Text("p_text_inherit_next")
	self.inheritGlobalAttrArrow = self:Image("p_icon_arrow")

	self.inheritChangePetButton = self:Button("p_btn_exchange", Delegate.GetOrCreate(self, self.OnInheritAddButtonClick))

	---@type CommonSkillCard
	self.inheritSeCard = self:LuaObject("child_card_skill")
	self.inheritSeSkillDesc = self:Text("p_text_card_detail")
	self.inheritSeSkillRankNow = self:Text("p_text_strengthen_now_card")
	self.inheritSeSkillValueNow = self:Text("p_text_card_now")
	self.inheritSeSkillNextNode = self:GameObject("p_group_next_card")
	self.inheritSeSkillRankNext = self:Text("p_text_strengthen_next_card")
	self.inheritSeSkillValueNext = self:Text("p_text_card_next")
	self.inheritSeSkillArrowA = self:Image("p_icon_arrow_card_a")
	self.inheritSeSkillArrowB = self:Image("p_icon_arrow_card_b")

	---@type BaseSkillIcon
	self.inheritSlgSkill = self:LuaObject("p_inherit_slg_skill")
	self.inheritSlgSkillDesc = self:Text("p_text_skill_detail_1")
	self.inheritSlgSkillRankNow = self:Text("p_text_strengthen_now_skill_1")
	self.inheritSlgSkillValueNow = self:Text("p_text_now_skill_1")
	self.inheritSlgSkillNextNode = self:GameObject("p_group_next_skill_1")
	self.inheritSlgSkillRankNext = self:Text("p_text_strengthen_next_skill_1")
	self.inheritSlgSkillValueNext = self:Text("p_text_skill_next_1")
	self.inheritSlgSkillArrowA = self:Image("p_icon_arrow_skill_1")
	self.inheritSlgSkillArrowB = self:Image("p_icon_arrow_skill_1_b")

	---@type BaseSkillIcon
	self.inheritSocSkill = self:LuaObject("p_inherit_soc_skill")
	self.inheritSocSkillDesc = self:Text("p_text_skill_detail_2")
	self.inheritSocSkillRankNow = self:Text("p_text_strengthen_now_skill_2")
	self.inheritSocSkillValueNow = self:Text("p_text_skill_now_2")
	self.inheritSocSkillNextNode = self:GameObject("p_group_next_skill_2")
	self.inheritSocSkillRankNext = self:Text("p_text_strengthen_next_skill_2")
	self.inheritSocSkillValueNext = self:Text("p_text_skill_next_2")
	self.inheritSocSkillArrowA = self:Image("p_icon_arrow_skill_a")
	self.inheritSocSkillArrowB = self:Image("p_icon_arrow_skill_b")

	self.inheritButton = self:Button("p_btn_inherit", Delegate.GetOrCreate(self, self.OnInheritButtonClick))
	self.inheritButtonText = self:Text("p_text_inherit", "pet_inherit_icon_name")
	self.inheritButtonIcon = self:Image("p_icon_item_bl_inherit")
	self.inheritButtonNumGreen = self:Text("p_text_num_green_bl_inherit")
	self.inheritButtonNumRed = self:Text("p_text_num_red_bl_inherit")
	self.inheritButtonNeedNum = self:Text("p_text_num_wilth_bl_inherit")

	self.inheritPetFrame = self:Image("p_inherit_pet_frame")
	self.inheritPetImage = self:Image("p_inherit_pet_img")

	self.vxTrigger = self:BindComponent("vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function UIPetRankUpMediator:OnShow(param)
	self._param = param
	if (self._param and self._param.closeCallback) then
		self._closeCallback = param.closeCallback
	end
    self:InitData()
	self:RefreshData(param)
    self:InitUI()
    self:RefreshUI()
end

function UIPetRankUpMediator:OnHide(param)
end

function UIPetRankUpMediator:OnOpened(param)
end

function UIPetRankUpMediator:OnClose(param)
	if (self._closeCallback) then
		self._closeCallback(self._petId)
	end
end

--- 刷新数据
---@param self UIPetRankUpMediator
---@param param table
function UIPetRankUpMediator:RefreshData(param)
	if (param and param.petId) then
		self._petId = param.petId
	end
	if (not self._petId) then return end
	self._petInfo = ModuleRefer.PetModule:GetPetByID(self._petId)
	if (not self._petInfo) then return end
	self._petCfg = ModuleRefer.PetModule:GetPetCfg(self._petInfo.ConfigId)
	self._rankDispAttr = ConfigRefer.AttrDisplay:Find(ATTR_DISP_RANK_BOOST)

	MAX_RANK = self:GetMaxRank() or MAX_RANK
	--g_Logger.Trace("**** 宠物%s最大阶级%s", self._petId, MAX_RANK)
	INHERIT_NEED_ITEM_COUNT = ConfigRefer.PetConsts.PetInheritItemCostNum and ConfigRefer.PetConsts:PetInheritItemCostNum() or INHERIT_NEED_ITEM_COUNT

	local rankAttrCfg = ConfigRefer.PetRankAttr:Find(self._petCfg:RankAttr())
	if (rankAttrCfg) then
		local attrTmpId = rankAttrCfg:AttrTempUI()
		self._rankAttrList = {}
		for i = 1, MAX_RANK do
			self._rankAttrList[i] = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(attrTmpId, i)
		end
	end
end

function UIPetRankUpMediator:GetMaxRank()
	if (not self._petCfg) then return nil end
	local maxRank = 999999
	for i = 1, self._petCfg:SkillLevelExpLength() do
		local expTemp = ConfigRefer.ExpTemplate:Find(self._petCfg:SkillLevelExp(i))
		if (expTemp) then
			local lv = expTemp:ExpLvLength()
			if (lv > 0 and lv < maxRank) then
				maxRank = lv
			end
		end
	end
	return maxRank
end

--- 初始化数据
---@param self UIPetRankUpMediator
function UIPetRankUpMediator:InitData()
    self.backButton:FeedData({
        title = I18N.Get("pet_rank_up_name"),
    })

	local filterDropDownData = {}
	filterDropDownData.items = CommonDropDown.CreateData(
		--"", I18N.Get("pet_filter_condition2"),
		"", I18N.Get("pet_filter_condition3"),
		"", I18N.Get("pet_filter_condition4"),
		"", I18N.Get("pet_filter_condition5"),
		"", I18N.Get("pet_type_name0")
	)
	filterDropDownData.defaultId = PET_FILTER_QUALITY_BLUE - 1
	filterDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnFilterDropDownSelect)
	self.filterDropDown:FeedData(filterDropDownData)
end

--- 初始化UI
---@param self UIPetRankUpMediator
function UIPetRankUpMediator:InitUI()
	self.tabUpgrade:FeedData({
		index = 1,
		btnName = I18N.Get("pet_rank_up_name"),
		titleText = I18N.Get("pet_rank_up_name"),
		isLocked = false,
		onClick = Delegate.GetOrCreate(self, self.OnTabUpgradeClick),
	})
	self.tabInherit:FeedData({
		index = 2,
		btnName = I18N.Get("pet_inherit_name"),
		titleText = I18N.Get("pet_inherit_name"),
		isLocked = false,
		onClick = Delegate.GetOrCreate(self, self.OnTabInheritClick),
	})
	self.petSelectPanel.CSComponent.gameObject:SetActive(false)

	if (self._selectedSkillIndex == INDEX_SE_SKILL) then
		self:OnSeCardClick(true)
	elseif (self._selectedSkillIndex == INDEX_SLG_SKILL) then
		self:OnSlgSkillClick(true)
	else
		self:OnSocSkillClick(true)
	end
end

--- 刷新UI
---@param self UIPetRankUpMediator
function UIPetRankUpMediator:RefreshUI()
	if (self._inheritMode) then
		self.tabUpgrade:SetStatus(1)
		self.tabInherit:SetStatus(0)
		self.backButton:FeedData({
			title = self.tabInherit:GetTitleString(),
		})
	else
		self.tabUpgrade:SetStatus(0)
		self.tabInherit:SetStatus(1)
		self.backButton:FeedData({
			title = self.tabUpgrade:GetTitleString(),
		})
	end

	if (not self._petInfo or not self._petCfg) then return end
	self._petAttrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(self._petCfg:AttrTempId(), self._petInfo.Level)

	self:RefreshGlobalAttr()

	if (self._inheritMode) then
		self:RefreshInherit()
	else
		self:RefreshUpgrade()
	end
end

function UIPetRankUpMediator:RefreshGlobalAttr()
	local heroId = ModuleRefer.PetModule:GetPetLinkHero(self._petId)
	if (heroId and heroId > 0) then
		self.petHeroComp.CSComponent.gameObject:SetActive(true)
		self.petHeroComp:FeedData({heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)})
	else
		self.petHeroComp.CSComponent.gameObject:SetActive(false)
	end

	self.rankText.text = tostring(self._petInfo.RankLevel)
	local attrList = self._rankAttrList[self._petInfo.RankLevel]
	if (attrList and self._rankDispAttr) then
		local value = ModuleRefer.AttrModule:GetDisplayValueWithData(self._rankDispAttr, attrList)
		self.skillHintText.text = I18N.GetWithParams(I18N_GLOBAL_ATTR_DESC, value)
	end
	self.skillHintInfoText.text = I18N.GetWithParams(I18N_UPGRADE_HINT, self._petInfo.RankLevel + 1)
	--self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)

	-- 预览
	self.tipsGroupTable:Clear()
	for i = 1, MAX_RANK do
		if (self._rankAttrList[i]) then
			local value = ModuleRefer.AttrModule:GetDisplayValueWithData(self._rankDispAttr, self._rankAttrList[i])
			self.tipsGroupTable:AppendData({
				desc = I18N.GetWithParams(I18N_GLOBAL_ATTR_DESC, value),
				level = tostring(i),
				selected = i == self._petInfo.RankLevel,
			})
		end
	end
end

function UIPetRankUpMediator:RefreshUpgrade()
	self.iconNode:SetActive(true)
	self.rankUpGroup:SetActive(true)
	self.inheritGroup:SetActive(false)
	self:RefreshUpgradePetFeedList()
end

function UIPetRankUpMediator:RefreshUpgradeSkill()
	self:RecalcSkillLevelMinMax()

	-- SE技能
	self:RefreshSeSkill()

	-- SLG技能
	self:RefreshSlgSkill()

	-- SOC技能
	self:RefreshSocSkill()
end

function UIPetRankUpMediator:RefreshInherit()
	self.iconNode:SetActive(true)
	self.rankUpGroup:SetActive(false)
	self.inheritGroup:SetActive(true)

	if (self._inheirtSelectedPetId <= 0) then
		self.inheritAddNode:SetActive(true)
		self.inheritInfoNode:SetActive(false)
	else
		self.inheritAddNode:SetActive(false)
		self.inheritInfoNode:SetActive(true)
		self:RefreshInheritInfo()
	end
end

function UIPetRankUpMediator:RefreshInheritInfo()
	local feedPetInfo = ModuleRefer.PetModule:GetPetByID(self._inheirtSelectedPetId)
	local feedPetCfg = ModuleRefer.PetModule:GetPetCfg(feedPetInfo.ConfigId)

	-- 宠物图标
	g_Game.SpriteManager:LoadSprite(SP_PET_FRAME_PREFIX .. (feedPetCfg:Quality() + 1), self.inheritPetFrame)
	self:LoadSprite(feedPetCfg:Icon(), self.inheritPetImage)

	-- 阶级上限检查
	self._inheritRankExceed = feedPetInfo.RankLevel > MAX_RANK
	local realFeedRank = math.min(feedPetInfo.RankLevel, MAX_RANK)

	-- 阶级
	self.inheritLevelNow.text = tostring(self._petInfo.RankLevel)
	self.inheritLevelNext.text = tostring(realFeedRank)
	local inheritLevelColor = self:GetColorByValueCompare(self._petInfo.RankLevel, realFeedRank)
	self.inheritLevelArrow.color = inheritLevelColor
	self.inheritLevelNext.color = inheritLevelColor

	-- 全局属性
	local globalOldValue, globalDesc = ModuleRefer.AttrModule:GetDisplayValueWithData(self._rankDispAttr, self._rankAttrList[self._petInfo.RankLevel])
	local globalNewValue = ModuleRefer.AttrModule:GetDisplayValueWithData(self._rankDispAttr, self._rankAttrList[realFeedRank])
	self.inheritGlobalAttrDesc.text = I18N.Get(globalDesc)
	self.inheritGlobalAttrValueNow.text = tostring(globalOldValue) .. "%"
	--if (globalOldValue ~= globalNewValue) then
	self.inheritGlobalAttrValueNext.gameObject:SetActive(true)
	self.inheritGlobalAttrValueNext.text = tostring(globalNewValue) .. "%"
	local inheritGlobalAttrColor = self:GetColorByValueCompare(globalOldValue, globalNewValue)
	self.inheritGlobalAttrArrow.color = inheritGlobalAttrColor
	self.inheritGlobalAttrValueNext.color = inheritGlobalAttrColor
	-- else
	-- 	self.inheritGlobalAttrValueNext.gameObject:SetActive(false)
	-- end

	-- SE属性
	self.inheritSeCard:FeedData({
		cardId = self._petCfg:CardId(),
	})
	local seSkillOldLevel = self._petInfo.SkillLevels[INDEX_SE_SKILL]
	local realSeSkillNewLevel = math.min(feedPetInfo.SkillLevels[INDEX_SE_SKILL], MAX_RANK)
	self._inheritRankExceed = self._inheritRankExceed or realSeSkillNewLevel < feedPetInfo.SkillLevels[INDEX_SE_SKILL]
	local seSkillNewLevel = realSeSkillNewLevel
	self.inheritSeSkillRankNow.text = tostring(seSkillOldLevel)
	local seNpc = ConfigRefer.SeNpc:Find(self._petCfg:SeNpcId())
	if (seNpc) then
		local attrAtk = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_ATTACK)
		local attrAtkValue = ModuleRefer.AttrModule:GetDisplayValueWithData(attrAtk, self._petAttrList)
		local skillId = seNpc:Seskill(1)
		local oldSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, seSkillOldLevel)
		local oldSkill = ConfigRefer.KheroSkillLogicalSe:Find(oldSkillId)
		--self.inheritSeSkillDesc.text = I18N.Get(oldSkill:IntroductionKey())
		self.inheritSeSkillDesc.text = I18N.Get(oldSkill:NameKey())
		local oldValue = attrAtkValue * oldSkill:DamageFactor() + oldSkill:DamageValue()
		self.inheritSeSkillValueNow.text = tostring(math.floor(oldValue))
		--if (seSkillNewLevel ~= seSkillOldLevel) then
		self.inheritSeSkillNextNode:SetActive(true)
		self.inheritSeSkillRankNext.text = tostring(seSkillNewLevel)
		local newSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, seSkillNewLevel)
		local newSkill = ConfigRefer.KheroSkillLogicalSe:Find(newSkillId)
		local newValue = attrAtkValue * newSkill:DamageFactor() + newSkill:DamageValue()
		self.inheritSeSkillValueNext.text = tostring(math.floor(newValue))
		self.inheritSeSkillArrowA.color = self:GetColorByValueCompare(seSkillOldLevel, seSkillNewLevel)
		local inheritSeSkillValueColor = self:GetColorByValueCompare(oldValue, newValue)
		self.inheritSeSkillArrowB.color = inheritSeSkillValueColor
		self.inheritSeSkillValueNext.color = inheritSeSkillValueColor
		-- else
		-- 	self.inheritSeSkillNextNode:SetActive(false)
		-- end
	end

	-- Slg属性
	local slgSkillId = self._petCfg:SkillIdSLG()
	local slgSkillOldLevel = self._petInfo.SkillLevels[INDEX_SLG_SKILL]
	local realSlgSkillNewLevel = math.min(feedPetInfo.SkillLevels[INDEX_SLG_SKILL], MAX_RANK)
	self._inheritRankExceed = self._inheritRankExceed or realSlgSkillNewLevel < feedPetInfo.SkillLevels[INDEX_SLG_SKILL]
	local slgSkillNewLevel = realSlgSkillNewLevel
	local slgOldSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, slgSkillOldLevel)
	local slgNewSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, slgSkillNewLevel)
	self.inheritSlgSkill:FeedData({
		skillId = slgNewSkillId,
		index = INDEX_SLG_SKILL,
		skillLevel = slgSkillNewLevel,
		isSlg = true,
	})
	self.inheritSlgSkillRankNow.text = tostring(slgSkillOldLevel)
	local oldSlgCfg = ConfigRefer.KheroSkillLogical:Find(slgOldSkillId)
	local newSlgCfg = ConfigRefer.KheroSkillLogical:Find(slgNewSkillId)
	local oldSlgValue = math.floor(oldSlgCfg:DamageFactor() * 100)
	local newSlgValue = math.floor(newSlgCfg:DamageFactor() * 100)
	self.inheritSlgSkillValueNow.text = oldSlgValue
	self.inheritSlgSkillDesc.text = I18N.Get(oldSlgCfg:NameKey())
	--if (slgSkillOldLevel ~= slgSkillNewLevel) then
	self.inheritSlgSkillNextNode:SetActive(true)
	self.inheritSlgSkillRankNext.text = tostring(slgSkillNewLevel)
	self.inheritSlgSkillValueNext.text = newSlgValue
	self.inheritSlgSkillArrowA.color = self:GetColorByValueCompare(slgSkillOldLevel, slgSkillNewLevel)
	local inheritSlgSkillColor = self:GetColorByValueCompare(oldSlgValue, newSlgValue)
	self.inheritSlgSkillArrowB.color = inheritSlgSkillColor
	self.inheritSlgSkillValueNext.color = inheritSlgSkillColor
	-- else
	-- 	self.inheritSlgSkillNextNode:SetActive(false)
	-- end

	-- Soc属性
	local socSkillId = self._petCfg:SkillIdSOC()
	local socSkillOldLevel = self._petInfo.SkillLevels[INDEX_SOC_SKILL]
	local realSocSkillNewLevel = math.min(feedPetInfo.SkillLevels[INDEX_SOC_SKILL], MAX_RANK)
	self._inheritRankExceed = self._inheritRankExceed or realSocSkillNewLevel < feedPetInfo.SkillLevels[INDEX_SOC_SKILL]
	local socSkillNewLevel = realSocSkillNewLevel
	local socOldSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(socSkillId, socSkillOldLevel)
	local socNewSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(socSkillId, socSkillNewLevel)
	self.inheritSocSkill:FeedData({
		skillId = socNewSkillId,
		index = INDEX_SOC_SKILL,
		skillLevel = socSkillNewLevel,
		isSoc = true,
	})
	local socOldCfg = ConfigRefer.CitizenSkillInfo:Find(socOldSkillId)
	self.inheritSocSkillDesc.text = I18N.Get(socOldCfg:Name())
	self.inheritSocSkillRankNow.text = tostring(socSkillOldLevel)
	local oldSocValue, _, oldFormattedValue = ModuleRefer.SkillModule:GetFirstShowCitizenSkillAttr(socOldSkillId)
	local newSocValue, _, newFormattedValue = ModuleRefer.SkillModule:GetFirstShowCitizenSkillAttr(socNewSkillId)
	self.inheritSocSkillValueNow.text = oldFormattedValue
	--if (socSkillOldLevel ~= socSkillNewLevel) then
	self.inheritSocSkillNextNode:SetActive(true)
	self.inheritSocSkillRankNext.text = tostring(socSkillNewLevel)
	self.inheritSocSkillValueNext.text = newFormattedValue
	self.inheritSocSkillArrowA.color = self:GetColorByValueCompare(socSkillOldLevel, socSkillNewLevel)
	local inheritSocSkillColor = self:GetColorByValueCompare(oldSocValue, newSocValue)
	self.inheritSocSkillArrowB.color = inheritSocSkillColor
	self.inheritSocSkillValueNext.color = inheritSocSkillColor
	-- else
	-- 	self.inheritSocSkillNextNode:SetActive(false)
	-- end

	-- 按钮
	local inheritCost = ConfigRefer.PetConsts.PetInheritCost and ConfigRefer.PetConsts:PetInheritCost() or 0
	local inheritCostItemGroup = ConfigRefer.ItemGroup:Find(inheritCost)
	local info = inheritCostItemGroup:ItemGroupInfoList(1)
	self._inhertiItemId = info:Items()
	local item = ConfigRefer.Item:Find(info:Items())
	self._inheritItemHasAmount = ModuleRefer.InventoryModule:GetAmountByConfigId(info:Items())
	self.inheritButtonNumGreen.text = tostring(self._inheritItemHasAmount)
	self.inheritButtonNumRed.text = tostring(self._inheritItemHasAmount)
	self.inheritButtonNeedNum.text = "/" .. INHERIT_NEED_ITEM_COUNT
	self.inheritButtonNumGreen.gameObject:SetActive(self._inheritItemHasAmount >= INHERIT_NEED_ITEM_COUNT)
	self.inheritButtonNumRed.gameObject:SetActive(self._inheritItemHasAmount < INHERIT_NEED_ITEM_COUNT)
	g_Game.SpriteManager:LoadSprite(item:Icon(), self.inheritButtonIcon)
end

function UIPetRankUpMediator:RecalcSkillLevelMinMax()
	self._lowestRank = 99999999
	self._highestRank = -1
	for index, lv in pairs(self._petInfo.SkillLevels) do
		if (lv < self._lowestRank) then
			self._lowestRank = lv
			self._lowestRankSkillIndex = index
		end
		if (lv > self._highestRank) then
			self._highestRank = lv
		end
	end
	self._allowedHighestRank = self._lowestRank + MAX_RANK_DIFF
end

function UIPetRankUpMediator:RefreshUpgradePetFeedList()
	self.tablePetList:Clear()
	self._addedPetFeedCount = 0
	self._addedExp = 0
	for id, _ in pairs(self._addedPetFeedList) do
		local petInfo = ModuleRefer.PetModule:GetPetByID(id)
		if (petInfo) then
			self._addedPetFeedCount = self._addedPetFeedCount + 1
			self._addedExp = self._addedExp + ModuleRefer.PetModule:GetPetFeedExp(petInfo)
			---@type UIPetIconData
			local data = {
				id = id,
				cfgId = petInfo.ConfigId,
				level = petInfo.Level,
				rank = petInfo.RankLevel,
				templateIds = petInfo.TemplateIds,
			}
			self.tablePetList:AppendData(data, PREFAB_INDEX_PET)
		end
	end
	for i = 1, PET_FEED_COUNT_MAX - self._addedPetFeedCount do
		self.tablePetList:AppendData(self._emptyPetFeedData, PREFAB_INDEX_EMPTY)
	end
	self:RefreshUpgradeSkill()
end

function UIPetRankUpMediator:OnTabUpgradeClick(index)
	if (self._inheritMode) then
		self._inheritMode = false
		self:InitUI()
		self:RefreshUI()
	end
end

function UIPetRankUpMediator:OnTabInheritClick(index)
	if (not self._inheritMode) then
		self._inheritMode = true
		self:InitUI()
		self:RefreshUI()
	end
end

---@param self UIPetRankUpMediator
---@param force boolean
function UIPetRankUpMediator:OnSeCardClick(force)
	if (not force and self._selectedSkillIndex == INDEX_SE_SKILL) then return end
	self._selectedSkillIndex = INDEX_SE_SKILL
	self.seSkillMask:SetActive(false)
	self.seSkillExpSlider.gameObject:SetActive(true)
	self.slgSkillMask:SetActive(true)
	self.slgSkillExpSlider.gameObject:SetActive(false)
	self.slgSkillLvNew:SetActive(false)
	self.socSkillMask:SetActive(true)
	self.socSkillExpSlider.gameObject:SetActive(false)
	self.socSkillLvNew:SetActive(false)
	self:ClearFeedPets()
	self:RefreshUI()
end

---@param self UIPetRankUpMediator
---@param force boolean
function UIPetRankUpMediator:OnSlgSkillClick(force)
	if (not force and self._selectedSkillIndex == INDEX_SLG_SKILL) then return end
	self._selectedSkillIndex = INDEX_SLG_SKILL
	self.seSkillMask:SetActive(true)
	self.seSkillExpSlider.gameObject:SetActive(false)
	self.seSkillLvNew:SetActive(false)
	self.slgSkillMask:SetActive(false)
	self.slgSkillExpSlider.gameObject:SetActive(true)
	self.socSkillMask:SetActive(true)
	self.socSkillExpSlider.gameObject:SetActive(false)
	self.socSkillLvNew:SetActive(false)
	self:ClearFeedPets()
	self:RefreshUI()
end

---@param self UIPetRankUpMediator
---@param force boolean
function UIPetRankUpMediator:OnSocSkillClick(force)
	if (not force and self._selectedSkillIndex == INDEX_SOC_SKILL) then return end
	self._selectedSkillIndex = INDEX_SOC_SKILL
	self.seSkillMask:SetActive(true)
	self.seSkillExpSlider.gameObject:SetActive(false)
	self.seSkillLvNew:SetActive(false)
	self.slgSkillMask:SetActive(true)
	self.slgSkillExpSlider.gameObject:SetActive(false)
	self.slgSkillLvNew:SetActive(false)
	self.socSkillMask:SetActive(false)
	self.socSkillExpSlider.gameObject:SetActive(true)
	self:ClearFeedPets()
	self:RefreshUI()
end

function UIPetRankUpMediator:OnFilterDropDownSelect(id)
	self._selectedFilter = id + 1
end

---@param self UIPetRankUpMediator
---@param index number
---@param lvTextComp CS.UnityEngine.UI.Text
---@param expSlider CS.UnityEngine.UI.Slider
---@param newLvNode CS.UnityEngine.GameObject
---@param newLvText CS.UnityEngine.UI.Text
---@param expAddSlider CS.UnityEngine.UI.Image
---@return number, number, boolean @旧阶级, 新阶级, 超出阶级差
function UIPetRankUpMediator:RefreshSkillInfo(index, lvTextComp, expSlider, newLvNode, newLvText, expAddSlider)
	local skillLevel = self._petInfo.SkillLevels[index]
	lvTextComp.text = tostring(skillLevel)
	self:CalcCurrentSkillAllowedMaxFeedExp()
	local expTempId = self._petCfg:SkillLevelExp(index)
	local skillExp = self._petInfo.SkillExps[index]
	local skillExpCache = ModuleRefer.PetModule:GetSkillExpCache(expTempId, skillLevel)
	if (skillExpCache) then
		local pct = (skillExp - skillExpCache.minExp) / skillExpCache.lvExp
		expSlider.value = pct
	end

	local newLevel = 0
	local newCache
	if (self._selectedSkillIndex == index and self._addedExp and self._addedExp > 0) then
		local newSkillExp = skillExp + self._addedExp
		newLevel, newCache = ModuleRefer.PetModule:GetSkillLevelByExp(expTempId, newSkillExp)
		self._newSkillLevel = newLevel
		local newPct = (newSkillExp - newCache.minExp) / newCache.lvExp
		newLvNode:SetActive(newLevel > skillLevel)
		newLvText.text = tostring(newLevel)
		expAddSlider.gameObject:SetActive(true)
		expAddSlider.fillAmount = newPct
	else
		newLvNode:SetActive(false)
		expAddSlider.gameObject:SetActive(false)
	end

	-- 按钮状态变更
	if (self._selectedSkillIndex == index) then
		if (newLevel > skillLevel) then
			self.btnUpgradeText.text = I18N.Get(I18N_UPGRADE_RANK)
		elseif (self._addedExp > 0) then
			self.btnUpgradeText.text = I18N.Get(I18N_ADD_RANK_EXP)
		else
			self.btnUpgradeText.text = I18N.Get(I18N_UPGRADE_RANK)
		end
	end

	if (self._selectedSkillIndex == index and self:CheckExceedRankDiff()) then
		return skillLevel, skillLevel, true
	end

	return skillLevel, newLevel, false
end

function UIPetRankUpMediator:CheckExceedRankDiff()
	local selectedSkillLevel = self._petInfo.SkillLevels[self._selectedSkillIndex]
	if (self._highestRank - self._lowestRank >= MAX_RANK_DIFF and selectedSkillLevel >= self._allowedHighestRank) then
		local skillName = "???"
		local skillLevel = self._petInfo.SkillLevels[self._lowestRankSkillIndex]
		if (self._lowestRankSkillIndex == INDEX_SE_SKILL) then
			local seNpc = ConfigRefer.SeNpc:Find(self._petCfg:SeNpcId())
			if (seNpc) then
				local skillId = seNpc:Seskill(1)
				local realSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, skillLevel)
				local skillCfg = ConfigRefer.KheroSkillLogicalSe:Find(realSkillId)
				skillName = I18N.Get(skillCfg:NameKey())
			end
		elseif (self._lowestRankSkillIndex == INDEX_SLG_SKILL) then
			local skillId = self._petCfg:SkillIdSLG()
			local realSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, skillLevel)
			local skillCfg = ConfigRefer.KheroSkillLogical:Find(realSkillId)
			skillName = I18N.Get(skillCfg:NameKey())
		else
			local skillId = self._petCfg:SkillIdSOC()
			local realSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, skillLevel)
			local skillCfg = ConfigRefer.CitizenSkillInfo:Find(realSkillId)
			skillName = I18N.Get(skillCfg:Name())
		end
		self.upgradeHintText.text = I18N.GetWithParams(I18N_UPGRADE_LOWEST_FIRST, skillName, self._lowestRank + 1)
		return true
	else
		self.upgradeHintText.text = ""
		return false
	end
end

function UIPetRankUpMediator:RefreshSeSkill()
	local seCardId = self._petCfg:CardId()
	if (seCardId and seCardId > 0) then
		self.seSkillCard:FeedData({
			cardId = seCardId,
			skillLevel = self._petInfo.SkillLevels[INDEX_SE_SKILL],
			disableCardClick = true,
		})
		self.seSkillCard.CSComponent.gameObject:SetActive(true)
		local oldLevel, newLevel, exceedRankDiff = self:RefreshSkillInfo(INDEX_SE_SKILL, self.seSkillLvText, self.seSkillExpSlider, self.seSkillLvNew, self.seSkillLvTextNew, self.seSkillExpAddSlider)
		if (self._selectedSkillIndex == INDEX_SE_SKILL) then
			-- 满级
			if (oldLevel >= MAX_RANK) then
				self.btnUpgrade.gameObject:SetActive(false)
				self.feedArea:SetActive(false)
				self.seSkillExpSlider.gameObject:SetActive(false)
				self.upgradeHintText.text = ""
			elseif (exceedRankDiff) then
				self.btnUpgrade.gameObject:SetActive(true)
				self.btnUpgradeText.text = I18N.Get(I18N_GOTO_SKILL)
				self.feedArea:SetActive(false)
			else
				self.btnUpgrade.gameObject:SetActive(true)
				self.feedArea:SetActive(true)
			end
			self:ShowSeSkillDesc(oldLevel, newLevel)
		end
	else
		self.seSkillCard.CSComponent.gameObject:SetActive(false)
	end
end

function UIPetRankUpMediator:RefreshSlgSkill()
	local slgSkillId = self._petCfg:SkillIdSLG()
	slgSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, self._petInfo.SkillLevels[INDEX_SLG_SKILL])
	if (slgSkillId and slgSkillId > 0) then
		self.slgSkill:FeedData({
			skillId = slgSkillId,
			index = slgSkillId,
			skillLevel = self._petInfo.SkillLevels[INDEX_SLG_SKILL],
			isSlg = true,
		})
		self.slgSkill.CSComponent.gameObject:SetActive(true)
		local oldLevel, newLevel, exceedRankDiff = self:RefreshSkillInfo(INDEX_SLG_SKILL, self.slgSkillLvText, self.slgSkillExpSlider, self.slgSkillLvNew, self.slgSkillLvTextNew, self.slgSkillExpAddSlider)
		if (self._selectedSkillIndex == INDEX_SLG_SKILL) then
			-- 满级
			if (oldLevel >= MAX_RANK) then
				self.btnUpgrade.gameObject:SetActive(false)
				self.feedArea:SetActive(false)
				self.slgSkillExpSlider.gameObject:SetActive(false)
				self.upgradeHintText.text = ""
			elseif (exceedRankDiff) then
				self.btnUpgrade.gameObject:SetActive(true)
				self.btnUpgradeText.text = I18N.Get(I18N_GOTO_SKILL)
				self.feedArea:SetActive(false)
			else
				self.btnUpgrade.gameObject:SetActive(true)
				self.feedArea:SetActive(true)
			end
			self:ShowSlgSkillDesc(oldLevel, newLevel)
		end
	else
		self.slgSkill.CSComponent.gameObject:SetActive(false)
	end
end

function UIPetRankUpMediator:RefreshSocSkill()
	local socSkillId = self._petCfg:SkillIdSOC()
	socSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(socSkillId, self._petInfo.SkillLevels[INDEX_SOC_SKILL])
	if (socSkillId and socSkillId > 0) then
		self.socSkill:FeedData({
			skillId = socSkillId,
			index = socSkillId,
			skillLevel = self._petInfo.SkillLevels[INDEX_SOC_SKILL],
			isSoc = true,
		})
		self.socSkill.CSComponent.gameObject:SetActive(true)
		local oldLevel, newLevel, exceedRankDiff = self:RefreshSkillInfo(INDEX_SOC_SKILL, self.socSkillLvText, self.socSkillExpSlider, self.socSkillLvNew, self.socSkillLvTextNew, self.socSkillExpAddSlider)
		if (self._selectedSkillIndex == INDEX_SOC_SKILL) then
			-- 满级
			if (oldLevel >= MAX_RANK) then
				self.btnUpgrade.gameObject:SetActive(false)
				self.feedArea:SetActive(false)
				self.socSkillExpSlider.gameObject:SetActive(false)
				self.upgradeHintText.text = ""
			elseif (exceedRankDiff) then
				self.btnUpgrade.gameObject:SetActive(true)
				self.btnUpgradeText.text = I18N.Get(I18N_GOTO_SKILL)
				self.feedArea:SetActive(false)
			else
				self.btnUpgrade.gameObject:SetActive(true)
				self.feedArea:SetActive(true)
			end
			self:ShowSocSkillDesc(oldLevel, newLevel)
		end
	else
		self.socSkill.CSComponent.gameObject:SetActive(false)
	end
end

function UIPetRankUpMediator:ShowSeSkillDesc(oldLevel, newLevel)
	local seNpc = ConfigRefer.SeNpc:Find(self._petCfg:SeNpcId())
	if (seNpc) then
		local attrAtk = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_ATTACK)
		local attrAtkValue = ModuleRefer.AttrModule:GetDisplayValueWithData(attrAtk, self._petAttrList)
		local skillId = seNpc:Seskill(1)
		local oldSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, oldLevel)
		local oldSkill = ConfigRefer.KheroSkillLogicalSe:Find(oldSkillId)
		if (oldSkill) then
			self.skillNameText.text = I18N.Get(oldSkill:NameKey())
			self.skillText.text = I18N.Get(oldSkill:IntroductionKey())
			local oldValue = attrAtkValue * oldSkill:DamageFactor() + oldSkill:DamageValue()
			self.skillTextNow.text = tostring(math.floor(oldValue))
		else
			self.skillNameText.text = "???"
			self.skillText.text = ""
			self.skillTextNow.text = ""
		end
		if (newLevel and newLevel > oldLevel) then
			self.skillTextNext.gameObject:SetActive(true)
			local newSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, newLevel)
			local newSkill = ConfigRefer.KheroSkillLogicalSe:Find(newSkillId)
			if (newSkill) then
				local newValue = attrAtkValue * newSkill:DamageFactor() + newSkill:DamageValue()
				self.skillTextNext.text = tostring(math.floor(newValue))
			else
				self.skillTextNext.text = ""
			end
		else
			self.skillTextNext.gameObject:SetActive(false)
		end
	end
end

function UIPetRankUpMediator:ShowSlgSkillDesc(oldLevel, newLevel)
	local skillId = self._petCfg:SkillIdSLG()
	local oldSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, oldLevel)
	local oldSkill = ConfigRefer.KheroSkillLogical:Find(oldSkillId)
	if (oldSkill) then
		self.skillNameText.text = I18N.Get(oldSkill:NameKey())
		self.skillText.text = I18N.Get(oldSkill:IntroductionKey())
		local oldValue = math.floor(oldSkill:DamageFactor() * 100)
		self.skillTextNow.text = tostring(oldValue)
	else
		self.skillNameText.text = "???"
		self.skillText.text = ""
		self.skillTextNow.text = ""
	end
	if (newLevel and newLevel > oldLevel) then
		self.skillTextNext.gameObject:SetActive(true)
		local newSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, newLevel)
		local newSkill = ConfigRefer.KheroSkillLogical:Find(newSkillId)
		if (newSkill) then
			local newValue = math.floor(newSkill:DamageFactor() * 100)
			self.skillTextNext.text = tostring(math.floor(newValue))
		else
			self.skillTextNext.text = ""
		end
	else
		self.skillTextNext.gameObject:SetActive(false)
	end
end

function UIPetRankUpMediator:ShowSocSkillDesc(oldLevel, newLevel)
	local skillId = self._petCfg:SkillIdSOC()
	local oldSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, oldLevel)
	local oldSkill = ConfigRefer.CitizenSkillInfo:Find(oldSkillId)
	if (oldSkill) then
		self.skillNameText.text = I18N.Get(oldSkill:Name())
		self.skillText.text = I18N.Get(oldSkill:Des())
		local oldValue, _, oldFormattedValue = ModuleRefer.SkillModule:GetFirstShowCitizenSkillAttr(oldSkillId)
		self.skillTextNow.text = oldFormattedValue
	else
		self.skillNameText.text = "???"
		self.skillText.text = ""
		self.skillTextNow.text = ""
	end
	if (newLevel and newLevel > oldLevel) then
		self.skillTextNext.gameObject:SetActive(true)
		local newSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, newLevel)
		local newSkill = ConfigRefer.CitizenSkillInfo:Find(newSkillId)
		if (newSkill) then
			local newValue, _, newFormattedValue = ModuleRefer.SkillModule:GetFirstShowCitizenSkillAttr(newSkillId)
			self.skillTextNext.text = newFormattedValue
		else
			self.skillTextNext.text = ""
		end
	else
		self.skillTextNext.gameObject:SetActive(false)
	end
end

function UIPetRankUpMediator:OnTablePetButtonClick()
	---@type UIPetSelectPopupComponentParam
	local param = {
		showAllType = true,
		petDataPostProcess = Delegate.GetOrCreate(self, self.PetDataPostProcessForUpgrade),
		petDataFilter = Delegate.GetOrCreate(self, self.PetDataFilterForUpgrade),
		hintText = I18N.Get("pet_rank_mtrl_slct_name"),
		sortMode = 1,
		reverseOrder = true,
	}
	self.petSelectPanel:SetVisible(true, param)
end

function UIPetRankUpMediator:OnTablePetPutButtonClick()
	if (self._addedPetFeedCount >= PET_FEED_COUNT_MAX) then return end
	local petList = ModuleRefer.PetModule:GetPetList()
	if (table.isNilOrZeroNums(petList)) then return end

	-- 收集
	local sortList = {}
	for id, pet in pairs(petList) do
		-- 自身过滤
		if (not self:FilterBySelf(id)) then goto continue end

		-- 已选中过滤
		if (self._addedPetFeedList[id]) then goto continue end

		-- 英雄绑定过滤
		if (not self:FilterByBindHero(id)) then goto continue end

		-- 上阵过滤
		if (not self:FilterByInTeam(id)) then goto continue end

		-- 品质过滤
		local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
		if (cfg:Quality() > self._selectedFilter) then goto continue end

		-- 添加
		table.insert(sortList, {
			id = pet.ID,
			rank = pet.RankLevel,
			level = pet.Level,
			rarity = cfg:Quality(),
			templateIds = pet.TemplateIds,
		})

		::continue::
	end

	-- 无可添加提示
	if (table.isNilOrZeroNums(sortList)) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_available_lack_des"))
		return
	end

	-- 排序
	table.sort(sortList, UIPetRankUpMediator.SortPetDataForFeed)

	-- 添加
	for _, data in ipairs(sortList) do
		if (not self:OnSelectPet(data, true) and self._addedPetFeedCount > 0) then
			break
		end
	end
end

---@param data UIPetIconData
---@param auto boolean
function UIPetRankUpMediator:OnSelectPet(data, auto)
	if (not data) then return end
	if (self._addedPetFeedCount >= PET_FEED_COUNT_MAX) then return end
	if (self._addedPetFeedList[data.id]) then return end

	local curSkillLv = self._petInfo.SkillLevels[self._selectedSkillIndex]
	local curSkillExp = self._petInfo.SkillExps[self._selectedSkillIndex]

	-- 自动升级只升一级
	if (auto and self._addedExp >= self._nextRankNeedExp - curSkillExp) then
		return false
	end

	local feedPet = ModuleRefer.PetModule:GetPetByID(data.id)
	local previewExp = self._addedExp + ModuleRefer.PetModule:GetPetFeedExp(feedPet)

	-- 超出经验上限
	if (previewExp > self._allowedMaxFeedExpFor1) then
		if ((previewExp <= self._allowedMaxFeedExpFor2 or curSkillLv == MAX_RANK - 1) and not self._exceedMaxExpOnce) then
			self._exceedMaxExpOnce = true
		else
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(ConfigRefer.PetConsts:PetSkillRankRstDes()))
			return false
		end
	else
		self._exceedMaxExpOnce = false
	end

	self._addedPetFeedList[data.id] = data
	self:RefreshUpgradePetFeedList()
	self:PetDataPostProcessForUpgrade()
	self.petSelectPanel:RefreshPetTable()
	return true
end

---@param data UIPetIconData
function UIPetRankUpMediator:OnUnselectPet(data)
	if (not data) then return end
	if (not self._addedPetFeedList[data.id]) then return end
	self._addedPetFeedList[data.id] = nil
	self._exceedMaxExpOnce = false
	self:RefreshUpgradePetFeedList()
	self:PetDataPostProcessForUpgrade()
	self.petSelectPanel:RefreshPetTable()
end

---@param petData table<number, UIPetIconData>
function UIPetRankUpMediator:PetDataPostProcessForUpgrade(petDataList)
	if (petDataList) then
		self._petDataListForUpgrade = petDataList
	end
	if (not table.isNilOrZeroNums(self._petDataListForUpgrade)) then
		for id, data in pairs(self._petDataListForUpgrade) do
			data.disabled = (self._addedPetFeedCount >= PET_FEED_COUNT_MAX)
			if (self._addedPetFeedList[id]) then
				data.showDelete = true
				data.showMask = true
				data.disabled = false
				data.onDeleteClick = Delegate.GetOrCreate(self, self.OnUnselectPet)
				data.onClick = Delegate.GetOrCreate(self, self.OnUnselectPet)
			else
				data.showDelete = false
				data.showMask = false
				data.onDeleteClick = nil
				data.onClick = Delegate.GetOrCreate(self, self.OnSelectPet)
			end
		end
	end
end

---@param self UIPetRankUpMediator
---@param petData UIPetIconData
---@return boolean
function UIPetRankUpMediator:PetDataFilterForUpgrade(petData)
	if (not petData) then return false end

	-- 过滤自身
	if (not self:FilterBySelf(petData.id)) then
		return false
	end

	-- 过滤已绑定英雄宠物
	if (not self:FilterByBindHero(petData.id)) then
		return false
	end

	-- 过滤已上阵宠物
	if (not self:FilterByInTeam(petData.id)) then
		return false
	end

	return true
end

---@param self UIPetRankUpMediator
---@param petData UIPetIconData
---@return boolean
function UIPetRankUpMediator:PetDataFilterForInherit(petData)
	if (not petData) then return false end

	-- 过滤自身
	if (not self:FilterBySelf(petData.id)) then
		return false
	end

	-- 过滤已绑定英雄宠物
	if (not self:FilterByBindHero(petData.id)) then
		return false
	end

	-- 过滤已上阵宠物
	if (not self:FilterByInTeam(petData.id)) then
		return false
	end

	return true
end

function UIPetRankUpMediator:FilterBySelf(petId)
	return petId ~= self._petId
end

function UIPetRankUpMediator:FilterByBindHero(petId)
	local heroId = ModuleRefer.PetModule:GetPetLinkHero(petId)
	if (heroId and heroId > 0) then
		return false
	end
	return true
end

function UIPetRankUpMediator:FilterByInTeam(petId)
	return true
end

function UIPetRankUpMediator:OnBtnUpgradeClick()
	-- 等级检查跳转
	local selectedSkillLevel = self._petInfo.SkillLevels[self._selectedSkillIndex]
	if (self._highestRank - self._lowestRank >= MAX_RANK_DIFF and selectedSkillLevel >= self._allowedHighestRank) then
		if (self._lowestRankSkillIndex == INDEX_SE_SKILL) then
			self:OnSeCardClick()
		elseif (self._lowestRankSkillIndex == INDEX_SLG_SKILL) then
			self:OnSlgSkillClick()
		else
			self:OnSocSkillClick()
		end
		return
	end

	if (self._addedExp <= 0) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(I18N_ADD_PET_FEED))
		return
	end

	-- 品质检查
	local showWarning = false
	for id, _ in pairs(self._addedPetFeedList) do
		local pet = ModuleRefer.PetModule:GetPetByID(id)
		local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
		if (cfg:Quality() >= PET_QUALITY_WARNING or pet.RankLevel >= PET_RANK_WARNING) then
			showWarning = true
			break
		end
	end

	if (showWarning) then
		---@type CommonConfirmPopupMediatorParameter
		local dialogParam = {}
		dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
		dialogParam.title = I18N.Get("pet_rank_up_cnfm_name")
		local content = I18N.Get("pet_rank_up_cnfm_des")
		dialogParam.content = I18N.Get(content)
		dialogParam.onConfirm = function(context)
			self:DoUpgrade()
			return true
		end
		dialogParam.onCancel = function(context)
			return true
		end
		dialogParam.forceClose = true
		g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
	else
		self:DoUpgrade()
	end
end

function UIPetRankUpMediator:ClearFeedPets()
	self._addedPetFeedList = {}
	self._addedExp = 0
	self._addedPetFeedCount = 0
	self._exceedMaxExpOnce = false
end

function UIPetRankUpMediator:DoUpgrade()
	local doUpgrade = function()
		local oldRank = self._petInfo.RankLevel
		local oldValue = 0
		local oldAttrList = self._rankAttrList[oldRank]
		if (oldAttrList and self._rankDispAttr) then
			oldValue = ModuleRefer.AttrModule:GetDisplayValueWithData(self._rankDispAttr, oldAttrList)
		end

		local msg = require("PetSkillLevelUpParameter").new()
		msg.args.PetCompId = self._petId
		msg.args.SkillIndex = self._selectedSkillIndex - 1
		for id, _ in pairs(self._addedPetFeedList) do
			msg.args.CostPetCompIds:Add(id)
		end
		msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, rsp)
			if (suc) then
				ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(I18N_UPGRADE_SUCCESS))
				if (self._petInfo.RankLevel > oldRank) then
					local attrList = self._rankAttrList[self._petInfo.RankLevel]
					local value, str = ModuleRefer.AttrModule:GetDisplayValueWithData(ConfigRefer.AttrDisplay:Find(ATTR_DISP_RANK_BOOST), attrList)
					g_Game.UIManager:Open(UIMediatorNames.UIPetRankUpSuccessMediator, {
						rank = oldRank,
						rankNext = self._petInfo.RankLevel,
						attrDesc = I18N.Get(str),
						attrValue = value,
						attrValueOld = oldValue,
						templateIds = self._petInfo.TemplateIds,
					})
				end
				self:ClearFeedPets()
				self:RefreshData()
				self:RefreshUI()
			end
		end)
	end

	-- 动效
	local vxPlayed = false
	if (self.seSkillLvNew.activeSelf) then
		self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
		vxPlayed = true
	end
	if (self.slgSkillLvNew.activeSelf) then
		self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
		vxPlayed = true
	end
	if (self.socSkillLvNew.activeSelf) then
		self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
		vxPlayed = true
	end

	if (vxPlayed) then
		UIHelper.DisableUIInputs()
		require("TimerUtility").DelayExecute(function()
			doUpgrade()
			UIHelper.EnableUIInputs()
		end, VX_UPGRADE_TIME)
	else
		doUpgrade()
	end
end

function UIPetRankUpMediator:OnInheritAddButtonClick()
	local param = {
		showAllType = true,
		petDataPostProcess = Delegate.GetOrCreate(self, self.PetDataPostProcessForInherit),
		petDataFilter = Delegate.GetOrCreate(self, self.PetDataFilterForInherit),
		hintText = I18N.Get("pet_rank_mtrl_slct_name"),
		sortMode = 3,
	}
	self.petSelectPanel:SetVisible(true, param)
end

---@param petDataList table<number, UIPetIconData>
function UIPetRankUpMediator:PetDataPostProcessForInherit(petDataList)
	if (petDataList) then
		self._petDataListForInherit = petDataList
	end
	if (not table.isNilOrZeroNums(self._petDataListForInherit)) then
		local selectedData = nil
		for id, data in pairs(self._petDataListForInherit) do
			data.selected = self._inheirtSelectedPetId == id
			data.onClick = Delegate.GetOrCreate(self, self.OnSelectInheritPet)
			if (data.selected) then
				selectedData = data
			end
		end
		if (selectedData) then
			self.petSelectPanel:GetPetListTable():SetDataVisable(selectedData)
		end
	end
end

---@param self UIPetRankUpMediator
---@param data UIPetIconData
function UIPetRankUpMediator:OnSelectInheritPet(data)
	if (not data or not self._petDataListForInherit) then return end
	if (data.id == self._inheirtSelectedPetId) then return end
	local selectedData = self._petDataListForInherit[self._inheirtSelectedPetId]
	if (selectedData) then
		selectedData.selected = false
	end
	self._inheirtSelectedPetId = data.id
	data.selected = true
	self.petSelectPanel:RefreshPetTable()
	self:RefreshUI()
end

function UIPetRankUpMediator:OnTipsGroupCloseClick()
	self.tipsGroup:SetActive(false)
end

function UIPetRankUpMediator:OnTipsGroupButtonClick()
	self.tipsGroup:SetActive(true)
end

function UIPetRankUpMediator:GetColorByValueCompare(oldValue, newValue)
	if (oldValue > newValue) then
		return COLOR_ATTR_DOWN
	elseif (oldValue < newValue) then
		return COLOR_ATTR_UP
	else
		return COLOR_ATTR_SAME
	end
end

function UIPetRankUpMediator:OnInheritButtonClick()
	if (self._inheritItemHasAmount < INHERIT_NEED_ITEM_COUNT) then
		local data = {
			id = self._inhertiItemId,
			num = INHERIT_NEED_ITEM_COUNT - self._inheritItemHasAmount,
		}
		ModuleRefer.InventoryModule:OpenExchangePanel({data})
		return
	end

	local feedPetInfo = ModuleRefer.PetModule:GetPetByID(self._inheirtSelectedPetId)
	if (not feedPetInfo) then return end

	local checkRarity = function()
		if (feedPetInfo.Rarity > self._petInfo.Rarity) then
			---@type CommonConfirmPopupMediatorParameter
			local dialogParam = {}
			dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
			dialogParam.title = I18N.Get("pet_rank_up_cnfm_name")
			local content = I18N.Get("pet_inherit_cnfm_des2")
			dialogParam.content = I18N.Get(content)
			dialogParam.onConfirm = function(context)
				self:DoInherit()
				return true
			end
			dialogParam.onCancel = function(context)
				return true
			end
			dialogParam.forceClose = true
			g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam, nil, true)
		else
			self:DoInherit()
		end
	end

	local checkRank = function()
		if (feedPetInfo.RankLevel < self._petInfo.RankLevel) then
			---@type CommonConfirmPopupMediatorParameter
			local dialogParam = {}
			dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
			dialogParam.title = I18N.Get("pet_rank_up_cnfm_name")
			local content = I18N.Get("pet_inherit_cnfm_des1")
			dialogParam.content = I18N.Get(content)
			dialogParam.onConfirm = function(context)
				checkRarity()
				return true
			end
			dialogParam.onCancel = function(context)
				return true
			end
			dialogParam.forceClose = true
			g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam, nil, true)
		else
			checkRarity()
		end
	end

	local checkRankExceed = function()
		if (self._inheritRankExceed) then
			---@type CommonConfirmPopupMediatorParameter
			local dialogParam = {}
			dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
			dialogParam.title = I18N.Get("pet_rank_up_cnfm_name")
			local content = I18N.Get("pet_inherit_cnfm_des3")
			dialogParam.content = I18N.Get(content)
			dialogParam.onConfirm = function(context)
				checkRank()
				return true
			end
			dialogParam.onCancel = function(context)
				return true
			end
			dialogParam.forceClose = true
			g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam, nil, true)
		else
			checkRank()
		end
	end

	checkRankExceed()
end

function UIPetRankUpMediator:DoInherit()
	local doInherit = function()
		local oldRank = self._petInfo.RankLevel
		local msg = require("PetInheritParameter").new()
		g_Logger.Trace("Pet inherit: %s <- %s", self._petId, self._inheirtSelectedPetId)
		msg.args.PetCompId = self._petId
		msg.args.CostPetCompId = self._inheirtSelectedPetId
		msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, rsp)
			if (suc) then
				self._inheirtSelectedPetId = -1
				self:RefreshUI()
				g_Game.UIManager:Open(UIMediatorNames.UIPetInheritSuccessMediator, {petId = self._petId, oldRank = oldRank})
			end
		end)
	end

	-- 动效
	self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
	UIHelper.DisableUIInputs()
	require("TimerUtility").DelayExecute(function()
		doInherit()
		UIHelper.EnableUIInputs()
	end, VX_INHERIT_TIME)
end

function UIPetRankUpMediator:CalcCurrentSkillAllowedMaxFeedExp()
	local expTempId = self._petCfg:SkillLevelExp(self._selectedSkillIndex)
	local skillExp = self._petInfo.SkillExps[self._selectedSkillIndex]
	local maxRank = math.min(MAX_RANK, self._allowedHighestRank)
	local skillExpCacheCur = ModuleRefer.PetModule:GetSkillExpCache(expTempId, self._petInfo.SkillLevels[self._selectedSkillIndex])
	self._nextRankNeedExp = skillExpCacheCur.maxExp + 1
	local maxRankPlus1 = maxRank + 1
	local skillExpCacheMost = ModuleRefer.PetModule:GetSkillExpCache(expTempId, maxRank)
	self._allowedMaxFeedExpFor1 = skillExpCacheMost.minExp - skillExp - 1
	local skillExpCacheMostPlus1 = ModuleRefer.PetModule:GetSkillExpCache(expTempId, maxRankPlus1)
	if (skillExpCacheMostPlus1) then
		self._allowedMaxFeedExpFor2 = skillExpCacheMostPlus1.minExp - skillExp - 1
	else
		self._allowedMaxFeedExpFor2 = self._allowedMaxFeedExpFor1
	end
end

function UIPetRankUpMediator.SortPetDataForFeed(a, b)
	if (a.rarity ~= b.rarity) then
		return a.rarity < b.rarity
	elseif (a.rank ~= b.rank) then
		return a.rank < b.rank
	elseif (a.level ~= b.level) then
		return a.level < b.level
	end
	return a.id < b.id
end

return UIPetRankUpMediator
