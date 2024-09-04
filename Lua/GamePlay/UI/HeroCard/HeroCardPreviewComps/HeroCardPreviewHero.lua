local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIHeroLocalData = require('UIHeroLocalData')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AttackDistanceType = require('AttackDistanceType')
local UIHelper = require('UIHelper')
local HeroType = require("HeroType")
local AudioConsts = require("AudioConsts")
local HeroUIUtilities = require('HeroUIUtilities')
---@class HeroCardPreviewHero : BaseUIComponent
---@field module HeroModule
---@field parentMediator UIHeroMainUIMediator
---@field heroList table<number,HeroConfigCache>
---@field selectHeroData HeroConfigCache
---@field compListDetail UIHeroAttrListComponent
local HeroCardPreviewHero = class('HeroCardPreviewHero', BaseUIComponent)

local QUALITY_COLOR = {
    "#6d9d3a",
    "#4a8ddf",
    "#b259e6",
    "#f9751c",
}

local SE = 0
local SLG = 1


function HeroCardPreviewHero:ctor()
    self.module = ModuleRefer.HeroModule
end

function HeroCardPreviewHero:OnCreate()
    self.imgHero = self:Image('p_img_hero')
    self.textHeroNameB = self:Text('p_text_name_b')
    self.textCharactername2 = self:Text('p_text_charactername_2')
    self.textCharactername1 = self:Text('p_text_charactername_1')
    self.detailPageController = self:BindComponent("p_scroll", typeof(CS.PageViewController))
	self.detailPageController.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)
    self.goBasicContent = self:GameObject('p_basic_content')
    self.compListDetail = self:LuaBaseComponent('p_list_detail')
    self.compSLGListDetail = self:LuaBaseComponent('p_list_detail_slg')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.goToggle = self:GameObject('p_toggle')
    self.btnToggleLeft = self:Button('p_base_n_l', Delegate.GetOrCreate(self, self.OnBtnToggleLeftClicked))
    self.goBaseNL = self:GameObject('p_base_n_l')
    self.goBaseSelectL = self:GameObject('p_base_select_l')
    self.textTitleBasice = self:Text('p_text_title_basice', I18N.Get("hero_se_tab"))
    self.btnToggleRight = self:Button('p_base_n', Delegate.GetOrCreate(self, self.OnBtnToggleRightClicked))
    self.goBaseN = self:GameObject('p_base_n')
    self.goBaseSelect = self:GameObject('p_base_select')
    self.textTitle = self:Text('p_text_title', I18N.Get("hero_slg_tab"))
    -- self.imgQuality = self:Image('p_img_quality')
    self.textQuality = self:Text('p_text_quality')
    self.goArms = self:GameObject("p_arms")
    self.imgArms = self:Image('p_icon_arms')
    self.goCity = self:GameObject("p_group_hero")
    self.textHero = self:Text('p_text_hero', I18N.Get('hero_city_tab'))
    self.compCityListDetail = self:LuaBaseComponent('p_list_detail_hero')
    self.imgHero.gameObject:SetActive(false)
end

function HeroCardPreviewHero:OnFeedData(param)
    local heroId = param.heroId
    local heroConfig = ConfigRefer.Heroes:Find(heroId)
    local index = heroConfig:Quality() + 1
    local color = QUALITY_COLOR[index]
    local heroName =  UIHelper.GetColoredText(I18N.Get(heroConfig:Name()), color)
    -- g_Game.SpriteManager:LoadSprite(UIHeroLocalData.QUALITY_IMAGE[index], self.imgQuality)
    local attackDistance = heroConfig:AttackDistance()
    if attackDistance == AttackDistanceType.Short then
        g_Game.SpriteManager:LoadSprite("sp_icon_survivor_type_1", self.imgArms)
    else
        g_Game.SpriteManager:LoadSprite("sp_icon_survivor_type_3", self.imgArms)
    end
    self.textHeroNameB.text = heroName
    self.textCharactername1.text = heroName
    self.textCharactername2.text = heroName
    self.isHero = heroConfig:Type() == HeroType.Heros
    self.btnToggleRight.gameObject:SetActive(self.isHero)
    self:OnBtnToggleLeftClicked()
    self.goBasicContent:SetActive(self.isHero)
    self.goCity:SetActive(not self.isHero)
    self.goToggle:SetActive(self.isHero)
    self.goArms:SetActive(self.isHero)
    self.heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    if self.isHero then
        self.compListDetail:FeedData({self.heroData, false, true})
        self.compSLGListDetail:FeedData({self.heroData, true, true})
    else
        self.compCityListDetail:FeedData({self.heroData, false, true})
    end
    self:LoadHeroModule(heroId)
