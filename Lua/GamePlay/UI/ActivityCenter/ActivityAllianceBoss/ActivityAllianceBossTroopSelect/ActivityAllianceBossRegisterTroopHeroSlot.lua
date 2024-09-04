local BaseUIComponent = require("BaseUIComponent")
local HeroUIUtilities = require("HeroUIUtilities")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ModuleRefer = require("ModuleRefer")
---@class ActivityAllianceBossRegisterTroopHeroSlot : BaseUIComponent
local ActivityAllianceBossRegisterTroopHeroSlot = class("ActivityAllianceBossRegisterTroopHeroSlot", BaseUIComponent)

function ActivityAllianceBossRegisterTroopHeroSlot:OnCreate()
    self.imgFrame = self:Image("p_base_frame")
    self.imgHero = self:Image("p_img_hero")
    self.goLv = self:GameObject("p_icon_lv")
    self.textLv = self:Text("p_text_lv")
    self.imgIconStrength = self:Image("p_icon_strengthen")
    self.goPet = self:GameObject("p_pet")
    self.imgBasePet = self:Image("p_base_pet")
    self.imgPet = self:Image("p_img_pet")
    self.goStyle = self:GameObject("p_icon_style")
    self.goJob = self:GameObject("p_base_job")
end

function ActivityAllianceBossRegisterTroopHeroSlot:OnShow()
    self.goStyle:SetActive(false)
    self.goJob:SetActive(false)
end

---@param param wds.HeroInitParam
function ActivityAllianceBossRegisterTroopHeroSlot:OnFeedData(param)
    self.data = param
    self.heroCfg = ConfigRefer.Heroes:Find(param.ConfigId)
    self.petCfg = ConfigRefer.Pet:Find((param.PetInfos[0] or {}).ConfigId)
    self:InitHeroInfo()
    self:InitPetInfo()
end

function ActivityAllianceBossRegisterTroopHeroSlot:InitHeroInfo()
    local heroQuality = self.heroCfg:Quality()
    local frameSpriteID = HeroUIUtilities.GetQualitySpriteID(heroQuality)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(frameSpriteID), self.imgFrame)

    local heroClientResCfg = ConfigRefer.HeroClientRes:Find(self.heroCfg:ClientResCfg())
    local heroIcon = heroClientResCfg:HeadMini()
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(heroIcon), self.imgHero)

    self.textLv.text = self.data.Level
    if self.data.StarLevel and self.data.StarLevel > 0 then
        self.imgIconStrength.gameObject:SetActive(true)
        ModuleRefer.HeroModule:LoadHeroStarLevelImage(self.data.StarLevel, self.imgIconStrength)
    else
        self.imgIconStrength.gameObject:SetActive(false)
    end
end

function ActivityAllianceBossRegisterTroopHeroSlot:InitPetInfo()
    if self.petCfg then
        self.goPet:SetActive(true)
        local petIcon = self.petCfg:Icon()
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(petIcon), self.imgPet)
        local petQuality = self.petCfg:Quality()
        local frameSpriteID = HeroUIUtilities.GetQualityFrontSpriteID(petQuality)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(frameSpriteID), self.imgBasePet)
    else
        self.goPet:SetActive(false)
    end
end

return ActivityAllianceBossRegisterTroopHeroSlot