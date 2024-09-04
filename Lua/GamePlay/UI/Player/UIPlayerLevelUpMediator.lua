local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class UIPlayerLevelUpMediator : BaseUIMediator
local UIPlayerLevelUpMediator = class('UIPlayerLevelUpMediator', BaseUIMediator)

function UIPlayerLevelUpMediator:ctor()

end

function UIPlayerLevelUpMediator:OnCreate()
    self:InitObjects()
end

function UIPlayerLevelUpMediator:InitObjects()
	self.hintText = self:Text("p_text_hint", "playerinfo_touchtocontinue")
	self.portrait = self:Image("p_img_head")
	self.levelUpLabel = self:Text("p_text_lvup", "playerinfo_levelup")
	self.levelText = self:Text("p_text_lv")
	self.rewardLabel = self:Text("p_text_reward", "playerinfo_levelreward")
	self.rewardText = {}
	self.rewardText[1] = self:Text("p_text_1")
	self.rewardText[2] = self:Text("p_text_2")
	self.rewardText[3] = self:Text("p_text_3")
	self.rewardText[1].gameObject:SetActive(false)
	self.rewardText[2].gameObject:SetActive(false)
	self.rewardText[3].gameObject:SetActive(false)
	self.rewardBase = {}
	self.rewardBase[1] = self:GameObject("base_1")
	self.rewardBase[2] = self:GameObject("base_2")
	self.rewardBase[3] = self:GameObject("base_3")
end

function UIPlayerLevelUpMediator:OnShow(param)
    self:RefreshUI()
end

function UIPlayerLevelUpMediator:OnHide(param)

end

function UIPlayerLevelUpMediator:OnOpened(param)
end

function UIPlayerLevelUpMediator:OnClose(param)
	
end

function UIPlayerLevelUpMediator:RefreshUI()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	self.levelText.text = tostring(player.Basics.CommanderLevel)
	g_Game.SpriteManager:LoadSprite(ModuleRefer.PlayerModule:GetSelfPortraitSpriteName(), self.portrait)
	local cfg = ConfigRefer.CommanderLevel:Find(player.Basics.CommanderLevel)
	local length = 0
	if (cfg and cfg:LevelUpRewardTextLength() > 0) then
		length = cfg:LevelUpRewardTextLength()
	end
	for i = 1, 3 do
		if (i > length) then
			self.rewardText[i].gameObject:SetActive(false)
			self.rewardBase[i]:SetActive(false)
		else
			self.rewardText[i].gameObject:SetActive(true)
			self.rewardBase[i]:SetActive(true)
			self.rewardText[i].text = I18N.Get(cfg:LevelUpRewardText(i))
		end
	end
end

return UIPlayerLevelUpMediator
