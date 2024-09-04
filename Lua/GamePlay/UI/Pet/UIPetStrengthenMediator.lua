local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require("ConfigRefer")
local AttrValueType = require("AttrValueType")
local EventConst = require("EventConst")
local CommonDropDown = require("CommonDropDown")
local PetAddRankExpParameter = require("PetAddRankExpParameter")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")
local SetPetIsLockParameter = require("SetPetIsLockParameter")
local UIHelper = require("UIHelper")
local PetBreakRankParameter = require("PetBreakRankParameter")

local PET_FEED_COUNT_MAX = 6
local PET_FILTER_QUALITY_BLUE = 1

---@class UIPetStrengthenMediator : BaseUIMediator
local UIPetStrengthenMediator = class('UIPetStrengthenMediator', BaseUIMediator)

function UIPetStrengthenMediator:ctor()
	self.addedPetFeedCount = 0
	self.petDataListForUpgrade = nil
	self.addedPetFeedList = {}
	self.selectedFilter = PET_FILTER_QUALITY_BLUE
	self.breakSelectedFilter = PET_FILTER_QUALITY_BLUE
	self.breakNeedPetType = nil
	self.breakNeedCount = 0
	self.petDataListForBreak = nil
	self.addedPetBreakCount = 0
	self.addedPetBreakList = {}
	self.emptyPetFeedData = {onClick = function() self:OnBtnPetClicked() end}
end

function UIPetStrengthenMediator:OnCreate()
	self.goGroupUpgrade = self:GameObject('p_group_upgrade')
    self.imgIconStrengthen = self:Image('p_icon_strengthen')
    self.goIconSatr1 = self:GameObject('p_icon_satr_1')
    self.goIconSatr2 = self:GameObject('p_icon_satr_2')
    self.goIconSatr3 = self:GameObject('p_icon_satr_3')
    self.goIconSatr4 = self:GameObject('p_icon_satr_4')
    self.goIconSatr5 = self:GameObject('p_icon_satr_5')

	self.imgIconSatr1 = self:Image('p_icon_satr_1')
    self.imgIconSatr2 = self:Image('p_icon_satr_2')
    self.imgIconSatr3 = self:Image('p_icon_satr_3')
    self.imgIconSatr4 = self:Image('p_icon_satr_4')
    self.imgIconSatr5 = self:Image('p_icon_satr_5')

	self.animtriggerTriggerStar1 = self:AnimTrigger('trigger_star1')
    self.animtriggerTriggerStar2 = self:AnimTrigger('trigger_star2')
    self.animtriggerTriggerStar3 = self:AnimTrigger('trigger_star3')
    self.animtriggerTriggerStar4 = self:AnimTrigger('trigger_star4')
    self.animtriggerTriggerStar5 = self:AnimTrigger('trigger_star5')
    self.textName = self:Text('p_text_name')
	self.goIconArrowName = self:GameObject('p_icon_arrow_name')
	self.textNameNew = self:Text('p_text_name_new')
    self.textProgress = self:Text('p_text_progress')
    self.sliderProgress = self:Slider('p_progress')
	self.goGroupBreak = self:GameObject('p_group_break')
	self.imgIconStrengthenOld = self:Image('p_icon_strengthen_old')
    self.goIconSatr1Old = self:GameObject('p_icon_satr_1_old')
    self.goIconSatr2Old = self:GameObject('p_icon_satr_2_old')
    self.goIconSatr3Old = self:GameObject('p_icon_satr_3_old')
    self.goIconSatr4Old = self:GameObject('p_icon_satr_4_old')
    self.goIconSatr5Old = self:GameObject('p_icon_satr_5_old')

	self.imgIconSatr1Old = self:Image('p_icon_satr_1_old')
    self.imgIconSatr2Old = self:Image('p_icon_satr_2_old')
    self.imgIconSatr3Old = self:Image('p_icon_satr_3_old')
    self.imgIconSatr4Old = self:Image('p_icon_satr_4_old')
    self.imgIconSatr5Old = self:Image('p_icon_satr_5_old')

    self.imgIconStrengthenNew = self:Image('p_icon_strengthen_new')
    self.goIconSatr1New = self:GameObject('p_icon_satr_1_new')
    self.goIconSatr2New = self:GameObject('p_icon_satr_2_new')
    self.goIconSatr3New = self:GameObject('p_icon_satr_3_new')
    self.goIconSatr4New = self:GameObject('p_icon_satr_4_new')
    self.goIconSatr5New = self:GameObject('p_icon_satr_5_new')

	self.imgIconSatr1New = self:Image('p_icon_satr_1_new')
    self.imgIconSatr2New = self:Image('p_icon_satr_2_new')
    self.imgIconSatr3New = self:Image('p_icon_satr_3_new')
    self.imgIconSatr4New = self:Image('p_icon_satr_4_new')
    self.imgIconSatr5New = self:Image('p_icon_satr_5_new')

	self.animtriggerTrigger = self:AnimTrigger('trigger')

	self.textBreakOld = self:Text('p_text_break_old')
    self.textBreakNew = self:Text('p_text_break_new')


    self.tableviewproTableBasics = self:TableViewPro('p_table_basics')
    self.textNeed = self:Text('p_text_need')

    self.goQuantity = self:GameObject('p_quantity')
    self.tableviewproTablePet = self:TableViewPro('p_table_pet')
    self.btnPet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnPetClicked))
    self.compChildDropdown = self:LuaObject('child_dropdown')
    self.btnPut = self:Button('p_btn_put', Delegate.GetOrCreate(self, self.OnBtnPutClicked))
    self.textPut = self:Text('p_text_put', "pet_recycle_button0")

	self.goSpecial = self:GameObject('p_special')
    self.tableviewproTablePetSpecial = self:TableViewPro('p_table_pet_special')
    self.btnPetSpecial = self:Button('p_btn_pet_special', Delegate.GetOrCreate(self, self.OnBtnPetSpecialClicked))
    self.btnPutSpecial = self:Button('p_btn_put_special', Delegate.GetOrCreate(self, self.OnBtnPutSpecialClicked))
    self.textPutSpecial = self:Text('p_text_put_special', "pet_recycle_button0")
    self.compChildDropdownSpecial = self:LuaObject('child_dropdown_special')
    self.imgImgPet = self:Image('p_img_pet')
    self.textPetName = self:Text('p_text_pet_name')

	self:DragEvent("p_btn_empty", nil, Delegate.GetOrCreate(self, self.OnModelDrag))
	self:PointerClick("p_btn_empty", Delegate.GetOrCreate(self, self.OnClickPet))



	self.goBtns = self:GameObject('btns')
    self.textHintUpgrade = self:Text('p_text_hint_upgrade')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.goStatusFull = self:GameObject('p_status_full')
    self.textFull = self:Text('p_text_full', "hero_level_full")

    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.compChildPetPopupSelect = self:LuaObject('child_pet_popup_select')
	self.stars = {self.goIconSatr1, self.goIconSatr2, self.goIconSatr3, self.goIconSatr4, self.goIconSatr5}
	self.starOlds = {self.goIconSatr1Old, self.goIconSatr2Old, self.goIconSatr3Old, self.goIconSatr4Old, self.goIconSatr5Old}
	self.starNews = {self.goIconSatr1New, self.goIconSatr2New, self.goIconSatr3New, self.goIconSatr4New, self.goIconSatr5New}
	self.animTriggers = {self.animtriggerTriggerStar1, self.animtriggerTriggerStar2, self.animtriggerTriggerStar3, self.animtriggerTriggerStar4, self.animtriggerTriggerStar5}
	self.imgStars = {self.imgIconSatr1, self.imgIconSatr2, self.imgIconSatr3, self.imgIconSatr4, self.imgIconSatr5}
	self.imgStarOlds = {self.imgIconSatr1Old, self.imgIconSatr2Old, self.imgIconSatr3Old, self.imgIconSatr4Old, self.imgIconSatr5Old}
	self.imgStarNews = {self.imgIconSatr1New, self.imgIconSatr2New, self.imgIconSatr3New, self.imgIconSatr4New, self.imgIconSatr5New}
	self.textHintUpgrade.gameObject:SetActive(false)
	self.btnPet.gameObject:SetActive(false)
