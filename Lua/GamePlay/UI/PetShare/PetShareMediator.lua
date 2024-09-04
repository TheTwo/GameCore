local BaseUIMediator = require("BaseUIMediator")
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local HeroUIUtilities = require("HeroUIUtilities")
local LuaReusedComponentPool = require('LuaReusedComponentPool')

---@class PetShareMediator : BaseUIMediator
local PetShareMediator = class("PetShareMediator", BaseUIMediator)

---@class PetShareMediatorParam
---@field configID number
---@field x number
---@field y number
---@field z number

local PET_QUALITY_LEGENDARY = 4
local SP_BASE_QUALITY_PREFIX = "sp_common_base_collect_0"
local SP_BASE_QUALITY_CIRCLE_PREFIX = "sp_common_base_collect_s_0"

local QUALITY_BACKGROUND = {
    "sp_common_base_collect_01",
    "sp_common_base_collect_02",
    "sp_common_base_collect_03",
    "sp_common_base_collect_04",
}

function PetShareMediator:OnCreate()
	self:InitObjects()
end

function PetShareMediator:InitObjects()
	self.iconQaulitt = self:Image("p_icon_quality")
	self.baseQuality = self:Image("p_base_quality")
	self.baseQualityCircle = self:Image("p_base_quality_circle")
	self.imagePet = self:Image("p_img_pet")
	self.imagePetShadow = self:Image("p_img_pet_l")
	self.vxTrigger = self:BindComponent("p_vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
	self.textContinue = self:Text("p_text_continue_1", "pet_se_result_memo")

	self.textName = self:Text("p_text_name")
	self.compPosition = self:LuaObject('p_position')
	self.aptitudeButton1 = self:Button("p_btn_aptitude_1", Delegate.GetOrCreate(self, self.OnAptitude1Click))
	self.aptitudeButton2 = self:Button("p_btn_aptitude_2", Delegate.GetOrCreate(self, self.OnAptitude2Click))
	self.aptitudeButton3 = self:Button("p_btn_aptitude_3", Delegate.GetOrCreate(self, self.OnAptitude3Click))

	self.skillText = self:Text("p_text_skill", "hero_card")
	self.fixedSkill = self:LuaObject("child_item_skill_1")
	self.dropSkill = self:LuaObject("child_item_skill")
	self.attrTableCloseButton = self:Button("p_btn_info", Delegate.GetOrCreate(self, self.OnAttrTableCloseButtonClick))
	self.attrTable = self:TableViewPro("p_table_info")
	self.goAttr = self:GameObject('attr')
	self.imgIconAttr = self:Image('p_icon_attr')
    self.textAttrName = self:Text('p_text_attr_name')
    self.textAttrNum = self:Text('p_text_attr_num')
	self.p_text_dna = self:Text('p_text_dna','pet_gene_name')
	---@type UIHeroAssociateIconComponent
	self.child_icon_style = self:LuaObject('child_icon_style')

	---@see PetGeneComp
	self.luaPetGene = self:LuaObject('child_pet_dna')

	---@type PetStarLevelComponent
	-- 星级
	self.group_star = self:LuaBaseComponent('group_star')
    -- 工种
    ---@type UIPetWorkTypeComp
    self.p_type_main = self:LuaBaseComponent('p_type_main')
    self.p_layout_type_main = self:Transform('p_layout_type_main')
    self.pool_type_info_main = LuaReusedComponentPool.new(self.p_type_main, self.p_layout_type_main)

	--战斗标签
	self.child_pet_lable_feature = self:LuaBaseComponent('child_pet_lable_feature')
	self.goAttr:SetVisible(false)
	self.dropSkill:SetVisible(false)
	self.p_base = self:Image("p_base")
end

function PetShareMediator:OnAttrTableCloseButtonClick()
	self.attrTableCloseButton.gameObject:SetActive(false)
	self.attrTable.gameObject:SetActive(false)
end

function PetShareMediator:OnShow(param)
	self.petCfgId = param.configID
	self.skillLevels = param.pl
	local randomAttrItemCfgId = param.z
	local templateId = param.x
	local templateLv = param.y

	local petCfg = ModuleRefer.PetModule:GetPetCfg(self.petCfgId)
	self.petCfg = petCfg
	g_Game.SpriteManager:LoadSprite(SP_BASE_QUALITY_PREFIX .. (petCfg:Quality() + 1), self.baseQuality)
	self.iconQaulitt.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(petCfg:Quality()))
	g_Game.SpriteManager:LoadSprite(SP_BASE_QUALITY_CIRCLE_PREFIX .. (petCfg:Quality() + 1), self.baseQualityCircle)
	g_Game.SpriteManager:LoadSprite(QUALITY_BACKGROUND[petCfg:Quality() + 1], self.p_base)

	local portrait = petCfg:ShowPortrait()
	self:LoadSprite(portrait, self.imagePet)
	self:LoadSprite(portrait, self.imagePetShadow)

	if petCfg:Quality() >= PET_QUALITY_LEGENDARY then
		self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
	else
		self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
	end
	self.textName.text = I18N.Get(petCfg:Name())
	local curPetBattleType = ModuleRefer.PetModule:GetPetBattleLabel(self.petCfgId)
	self.compPosition:FeedData({battleType = curPetBattleType})


	-- 风格
	local tagId = petCfg:AssociatedTagInfo()
	self.child_icon_style:FeedData({
		tagId = tagId,
	})

    -- 基因 为空
    self.luaPetGene:FeedData({ConfigId = self.petCfgId, PetGeneInfo = param.gn})

    -- 星级展示
    self:SetStars()

    -- 工种
    self.pool_type_info_main:HideAll()
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        local workType = petWorkCfg:Type()
        local level = petWorkCfg:Level()
        local param = {level = level, name = ModuleRefer.PetModule:GetPetWorkTypeStr(workType), icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(workType)}
        local itemMain = self.pool_type_info_main:GetItem().Lua
        itemMain:FeedData(param)
    end

	-- 掉落技能
    local dropSkill = ConfigRefer.PetSkillBase:Find(petCfg:RefSkillTemplate()):DropSkill()
    local slgSkillId = ConfigRefer.PetLearnableSkill:Find(dropSkill):SlgSkill()
    -- self.dropSkill:FeedData({index = dropSkill, skillLevel = 1, quality = petCfg:Quality(), isPet = true, clickCallBack = Delegate.GetOrCreate(self, self.OnSlgSkillClick)})
	self.dropSkill:FeedData({index = dropSkill,
		skillLevel = 1,
		quality = petCfg:Quality(),
		isPet = true,
		clickCallBack = function()
			g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 6, cfgId = dropSkill})
		end
	})

	-- 固定技能
    local skillId = petCfg:SLGSkillID(2)
    local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(skillId)
    self.fixedSkill:FeedData({
        skillId = slgSkillCell:SkillId(),
        index = slgSkillCell:SkillId(),
        skillLevel = self.skillLevels and self.skillLevels[1].level or 1,
        isPetFix = true,
        quality = petCfg:Quality(),
        clickCallBack = Delegate.GetOrCreate(self, self.OnSlgSkillClick),
    })

	-- 战斗标签
	if self.child_pet_lable_feature then
		local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(petCfg:Type())
		local petTagId = petTypeCfg:PetTagDisplay()
		if petTagId and petTagId > 0 then
			self.child_pet_lable_feature:SetVisible(true)
			self.child_pet_lable_feature:FeedData(petTagId)
		else
			self.child_pet_lable_feature:SetVisible(false)
		end
	end

	-- if not templateId then
	-- 	self.goAttr:SetActive(false)
	-- 	return
	-- end
	-- if templateId == 0 then
	-- 	self.goAttr:SetActive(false)
	-- 	return
	-- end
	-- self.goAttr:SetActive(true)
	templateId = ModuleRefer.PetModule:TransformTemplateId(templateId)
	local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(templateId, templateLv) or {}
	local showAttr = attrList[1]
	if showAttr then
		local cfg = ConfigRefer.AttrElement:Find(showAttr.type)
		g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgIconAttr)
		self.textAttrName.text = I18N.Get(cfg:Name())
		self.textAttrNum.text = ModuleRefer.AttrModule:GetAttrValueShowTextByType(cfg, showAttr.originValue)
	end
