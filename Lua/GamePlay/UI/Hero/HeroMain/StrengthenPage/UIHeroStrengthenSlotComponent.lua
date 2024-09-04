local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')

---@class UIHeroStrengthenSlotComponent : BaseUIComponent
---@field strengthConfig HeroStrengthenConfigCell
local UIHeroStrengthenSlotComponent = class('UIHeroStrengthenSlotComponent', BaseUIComponent)

function UIHeroStrengthenSlotComponent:ctor()
    self.module = ModuleRefer.HeroModule
end

function UIHeroStrengthenSlotComponent:OnCreate()
    self.goBefore = self:GameObject('p_before')
    self.imgIconLvBefore = self:Image('p_icon_lv_before')
    self.imgIconLvBefore1 = self:Image('p_icon_lv_before_1')
    self.goIconSatr1 = self:GameObject('p_icon_satr_1')
    self.goIconSatr2 = self:GameObject('p_icon_satr_2')
    self.goIconSatr3 = self:GameObject('p_icon_satr_3')
    self.goIconSatr4 = self:GameObject('p_icon_satr_4')
    self.goIconSatr5 = self:GameObject('p_icon_satr_5')
    self.goIconSatr6 = self:GameObject('p_icon_satr_6')

    self.imgIconSatr1 = self:Image('p_icon_satr_1')
    self.imgIconSatr2 = self:Image('p_icon_satr_2')
    self.imgIconSatr3 = self:Image('p_icon_satr_3')
    self.imgIconSatr4 = self:Image('p_icon_satr_4')
    self.imgIconSatr5 = self:Image('p_icon_satr_5')
    self.imgIconSatr6 = self:Image('p_icon_satr_6')

    self.textLvBefore = self:Text('p_text_lv_before')
    self.imgIconLvAfter = self:Image('p_icon_lv_after')
    self.goIconSatr7 = self:GameObject('p_icon_satr_7')
    self.goIconSatr8 = self:GameObject('p_icon_satr_8')
    self.goIconSatr9 = self:GameObject('p_icon_satr_9')
    self.goIconSatr10 = self:GameObject('p_icon_satr_10')
    self.goIconSatr11 = self:GameObject('p_icon_satr_11')
    self.goIconSatr12 = self:GameObject('p_icon_satr_12')

    self.imgIconSatr7 = self:Image('p_icon_satr_7')
    self.imgIconSatr8 = self:Image('p_icon_satr_8')
    self.imgIconSatr9 = self:Image('p_icon_satr_9')
    self.imgIconSatr10 = self:Image('p_icon_satr_10')
    self.imgIconSatr11 = self:Image('p_icon_satr_11')
    self.imgIconSatr12 = self:Image('p_icon_satr_12')

    self.textLvAfter = self:Text('p_text_lv_after')
    self.animtriggerTriggerStar1 = self:AnimTrigger('trigger_star_up1')
    self.animtriggerTriggerStar2 = self:AnimTrigger('trigger_star_up2')
    self.animtriggerTriggerStar3 = self:AnimTrigger('trigger_star_up3')
    self.animtriggerTriggerStar4 = self:AnimTrigger('trigger_star_up4')
    self.animtriggerTriggerStar5 = self:AnimTrigger('trigger_star_up5')
    self.animtriggerTriggerStar6 = self:AnimTrigger('trigger_star_up5')
    self.goStarGlow1 = self:GameObject('p_star_glow1')
    self.goStarGlow2 = self:GameObject('p_star_glow2')
    self.goStarGlow3 = self:GameObject('p_star_glow3')
    self.goStarGlow4 = self:GameObject('p_star_glow4')
    self.goStarGlow5 = self:GameObject('p_star_glow5')
    self.goStarGlow6 = self:GameObject('p_star_glow6')
    self.animtriggerStartGlow1 = self:AnimTrigger('p_star_glow1')
    self.animtriggerStartGlow2 = self:AnimTrigger('p_star_glow2')
    self.animtriggerStartGlow3 = self:AnimTrigger('p_star_glow3')
    self.animtriggerStartGlow4 = self:AnimTrigger('p_star_glow4')
    self.animtriggerStartGlow5 = self:AnimTrigger('p_star_glow5')
    self.animtriggerStartGlow6 = self:AnimTrigger('p_star_glow6')
    self.animtriggerTriggerAfter1 = self:AnimTrigger('trigger_after')
    self.animtriggerTriggerAfter2 = self:AnimTrigger('trigger_after1')
    self.animtriggerTriggerAfter3 = self:AnimTrigger('trigger_after2')
    self.animtriggerTriggerAfter4 = self:AnimTrigger('trigger_after3')
    self.animtriggerTriggerAfter5 = self:AnimTrigger('trigger_after4')
    self.animtriggerTriggerAfter6 = self:AnimTrigger('trigger_after5')


    self.beforeIcons = {self.goIconSatr1, self.goIconSatr2, self.goIconSatr3, self.goIconSatr4, self.goIconSatr5, self.goIconSatr6}
    self.afterIcons = {self.goIconSatr7, self.goIconSatr8, self.goIconSatr9, self.goIconSatr10, self.goIconSatr11, self.goIconSatr12}
    self.starGlows = {self.goStarGlow1, self.goStarGlow2, self.goStarGlow3, self.goStarGlow4, self.goStarGlow5, self.goStarGlow6}
    self.animTrigger = {self.animtriggerTriggerStar1, self.animtriggerTriggerStar2, self.animtriggerTriggerStar3, self.animtriggerTriggerStar4, self.animtriggerTriggerStar5, self.animtriggerTriggerStar6}
    self.animTriggerAfter = {self.animtriggerTriggerAfter1, self.animtriggerTriggerAfter2, self.animtriggerTriggerAfter3, self.animtriggerTriggerAfter4, self.animtriggerTriggerAfter5, self.animtriggerTriggerAfter6}
    self.animTriggerGlow = {self.animtriggerStartGlow1, self.animtriggerStartGlow2, self.animtriggerStartGlow3, self.animtriggerStartGlow4, self.animtriggerStartGlow5, self.animtriggerStartGlow6}

    self.beforeIconImages = {self.imgIconSatr1, self.imgIconSatr2, self.imgIconSatr3, self.imgIconSatr4, self.imgIconSatr5, self.imgIconSatr6}
    self.afterIconImages = {self.imgIconSatr7, self.imgIconSatr8, self.imgIconSatr9, self.imgIconSatr10, self.imgIconSatr11, self.imgIconSatr12}
