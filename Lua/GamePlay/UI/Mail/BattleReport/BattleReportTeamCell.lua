local BaseTableViewProCell = require ('BaseTableViewProCell')
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local ObjectType = require('ObjectType')
local HeroUIUtilities = require('HeroUIUtilities')
local ArtResourceUtils = require('ArtResourceUtils')
local MailUtils = require("MailUtils")

---@class BattleReportTeamCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local BattleReportTeamCell = class('BattleReportTeamCell', BaseTableViewProCell)

---@class BattleReportTeamCellData
---@field record wds.BattleReportRecord
---@field attacker MailUnitData
---@field defender MailUnitData

function BattleReportTeamCell:OnCreate(param)

	self.Node 						= {}
	self.Head 						= {}
	---@type HeroInfoItemComponent[]
	self.HeroComp 					= {}
	---@type CommonPetIconBase[]
	self.PetComp 					= {}
	---@type CommonMonsterIconBase[]
	self.MonsterComp 				= {}
	self.PetEmpty = {}
	self.HeroCurHp 					= {}
	self.HeroOrgHp 					= {}
	self.HeroHpText 				= {}
	self.HeroDamageDealtNumText 	= {}
	self.HeroDamageDealtSlider 		= {}
	self.HeroDamageDealtSliderText 	= {}
	self.HeroDamageTakenNumText 	= {}
	self.HeroDamageTakenSlider 		= {}
	self.HeroDamageTakenSliderText 	= {}
	self.HeroHealingNumText 		= {}
	self.HeroHealingSlider			= {}
	self.HeroHealingSliderText 		= {}

	self.Node[1] = self:GameObject("p_troop_player")
	self.Head[1] = self:GameObject("p_left_head")
	---@type HeroInfoItemComponent
	self.HeroComp[1] = self:LuaObject("p_left_hero")
	---@type CommonPetIconBase
	self.PetComp[1] = self:LuaObject("p_left_pet")	
	self.PetEmpty[1] = self:GameObject("p_pet_empty_l")
	self.HeroCurHp[1] = self:Slider("p_progress_power_troop")
	self.HeroOrgHp[1] = self:Image("p_progress_view_troop")
	self.HeroHpText[1] = self:Text("p_text_power_troop")
	self.HeroDamageDealtNumText[1] = self:Text("p_text_harm_num_1")
	self.HeroDamageDealtSlider[1] = self:Slider("p_progress_power_harm")
	self.HeroDamageDealtSliderText[1] = self:Text("p_text_harm_num")
	self.HeroDamageTakenNumText[1] = self:Text("p_text_injured_num_1")
	self.HeroDamageTakenSlider[1] = self:Slider("p_progress_power_injured")
	self.HeroDamageTakenSliderText[1] = self:Text("p_text_injured_num")
	self.HeroHealingNumText[1] = self:Text("p_text_treat_num_1")
	self.HeroHealingSlider[1] = self:Slider("p_progress_power_treat")
	self.HeroHealingSliderText[1] = self:Text("p_text_treat_num")

	self.Node[2] = self:GameObject("p_troop_boss")
	self.Head[2] = self:GameObject("p_right_head")
	---@type HeroInfoItemComponent
	self.HeroComp[2] = self:LuaObject("p_right_hero")
	---@type CommonMonsterIconBase
	self.MonsterComp[2] = self:LuaObject("p_right_monster")

	---@type CommonPetIconBase
	self.PetComp[2] = self:LuaObject("p_right_pet")
	self.PetEmpty[2] = self:GameObject("p_pet_empty_r")
	self.HeroCurHp[2] = self:Slider("p_progress_power_troop_r")
	self.HeroOrgHp[2] = self:Image("p_progress_view_troop_r")
	self.HeroHpText[2] = self:Text("p_text_power_troop_r")
	self.HeroDamageDealtNumText[2] = self:Text("p_text_harm_num_1_r")
	self.HeroDamageDealtSlider[2] = self:Slider("p_progress_power_harm_r")
	self.HeroDamageDealtSliderText[2] = self:Text("p_text_harm_num_r")
	self.HeroDamageTakenNumText[2] = self:Text("p_text_injured_num_1_r")
	self.HeroDamageTakenSlider[2] = self:Slider("p_progress_power_injured_r")
	self.HeroDamageTakenSliderText[2] = self:Text("p_text_injured_num_r")
	self.HeroHealingNumText[2] = self:Text("p_text_treat_num_1_r")
	self.HeroHealingSlider[2] = self:Slider("p_progress_power_treat_r")
	self.HeroHealingSliderText[2] = self:Text("p_text_treat_num_r")

end

---@param data BattleReportTeamCellData
function BattleReportTeamCell:OnFeedData(data)
	self:RefreshUI(data)
end

