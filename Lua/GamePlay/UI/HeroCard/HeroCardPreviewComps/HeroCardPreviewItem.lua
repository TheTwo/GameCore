local BaseUIComponent = require ('BaseUIComponent')
local HeroUIUtilities = require('HeroUIUtilities')
local I18N = require('I18N')
local HeroQuality = require('HeroQuality')
local FunctionClass = require('FunctionClass')
local UIMediatorNames = require('UIMediatorNames')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local QualityColorHelper = require('QualityColorHelper')
---@class HeroCardPreviewItem : BaseUIComponent
local HeroCardPreviewItem = class('HeroCardPreviewItem', BaseUIComponent)

function HeroCardPreviewItem:ctor()
    self.heroId = nil
    self.petCfg = nil
end

function HeroCardPreviewItem:OnCreate()
	self.btnChildHeroCard01 = self:Button('', Delegate.GetOrCreate(self, self.OnBtnChildHeroCard01Clicked))
    self.goBaseFrameUp = self:GameObject('p_base_frame_up')
    self.imgBaseFrameS = self:Image('p_base_frame_s')
    self.imgBaseFrame = self:Image('p_base_frame')
    self.imgImgPet = self:Image('p_img_pet')
    self.goMaskPet = self:GameObject('p_mask_pet')
    self.goMaskHero = self:GameObject('p_mask_hero')
    self.goVxMask = self:GameObject('vx_img_hero_black')
    self.imgImgHero = self:Image('p_img_hero')
    self.compChildReddotDefault = self:LuaObject('child_reddot_default')
    self.goConverted = self:GameObject('p_converted')
    self.textConverted = self:Text('p_text_converted', I18N.Get("gacha_result_trans_short"))
    self.animtriggerTrigger = self:AnimTrigger('Trigger')
    self.textNum = self:Text('p_text_num')
end

function HeroCardPreviewItem:OnFeedData(param)
    self.param = param
    self.compChildReddotDefault:SetVisible(param.new)
    local itemId = param.itemId
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        self.goMaskPet:SetActive(false)
        self.goMaskHero:SetActive(true)
        self.heroId = tonumber(itemCfg:UseParam(1))
        local heroCfg = ConfigRefer.Heroes:Find(self.heroId)
        if heroCfg then
            self.imgImgPet.gameObject:SetActive(false)
            self.imgImgHero.gameObject:SetActive(true)
            local isShowUp = heroCfg:Quality() >= HeroQuality.Golden
            self.goBaseFrameUp:SetActive(isShowUp)
            self:LoadSprite(HeroUIUtilities.GetQualityFrontSpriteID(heroCfg:Quality()), self.imgBaseFrameS)
            self:LoadSprite(HeroUIUtilities.GetQualitySpriteID(heroCfg:Quality()), self.imgBaseFrame)
            local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
            local headIcon = UIHelper.GetFitHeroHeadIcon(self.imgImgHero, resCell)
            self:LoadSprite(headIcon,self.imgImgHero)
            self.goConverted:SetActive(param.transItemCount and param.transItemCount > 0)
            if heroCfg:Quality() == HeroQuality.Golden then
                self.animtriggerTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
            elseif heroCfg:Quality() == HeroQuality.Purple then
                self.animtriggerTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
            end
            self.textNum.gameObject:SetActive(false)
        end
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        self.goMaskPet:SetActive(true)
        self.goMaskHero:SetActive(false)
        local petId = tonumber(itemCfg:UseParam(1))
        self.petCfg = ConfigRefer.Pet:Find(petId)
        self.imgImgPet.gameObject:SetActive(true)
        self.imgImgHero.gameObject:SetActive(false)
        local petQuality = self.petCfg:Quality()
        local isShowUp = petQuality >= 4
        self.goBaseFrameUp:SetActive(isShowUp)
        self:LoadSprite(HeroUIUtilities.GetQualityFrontSpriteID(petQuality - 1), self.imgBaseFrameS)
        self:LoadSprite(HeroUIUtilities.GetQualitySpriteID(petQuality - 1), self.imgBaseFrame)
        self:LoadSprite(self.petCfg:ShowPortrait(),self.imgImgPet)
        self.goConverted:SetActive(false)
        if petQuality == 4 then
            self.animtriggerTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
        elseif petQuality == 3 then
            self.animtriggerTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        end
        self.textNum.gameObject:SetActive(false)
    else
        self.goMaskPet:SetActive(false)
        self.goMaskHero:SetActive(true)
        self.goConverted:SetActive(false)
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgImgHero)
        self.imgImgHero.gameObject.transform.localScale = CS.UnityEngine.Vector3.one * 0.7
        self.imgImgHero.gameObject.transform.localPosition = CS.UnityEngine.Vector3(0, -32, 0)
        self.goVxMask.transform.localScale = CS.UnityEngine.Vector3.one * 0.7
        self.goVxMask.transform.localPosition = CS.UnityEngine.Vector3(0, -32, 0)
        g_Game.SpriteManager:LoadSprite(QualityColorHelper.GetQualityCircleBaseIcon(itemCfg:Quality(), QualityColorHelper.Type.Item, QualityColorHelper.Type.Hero), self.imgBaseFrameS)
        g_Game.SpriteManager:LoadSprite(QualityColorHelper.GetQualityCircleBaseIcon(itemCfg:Quality(), QualityColorHelper.Type.Item, QualityColorHelper.Type.Hero), self.imgBaseFrame)
        self.textNum.gameObject:SetActive(true)
        self.textNum.text = ("x%d"):format(param.itemCount)
    end
end

function HeroCardPreviewItem:OnBtnChildHeroCard01Clicked(args)
    if self.heroId then
        g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = self.heroId, transItemId = self.param.transItemId, transItemCount = self.param.transItemCount})
    elseif self.petCfg then
        g_Game.UIManager:Open(UIMediatorNames.SEPetSettlementMediator, {petCompId = self.param.CompId})
    end
end

return HeroCardPreviewItem
