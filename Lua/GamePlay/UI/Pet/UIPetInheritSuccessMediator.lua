local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

---@class UIPetInheritSuccessMediator : BaseUIMediator
local UIPetInheritSuccessMediator = class('UIPetInheritSuccessMediator', BaseUIMediator)

local INDEX_SE_SKILL = 1
local INDEX_SLG_SKILL = 2
local INDEX_SOC_SKILL = 3

function UIPetInheritSuccessMediator:ctor()

end

function UIPetInheritSuccessMediator:OnCreate()
	self:InitObjects()
end

function UIPetInheritSuccessMediator:InitObjects()
	self.petImage = self:Image("p_img_pet")
	self.titleText = self:Text("p_text_title", "pet_inherit_scc_des")
	
	---@type HeroInfoItemComponent
	self.petHeroComp = self:LuaObject("child_card_hero_s_ex")

	self.rankOldText = self:Text("p_text_strengthen")
	self.rankNewText = self:Text("p_text_strengthen_next")

	self.globalAttrDesc = self:Text("p_text_skill_detail")
	self.globalAttrValue = self:Text("p_text_inherit_now")

	---@type CommonSkillCard
	self.seCard = self:LuaObject("child_card_skill")
	self.seSkillDesc = self:Text("p_text_card_detail")
	self.seSkillRank = self:Text("p_text_strengthen_now_card")
	self.seSkillValue = self:Text("p_text_card_now")

	---@type BaseSkillIcon
	self.slgSkill = self:LuaObject("child_item_skill_1")
	self.slgSkillDesc = self:Text("p_text_skill_detail_1")
	self.slgSkillRank = self:Text("p_text_strengthen_now_skill_1")
	self.slgSkillValue = self:Text("p_text_now_skill_1")

	---@type BaseSkillIcon
	self.socSkill = self:LuaObject("child_item_skill_2")
	self.socSkillDesc = self:Text("p_text_skill_detail_2")
	self.socSkillRank = self:Text("p_text_strengthen_now_skill_2")
	self.socSkillValue = self:Text("p_text_skill_now_2")

	self.hintText = self:Text("p_text_hint", "tech_info_close")
end

function UIPetInheritSuccessMediator:OnShow(param)
	if (not param) then return end
	self.petId = param.petId
	self.oldRank = param.oldRank

	local petInfo = ModuleRefer.PetModule:GetPetByID(self.petId)
	if (not petInfo) then return end

	local petCfg = ModuleRefer.PetModule:GetPetCfg(petInfo.ConfigId)
	self:LoadSprite(petCfg:ShowPortrait(), self.petImage)

	local heroId = ModuleRefer.PetModule:GetPetLinkHero(self.petId)
	if (heroId and heroId > 0) then
		self.petHeroComp.CSComponent.gameObject:SetActive(true)
		self.petHeroComp:FeedData({heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)})
	else
		self.petHeroComp.CSComponent.gameObject:SetActive(false)
	end

	self.rankOldText.text = self.oldRank
	self.rankNewText.text = petInfo.RankLevel

	local rankAttrCfg = ConfigRefer.PetRankAttr:Find(petCfg:RankAttr())
	local globalAttrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(rankAttrCfg:AttrTempUI(), petInfo.RankLevel)
	local globalDispAttr = ConfigRefer.AttrDisplay:Find(ConfigRefer.PetConsts:PetRankAllElemBoost())
	local value, str = ModuleRefer.AttrModule:GetDisplayValueWithData(globalDispAttr, globalAttrList)
	self.globalAttrDesc.text = I18N.Get(str)
	self.globalAttrValue.text = tostring(value)

	-- SE
	self.seCard:FeedData({
		cardId = petCfg:CardId(),
		skillLevel = petInfo.SkillLevels[INDEX_SE_SKILL],
		disableCardClick = true,
	})
	local seNpc = ConfigRefer.SeNpc:Find(petCfg:SeNpcId())
	local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(petInfo.AttrTemplateCfgId, petInfo.Level)
	local attrAtk = ConfigRefer.AttrDisplay:Find(ConfigRefer.PetConsts:PetSeSkillAtk())
	local attrAtkValue = ModuleRefer.AttrModule:GetDisplayValueWithData(attrAtk, attrList)
	local seSkillId = seNpc:Seskill(1)
	local realSeSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(seSkillId, petInfo.SkillLevels[INDEX_SE_SKILL])
	local seSkillCfg = ConfigRefer.KheroSkillLogicalSe:Find(realSeSkillId)
	self.seSkillRank.text = tostring(petInfo.SkillLevels[INDEX_SE_SKILL])
	--self.seSkillDesc.text = I18N.Get(seSkillCfg:IntroductionKey())
	self.seSkillDesc.text = I18N.Get(seSkillCfg:NameKey())
	local skillValue = attrAtkValue * seSkillCfg:DamageFactor() + seSkillCfg:DamageValue()
	self.seSkillValue.text = tostring(math.floor(skillValue))

	-- SLG
	local slgSkillId = petCfg:SkillIdSLG()
	local realSlgSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, petInfo.SkillLevels[INDEX_SLG_SKILL])
	local slgSkillCfg = ConfigRefer.KheroSkillLogical:Find(realSlgSkillId)
	self.slgSkillRank.text = tostring(petInfo.SkillLevels[INDEX_SLG_SKILL])
	--self.slgSkillDesc.text = I18N.Get(slgSkillCfg:IntroductionKey())
	self.slgSkillDesc.text = I18N.Get(slgSkillCfg:NameKey())
	self.slgSkillValue.text = math.floor(slgSkillCfg:DamageFactor() * 100)
	self.slgSkill:FeedData({
		skillId = slgSkillId,
		index = slgSkillId,
		skillLevel = petInfo.SkillLevels[INDEX_SLG_SKILL],
		isSlg = true,
	})

	-- SOC
	local socSkillId = petCfg:SkillIdSOC()
	local realSocSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(socSkillId, petInfo.SkillLevels[INDEX_SOC_SKILL])
	local socSkillCfg = ConfigRefer.CitizenSkillInfo:Find(realSocSkillId)
	self.socSkillRank.text = tostring(petInfo.SkillLevels[INDEX_SOC_SKILL])
	--self.socSkillDesc.text = I18N.Get(socSkillCfg:Des())
	self.socSkillDesc.text = I18N.Get(socSkillCfg:Name())
	local _, _, socValue = ModuleRefer.SkillModule:GetFirstShowCitizenSkillAttr(realSocSkillId)
	self.socSkillValue.text = socValue
	self.socSkill:FeedData({
		skillId = socSkillId,
		index = socSkillId,
		skillLevel = petInfo.SkillLevels[INDEX_SOC_SKILL],
		isSoc = true,
	})
end

function UIPetInheritSuccessMediator:OnHide(param)
end

function UIPetInheritSuccessMediator:OnOpened(param)
end

function UIPetInheritSuccessMediator:OnClose(param)

end

return UIPetInheritSuccessMediator