end

function UIPetStrengthenMediator:OnOpened(param)
	self.goProgressVfx = self:GameObject('vfx_jindu_light')
	self.goProgressVfx:SetActive(false)
    self.compChildCommonBack:FeedData({title = I18N.Get("pet_rank_up_name")})
	self.petId = param.petId
	self.closeCallback = param.closeCallback
	self.pet = ModuleRefer.PetModule:GetPetByID(self.petId)
	self.petCfg = ModuleRefer.PetModule:GetPetCfg(self.pet.ConfigId)
	self.targetLv = 0
	self:RefreshStar()
	self:RefreshItems()
	self:RefreshAttr()

	local filterDropDownData = {}
	filterDropDownData.items = CommonDropDown.CreateData(
		"", I18N.Get("pet_filter_condition3"),
		"", I18N.Get("pet_filter_condition4"),
		"", I18N.Get("pet_filter_condition5")
	)
	filterDropDownData.defaultId = PET_FILTER_QUALITY_BLUE
	filterDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnFilterDropDownSelect)
	self.compChildDropdown:FeedData(filterDropDownData)

	local breakFilterDropDownData = {}
	breakFilterDropDownData.items = CommonDropDown.CreateData(
		"", I18N.Get("pet_filter_condition3"),
		"", I18N.Get("pet_filter_condition4"),
		"", I18N.Get("pet_filter_condition5")
	)
	breakFilterDropDownData.defaultId = PET_FILTER_QUALITY_BLUE
	breakFilterDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnBreakFilterDropDownSelect)
	self.compChildDropdownSpecial:FeedData(breakFilterDropDownData)
	g_Game.EventManager:AddListener(EventConst.PET_REFRESH_UNLOCK_ITEM,Delegate.GetOrCreate(self,self.OnRefreshUnlockItem))
end

function UIPetStrengthenMediator:OnFilterDropDownSelect(id)
	self.selectedFilter = id
end

function UIPetStrengthenMediator:OnBreakFilterDropDownSelect(id)
	self.breakSelectedFilter = id
end

function UIPetStrengthenMediator:RefreshStar()
	local rankLevel = self.pet.RankLevel
	local stageLevel = math.floor(rankLevel / 5)
	local showIndex = rankLevel % 5
	if self.pet.RankLevel == 0 or showIndex ~= 0 then
		stageLevel = stageLevel + 1
		for i, star in ipairs(self.imgStars) do
			star.gameObject:SetActive(i <= showIndex)
			star.transform.localScale = CS.UnityEngine.Vector3.one
			if i <= showIndex then
				if i < #self.imgStars then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
				end
			end
		end
		self.textName.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), showIndex)
	else
		for i, star in ipairs(self.imgStars) do
			if i < #self.imgStars then
				g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
			else
				g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
			end
			star.gameObject:SetActive(true)
			star.transform.localScale = CS.UnityEngine.Vector3.one
		end
		self.textName.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), #self.imgStars)
	end
	if stageLevel <= ConfigRefer.PetConsts:PetRankIconLength() then
        local icon = ConfigRefer.PetConsts:PetRankIcon(stageLevel)
		self:LoadSprite(icon, self.imgIconStrengthen)
	end
	local expId = self.petCfg:RankExpTemplate()
	local expCfg = ConfigRefer.ExpTemplate:Find(expId)
	local isMax = rankLevel >= expCfg:MaxLv()
	self.textProgress.gameObject:SetActive(not isMax)
	self.sliderProgress.gameObject:SetActive(not isMax)
	if not isMax then
		self.textProgress.text = string.format("%d/%d", self.pet.RankExp, expCfg:ExpLv(rankLevel + 1))
		self.sliderProgress.value = self.pet.RankExp / expCfg:ExpLv(rankLevel + 1)
		self.goProgressVfx:SetActive(false)
	end