end

function HeroCardPreviewHero:LoadHeroModule(heroId)
    -- local heroCfg = ConfigRefer.Heroes:Find(heroId)
    -- local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    -- if resCell:ShowModel() and resCell:ShowModel() > 0 then
    --     g_Game.SoundManager:PlayAudio(resCell:ShowVoiceRes())
    --     g_Game.UIManager:CloseUI3DModelView()
    --     g_Game.UIManager:SetupUI3DModelView(ConfigRefer.ArtResource:Find(resCell:ShowModel()):Path(), ConfigRefer.ArtResource:Find(resCell:ShowBackground()):Path(), nil, function(viewer)
    --         self.ui3dModel = viewer
    --         self.aniName = resCell:ShowAnimation()
    --         self.ui3dModel:PlayAnim(self.aniName)
    --         local scale = ConfigRefer.ArtResource:Find(resCell:ShowModel()):ModelScale()
    --         self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3(scale,scale,scale))
    --         self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30,322.46,0))
    --         self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(resCell:ModelPosition(1), resCell:ModelPosition(2), resCell:ModelPosition(3)))
    --         self.ui3dModel:RefreshEnv()
    --         self.ui3dModel:InitVirtualCameraSetting(self:GetCameraSetting())
    --         self.animation = self.ui3dModel.curEnvGo.transform:Find("vx_w_hero_main/all/vx_ui_hero_main"):GetComponent(typeof(CS.UnityEngine.Animation))
    --         if self.animation then
    --             self.animation:Play("anim_vx_w_hero_main_open")
    --         end
    --     end)
    -- end
end


function HeroCardPreviewHero:GetCameraSetting()
    local cameraSetting = {}
    for i = 1, 2 do
        local singleSetting = {}
        singleSetting.fov = ConfigRefer.ConstMain:HeroEuipMoveFOV(i)
        singleSetting.nearCp = ConfigRefer.ConstMain:HeroEuipMoveNCP(i)
        singleSetting.farCp = ConfigRefer.ConstMain:HeroEuipMoveFCP(i)
        if i == 1 then
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipCameraMove(1), ConfigRefer.ConstMain:HeroEuipCameraMove(2), ConfigRefer.ConstMain:HeroEuipCameraMove(3))
        else
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipCameraMove(4), ConfigRefer.ConstMain:HeroEuipCameraMove(5), ConfigRefer.ConstMain:HeroEuipCameraMove(6))
        end
        cameraSetting[i] = singleSetting
    end
    return cameraSetting
end

function HeroCardPreviewHero:GetSelectHero()
    return self.heroData
end

function HeroCardPreviewHero:OnBtnDetailClicked()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    g_Game.UIManager:Open(require('UIMediatorNames').UIHeroAttrDetailUIMediator, {self.heroData, self.isHero})
end

function HeroCardPreviewHero:OnClose(param)
	self.detailPageController.onPageChanged = nil
    -- if self.ui3dModel then
    -- 	g_Game.UIManager:CloseUI3DModelView()
	-- end
end

function HeroCardPreviewHero:OnPageChanged(old, new)
	self:SwitchToDetailPage(new)
end

function HeroCardPreviewHero:SwitchToDetailPage(page, scroll)
    if not self.isHero then
        return
    end
	if (page == SE) then
        self.goBaseNL:SetActive(false)
        self.goBaseSelectL:SetActive(true)
        self.textTitleBasice.gameObject:SetActive(true)
        self.goBaseN:SetActive(true)
        self.goBaseSelect:SetActive(false)
        self.textTitle.gameObject:SetActive(false)
        self.goToggle:SetActive(false)
        self.goToggle:SetActive(true)
	elseif (page == SLG) then
        self.goBaseNL:SetActive(true)
        self.goBaseSelectL:SetActive(false)
        self.textTitleBasice.gameObject:SetActive(false)
        self.goBaseN:SetActive(false)
        self.goBaseSelect:SetActive(true)
        self.textTitle.gameObject:SetActive(true)
        self.goToggle:SetActive(false)
        self.goToggle:SetActive(true)
	end
	if (scroll) then
		self.detailPageController:ScrollToPage(page)
	end
end

function HeroCardPreviewHero:OnBtnToggleLeftClicked()
    self:SwitchToDetailPage(SE, true)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

function HeroCardPreviewHero:OnBtnToggleRightClicked()
    self:SwitchToDetailPage(SLG, true)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

return HeroCardPreviewHero
