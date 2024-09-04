local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CardType = require('CardType')
local Utils = require("Utils")
local Delegate = require("Delegate")
local TimerUtility = require("TimerUtility")
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')

local TABLE_CELL_INDEX_NAME = 0
local TABLE_CELL_INDEX_HINT = 1
local TABLE_CELL_INDEX_TEXT = 2
local TABLE_CELL_INDEX_ATTR = 3
local TABLE_CELL_INDEX_TITLE = 4

local ATTR_DISP_ID_ATTACK = 15

---@class SEHudTipsSkillCard : BaseUIComponent
local SEHudTipsSkillCard = class('SEHudTipsSkillCard', BaseUIComponent)

function SEHudTipsSkillCard:ctor()
	self.onGotoClick = nil
end

function SEHudTipsSkillCard:OnCreate()
    self.table = self:TableViewPro("p_table")
	self.p_btn = self:GameObject('p_btn')
	self.p_btn_unload = self:Button('p_btn_unload', Delegate.GetOrCreate(self, self.OnBtnUnloadClick))
	self.p_btn_upgrade_pet = self:Button('p_btn_upgrade_pet', Delegate.GetOrCreate(self, self.OnBtnUpgradeClick))
	self.p_text = self:Text('p_text','pet_skill_unload_name')
	self.p_text_upgrade_pet = self:Text('p_text_upgrade_pet',"pet_rank_up_name")
	self.btnView = self:Button('p_btn_view', Delegate.GetOrCreate(self, self.OnBtnViewClicked))
	self.imgIconView = self:Image('p_icon_view')
    self.textView = self:Text('p_text_view')
	self.goTableDetail = self:GameObject('p_table_detail')
    self.tableviewproTableDetail = self:TableViewPro('p_table_detail')
	---@type CS.UnityEngine.UI.ContentSizeFitterEx
	self.detailTableLayout = self:BindComponent("p_table_detail", typeof(CS.UnityEngine.UI.ContentSizeFitterEx))
	if self.btnView then
        self.btnView:SetVisible(false)
    end
    if self.goTableDetail then
        self.goTableDetail:SetVisible(false)
    end
	local cellPrefabRight = self.tableviewproTableDetail.cellPrefab[0]
	local prefabTexts = cellPrefabRight:GetComponentsInChildren(typeof(CS.DragonReborn.UI.ShrinkText))
	self.prefabTextRight = prefabTexts[prefabTexts.Length - 1]
	self.p_btn:SetVisible(false)
	self.child_reddot_default_upgrade = self:LuaObject('child_reddot_default_upgrade')

	self.goUpgradeHero = self:GameObject('p_upgrade_hero')
	self.btnHeroUpgrade = self:Button('p_btn_hero_upgrade', Delegate.GetOrCreate(self, self.OnGotoClick))
	self.textHeroUpgrade = self:Text('p_text_pet_bound', 'hero_skill_level_up_tips')

	self.goHeroLvlMax = self:GameObject('p_hero_lv_full')
	self.textHeroLvlMax = self:Text('p_text_hero_lv_full', 'hero_skill_level_up_full')
	self.goUpgradeHero:SetActive(false)
	self.p_pet_bound = self:GameObject('p_pet_bound')
	self.p_text_pet_bound_fixed = self:Text('p_text_pet_bound_fixed',"pet_bound_skill_upgrade_tips")
end

function SEHudTipsSkillCard:GetHeightRight(showText)
    local settings = self.prefabTextRight:GetGenerationSettings(CS.UnityEngine.Vector2(self.prefabTextRight:GetPixelAdjustedRect().size.x, 0))
    local height = self.prefabTextRight.cachedTextGeneratorForLayout:GetPreferredHeight(showText, settings) / self.prefabTextRight.pixelsPerUnit
    return height + 70
end

function SEHudTipsSkillCard:OnShow(param)
	g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
	g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function SEHudTipsSkillCard:OnHide(param)
	if self.delayMovingTimer then
		TimerUtility.StopAndRecycle(self.delayMovingTimer)
		self.delayMovingTimer = nil
	end
	g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function SEHudTipsSkillCard:OnClose(param)
	if self.delayMovingTimer then
		TimerUtility.StopAndRecycle(self.delayMovingTimer)
		self.delayMovingTimer = nil
	end
	g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