end

function UIPetStrengthenMediator:OnModelDrag(go, eventData)
	local petMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIPetMediator)
    if petMediator then
        petMediator:OnModelDrag(go, eventData)
    end
end

function UIPetStrengthenMediator:OnClickPet()
	local petMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIPetMediator)
	if petMediator then
		petMediator:OnClickPet()
	end
end

function UIPetStrengthenMediator:PreviewRefreshAttr()
	self.lockRefreshAttr = true
	self.upValueAttrs = {}
	self.newValueAttrs = {}
	local petCfg = self.petCfg
	local pet = self.pet
	self.tableviewproTableBasics:Clear()
	local maxCellNum = ConfigRefer.PetRarity:Find(petCfg:Quality()):AttrEntryNumMax()
	local templateIds = pet.TemplateIds or {}
	local templateLvs = pet.TemplateLevels
	local unlockNum = #pet.TemplateIds
	local count = 1
	for i = 1, unlockNum do
		local templateId = templateIds[i]
		local templateLv = templateLvs[i]
		templateId = ModuleRefer.PetModule:TransformTemplateId(templateId)
		local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(templateId, templateLv) or {}
		local nextAttrList = {}
		if i == 1  and self.targetLv > self.pet.RankLevel then
			nextAttrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(templateId, self.targetLv + 1) or {}
		end
		local showAttr = attrList[1]
		local showNextAttr = nextAttrList[1] or {}
		if showAttr then
			local recordValue = self.recordAttrState[showAttr.type]
			if recordValue then
				local single = {}
				local cfg = ConfigRefer.AttrElement:Find(showAttr.type)
				single.icon = cfg:Icon()
				single.name = I18N.Get(cfg:Name())
				local value
				local valueType = cfg:ValueType()
				local nextValue = 0
				if valueType == AttrValueType.OneTenThousand then
					value = showAttr.originValue / 100
					nextValue = (showNextAttr.originValue or 0) / 100
				else
					value = showAttr.originValue
					nextValue = showNextAttr.originValue or 0
				end
				single.num = value + nextValue
				single.add = nextValue
				single.showBase = count % 2 == 0
				single.showArrow = true
				count = count + 1
				single.isPer = cfg:ValueType() ~= AttrValueType.Fix
				self.tableviewproTableBasics:AppendData(single, 0)
				if value > recordValue then
					self.upValueAttrs[showAttr.type] = true
				end
			else
				self.newValueAttrs[showAttr.type] = true
			end
		end
	end
	local lockNum = maxCellNum - unlockNum
	if self.recordLockNum > 0 then
		local unlockNewNum = self.recordLockNum - lockNum
		for i = 1, self.recordLockNum do
			local unlockLevel = petCfg:AddAttrEntryRankLevel(unlockNum + i - 2)
			if unlockLevel > 0 then
				local isUnlockItem = i <= unlockNewNum
				self.tableviewproTableBasics:AppendData({showBase = count % 2 == 0, unlockLevel = unlockLevel, petId = self.petId, isUnlockItem = isUnlockItem}, 1)
				count = count + 1
			end
		end
	end
end

function UIPetStrengthenMediator:OnRefreshUnlockItem()
	self:RefreshAttr()
end

function UIPetStrengthenMediator:RefreshAttr()
	self.lockRefreshAttr = false
	self.recordAttrState = {}
	self.recordLockNum = 0
	local petCfg = self.petCfg
	local pet = self.pet
	self.tableviewproTableBasics:Clear()
	local perRarity = ConfigRefer.PetRarity:Find(petCfg:Quality())
	local maxCellNum = perRarity:AttrEntryNumMax()
	local templateIds = pet.TemplateIds or {}
	local templateLvs = pet.TemplateLevels
	local unlockNum = #pet.TemplateIds
	local count = 1
	for i = 1, unlockNum do
		local templateId = templateIds[i]
		local templateLv = templateLvs[i]
		templateId = ModuleRefer.PetModule:TransformTemplateId(templateId)
		local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(templateId, templateLv) or {}
		local nextAttrList = {}
		if i == 1 and self.targetLv > self.pet.RankLevel then
			nextAttrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(templateId, self.targetLv + 1) or {}
		end
		local showAttr = attrList[1]
		local showNextAttr = nextAttrList[1] or {}
		if showAttr then
			local single = {}
			local cfg = ConfigRefer.AttrElement:Find(showAttr.type)
			single.icon = cfg:Icon()
			single.name = I18N.Get(cfg:Name())
			local value
			local valueType = cfg:ValueType()
			local nextValue = 0
			if valueType == AttrValueType.OneTenThousand then
				value = showAttr.originValue / 100
				nextValue = (showNextAttr.originValue or 0) / 100
			else
				value = showAttr.originValue
				nextValue = showNextAttr.originValue or 0
			end
			single.num = value + nextValue
			single.add = nextValue
			single.showBase = count % 2 == 0
			single.showArrow = true
			count = count + 1
			single.isUpValue = (self.upValueAttrs or {})[showAttr.type] == true
			(self.upValueAttrs or {})[showAttr.type] = false
			single.isNewValue = (self.newValueAttrs or {})[showAttr.type] == true
			(self.newValueAttrs or {})[showAttr.type] = false
			single.isPer = cfg:ValueType() ~= AttrValueType.Fix
			self.tableviewproTableBasics:AppendData(single, 0)
			self.recordAttrState[showAttr.type] = value
		end
	end
	local lockNum = maxCellNum - unlockNum
	if lockNum > 0 then
		self.recordLockNum = lockNum
		for i = 1, lockNum do
			local unlockLevel = petCfg:AddAttrEntryRankLevel(unlockNum + i - 1)
			if unlockLevel > 0 then
				self.tableviewproTableBasics:AppendData({showBase = count % 2 == 0, unlockLevel = unlockLevel, petId = self.petId, showUnlock = i == 1 and self.isNeedBreak}, 1)
				count = count + 1
			end
		end
	end
