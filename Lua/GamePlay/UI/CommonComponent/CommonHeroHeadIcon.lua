local BaseUIComponent = require ('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")
local HeroQuality = require("HeroQuality")
local UIHelper = require("UIHelper")
local HeroUIUtilities = require('HeroUIUtilities')

---@class CommonHeroHeadIcon : BaseUIComponent
---@field super BaseUIComponent
local CommonHeroHeadIcon = class('CommonHeroHeadIcon', BaseUIComponent)

function CommonHeroHeadIcon:OnCreate()
    self.imgHero = self:Image("p_img_hero")
    self.imgMonster = self:Image("p_img_monster")
	self.imgFrame = self:Image("p_base_kill")
end

function CommonHeroHeadIcon:OnFeedData(heroConfigId)
    self:ShowHeroIcon(heroConfigId)
end

function CommonHeroHeadIcon:ShowHeroIcon(heroConfigId)
    self.imgHero:SetVisible(true)
    self.imgMonster:SetVisible(false)
    local config = ConfigRefer.Heroes:Find(heroConfigId)
    local heroIcon = UIHelper.GetFitHeroHeadIcon(self.imgHero, ConfigRefer.HeroClientRes:Find(config:ClientResCfg()))
    self:LoadSprite(heroIcon, self.imgHero)
	g_Game.SpriteManager:LoadSprite("sp_se_hero_0" .. (config:Quality() + 1), self.imgFrame)
end

function CommonHeroHeadIcon:ShowMonsterIcon(heroConfigId)
    self.imgHero:SetVisible(false)
    self.imgMonster:SetVisible(true)
    local config = ConfigRefer.Heroes:Find(heroConfigId)
    local heroIcon = UIHelper.GetFitHeroHeadIcon(self.imgMonster, ConfigRefer.HeroClientRes:Find(config:ClientResCfg()))
    self:LoadSprite(heroIcon, self.imgMonster)
end

function CommonHeroHeadIcon:ShowCustomIcon(customIcon)
    self.imgHero:SetVisible(true)
    self.imgMonster:SetVisible(false)
    self.imgFrame:SetVisible(false)
    g_Game.SpriteManager:LoadSprite(customIcon, self.imgHero)
end

return CommonHeroHeadIcon
