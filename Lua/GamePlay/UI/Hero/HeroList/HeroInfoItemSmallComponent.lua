local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local HeroUIUtilities = require('HeroUIUtilities')
local I18N = require('I18N')
local UIHelper = require("UIHelper")
local HeroModule = require("ModuleRefer").HeroModule
local Utils = require('Utils')

---@class HeroInfoItemSmallComponent : BaseUIComponent
local HeroInfoItemSmallComponent = class('HeroInfoItemSmallComponent', BaseUIComponent)

function HeroInfoItemSmallComponent:ctor()
    self.isPressing = false
    self.pressingThreshold = 0.2
    self.pressTimer = 0
end

function HeroInfoItemSmallComponent:OnCreate()
    self:PointerClick('p_btn', Delegate.GetOrCreate(self, self.OnBtnChildCardHeroMClicked))
    self:PointerDown('p_btn', Delegate.GetOrCreate(self, self.OnPressDown))
    self:PointerUp('p_btn', Delegate.GetOrCreate(self, self.OnPressUp))
    self.imgBaseFrame = self:Image('p_base_frame');
    self.imgBaseFrame01 = self:Image('p_base_frame_01');
    self.goSelect = self:GameObject("p_img_select_1")
    if Utils.IsNull(self.goSelect) then
        self.goSelect = self:GameObject("p_img_select")
    end
    self.imgImgHero = self:Image('p_img_hero');
    self.goIconLv = self:GameObject('p_icon_lv');
    self.textLv = self:Text('p_text_lv');
    self.goBaseJob = self:GameObject('p_base_job');
    self.imgIconJob = self:Image('p_icon_job');
    ------------------------------------------------------------------
    self.textName = self:Text('p_text_name');
    self.goBaseN = self:GameObject('p_base_n');
    self.goBaseLock = self:GameObject('p_base_lock');
    self.compIconStrong = self:LuaObject('p_icon_strong');
    self.goIconTroop = self:GameObject('p_icon_troop')

    self.escrowRoot = self:GameObject('p_escrow_root')
    self.escrowIcon = self:Image('p_escrow_icon')

    ---@type UIHeroAssociateIconComponent
    self.compStyle = self:LuaObject('p_icon_style')
    if Utils.IsNotNull(self.escrowRoot) then
        self.escrowRoot:SetVisible(false)
    end

    self.p_strengthen_hero_group = self:LuaObject('p_strengthen_hero_group')
    self.p_mask = self:GameObject('p_mask')
    self.p_lock = self:GameObject('p_lock')
end

function HeroInfoItemSmallComponent:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function HeroInfoItemSmallComponent:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function HeroInfoItemSmallComponent:OnOpened(param)
end

function HeroInfoItemSmallComponent:OnClose(param)
end

function HeroInfoItemSmallComponent:OnTick(dt)
    if not self.isPressing then
        self.pressTimer = 0
        return
    end
    self.pressTimer = self.pressTimer + dt
end

function HeroInfoItemSmallComponent:ChangeStateSelect(isShow)
    if Utils.IsNotNull(self.goSelect) then
        self.goSelect:SetActive(isShow)
    end
end

function HeroInfoItemSmallComponent:TroopIconVisible(visible)
    if Utils.IsNotNull(self.goIconTroop) then
        self.goIconTroop:SetVisible(visible)
    end
end

function HeroInfoItemSmallComponent:SetupIcons()
    if self.data.configCell then
        self:LoadSprite(HeroUIUtilities.GetQualitySpriteID(self.data.configCell:Quality()), self.imgBaseFrame)
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
            self.compStyle:FeedData({tagId = tagId})
        else
            self.compStyle:SetVisible(false)
        end
    end

    if self.data.resCell then
        local heroIcon = UIHelper.GetFitHeroHeadIcon(self.imgImgHero, self.data.resCell)
        self:LoadSprite(heroIcon, self.imgImgHero)
    end
end