end

function UIPetStrengthenMediator:RefreshItems()
	for i = 1, 5 do
		self.animTriggers[i]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
		self.animTriggers[i]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
	end
	local rankLevel = self.pet.RankLevel
	local expId = self.petCfg:RankExpTemplate()
	local expCfg = ConfigRefer.ExpTemplate:Find(expId)
	local isMax = rankLevel >= expCfg:MaxLv()
	local specialCost = nil
	local cfg = ConfigRefer.PetRankLevelUpCost:Find(self.petCfg:RankLevelUpCost())
	local unlockNum = #self.pet.TemplateIds
	if cfg then
		for i = 1, cfg:ItemsLength() do
			if i + 1 > unlockNum then
				local item = cfg:Items(i)
				if item:DestLevel() == rankLevel then
					specialCost = item
				end
			end
		end
	end
	local isNeedBreak = false
	if specialCost ~= nil then
		--local lv = specialCost:DestLevel()
		--local fullExp = expCfg:ExpLv(lv + 1)
		isNeedBreak = true--self.pet.RankExp >= fullExp
	end
	if isNeedBreak and not isMax then
		self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
		local btnData = {}
		btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBreakBtn)
		btnData.disableClick = Delegate.GetOrCreate(self, self.OnDisableClickBreakBtn)
		btnData.buttonText = I18N.Get("pet_breakthrough_name")
		self.compChildCompB:FeedData(btnData)
		self.breakNeedPetType = specialCost:EatPets()
		local petNum = specialCost:PetNum()
		self.breakNeedCount = petNum
		local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(self.breakNeedPetType)
		local samplePetCfg = ModuleRefer.PetModule:GetPetCfg(petTypeCfg:SamplePetCfg())
		self:LoadSprite(samplePetCfg:Icon(), self.imgImgPet)
		self.textPetName.text = I18N.Get(samplePetCfg:Name()) .. " x" .. petNum
		self.textNeed.text = I18N.Get(samplePetCfg:Name()) .. " x" .. petNum
		self:RefreshBreakPetFeedList()
		local stageLevel = math.floor(rankLevel / 5)
		local showIndex = rankLevel % 5
		if self.pet.RankLevel == 0 or showIndex ~= 0 then
			stageLevel = stageLevel + 1
			for i, star in ipairs(self.imgStarOlds) do
				if i < #self.imgStarOlds then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
				end
				star.gameObject:SetActive(i <= showIndex)
			end
			self.textBreakOld.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), showIndex)
		else
			for i, star in ipairs(self.imgStarOlds) do
				if i < #self.imgStarOlds then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
				end
				star.gameObject:SetActive(true)
			end
			self.textBreakOld.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), #self.imgStarOlds)
		end
		if stageLevel <= ConfigRefer.PetConsts:PetRankIconLength() then
			local icon = ConfigRefer.PetConsts:PetRankIcon(stageLevel)
			self:LoadSprite(icon, self.imgIconStrengthenOld)
		end

		local nextStageLevel = stageLevel
		if rankLevel ~= 0 and showIndex == 0 then
			nextStageLevel = nextStageLevel + 1
			for i, star in ipairs(self.imgStarNews) do
				if i < #self.imgStarNews then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. nextStageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. nextStageLevel .. "_star_l", star)
				end
				star.gameObject:SetActive(false)
			end
			self.textBreakNew.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(nextStageLevel), 0)
		else
			local nextIndex = showIndex + 1
			for i, star in ipairs(self.imgStarNews) do
				if i < #self.imgStarNews then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. nextStageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. nextStageLevel .. "_star_l", star)
				end
				star.gameObject:SetActive(i <= nextIndex)
			end
			self.textBreakNew.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(nextStageLevel), nextIndex)
		end
		if nextStageLevel <= ConfigRefer.PetConsts:PetRankIconLength() then
			local icon = ConfigRefer.PetConsts:PetRankIcon(nextStageLevel)
			self:LoadSprite(icon, self.imgIconStrengthenNew)
		end
	else
		self.breakNeedPetType = nil
		self.breakNeedCount = 0
		local btnData = {}
		btnData.onClick = Delegate.GetOrCreate(self, self.OnClickStrengthenBtn)
		btnData.buttonText = I18N.Get("pet_rank_up_name")
		self.compChildCompB:FeedData(btnData)
		self.textNeed.text = I18N.Get("pet_rank_up_material_name")
		self:RefreshUpgradePetFeedList()
	end
	self.textNeed.gameObject:SetActive(not isMax)
	self.goQuantity:SetActive(not (isMax or isNeedBreak))
	self.goSpecial:SetActive(isNeedBreak and not isMax)
	self.goBtns:SetActive(not isMax)
	self.goStatusFull:SetActive(isMax)
	self.goGroupUpgrade:SetActive(not isNeedBreak)
	self.goGroupBreak:SetActive(isNeedBreak and not isMax)
	self.isNeedBreak = isNeedBreak and not isMax
end

function UIPetStrengthenMediator:FilterBySelf(petId)
	return petId ~= self.petId
end

function UIPetStrengthenMediator:FilterByBindHero(petId)
	local heroId = ModuleRefer.PetModule:GetPetLinkHero(petId)
	if (heroId and heroId > 0) then
		return false
	end
	return true
end

function UIPetStrengthenMediator:FilterByBindPvp(petId)
	return not ModuleRefer.PetModule:IsLockByPvp(petId)
end

function UIPetStrengthenMediator:FilterByInTeam(petId)
	return true
end

function UIPetStrengthenMediator:FilterByLock(petId)
	return not ModuleRefer.PetModule:IsPetLocked(petId)
end

function UIPetStrengthenMediator:FilterByPetType(petId)
	local petInfo = ModuleRefer.PetModule:GetPetByID(petId)
	local cfg = ModuleRefer.PetModule:GetPetCfg(petInfo.ConfigId)
	return cfg:Type() == self.breakNeedPetType