end

function UIHeroStrengthenSlotComponent:OnFeedData(param)
    for _, trigger in ipairs(self.animTrigger) do
        trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    local strengthConfig = param.strengthConfig
    local strengthLv = param.strengthLv
    self.animationTrigger = param.animationTrigger
    self.needPlayNPropEffect = param.needPlayNPropEffect
    local maxLevel = strengthConfig:StrengthenInfoListLength()
    local isMax = strengthLv >= maxLevel
    local stageLevel = math.floor(strengthLv / ModuleRefer.HeroModule.STRENGTH_COUNT)
    local showIndex = strengthLv % ModuleRefer.HeroModule.STRENGTH_COUNT
    local curIndex = showIndex
    if strengthLv == 0 or showIndex ~= 0 then
        stageLevel = stageLevel + 1
        -- for index, icon in ipairs(self.beforeIcons) do
        --     icon:SetActive(index <= showIndex)
        --     icon.transform.localScale = CS.UnityEngine.Vector3.one
        --     if index == showIndex and self.needPlayNPropEffect then
        --         -- self.animTrigger[index]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
        --         --     self.animTrigger[index]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        --         --     icon.transform.localScale = CS.UnityEngine.Vector3.one
        --         --     icon:SetActive(true)
        --         -- end)
        --         icon.transform.localScale = CS.UnityEngine.Vector3.one
        --         icon:SetActive(true)
        --     end
        -- end


        for index, icon in ipairs(self.beforeIconImages) do
            g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel .. "_star", icon)
            icon.transform.localScale = CS.UnityEngine.Vector3.one
            icon.gameObject:SetActive(index <= showIndex)
            if index == showIndex and self.needPlayNPropEffect then
                self.animTrigger[index]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
                    self.animTrigger[index]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
                    icon.transform.localScale = CS.UnityEngine.Vector3.one
                    icon.gameObject:SetActive(true)
                end)
            end
        end
    else
        curIndex = ModuleRefer.HeroModule.STRENGTH_COUNT

        for index, icon in ipairs(self.beforeIconImages) do
            g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel .. "_star", icon)
            icon.transform.localScale = CS.UnityEngine.Vector3.one
            icon.gameObject:SetActive(true)
            if curIndex == index and self.needPlayNPropEffect then
                self.animTrigger[index]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
                    self.animTrigger[index]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
                    icon.transform.localScale = CS.UnityEngine.Vector3.one
                    icon.gameObject:SetActive(true)
                end)
            end
        end

        -- for index, icon in ipairs(self.beforeIcons) do
        --     icon:SetActive(true)
        --     icon.transform.localScale = CS.UnityEngine.Vector3.one
        --     if curIndex == index and self.needPlayNPropEffect then
        --         -- self.animTrigger[index]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
        --         --     self.animTrigger[index]:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        --         --     icon.transform.localScale = CS.UnityEngine.Vector3.one
        --         --     icon:SetActive(true)
        --         -- end)
        --         icon.transform.localScale = CS.UnityEngine.Vector3.one
        --         icon:SetActive(true)
        --     end
        -- end
    end
    local scfg = ConfigRefer.HeroStrengthenLvInfo:Find(stageLevel)
    self.textLvBefore.text = I18N.GetWithParams(scfg:Name(), curIndex)
    if isMax then
        self.goBefore:SetActive(false)
        -- for _, icon in ipairs(self.afterIcons) do
        --     icon:SetActive(true)
        -- end

        for _, icon in ipairs(self.afterIconImages) do
            g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel .. "_star", icon)
            icon.gameObject:SetActive(true)
        end

        for _, glow in ipairs(self.starGlows) do
            glow:SetActive(false)
        end
        self:LoadSprite(scfg:Icon(), self.imgIconLvAfter)
        self.textLvAfter.text = I18N.GetWithParams(scfg:Name(), ModuleRefer.HeroModule.STRENGTH_COUNT)
        return
    end
    self.goBefore:SetActive(true)
    local nextStageLevel = stageLevel
    if strengthLv ~= 0 and showIndex == 0 then
        nextStageLevel = nextStageLevel + 1
        local nscfg = ConfigRefer.HeroStrengthenLvInfo:Find(nextStageLevel)
        self:LoadSprite(nscfg:Icon(), self.imgIconLvAfter)
        -- for index, icon in ipairs(self.afterIcons) do
        --     icon:SetActive(index == 1)
        -- end

        for index, icon in ipairs(self.afterIconImages) do
            g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. nextStageLevel .. "_star", icon)
            icon.gameObject:SetActive(index == 1)
        end

        for _, glow in ipairs(self.starGlows) do
            glow:SetActive(false)
        end
        self.textLvAfter.text = I18N.GetWithParams(nscfg:Name(), 1)
    else
        local nextIndex = showIndex + 1
        -- for index, icon in ipairs(self.afterIcons) do
        --     icon:SetActive(index <= nextIndex)
        -- end

        for index, icon in ipairs(self.afterIconImages) do
            g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. nextStageLevel .. "_star", icon)
            icon.gameObject:SetActive(index <= nextIndex)
        end

        for index, glow in ipairs(self.starGlows) do
            glow:SetActive(index == nextIndex)
            if index == nextIndex then
                self.animTriggerGlow[index]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            else
                self.animTriggerAfter[index]:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
        end
        self:LoadSprite(scfg:Icon(), self.imgIconLvAfter)
        self.textLvAfter.text = I18N.GetWithParams(scfg:Name(), nextIndex)
    end
    self:LoadSprite(scfg:Icon(), self.imgIconLvBefore1)
    if stageLevel > 1 and nextStageLevel == stageLevel and showIndex == 1 and self.needPlayNPropEffect then
        local lastCfg = ConfigRefer.HeroStrengthenLvInfo:Find(stageLevel - 1)
        if lastCfg then
            self:LoadSprite(lastCfg:Icon(), self.imgIconLvBefore)
            for _, icon in ipairs(self.beforeIconImages) do
                g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel - 1 .. "_star", icon)
            end
        end
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
            self:LoadSprite(scfg:Icon(), self.imgIconLvBefore)
            --self.animationTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
            for _, icon in ipairs(self.beforeIconImages) do
                g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel .. "_star", icon)
            end
        end)
    else
        self:LoadSprite(scfg:Icon(), self.imgIconLvBefore)
    end
end

return UIHeroStrengthenSlotComponent