end

function SEHudTipsSkillCard:OnBtnViewClicked(args)
	ModuleRefer.HeroModule:SetIsShowBuffKey(not ModuleRefer.HeroModule:GetIsShowBuffKey())
	self:RefreshBuffDetailsState()
end

--- 获取技能伤害
---@private
---@param self SEHudTipsSkillCard
---@param unitManager SEUnitManager
---@param skillCfgCell KheroSkillLogicalSeConfigCell
---@param heroCfgId number
---@return number
function SEHudTipsSkillCard:GetSkillDamage(unitManager, skillCfgCell, heroCfgId)
	if (not skillCfgCell and (not heroCfgId or heroCfgId <= 0)) then return 0 end
	local damage = 0

	-- 英雄技能
	if (unitManager) then
		local hero = unitManager:GetHeroByHeroCfgId(heroCfgId)
		if (hero) then
			local entity = hero:GetEntity()
			if (entity) then
				local fight = entity.Fight
				if (fight) then
					damage = fight.Attack or 0
				end
			end
		end
	end

	-- 技能倍率
	if (skillCfgCell) then
		damage = damage * skillCfgCell:DamageFactor()
	end

	return damage
end

--- 显示SOC技能提示
---@param self SEHudTipsSkillCard
---@param socSkillId number
---@param skillLevel number
function SEHudTipsSkillCard:ShowSocSkillTips(socSkillId, skillLevel)
	self.table:Clear()
	socSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(socSkillId, skillLevel)
	local skillCfg = ConfigRefer.CitizenSkillInfo:Find(socSkillId)
	if (not skillCfg) then return end
	self.table:AppendData({
		name = I18N.Get(skillCfg:Name()),
	}, TABLE_CELL_INDEX_NAME)
	self.table:AppendData(I18N.Get(skillCfg:Des()), TABLE_CELL_INDEX_TEXT)
	local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(skillCfg:AttrTemplateCfg(), skillLevel)
	for i = 1, skillCfg:CitizenAttrDisplayLength() do
		local attrId = skillCfg:CitizenAttrDisplay(i)
		local dispConf = ConfigRefer.AttrDisplay:Find(attrId)
		if (dispConf) then
			local value, desc, formattedValue = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConf, attrList)
			if (ModuleRefer.AttrModule:IsAttrValueShow(dispConf, value)) then
				self.table:AppendData({
					text = I18N.Get(desc),
					number = formattedValue,
				}, TABLE_CELL_INDEX_ATTR)
			end
		end
	end
end

--- 显示SLG技能提示
---@param self SEHudTipsSkillCard
---@param slgSkillId number
---@param skillLevel number
function SEHudTipsSkillCard:ShowSlgSkillTips(slgSkillId, skillLevel, isPetFix)
	self.table:Clear()
	slgSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, skillLevel)
	local skillCfg = ConfigRefer.KheroSkillLogical:Find(slgSkillId)
	if (not skillCfg) then
		g_Logger.Error("slgSkillId:%s 找不到 KheroSkillLogical 配置", slgSkillId)
		return
	end
	local skillName = I18N.Get(skillCfg:NameKey())
	if UNITY_DEBUG and string.IsNullOrEmpty(skillName) then
		skillName = ("slgSkillId:%s KheroSkillLogical NameKey:%s 找不到多语言"):format(slgSkillId , skillCfg:NameKey())
	end
	self.table:AppendData({
		name = skillName,
		heroConfigId = 0,
	}, TABLE_CELL_INDEX_NAME)
	local introduction = I18N.GetWithParams(skillCfg:IntroductionKey(), math.floor(skillCfg:DamageFactor() * 100))
	if UNITY_DEBUG and string.IsNullOrEmpty(introduction) then
		introduction = ("slgSkillId:%s KheroSkillLogical IntroductionKey:%s 找不到多语言"):format(slgSkillId, skillCfg:IntroductionKey())
	end
	self.table:AppendData(introduction,
		TABLE_CELL_INDEX_TEXT)

	if isPetFix then
		self.p_btn:SetVisible(true)
		self.p_pet_bound:SetVisible(true)
		self.p_btn_unload:SetVisible(false)
		self.p_btn_upgrade_pet:SetVisible(false)

	end