end

--------------------------------------------升阶-------------------------------------------
function UIPetStrengthenMediator:OnBtnPetClicked(args)
	local param = {
		showAllType = true,
		petDataPostProcess = Delegate.GetOrCreate(self, self.PetDataPostProcessForUpgrade),
		petDataFilter = Delegate.GetOrCreate(self, self.PetDataFilterForUpgrade),
		hintText = I18N.Get("pet_rank_mtrl_slct_name"),
		sortMode = 1,
		reverseOrder = true,
	}
	self.compChildPetPopupSelect:SetVisible(true, param)
end

function UIPetStrengthenMediator:PetDataPostProcessForUpgrade(petDataList)
	if (petDataList) then
		self.petDataListForUpgrade = petDataList
	end
	if (not table.isNilOrZeroNums(self.petDataListForUpgrade)) then
		for id, data in pairs(self.petDataListForUpgrade) do
			local isLockPvp = ModuleRefer.PetModule:IsLockByPvp(id)
			local heroId = ModuleRefer.PetModule:GetPetLinkHero(id)
			local isLockTeam = heroId and heroId > 0
			data.lockByTeam = isLockPvp or isLockTeam
			data.heroId = heroId
			data.disabled = (self.addedPetFeedCount >= PET_FEED_COUNT_MAX)
			if (self.addedPetFeedList[id]) then
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

function UIPetStrengthenMediator:OnUnselectPet(data)
	if (not data) then return end
	if (not self.addedPetFeedList[data.id]) then return end
	self.addedPetFeedList[data.id] = nil
	self:RefreshUpgradePetFeedList()
	self:PetDataPostProcessForUpgrade()
	self.compChildPetPopupSelect:RefreshPetTable()
end

function UIPetStrengthenMediator:OnSelectPet(data)
	if (not data) then return end
	if not self:FilterByBindHero(data.id) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_list_squad_des"))
		return
	end
	if not self:FilterByLock(data.id) then
		UIHelper.ShowConfirm(I18N.Get("pet_list_locked_des"), nil, function()
			local params = SetPetIsLockParameter.new()
			params.args.PetCompId = data.id
			params.args.Value = false
			params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
				if (suc) then
					if (self.addedPetFeedCount >= PET_FEED_COUNT_MAX) then return end
					if (self.addedPetFeedList[data.id]) then return end
					self.addedPetFeedList[data.id] = data
					self:RefreshUpgradePetFeedList()
					self:PetDataPostProcessForUpgrade()
					self.compChildPetPopupSelect:RefreshPetTable()
				end
			end)
		end)
		return
	end
	if not self:FilterByBindPvp(data.id) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_list_pvp_des"))
		return
	end
	if (self.addedPetFeedCount >= PET_FEED_COUNT_MAX) then return end
	if (self.addedPetFeedList[data.id]) then return end
	self.addedPetFeedList[data.id] = data
	self:RefreshUpgradePetFeedList()
	self:PetDataPostProcessForUpgrade()
	self.compChildPetPopupSelect:RefreshPetTable()
end

function UIPetStrengthenMediator:PetDataFilterForUpgrade(petData)
	if (not petData) then return false end
	-- 过滤自身
	if (not self:FilterBySelf(petData.id)) then
		return false
	end
	-- -- 过滤已绑定英雄宠物
	-- if (not self:FilterByBindHero(petData.id)) then
	-- 	return false
	-- end
	-- 过滤已上阵宠物
	if (not self:FilterByInTeam(petData.id)) then
		return false
	end
	-- --过滤加锁的宠物
	-- if(not self:FilterByLock(petData.id)) then
	-- 	return false
	-- end
	-- --过滤在竞技场中的宠物
	-- if (not self:FilterByBindPvp(petData.id)) then
	-- 	return false
	-- end
	return true
end

function UIPetStrengthenMediator:ClearFeedList()
	self.targetLv = 0
	self.tableviewproTablePet:Clear()
	self.addedPetFeedCount = 0
	self._addedExp = 0
	for i = 1, PET_FEED_COUNT_MAX do
		self.tableviewproTablePet:AppendData(self.emptyPetFeedData, 1)
	end
	self.compChildCompB:SetEnabled(false)
end

function UIPetStrengthenMediator:RefreshUpgradePetFeedList()
	self.targetLv = 0
	self.tableviewproTablePet:Clear()
	self.addedPetFeedCount = 0
	self._addedExp = 0
	for id, _ in pairs(self.addedPetFeedList) do
		local petInfo = ModuleRefer.PetModule:GetPetByID(id)
		if (petInfo) then
			self.addedPetFeedCount = self.addedPetFeedCount + 1
			self._addedExp = self._addedExp + ModuleRefer.PetModule:GetPetStrengthFeedExp(petInfo)
			local data = {
				id = id,
				cfgId = petInfo.ConfigId,
				level = petInfo.Level,
				rank = petInfo.RankLevel,
				templateIds = petInfo.TemplateIds,
				onClick = function() self:OnBtnPetClicked() end
			}
			self.tableviewproTablePet:AppendData(data, 0)
		end
	end
	for i = 1, PET_FEED_COUNT_MAX - self.addedPetFeedCount do
		self.tableviewproTablePet:AppendData(self.emptyPetFeedData, 1)
	end
	self.compChildCompB:SetEnabled(self._addedExp > 0)
	self:RefreshUpgradeExp()
end

