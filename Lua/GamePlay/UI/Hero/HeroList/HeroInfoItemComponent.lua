local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local HeroUIUtilities = require('HeroUIUtilities')
local I18N = require('I18N')
local UIHelper = require("UIHelper")
local HeroModule = require("ModuleRefer").HeroModule
local Utils = require('Utils')
local ColorConsts = require('ColorConsts')
---@class HeroInfoData
---@field heroData HeroConfigCache
---@field onClick fun()
---@field onPressDown fun()
---@field onPressUp fun()
---@field hideExtraInfo boolean
---@field hideJobIcon boolean
---@field hideLv boolean
---@field hideStrengthen boolean
---@field hideStyle boolean
---@field hideName boolean
---@field showInjured boolean
---@field showLevelPrefix boolean

---@class HeroInfoItemComponent : BaseUIComponent
---@field data HeroConfigCache
---@field onClick fun()
local HeroInfoItemComponent = class('HeroInfoItemComponent', BaseUIComponent)

function HeroInfoItemComponent:ctor()

end

function HeroInfoItemComponent:OnCreate()

    self.btnChildCardHeroM = self:Button('', Delegate.GetOrCreate(self, self.OnBtnChildCardHeroMClicked));
    self.imgBaseFrame = self:Image('p_base_frame');
    self.imgBaseFrame01 = self:Image('p_base_frame_01');
    self.goSelect = self:GameObject("p_img_select")
    self.imgImgHero = self:Image('p_img_hero');
    self.goIconLv = self:GameObject('p_icon_lv');
    self.textLv = self:Text('p_text_lv');
    self.goBaseJob = self:GameObject('p_base_job');
    self.imgIconJob = self:Image('p_icon_job');
    ------------------------------------------------------------------
    self.textName = self:Text('p_text_name');
    self.goBaseN = self:GameObject('p_base_n');
    self.goBaseLock = self:GameObject('p_base_lock');
    self.goIconStrong = self:GameObject('p_icon_strong');
    self.compIconStrong = self:LuaObject('p_icon_strong');
    self.goIconTroop = self:GameObject('p_icon_troop')
    -- self.textStrong = self:Text('p_text_strong')
    self.escrowRoot = self:GameObject('p_escrow_root')
    self.escrowIcon = self:Image('p_escrow_icon')
    self.goBaseInjured = self:GameObject('p_base_injuried')
    ---@type UIHeroAssociateIconComponent
    self.compStyle = self:LuaObject('p_icon_style')
    -- self.imgIconLv = self:Image('p_icon_lv')

    if Utils.IsNotNull(self.escrowRoot) then
        self.escrowRoot:SetVisible(false)
    end
    if Utils.IsNotNull(self.goBaseInjured) then
        self.goBaseInjured:SetVisible(false)
    end
end


function HeroInfoItemComponent:OnShow(param)
end

function HeroInfoItemComponent:OnOpened(param)
end

function HeroInfoItemComponent:OnClose(param)

end

function HeroInfoItemComponent:ChangeStateSelect(isShow)
    if Utils.IsNotNull(self.goSelect) then
        self.goSelect:SetActive(isShow)
    end
end

function HeroInfoItemComponent:TroopIconVisible(visible)
    if Utils.IsNotNull(self.goIconTroop) then
        self.goIconTroop:SetVisible(visible)
    end
end

function HeroInfoItemComponent:SetupIcons()
    if self.data and self.data.configCell then
        self:LoadSprite(HeroUIUtilities.GetCardQualitySpriteID(self.data.configCell:Quality()), self.imgBaseFrame)
        self:LoadSprite(HeroUIUtilities.GetQualityFrontSpriteID(self.data.configCell:Quality()), self.imgBaseFrame01)

        local battleType = HeroUIUtilities.GetHeroBattleTypeTextureName(self.data.configCell:BattleType())
        if not string.IsNullOrEmpty(battleType) then
            self.goBaseJob:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(battleType, self.imgIconJob)
        else
            self.goBaseJob:SetVisible(false)
        end
        local tagId = self.data.configCell:AssociatedTagInfo()
        if tagId > 0 then
            self.compStyle:SetVisible(true)
            self.compStyle:FeedData({
                tagId = tagId
            })
        else
            self.compStyle:SetVisible(false)
        end

    end
    if self.data.resCell then
        local heroHead = UIHelper.GetFitHeroHeadIcon(self.imgImgHero, self.data.resCell)
        self:LoadSprite(heroHead, self.imgImgHero)
    end
end