---OnFeedData
---@param param HeroInfoData | number
function HeroInfoItemSmallComponent:OnFeedData(param)
    if type(param) == 'number' then
        local id = param
        param = {}
        param.heroData = HeroModule:GetHeroByCfgId(id)
    end

    if not self.data or self.data.id ~= param.heroData.id then
        self.data = param.heroData
    end

    if self.data == nil then
        g_Logger.ErrorChannel("HeroInfoItemSmallComponent", "No hero data")
        return
    end

    self:SetupIcons()

    self:SetStrength()

    local prefix = ''
    if param.showLevelPrefix then
        prefix = 'Lv.'
    end
    if self.data.dbData then
        self.p_strengthen_hero_group:SetVisible(true)
        self.imgBaseFrame.gameObject:SetVisible(true)
        self.goIconLv:SetVisible(true)
        if self.goBaseN then
            self.goBaseN:SetVisible(true)
        end
        if self.goBaseLock then
            self.goBaseLock:SetVisible(false)
        end
        self.textLv.text = prefix .. self.data.dbData.Level
        self:ChangeImageAlpha(self.imgBaseFrame, 1)
        -- self.imgBaseFrame01.gameObject.transform.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        if self.textName then
            self.textName.text = string.format('<color=#F1E6E0>%s</color>', I18N.Get(self.data.configCell:Name()))
        end
    elseif self.data.heroInitParam then
        self.p_strengthen_hero_group:SetVisible(true)
        self.imgBaseFrame.gameObject:SetVisible(true)
        self.goIconLv:SetVisible(true)
        if self.goBaseN then
            self.goBaseN:SetVisible(true)
        end
        if self.goBaseLock then
            self.goBaseLock:SetVisible(false)
        end
        self.textLv.text = prefix .. self.data.heroInitParam.Level
        self:ChangeImageAlpha(self.imgBaseFrame, 1)
        -- self.imgBaseFrame01.gameObject.transform.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        if self.textName then
            self.textName.text = string.format('<color=#F1E6E0>%s</color>', I18N.Get(self.data.configCell:Name()))
        end
    else
        if self.data.starLevel then
            self.p_strengthen_hero_group:SetVisible(true)
        else
            self.p_strengthen_hero_group:SetVisible(false)
        end
        self.imgBaseFrame.gameObject:SetVisible(true)
        if self.goBaseN then
            self.goBaseN:SetVisible(false)
        end
        if self.goBaseLock then
            self.goBaseLock:SetVisible(true)
        end
        self:ChangeImageAlpha(self.imgBaseFrame, 1)
        -- self.imgBaseFrame01.gameObject.transform.localScale = CS.UnityEngine.Vector3(1.2, 1.2, 1.2)
        if self.textName then
            self.textName.text = string.format('<color=#AEB4B6>%s</color>', I18N.Get(self.data.configCell:Name()))
        end
        if self.data.lv then
            self.goIconLv:SetVisible(true)
            self.textLv.text = prefix .. tostring(self.data.lv)
        else
            self.goIconLv:SetVisible(false)
        end
    end

    if (param.hideExtraInfo) then
        self.goIconLv:SetActive(false)
        self.compStyle:SetVisible(false)
    else
        if param.hideLv then
            self.goIconLv:SetActive(false)
        end

        if param.hideJobIcon then
            self.goBaseJob:SetVisible(false)
        end

        if param.hideStyle then
            self.compStyle:SetVisible(false)
        end
    end

    self.onClick = param.onClick
    self.onPressDown = param.onPressDown
    self.onPressUp = param.onPressUp
end

function HeroInfoItemSmallComponent:SetGray(isGray)
    UIHelper.SetGray(self.imgImgHero.gameObject, isGray)
end

function HeroInfoItemSmallComponent:ChangeImageAlpha(image, alpha)
    local color = image.color
    color.a = alpha
    image.color = color
end

function HeroInfoItemSmallComponent:OnBtnChildCardHeroMClicked(args)
    if self.pressTimer >= self.pressingThreshold then
        return
    end
    if self.onClick then
        self.onClick()
    end
end

function HeroInfoItemSmallComponent:OnPressDown(args)
    if self.onPressDown then
        self.isPressing = true
        self.onPressDown()
    end
end

function HeroInfoItemSmallComponent:OnPressUp(args)
    if self.onPressUp then
        self.onPressUp()
        self.isPressing = false
    end
end

function HeroInfoItemSmallComponent:RefreshLv(lv)
    self.textLv.text = lv
end

function HeroInfoItemSmallComponent:ShowEscrow(iconName)
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

function HeroInfoItemSmallComponent:SetStrength()
    if self.data.dbData then
        self.p_strengthen_hero_group:FeedData(self.data.dbData.StarLevel or 0)
    elseif self.data.heroInitParam then
        self.p_strengthen_hero_group:FeedData(self.data.heroInitParam.StarLevel or 0)
    elseif self.data.starLevel then
        self.p_strengthen_hero_group:FeedData(self.data.starLevel or 0)
    end
end

function HeroInfoItemSmallComponent:SetLock()
    local hasHero = self.data:HasHero()
    self.p_mask:SetVisible(not hasHero)
    self.p_lock:SetVisible(not hasHero)
end

function HeroInfoItemSmallComponent:SetColor(color)
    self.imgImgHero.color = color
    self.imgBaseFrame.color = color
    self.imgBaseFrame01.color = color
end

return HeroInfoItemSmallComponent