function UIPetStrengthenMediator:RefreshUpgradeExp()
	local selfTotalExp = ModuleRefer.PetModule:GetPetTotalStrengthenExp(self.pet)
	local totalExp = selfTotalExp + self._addedExp
	local targetLv, lastExp, percent, exp = ModuleRefer.PetModule:CalcStrengthenTargetLevel(self.pet, totalExp)

	local expId = self.petCfg:RankExpTemplate()
	local expCfg = ConfigRefer.ExpTemplate:Find(expId)
	local isMax = self.pet.RankLevel >= expCfg:MaxLv()
	local unlockNum = #self.pet.TemplateIds
	local broken = false
	if not isMax then
		local breakLevel = 0
		local cfg = ConfigRefer.PetRankLevelUpCost:Find(self.petCfg:RankLevelUpCost())
		if cfg then
			for i = 1, cfg:ItemsLength() do
				local item = cfg:Items(i)
				if i + 1 > unlockNum then
					if item:DestLevel() <= targetLv and item:DestLevel() >= self.pet.RankLevel then
						breakLevel = item:DestLevel()
						break
					end
				end
				if i + 1 == unlockNum and item:DestLevel() == targetLv then
					broken = true
				end
			end
		end
		if breakLevel > 0 then
			targetLv = breakLevel
			local _, limitExp, _, curExp = ModuleRefer.PetModule:CalcStrengthenLimitLevel(self.pet, totalExp, targetLv)
			self.textProgress.text = string.format("%d/%d", limitExp, curExp)
			self.sliderProgress.value = percent
		else
			self.textProgress.text = string.format("%d/%d", lastExp, exp)
			self.sliderProgress.value = percent
		end
	end
	self.goProgressVfx:SetActive(self._addedExp > 0 and lastExp > 0)
	local stageLevel = math.floor(targetLv / 5)
	local showIndex = targetLv % 5
	local rankLevel = self.pet.RankLevel
	local originIndex = rankLevel % 5
	for i = 1, 5 do
		self.animTriggers[i]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
		self.animTriggers[i]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
	end
	self.needPlayUpgradeStars = {}
	if broken then
		if targetLv == 0 or showIndex ~= 0 then
			stageLevel = stageLevel + 1
		end
		stageLevel = stageLevel + 1
		for i, star in ipairs(self.imgStars) do
			star.gameObject:SetActive(false)
			star.transform.localScale = CS.UnityEngine.Vector3.one
		end
		self.textName.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), 0)
	else
		if targetLv == 0 or showIndex ~= 0 then
			stageLevel = stageLevel + 1
			for i, star in ipairs(self.imgStars) do
				star.gameObject:SetActive(i <= showIndex)
				star.transform.localScale = CS.UnityEngine.Vector3.one
				if i <= showIndex then
					if i < #self.imgStars then
						g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
					else
						g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
					end
				end
			end
			self.textNameNew.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), showIndex)
			if showIndex > originIndex and targetLv > rankLevel then
				for i = originIndex + 1, showIndex do
					self.animTriggers[i]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
					self.needPlayUpgradeStars[#self.needPlayUpgradeStars + 1] = self.animTriggers[i]
				end
			elseif showIndex > 0 and targetLv > rankLevel then
				for i = 1, showIndex do
					self.animTriggers[i]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
					self.needPlayUpgradeStars[#self.needPlayUpgradeStars + 1] = self.animTriggers[i]
				end
			end
		else
			for i, star in ipairs(self.imgStars) do
				if i < #self.imgStars then
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s", star)
				else
					g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l", star)
				end
				star.gameObject:SetActive(true)
				star.transform.localScale = CS.UnityEngine.Vector3.one
			end
			self.textNameNew.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetRankName(stageLevel), #self.imgStars)
			if targetLv > rankLevel then
				for i = originIndex + 1, 5 do
					self.animTriggers[i]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
					self.needPlayUpgradeStars[#self.needPlayUpgradeStars + 1] = self.animTriggers[i]
				end
			end
		end
	end
	if stageLevel <= ConfigRefer.PetConsts:PetRankIconLength() then
        local icon = ConfigRefer.PetConsts:PetRankIcon(stageLevel)
		self:LoadSprite(icon, self.imgIconStrengthen)
	end
	local isUpLv = targetLv > self.pet.RankLevel
	self.goIconArrowName:SetActive(isUpLv)
	self.textNameNew.gameObject:SetActive(isUpLv)
	if isUpLv then
		self.targetLv = targetLv
	else
		self.targetLv = 0
	end
	if not self.lockRefreshAttr then
		self:RefreshAttr()
	end
end

function UIPetStrengthenMediator:OnBtnPutClicked(args)
	if (self.addedPetFeedCount >= PET_FEED_COUNT_MAX) then return end
	local petList = ModuleRefer.PetModule:GetPetList()
	if (table.isNilOrZeroNums(petList)) then return end
	-- 收集
	local sortList = {}
	for id, pet in pairs(petList) do
		-- 自身过滤
		if (not self:FilterBySelf(id)) then goto continue end
		-- 已选中过滤
		if (self.addedPetFeedList[id]) then goto continue end
		-- 英雄绑定过滤
		if (not self:FilterByBindHero(id)) then goto continue end
		-- 上阵过滤
		if (not self:FilterByInTeam(id)) then goto continue end
		-- 锁定过滤
		if (not self:FilterByLock(id)) then goto continue end
		--过滤在竞技场中的宠物
		if (not self:FilterByBindPvp(id)) then  goto continue end
		-- 品质过滤
		local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
		if (cfg:Quality() > self.selectedFilter) then goto continue end
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
	local sortfunction = function(a, b)
		if (a.rarity ~= b.rarity) then
			return a.rarity < b.rarity
		elseif (a.rank ~= b.rank) then
			return a.rank < b.rank
		elseif (a.level ~= b.level) then
			return a.level < b.level
		end
		return a.id < b.id
	end
	-- 排序
	table.sort(sortList, sortfunction)
	-- 添加
	local isLimit = false
	local addedExp = 0
	local selfTotalExp = ModuleRefer.PetModule:GetPetTotalStrengthenExp(self.pet)
	local expId = self.petCfg:RankExpTemplate()
	local expCfg = ConfigRefer.ExpTemplate:Find(expId)
	local cfg = ConfigRefer.PetRankLevelUpCost:Find(self.petCfg:RankLevelUpCost())
	local breakLevel = 0
	for _, data in ipairs(sortList) do
		if not isLimit then
			local petInfo = ModuleRefer.PetModule:GetPetByID(data.id)
			addedExp = addedExp + ModuleRefer.PetModule:GetPetStrengthFeedExp(petInfo)
			local targetLv, _, _, _ = ModuleRefer.PetModule:CalcStrengthenTargetLevel(self.pet, addedExp + selfTotalExp)
			local isMax = targetLv >= expCfg:MaxLv()
			if isMax then
				isLimit = true
			end
			if cfg then
				local unlockNum = #self.pet.TemplateIds
				for i = 1, cfg:ItemsLength() do
					if i + 1 > unlockNum then
						local item = cfg:Items(i)
						if item:DestLevel() <= targetLv and item:DestLevel() >= self.pet.RankLevel then
							breakLevel = item:DestLevel()
						end
					end
				end
			end
			if breakLevel > 0 then
				isLimit = true
			end
			self:OnSelectPet(data)
		end
	end
end

function UIPetStrengthenMediator:OnClickStrengthenBtn()
	local callback = function()
		local params = PetAddRankExpParameter.new()
		params.args.PetCompId = self.petId
		for id, _ in pairs(self.addedPetFeedList) do
			params.args.PetCompIds:Add(id)
		end
		self.targetLv = 0
		params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, rsp)
			if (suc) then
				if self.needPlayUpgradeStars and #self.needPlayUpgradeStars > 0 then
					self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
					for i = 1, #self.needPlayUpgradeStars do
						if i == #self.needPlayUpgradeStars then
							self.needPlayUpgradeStars[i]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, function()
								self:ClearFeedPets()
								self:RefreshStar()
								self:PreviewRefreshAttr()
								self:RefreshItems()
								self:RefreshAttr()
								self:ClearFeedList()
							end)
						else
							self.needPlayUpgradeStars[i]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
						end
					end
					g_Game.EventManager:TriggerEvent(EventConst.PET_STRENGTN_UP)
				else
					self:ClearFeedPets()
					self:RefreshStar()
					self:RefreshItems()
					self:RefreshAttr()
					self:ClearFeedList()
				end
			end
		end)
	end
	local hasSpecialPet = false
	for id, _ in pairs(self.addedPetFeedList) do
		local petInfo = ModuleRefer.PetModule:GetPetByID(id)
		if petInfo then
			if petInfo.RankExp > 0 then
				hasSpecialPet = true
				break
			end
			if petInfo.RankLevel > 0 then
				hasSpecialPet = true
				break
			end
		end
	end
	if hasSpecialPet then
		UIHelper.ShowConfirm(I18N.Get("pet_nurture_overflow_des"), nil, function()
			callback()
		end)
	else
		callback()
	end