end

--- 显示SE卡牌提示
---@param self SEHudTipsSkillCard
---@param unitManager SEUnitManager
---@param cardCfgId number
---@param useSkillId boolean
---@param isNormalAttack boolean
---@param skillLevel number
function SEHudTipsSkillCard:ShowSECardTips(cardCfgId, unitManager, useSkillId, isNormalAttack, skillLevel)
    self.table:Clear()
	---@type CardConfigCell
	local cardCfg = nil
	local skillId
	if useSkillId then
		skillId = cardCfgId
	else
		cardCfg = ConfigRefer.Card:Find(cardCfgId)
		skillId = cardCfg:Skill()
		skillId = ModuleRefer.SkillModule:GetSkillLevelUpId(skillId, skillLevel)
	end

    local skillCfgCell = ConfigRefer.KheroSkillLogicalSe:Find(skillId)
    if (skillCfgCell) then
		local damage
        -- 名称与头像
		if not useSkillId then
			local cardCfgCell = ConfigRefer.Card:Find(cardCfgId)
			local heroCfgId = nil
			if (cardCfgCell:CardTypeEnum() == CardType.Hero) then
				heroCfgId = cardCfgCell:HeroBind()
			end
			self.table:AppendData({
				name = I18N.Get(skillCfgCell:NameKey()),
				heroConfigId = heroCfgId,
			}, TABLE_CELL_INDEX_NAME)
			damage = self:GetSkillDamage(unitManager, skillCfgCell, heroCfgId)
		else
			self.table:AppendData({
				name = I18N.Get(skillCfgCell:NameKey()),
			}, TABLE_CELL_INDEX_NAME)
			damage = self:GetSkillDamage(unitManager, skillCfgCell, nil)
		end

		-- 伤害
		if (damage and damage > 0) then
			self.table:AppendData({
				text = I18N.Get("attr_physical_atk_name"),
				number = math.floor(damage),
			}, TABLE_CELL_INDEX_ATTR)
		elseif (not isNormalAttack and (not cardCfg or cardCfg:PetId() <= 0)) then
			if (cardCfg:Value(1) > 0) then
				self.table:AppendData({
					text = I18N.Get("se_card_title_4"),
					number = cardCfg:Value(1),
				}, TABLE_CELL_INDEX_ATTR)
			end
		end

        -- 描述
        local skillDesc = I18N.Get(skillCfgCell:IntroductionKey())
        if (not Utils.IsNullOrEmpty(skillDesc)) then
            self.table:AppendData(skillDesc, TABLE_CELL_INDEX_TEXT)
        end

        -- 属性列表
		for i = 1, skillCfgCell:TipsContentLength(), 2 do
			local text = I18N.Get(skillCfgCell:TipsContent(i))
			local num = I18N.Get(skillCfgCell:TipsContent(i + 1))
			self.table:AppendData({
				text = text,
				number = num,
			}, TABLE_CELL_INDEX_ATTR)
		end
    end
end

function SEHudTipsSkillCard:ShowCustomTips(data)
	self.table:Clear()
	self.table:AppendData({name = data.name}, TABLE_CELL_INDEX_NAME)
	self.table:AppendData(data.desc, TABLE_CELL_INDEX_TEXT)
end

function SEHudTipsSkillCard:HideCardTips()
    self:SetVisible(false)
end