end

function PetShareMediator:OnHide(param)
	if self.petCfg then
		if self.petCfg:Quality() >= PET_QUALITY_LEGENDARY then
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
		else
			self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
		end
	end
end

function PetShareMediator:OnOpened(param)

end

function PetShareMediator:OnClose(param)

end

function PetShareMediator:OnAptitude1Click()
	ModuleRefer.ToastModule:ShowTextToast({
		content = I18N.Get(ConfigRefer.PetConsts:PetAttrEstmCtgrAtkDes()),
		clickTransform = self.aptitudeButton1.gameObject.transform,
	})
end

function PetShareMediator:OnAptitude2Click()
	ModuleRefer.ToastModule:ShowTextToast({
		content = I18N.Get(ConfigRefer.PetConsts:PetAttrEstmCtgrDefDes()),
		clickTransform = self.aptitudeButton2.gameObject.transform,
	})
end

function PetShareMediator:OnAptitude3Click()
	ModuleRefer.ToastModule:ShowTextToast({
		content = I18N.Get(ConfigRefer.PetConsts:PetAttrEstmCtgrLivDes()),
		clickTransform = self.aptitudeButton3.gameObject.transform,
	})
end


function PetShareMediator:OnSlgSkillClick(param)
    g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {type = 2, cfgId = param.index, level = 1})
end

function PetShareMediator:OnSocSkillClick(skillId, skillLevel)
	g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, {
		type = 3,
		cfgId = skillId,
		level = skillLevel or 1,
	})
end

function PetShareMediator:SetStars()
    if self.group_star then
		if self.skillLevels then
			local param = {skillLevels = self.skillLevels}
			self.group_star:FeedData(param)
			self.group_star:SetVisible(true)
		else
			--可能不存在这种情况 没有收到协议中的等级时 打开了分享
			local param = {skillLevels = {{level = 1, quality = self.petCfg:Quality()}}}
			self.group_star:FeedData(param)
			self.group_star:SetVisible(true)
		end
    end
end

return PetShareMediator