end

function UIPetStrengthenMediator:ClearFeedPets()
	self.addedPetFeedList = {}
	self._addedExp = 0
	self.addedPetFeedCount = 0
end
-------------------------------------------------------------------------------------------
---------------------------------------突破------------------------------------------------
function UIPetStrengthenMediator:OnBtnPetSpecialClicked(args)
	local param = {
		showAllType = false,
		onlyShowType = true,
		selectedType = self.breakNeedPetType,
		petDataPostProcess = Delegate.GetOrCreate(self, self.PetDataPostProcessForBreak),
		petDataFilter = Delegate.GetOrCreate(self, self.PetDataFilterForBreak),
		hintText = I18N.Get("pet_rank_mtrl_slct_name"),
		sortMode = 1,
		reverseOrder = true,
	}
	self.compChildPetPopupSelect:SetVisible(true, param)
end

function UIPetStrengthenMediator:PetDataPostProcessForBreak(petDataList)
	if (petDataList) then
		self.petDataListForBreak = petDataList
	end
	if (not table.isNilOrZeroNums(self.petDataListForBreak)) then
		for id, data in pairs(self.petDataListForBreak) do
			local isLockPvp = ModuleRefer.PetModule:IsLockByPvp(id)
			local heroId = ModuleRefer.PetModule:GetPetLinkHero(id)
			local isLockTeam = heroId and heroId > 0
			data.lockByTeam = isLockPvp or isLockTeam
			data.heroId = heroId
			data.disabled = (self.addedPetBreakCount >= self.breakNeedCount)
			if (self.addedPetBreakList[id]) then
				data.showDelete = true
				data.showMask = true
				data.disabled = false
				data.onDeleteClick = Delegate.GetOrCreate(self, self.OnUnselectBreakPet)
				data.onClick = Delegate.GetOrCreate(self, self.OnUnselectBreakPet)
			else
				data.showDelete = false
				data.showMask = false
				data.onDeleteClick = nil
				data.onClick = Delegate.GetOrCreate(self, self.OnSelectBreakPet)
			end
		end
	end
end

function UIPetStrengthenMediator:OnUnselectBreakPet(data)
	if (not data) then return end
	if (not self.addedPetBreakList[data.id]) then return end
	self.addedPetBreakList[data.id] = nil
	self:RefreshBreakPetFeedList()
	self:PetDataPostProcessForBreak()
	self.compChildPetPopupSelect:RefreshPetTable()
end

function UIPetStrengthenMediator:OnSelectBreakPet(data)
	if (not data) then return end
	if not self:FilterByBindHero(data.id) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_list_squad_des"))
		return
	end
	if not self:FilterByLock(data.id) then
		UIHelper.ShowConfirm(I18N.Get("pet_list_locked_des"), nil, function()
			local params = SetPetIsLockParameter.new()
			params.args.PetCompId = data.id
			params.args.Value = false
			params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
				if (suc) then
					if (self.addedPetBreakCount >= self.breakNeedCount) then return end
					if (self.addedPetBreakList[data.id]) then return end
					self.addedPetBreakList[data.id] = data
					self:RefreshBreakPetFeedList()
					self:PetDataPostProcessForBreak()
					self.compChildPetPopupSelect:RefreshPetTable()
				end
			end)
		end)
		return
	end
	if not self:FilterByBindPvp(data.id) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_list_pvp_des"))
		return
	end
	if (self.addedPetBreakCount >= self.breakNeedCount) then return end
	if (self.addedPetBreakList[data.id]) then return end
	self.addedPetBreakList[data.id] = data
	self:RefreshBreakPetFeedList()
	self:PetDataPostProcessForBreak()
	self.compChildPetPopupSelect:RefreshPetTable()