--- 显示英雄技能提示
---@param self SEHudTipsSkillCard
---@param slgSkillId number
---@param cardId number
---@param isLock boolean
---@param skillLevel number
---@param slgSkillCell SlgSkillInfoConfigCell
---@param onGoto fun()
function SEHudTipsSkillCard:ShowHeroSkillTips(slgSkillId, cardId, isLock, skillLevel, slgSkillCell, onGoto, hasHero)
	self.onGotoClick = onGoto
	self.table:Clear()
	slgSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, skillLevel)
	local skillCfg = ConfigRefer.KheroSkillLogical:Find(slgSkillId)
	if (not skillCfg) then return end
	self.table:AppendData({name = I18N.Get(skillCfg:NameKey()),heroConfigId = 0,}, TABLE_CELL_INDEX_NAME)
	if isLock then
		self.table:AppendData(I18N.Get("hero_skill_tip_carried_unlock"), TABLE_CELL_INDEX_HINT)
	end
	self.table:AppendData(I18N.Get("hero_skill_tip_slg"), TABLE_CELL_INDEX_TITLE)
	local isMaxLvl = slgSkillCell:HurtProbaLength() == skillLevel -- todo 找个常量表配置下
	local hurtProba = slgSkillCell:HurtProba(skillLevel)
	if hurtProba and hurtProba > 0 then
		---@type SkillTipAttributeCellData
		local data = {}
		data.text = I18N.Get("hero_skill_tip_damage")
		data.number = slgSkillCell:HurtProba(skillLevel)
		data.showPercent = true
		if not isMaxLvl then
			data.extra = CS.System.String.Format("{0:#0.#}%", slgSkillCell:HurtProba(skillLevel + 1) * 100)
		end
		data.showArrow = not isMaxLvl

		self.table:AppendData(data, TABLE_CELL_INDEX_ATTR)
	end
	if slgSkillCell:TriggerProbaLength() > 0 then
		---@type SkillTipAttributeCellData
		local data = {}
		data.text = I18N.Get("hero_skill_tip_prob")
		data.number = slgSkillCell:TriggerProba(skillLevel)
		data.showPercent = true
		if not isMaxLvl then
			data.extra = CS.System.String.Format("{0:#0.#}%", slgSkillCell:TriggerProba(skillLevel + 1) * 100)
		end
		data.showArrow = not isMaxLvl
		self.table:AppendData(data, TABLE_CELL_INDEX_ATTR)
	end
	self.table:AppendData(I18N.Get(skillCfg:IntroductionKey()), TABLE_CELL_INDEX_TEXT)
	if cardId and cardId > 0 then
		self.table:AppendData(I18N.Get("hero_skill_tip_se"), TABLE_CELL_INDEX_TITLE)
		local cardCfg = ConfigRefer.Card:Find(cardId)
		local value = cardCfg:Value(skillLevel)
		if value and value> 0 then
			---@type SkillTipAttributeCellData
			local data = {}
			data.text = I18N.Get("hero_skill_tip_damage")
			data.number = cardCfg:Value(skillLevel)
			data.showPercent = true
			if not isMaxLvl then
				data.extra = CS.System.String.Format("{0:#0.#}%", cardCfg:Value(skillLevel + 1) * 100)
			end
			data.showArrow = not isMaxLvl
			self.table:AppendData(data, TABLE_CELL_INDEX_ATTR)
		end
		if cardCfg:IntroductionKey() then
			self.table:AppendData(I18N.Get(cardCfg:IntroductionKey()), TABLE_CELL_INDEX_TEXT)
		end
	end
	self:RefreshBuffDetailsState()
	self.tableviewproTableDetail:Clear()
	if slgSkillCell:AssociationBuffLength() > 0 then
		self.btnView.gameObject:SetActive(true)
		for i = 1, slgSkillCell:AssociationBuffLength() do
			local buffId = slgSkillCell:AssociationBuff(i)
			local buffCfg = ConfigRefer.KheroBuffLogical:Find(buffId)
			local single = {}
			single.title = I18N.Get(buffCfg:NameKey())
			local desc = I18N.Get(buffCfg:IntroductionKey())
			single.detail = desc
			local height = self:GetHeightRight(desc)
			self.tableviewproTableDetail:AppendDataEx(single,-1,height,0,0,0)
		end
		self:UpdateTableDetailSize()
	else
		self.btnView.gameObject:SetActive(false)
	end
	if self.delayMovingTimer then
		TimerUtility.StopAndRecycle(self.delayMovingTimer)
		self.delayMovingTimer = nil
	end
	self.delayMovingTimer = TimerUtility.DelayExecute(function()
		self.table:SetIsCanMoving(true)
	end, 0.5)
	self.goUpgradeHero:SetActive(true)
	self.btnHeroUpgrade.gameObject:SetActive(not isMaxLvl and hasHero)
	self.goHeroLvlMax:SetActive(isMaxLvl)