---OnFeedData
---@param param HeroInfoData
function HeroInfoItemComponent:OnFeedData(param)
    if not self.data or self.data.id ~= param.heroData.id then
        self.data = param.heroData
        self:SetupIcons()
    end

    if self.data.dbData then
        self.imgBaseFrame.gameObject:SetVisible(true)
        self.goIconLv:SetVisible(true)
        self.goBaseJob:SetVisible(true)
        self.compStyle:SetVisible(true)
        if self.goBaseN then
            self.goBaseN:SetVisible(false)
        end
        if self.goBaseLock then
            self.goBaseLock:SetVisible(false)
        end
        self.textLv.text = 'Lv.' .. tostring(self.data.dbData.Level)
        if self.goIconStrong then
            self.compIconStrong:FeedData(self.data.dbData.StarLevel)
        end
        self:ChangeImageAlpha(self.imgBaseFrame, 1)
        self.imgBaseFrame01.gameObject.transform.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        if self.textName then
            self.textName.text = string.format('<color=#F1E6E0>%s</color>', I18N.Get(self.data.configCell:Name()))
        end
    elseif self.data.heroInitParam then
        self.imgBaseFrame.gameObject:SetVisible(true)
        self.goIconLv:SetVisible(true)
        self.goBaseJob:SetVisible(true)
        self.compStyle:SetVisible(true)
        if self.goBaseN then
            self.goBaseN:SetVisible(false)
        end
        if self.goBaseLock then
            self.goBaseLock:SetVisible(false)
        end
        self.textLv.text = 'Lv.' .. tostring(self.data.heroInitParam.Level)
        if self.goIconStrong then
            if self.data.heroInitParam.StarLevel >= 0 then
                self.goIconStrong:SetVisible(true)
                self.compIconStrong:FeedData(self.data.heroInitParam.StarLevel)
            else
                self.goIconStrong:SetVisible(false)
            end
        end
        self:ChangeImageAlpha(self.imgBaseFrame, 1)
        self.imgBaseFrame01.gameObject.transform.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        --UIHelper.SetGray(self.imgImgHero.gameObject, false)
        if self.textName then
            self.textName.text = string.format('<color=#F1E6E0>%s</color>', I18N.Get(self.data.configCell:Name()))
        end
    else
        self.imgBaseFrame.gameObject:SetVisible(false)
        if self.goIconStrong then
            self.goIconStrong:SetVisible(false)
        end
        self.goBaseJob:SetVisible(true)
        if self.goBaseN then
            self.goBaseN:SetVisible(false)
        end
        if self.goBaseLock then
            self.goBaseLock:SetVisible(true)
        end
        self.compStyle:SetVisible(true)
        self:ChangeImageAlpha(self.imgBaseFrame, 0.5)
        self.imgBaseFrame01.gameObject.transform.localScale = CS.UnityEngine.Vector3(1.2, 1.2, 1.2)
        if self.textName then
            self.textName.text = string.format('<color=#AEB4B6>%s</color>', I18N.Get(self.data.configCell:Name()))
        end
        if self.data.lv then
            self.goIconLv:SetVisible(true)
            self.textLv.text ='Lv.' .. tostring(self.data.lv)
        else
            self.goIconLv:SetVisible(false)
        end
        if self.goIconStrong then
            if self.data.star and self.data.star >= 0 then
                self.goIconStrong:SetVisible(true)
                self.compIconStrong:FeedData(self.data.dbData.StarLevel)
            else
                self.goIconStrong:SetVisible(false)
            end
        end
    end


    if (param.hideExtraInfo) then
		-- if (Utils.IsNotNull(self.goIconLv)) then
			self.goIconLv:SetActive(false)
		-- end
		-- if (Utils.IsNotNull(self.goIconStrong)) then
			self.goIconStrong:SetActive(false)
		-- end
		-- if (Utils.IsNotNull(self.goBaseJob)) then
			self.goBaseJob:SetActive(false)
		-- end
        self.compStyle:SetVisible(false)
    else
        if param.hideLv then
            self.goIconLv:SetActive(false)
        end

        if param.hideStrengthen then
            self.goIconStrong:SetActive(false)
        end

        if param.hideJobIcon then
            self.goBaseJob:SetVisible(false)
        end

        if param.hideStyle then
            self.compStyle:SetVisible(false)
        end
    end

    if param.showInjured then
        if Utils.IsNotNull(self.goBaseInjured) then
            self.goBaseInjured:SetVisible(true)
        end
        self.textName.text = ''
        -- g_Game.SpriteManager:LoadSprite('sp_comp_base_lv_1', self.imgIconLv)
    else
        if Utils.IsNotNull(self.goBaseInjured) then
            self.goBaseInjured:SetVisible(false)
        end
        -- g_Game.SpriteManager:LoadSprite('sp_comp_base_lv', self.imgIconLv)
    end

    if param.hideName then
        self.textName:SetVisible(false)
    else
        self.textName:SetVisible(true)
    end

    self:SetColor( UIHelper.TryParseHtmlString(ColorConsts.white))
    self.onClick = param.onClick
end

function HeroInfoItemComponent:SetGray(isGray)
    UIHelper.SetGray(self.imgImgHero.gameObject, isGray)
end

function HeroInfoItemComponent:SetColor(color)
    self.imgImgHero.color = color
    self.imgBaseFrame.color = color
    self.imgBaseFrame01.color = color
end

function HeroInfoItemComponent:ChangeImageAlpha(image, alpha)
    local color = image.color
    color.a = alpha
    image.color = color
end

function HeroInfoItemComponent:OnBtnChildCardHeroMClicked(args)
    if self.onClick then
        self.onClick(self.data)
    end
end

function HeroInfoItemComponent:RefreshLv(lv)
    self.textLv.text = 'Lv.' .. tostring(lv)
end

function HeroInfoItemComponent:ShowEscrow(iconName)
    if not Utils.IsNotNull(self.escrowRoot) then
        return
    end
    if string.IsNullOrEmpty(iconName) then
        self.escrowRoot:SetVisible(false)
    else
        self.escrowRoot:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(iconName, self.escrowIcon)
    end
end

return HeroInfoItemComponent;