end

function UIPetStrengthenMediator:PetDataFilterForBreak(petData)
	if (not petData) then return false end
	-- 过滤自身
	if (not self:FilterBySelf(petData.id)) then
		return false
	end
	-- -- 过滤已绑定英雄宠物
	-- if (not self:FilterByBindHero(petData.id)) then
	-- 	return false
	-- end
	-- 过滤已上阵宠物
	if (not self:FilterByInTeam(petData.id)) then
		return false
	end
	-- --过滤加锁的宠物
	-- if(not self:FilterByLock(petData.id)) then
	-- 	return false
	-- end
	-- --过滤在竞技场中的宠物
	-- if (not self:FilterByBindPvp(petData.id)) then
	-- 	return false
	-- end
	--过滤不同类型
	if(not self:FilterByPetType(petData.id)) then
		return false
	end
	return true
end

function UIPetStrengthenMediator:RefreshBreakPetFeedList()
	self.tableviewproTablePetSpecial:Clear()
	self.addedPetBreakCount = 0
	for id, _ in pairs(self.addedPetBreakList) do
		local petInfo = ModuleRefer.PetModule:GetPetByID(id)
		if (petInfo) then
			self.addedPetBreakCount = self.addedPetBreakCount + 1
			local data = {
				id = id,
				cfgId = petInfo.ConfigId,
				level = petInfo.Level,
				rank = petInfo.RankLevel,
				templateIds = petInfo.TemplateIds,
			}
			self.tableviewproTablePetSpecial:AppendData(data, 0)
		end
	end
	for i = 1, self.breakNeedCount - self.addedPetBreakCount do
		self.tableviewproTablePetSpecial:AppendData(self.emptyPetFeedData, 1)
	end
	self:RefreshBreakState()
end

function UIPetStrengthenMediator:RefreshBreakState()
	local isCanBreak = self.addedPetBreakCount >= self.breakNeedCount
	g_Game.EventManager:TriggerEvent(EventConst.PET_BREAK_UP, isCanBreak)
	self.compChildCompB:SetEnabled(isCanBreak)
end

function UIPetStrengthenMediator:OnBtnPutSpecialClicked(args)
    if (self.addedPetBreakCount >= self.breakNeedCount) then return end
	local petList = ModuleRefer.PetModule:GetPetList()
	if (table.isNilOrZeroNums(petList)) then return end
	-- 收集
	local sortList = {}
	for id, pet in pairs(petList) do
		-- 自身过滤
		if (not self:FilterBySelf(id)) then goto continue end
		-- 已选中过滤
		if (self.addedPetBreakList[id]) then goto continue end
		-- 英雄绑定过滤
		if (not self:FilterByBindHero(id)) then goto continue end
		-- 上阵过滤
		if (not self:FilterByInTeam(id)) then goto continue end
		-- 锁定过滤
		if (not self:FilterByLock(id)) then goto continue end
		--过滤在竞技场中的宠物
		if (not self:FilterByBindPvp(id)) then  goto continue end
		-- 品质过滤
		local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
		if (cfg:Quality() > self.breakSelectedFilter) then goto continue end
		-- 类型过滤
		if(not self:FilterByPetType(id)) then goto continue end
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
	local sortfunction = function(a, b)
		if (a.rarity ~= b.rarity) then
			return a.rarity < b.rarity
		elseif (a.rank ~= b.rank) then
			return a.rank < b.rank
		elseif (a.level ~= b.level) then
			return a.level < b.level
		end
		return a.id < b.id
	end
	-- 排序
	table.sort(sortList, sortfunction)
	-- 添加
	for _, data in ipairs(sortList) do
		self:OnSelectBreakPet(data)
	end
end

function UIPetStrengthenMediator:OnClickBreakBtn()
	local callback = function()
		local params = PetBreakRankParameter.new()
		params.args.PetCompId = self.petId
		for id, _ in pairs(self.addedPetBreakList) do
			params.args.PetCompIds:Add(id)
		end
		params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, rsp)
			if (suc) then
				self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
					self:ClearBreakPets()
					self:RefreshStar()
					self:PreviewRefreshAttr()
					self:RefreshItems()
					self:RefreshBreakPetFeedList()
				end)
				g_Game.EventManager:TriggerEvent(EventConst.PET_STRENGTN_UP)
			end
		end)
	end
	local hasSpecialPet = false
	for id, _ in pairs(self.addedPetBreakList) do
		local petInfo = ModuleRefer.PetModule:GetPetByID(id)
		if petInfo then
			if petInfo.RankExp > 0 then
				hasSpecialPet = true
				break
			end
			if petInfo.RankLevel > 0 then
				hasSpecialPet = true
				break
			end
		end
	end
	if hasSpecialPet then
		UIHelper.ShowConfirm(I18N.Get("pet_nurture_overflow_des"), nil, function()
			callback()
		end)
	else
		callback()
	end
end

function UIPetStrengthenMediator:ClearBreakPets()
	self.addedPetBreakList = {}
	self.addedPetBreakCount = 0
end

function UIPetStrengthenMediator:OnDisableClickBreakBtn()
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_breakthrough_material_lack_des"))
end
-------------------------------------------------------------------------------------------

function UIPetStrengthenMediator:OnClose(param)
	if self.closeCallback then
		self.closeCallback(self.petId)
	end
	g_Game.EventManager:RemoveListener(EventConst.PET_REFRESH_UNLOCK_ITEM,Delegate.GetOrCreate(self,self.OnRefreshUnlockItem))
end

return UIPetStrengthenMediator