end


--- 显示宠物技能提示
---@param self SEHudTipsSkillCard
---@param slgSkillId number
---@param cardId number
---@param isLock boolean
---@param skillLevel number
---@param slgSkillCell SlgSkillInfoConfigCell
function SEHudTipsSkillCard:ShowPetSkillTips(slgSkillId, cardId, isLock, skillLevel, slgSkillCell)
	self.table:Clear()
	slgSkillId = ModuleRefer.SkillModule:GetSkillLevelUpId(slgSkillId, skillLevel)
	local skillCfg = ConfigRefer.KheroSkillLogical:Find(slgSkillId)
	if (not skillCfg) then return end
	self.table:AppendData({name = I18N.Get(skillCfg:NameKey()),heroConfigId = 0,}, TABLE_CELL_INDEX_NAME)
	if isLock then
		self.table:AppendData(I18N.Get("hero_skill_tip_carried_unlock"), TABLE_CELL_INDEX_HINT)
	end
	self.table:AppendData(I18N.Get("hero_skill_tip_slg"), TABLE_CELL_INDEX_TITLE)
	local hurtProba = slgSkillCell:HurtProba(1)
	if hurtProba and hurtProba > 0 then
		self.table:AppendData({text = I18N.Get("hero_skill_tip_damage"),number = slgSkillCell:HurtProba(1), showPercent = true}, TABLE_CELL_INDEX_ATTR)
	end
	local triggerProba = slgSkillCell:TriggerProba(1)
	if triggerProba and triggerProba > 0 then
		self.table:AppendData({text = I18N.Get("hero_skill_tip_prob"),number = slgSkillCell:TriggerProba(1), showPercent = true}, TABLE_CELL_INDEX_ATTR)
	end
	self.table:AppendData(I18N.Get(skillCfg:IntroductionKey()), TABLE_CELL_INDEX_TEXT)
	if cardId and cardId > 0 then
		self.table:AppendData(I18N.Get("hero_skill_tip_se"), TABLE_CELL_INDEX_TITLE)
		local cardCfg = ConfigRefer.Card:Find(cardId)
		local value = cardCfg:Value(1)
		if value and value> 0 then
			self.table:AppendData({text = I18N.Get("hero_skill_tip_damage"),number = cardCfg:Value(1), showPercent = true}, TABLE_CELL_INDEX_ATTR)
		end
		if cardCfg:IntroductionKey() then
			self.table:AppendData(I18N.Get(cardCfg:IntroductionKey()), TABLE_CELL_INDEX_TEXT)
		end
	end
	self:RefreshBuffDetailsState()
	self.tableviewproTableDetail:Clear()
	if slgSkillCell:AssociationBuffLength() > 0 then
		self.btnView.gameObject:SetActive(true)
		for i = 1, slgSkillCell:AssociationBuffLength() do
			local buffId = slgSkillCell:AssociationBuff(i)
			local buffCfg = ConfigRefer.KheroBuffLogical:Find(buffId)
			local single = {}
			single.title = I18N.Get(buffCfg:NameKey())
			local desc = I18N.Get(buffCfg:IntroductionKey())
			single.detail = desc
			local height = self:GetHeightRight(desc)
			self.tableviewproTableDetail:AppendDataEx(single,-1,height,0,0,0)
		end
		self:UpdateTableDetailSize()
	else
		self.btnView.gameObject:SetActive(false)
	end
	if self.delayMovingTimer then
		TimerUtility.StopAndRecycle(self.delayMovingTimer)
		self.delayMovingTimer = nil
	end

	self.delayMovingTimer = TimerUtility.DelayExecute(function()
		self.table:SetIsCanMoving(true)
	end, 0.5)
end

