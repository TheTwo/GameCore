local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local HeroUIUtilities = require('HeroUIUtilities')
local UIHelper = require('UIHelper')
local ModuleRefer = require('ModuleRefer')
local FunctionClass = require('FunctionClass')
local HeroType = require('HeroType')
local UIMediatorNames = require('UIMediatorNames')
local NoviceConst = require('NoviceConst')
---@class NoviceTVPage : BaseUIComponent
local NoviceTVPage = class('NoviceTVPage', BaseUIComponent)

local HINT_I18N_KEYS = {
    [false] = NoviceConst.I18NKeys.REWARD_UNCLAIM,
    [true] = NoviceConst.I18NKeys.REWARD_CLAIMED,
}

function NoviceTVPage:OnCreate()
    self.imgItem = self:Image('p_img_hero')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.textDetail = self:Text('p_text_detail', I18N.Get(NoviceConst.I18NKeys.BTN_DETAIL))
    self.textHint = self:Text('p_text_hint')
    self.textLeftTime = self:Text('p_text_time_2')
    self.textQuality = self:Text('p_text_quality_hero')
    self.textName = self:Text('p_text_hero_name')
end

function NoviceTVPage:OnFeedData(param)
    if not param then
        return
    end
    self:InitInfo(param)
end

function NoviceTVPage:InitInfo(param)
    local spItemCfg = ModuleRefer.NoviceModule:GetSpeicalRewardConfig(param.spIndex)
    local score = param.score
    self.spType = spItemCfg:FunctionClass()
    local isClaimed = ModuleRefer.NoviceModule:IsRewardOpened(param.spIndex)
    self.textHint.text = I18N.GetWithParams(HINT_I18N_KEYS[isClaimed], tostring(score))
    if self.spType == FunctionClass.AddHero then
        self.heroId = tonumber(spItemCfg:UseParam(1))
        self:InitHeroInfo(self.heroId)
    elseif self.spType == FunctionClass.AddPet then
        self.petId = tonumber(spItemCfg:UseParam(1))
        self:InitPetInfo(self.petId)
    else
        self:InitItemInfo(spItemCfg)
    end
end

function NoviceTVPage:InitHeroInfo(heroId)
    self.btnDetail.gameObject:SetActive(ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NoviceConst.HERO_SYSTEM_ID))
    local heroCfg = ConfigRefer.Heroes:Find(heroId)
    local index = heroCfg:Quality() + 1
    local heroResId = heroCfg:ClientResCfg()
    self.heroResCfg = ConfigRefer.HeroClientRes:Find(heroResId)
    local heroBodyPaintId = self.heroResCfg:HeadMini()
    local heroBodyPaint = ConfigRefer.ArtResourceUI:Find(heroBodyPaintId):Path()
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    g_Game.SpriteManager:LoadSprite(heroBodyPaint, self.imgItem)
    self.textName.text = I18N.Get(heroCfg:Name())
end

function NoviceTVPage:InitPetInfo(petId)
    self.btnDetail.gameObject:SetActive(ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NoviceConst.PET_SYSTEM_ID))
    local petCfg = ConfigRefer.Pet:Find(petId)
    local index = petCfg:Quality()
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index))
    self:LoadSprite(petCfg:ShowPortrait(), self.imgItem)
    self.textName.text = I18N.Get(petCfg:Name())
end

function NoviceTVPage:InitItemInfo(cfg)
    self.btnDetail.gameObject:SetActive(false)
    self.textDetail.gameObject:SetActive(false)
    self.textName.text = I18N.Get(cfg:NameKey())
    local index = cfg:Quality() - 1
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgItem)
end

function NoviceTVPage:OnBtnDetailClicked(args)
    if self.spType == FunctionClass.AddHero then
        ModuleRefer.HeroModule:SetHeroSelectType(HeroType.Heros)
        if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NoviceConst.HERO_SYSTEM_ID) then
            g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator, {id = self.heroId})
        end
    elseif self.spType == FunctionClass.AddPet then
        if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NoviceConst.PET_SYSTEM_ID) then
            ModuleRefer.PetModule:ShowPetPreview(self.petId, "sss")
        end
    end
end

return NoviceTVPage