---@param self BattleReportTeamCell
---@param data BattleReportTeamCellData
function BattleReportTeamCell:RefreshUI(data)
	-- 统计总数值
	local attackerTotalDamageDealt, attackerTotalDamageTaken, attackerTotalHealing = MailUtils.CalculateTotalStatistics(data.record.Attacker)
	local defenderTotalDamageDealt, defenderTotalDamageTaken, defenderTotalHealing = MailUtils.CalculateTotalStatistics(data.record.Target)

	-- 进攻方
	self:RefreshHeroData(1, data.attacker,
		attackerTotalDamageDealt,
		attackerTotalDamageTaken,
		attackerTotalHealing,data.record.Attacker.BasicInfo.ObjectType == ObjectType.SlgMob)

	-- 目标
	self:RefreshHeroData(2, data.defender,
		defenderTotalDamageDealt,
		defenderTotalDamageTaken,
		defenderTotalHealing,data.record.Target.BasicInfo.ObjectType == ObjectType.SlgMob)
end

--- 刷新英雄信息
---@param self BattleReportTeamCell
---@param index number
---@param unitData MailUnitData
---@param totalDamageDealt number
---@param totalDamageTaken number
---@param totalHealing number
function BattleReportTeamCell:RefreshHeroData(index, unitData, totalDamageDealt, totalDamageTaken, totalHealing, isMob)
	if unitData == nil then
		self.Node[index]:SetActive(false)
		return
	end

	local unit = unitData.unit

	self.Node[index]:SetActive(true)

	local damageDealt = unit.OutputDamage
	local damageTaken = unit.TakeDamage
	local healing = unit.OutputHeal
	
	self.HeroComp[index]:SetVisible(false)
	if self.MonsterComp[index] then
		self.MonsterComp[index]:SetVisible(false)
	end
	self.PetComp[index]:SetVisible(false)
	self.PetEmpty[index]:SetVisible(false)

	if unitData.type == 1 then -- 英雄
		---@type wds.BattleReportHeroUnit
		local hero = unit
		local heroCfg = ConfigRefer.Heroes:Find(hero.TId)
	
		-- 头像
		local heroConfigCache = require("HeroConfigCache").New(heroCfg)
		heroConfigCache.lv = hero.Level
		heroConfigCache.star = hero.StarLevel
		heroConfigCache.heroInitParam = hero

		---@type HeroInfoData
		local heroInfoData = {
			heroData = heroConfigCache,			
			hideJobIcon = isMob,
			hideStrengthen = isMob,
			hideStyle = isMob,
		}

		--怪物和英雄头像
		if isMob then
			self.MonsterComp[index]:SetVisible(true)

			local spriteId = UIHelper.GetFitHeroHeadIcon(self.MonsterComp[index].p_img_hero, heroInfoData.heroData.resCell)
			local frameId = HeroUIUtilities.GetMonsterCardQualitySpriteID(heroInfoData.heroData.configCell:Quality())
			local sprite = ArtResourceUtils.GetUIItem(spriteId)
			local frame = ArtResourceUtils.GetUIItem(frameId)
			self.MonsterComp[index]:FeedData({sprite = sprite, level = heroInfoData.heroData.heroInitParam.Level, frame = frame})
		else
			self.HeroComp[index]:SetVisible(true)
			self.HeroComp[index]:FeedData(heroInfoData)
		end
	elseif unitData.type == 2 then -- 宠物
		self.PetComp[index]:SetVisible(true)
		
		---@type wds.BattleReportPetUnit
		local pet = unit

		---@type UIPetCircleData
		local petData = {}
		petData.cfgId = pet.TId
		petData.level = pet.Level
		petData.rank = pet.RankLevel
		self.PetComp[index]:FeedData(petData)
	end

	-- HP
	self.HeroCurHp[index].value = math.clamp01(unit.CurHp / unit.MaxHp)
	self.HeroOrgHp[index].fillAmount = math.clamp01(unit.OriHp / unit.MaxHp)
	self.HeroHpText[index].text = unit.CurHp
	UIHelper.SetGray(self.Head[index], self.HeroCurHp[index].value <= 0)

	-- 图表
	local damageDealtRatio = math.clamp01(damageDealt / totalDamageDealt)
	self.HeroDamageDealtSlider[index].value = damageDealtRatio
	self.HeroDamageDealtSliderText[index].text = string.format("%.0f%%", damageDealtRatio * 100)
	self.HeroDamageDealtNumText[index].text = tostring(damageDealt)

	local damageTakenRatio = math.clamp01(damageTaken / totalDamageTaken)
	self.HeroDamageTakenSlider[index].value = damageTakenRatio
	self.HeroDamageTakenSliderText[index].text = string.format("%.0f%%", damageTakenRatio * 100)
	self.HeroDamageTakenNumText[index].text = tostring(damageTaken)

	local healingRatio = math.clamp01(healing / totalHealing)
	self.HeroHealingSlider[index].value = healingRatio
	self.HeroHealingSliderText[index].text = string.format("%.0f%%", healingRatio * 100)
	self.HeroHealingNumText[index].text = tostring(healing)
end

return BattleReportTeamCell;