function SEHudTipsSkillCard:ShowPetDropSkillTips(param)
	local skillLevel = param.skillLevel
	self.cellIndex = param.cellIndex
	self.petId = param.petId
	self.skillId = param.cfgId
	self.table:Clear()
	local skillCfg = ConfigRefer.PetLearnableSkill:Find(param.cfgId)
	if (not skillCfg) then return end
	self.table:AppendData({name = I18N.Get(skillCfg:Name()), heroConfigId = 0,}, TABLE_CELL_INDEX_NAME)

	local descArgs = {}
	for i = 1, skillCfg:DescArgsLength() do
		descArgs[i] = I18N.Get(skillCfg:DescArgs(i))
	end

	local introduction = ModuleRefer.PetModule:GetPetSkillDesc(param.petId,param.cfgId)
	self.table:AppendData(introduction,
		TABLE_CELL_INDEX_TEXT)

	self.p_btn:SetVisible(self.cellIndex)
	if self.cellIndex then
		local upgradeNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetSkillUpgrade_"..self.petId.."_"..self.cellIndex, NotificationType.PET_SKILL_UPGRADE)
   		ModuleRefer.NotificationModule:AttachToGameObject(upgradeNode, self.child_reddot_default_upgrade.go, self.child_reddot_default_upgrade.redDot)
	end
end

function SEHudTipsSkillCard:OnBtnUnloadClick()
	if self.petId and self.cellIndex then
		ModuleRefer.PetModule:UnEquipSkill(self.petId, self.cellIndex)
	end
	g_Game.UIManager:CloseByName(UIMediatorNames.UICommonPopupCardDetailMediator)
end

function SEHudTipsSkillCard:OnBtnUpgradeClick()
    g_Game.UIManager:Open(UIMediatorNames.UIPetSkillLearnMediator, {skillId = self.skillId, cellIndex = self.cellIndex})
	g_Game.UIManager:CloseByName(UIMediatorNames.UICommonPopupCardDetailMediator)
end

function SEHudTipsSkillCard:OnGotoClick()
	if self.onGotoClick then
		self.onGotoClick()
	end
end

function SEHudTipsSkillCard:RefreshBuffDetailsState()
	local showBuffHint = ModuleRefer.HeroModule:GetIsShowBuffKey()
	self.goTableDetail:SetActive(showBuffHint)
	if showBuffHint then
		self.textView.text = I18N.Get("hero_skill_tip_buff_off")
		g_Game.SpriteManager:LoadSprite("sp_comp_icon_look_close", self.imgIconView)
	else
		self.textView.text = I18N.Get("hero_skill_tip_buff_on")
		g_Game.SpriteManager:LoadSprite("sp_comp_icon_look", self.imgIconView)
	end
end

function SEHudTipsSkillCard:UpdateTableDetailSize()
	if Utils.IsNull(self.detailTableLayout) then return end
	local iScrollRect = self.tableviewproTableDetail.ScrollRect
	if Utils.IsNull(iScrollRect) then return end
	local scrollRect = iScrollRect.scrollRect
	if Utils.IsNull(scrollRect) then return end
	---@type CS.UnityEngine.RectTransform
	local content = scrollRect.content
	if Utils.IsNull(content) then return end
	local flexibleHeight = content.sizeDelta.y
	local maxHeight = self.detailTableLayout.MaxHeight
	local minHeight = self.detailTableLayout.MinHeight
	local targetValue = 0
	if flexibleHeight < self.detailTableLayout.MaxHeight then
		targetValue = flexibleHeight
	elseif flexibleHeight == maxHeight then
		targetValue = maxHeight - 0.001
	end
	if math.abs(targetValue - minHeight) < 0.01 then return end
	self.detailTableLayout.MinHeight = targetValue
end

function SEHudTipsSkillCard:LateUpdate(dt)
	if Utils.IsNullOrEmpty(self.tableviewproTableDetail) then
		g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdate))
		return
	end
	if not self.tableviewproTableDetail.gameObject.activeInHierarchy then
		return
	end
	self:UpdateTableDetailSize()
end

return SEHudTipsSkillCard
