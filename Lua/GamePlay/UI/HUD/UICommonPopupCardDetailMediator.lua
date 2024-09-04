local BaseUIMediator = require ('BaseUIMediator')

---@class UICommonPopupCardDetailMediator : BaseUIMediator
local UICommonPopupCardDetailMediator = class('UICommonPopupCardDetailMediator', BaseUIMediator)

---@class UICommonPopupCardDetailParam
---@field type number @1:SE卡牌, 2:SLG技能, 3:SOC技能
---@field cfgId number @卡牌/技能ID
---@field level number @技能等级
---@field useSkillId boolean @SE卡牌是否直接使用技能ID
---@field isMirrorCard boolean @SE卡牌是否为镜像卡
---@field isNormalAttack boolean @SE卡牌是否为普攻
---@field slgSkillId number
---@field cardId number
---@field skillLevel number
---@field slgSkillCell any
---@field isLock boolean
---@field unloadFunc fun()
---@field offset CS.UnityEngine.Vector2

local TYPE_SE = 1
local TYPE_SLG = 2
local TYPE_SOC = 3
local TYPE_NEW = 4
local TYPE_PET = 5
local TYPE_PET_DROP = 6

function UICommonPopupCardDetailMediator:ctor()
	---@type UICommonPopupCardDetailParam
	self._param = nil
end

function UICommonPopupCardDetailMediator:OnCreate()
	self._root = self:RectTransform("")
	---@type SEHudTipsSkillCard
	self._card = self:LuaObject("child_tips_skill_card")
end

function UICommonPopupCardDetailMediator:OnShow(param)
	if (not param) then
		self:CloseSelf()
		return
	end
	self._param = param
	if (self._param.type == TYPE_SE) then
		self._card:ShowSECardTips(self._param.cfgId, self._param.isMirrorCard, self._param.unitManager, self._param.useSkillId, self._param.isNormalAttack, self._param.level)
	elseif (self._param.type == TYPE_SLG) then
		self._card:ShowSlgSkillTips(self._param.cfgId, self._param.level, self._param.isPetFix)
	elseif (self._param.type == TYPE_NEW) then
		self._card:ShowHeroSkillTips(self._param.slgSkillId, self._param.cardId, self._param.isLock, self._param.skillLevel, self._param.slgSkillCell)
	elseif (self._param.type == TYPE_PET) then
		self._card:ShowPetSkillTips(self._param.slgSkillId, self._param.cardId, self._param.isLock, self._param.skillLevel, self._param.slgSkillCell,self._param.unloadFunc)
	elseif (self._param.type == TYPE_PET_DROP) then
		self._card:ShowPetDropSkillTips(self._param)
	else
		self._card:ShowSocSkillTips(self._param.cfgId, self._param.level)
	end
	if (self._param.offset) then
		self._root.anchoredPosition = self._root.anchoredPosition + self._param.offset
	end
end

function UICommonPopupCardDetailMediator:OnHide(param)
end

function UICommonPopupCardDetailMediator:OnOpened(param)
end

function UICommonPopupCardDetailMediator:OnClose(param)

end



return UICommonPopupCardDetailMediator
