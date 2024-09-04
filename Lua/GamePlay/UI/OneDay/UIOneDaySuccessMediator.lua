local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local HeroQuality = require('HeroQuality')
local I18N = require('I18N')
local Delegate = require('Delegate')
local HeroType = require('HeroType')
local HeroUIUtilities = require('HeroUIUtilities')
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local UIHelper = require('UIHelper')
local CityCitizenResidentFeedbackUIDataProvider = require("CityCitizenResidentFeedbackUIDataProvider")
local ColorConsts = require('ColorConsts')

---@class UIOneDaySuccessMediator : BaseUIMediator

local UIOneDaySuccessMediator = class('UIOneDaySuccessMediator', BaseUIMediator)

---@class UIOneDaySuccessMediatorParam
---@field heroId number
---@field closeCallback fun()
---@field selectType number
---@field dontCloseUI3DView boolean

local QUALITY = {
    "sp_common_base_collect_01",
    "sp_common_base_collect_02",
    "sp_common_base_collect_03",
    "sp_common_base_collect_04",
}

local QUALITY_CIRCLE = {
    "sp_common_base_collect_s_01",
    "sp_common_base_collect_s_02",
    "sp_common_base_collect_s_03",
    "sp_common_base_collect_s_04",
}

function UIOneDaySuccessMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type CityCitizenResidentFeedbackUIDataProvider
    self._injectedProvider = nil
end

function UIOneDaySuccessMediator:OnCreate()
    self.btnBase = self:Button('p_base_btn', Delegate.GetOrCreate(self, self.OnBtnBaseClicked))
    self.compChildResource = self:LuaObject('child_resource')
    self.compChildResource1 = self:LuaObject('child_resource_1')
    self.textName = self:Text('p_text_name')
    self.textQuality = self:Text('p_text_quality')
    self.imgBaseQuality = self:Image('p_base_quality')
    self.imgIconQuality = self:Image('p_icon_quality')
    self.imgBaseQualityCircle = self:Image('p_base_quality_circle')
    self.compChildTagPosition = self:LuaObject('child_tag_position')
    self.goTagStyle = self:GameObject("child_tag_style")
    self.imgIconStyle = self:Image('p_icon_style')
    self.textStyle = self:Text('p_text_style')
    self.goGroupHero = self:GameObject('p_group_hero')
    self.imgIconType = self:Image('p_icon_type')
    self.textSkillSe = self:Text('p_text_skill_se', I18N.Get("skill_se"))
    self.textSkillSlg = self:Text('p_text_skill_slg', I18N.Get("skill_slg"))
    self.compChildItemSkill1 = self:LuaObject('child_item_skill_1')
    self.compChildItemSkill2 = self:LuaObject('child_item_skill_2')
    self.compChildItemSkill3 = self:LuaObject('child_item_skill_3')
    self.goGroupCitizen = self:GameObject('p_group_citizen')
    self.textSkillLogistics = self:Text('p_text_skill_logistics', I18N.Get("hero_type_city"))
    self.compChildItemSkillSe1 = self:LuaObject('child_item_skill_se_1')
    self.compChildItemSkillSe2 = self:LuaObject('child_item_skill_se_2')
    self.compChildItemSkillSe3 = self:LuaObject('child_item_skill_se_3')
    self.goRepetition = self:GameObject('p_repetition')
    self.textRepetition = self:Text('p_text_repetition', I18N.Get("gacha_result_trans"))
    self.imgItemPet = self:Image('p_item_pet')
    self.imgHero = self:Image('img_hero')
    self.imgImgHero = self:Image("p_img_hero")
    self.goBubble1 = self:GameObject('p_bubble_1')
    self.textContent1 = self:Text('p_text_content_1')
    self.goBubble2 = self:GameObject('p_bubble_2')
    self.textContent2 = self:Text('p_text_content_2')
    self.goNew = self:GameObject('p_new')
    self.goImgNewGold = self:GameObject('p_img_new_gold')
    self.textNewPet = self:Text('p_text_new_pet', I18N.Get("system_unlock_new"))
    self.textContinue = self:Text('p_text_continue', I18N.Get("click_next"))
	---@type SEHudTipsSkillCard
    self.compTipsSkillCard = self:LuaObject('p_tips_skill_card')

    self.goGroupBtns = self:GameObject('p_group_btns')
    self.btnCompClam = self:Button('p_comp_btn_clam', Delegate.GetOrCreate(self, self.OnBtnCompClamClicked))
    self.textClam = self:Text('p_text_clam', I18N.Get("gacha_result_confim"))
    self.btnOne = self:Button('p_btn_one', Delegate.GetOrCreate(self, self.OnBtnOneClicked))
    self.textOne = self:Text('p_text_one', I18N.Get("gacha_result_more_1"))
    self.imgIconOne = self:Image('p_icon_one')
    self.textNumOne = self:Text('p_text_num_one')
    self.btnTen = self:Button('p_btn_ten', Delegate.GetOrCreate(self, self.OnBtnTenClicked))
    self.textTen = self:Text('p_text_ten', I18N.Get("gacha_result_more_10"))
    self.imgIconTen = self:Image('p_icon_ten')
    self.textNumTen = self:Text('p_text_num_ten')
    self.aniTrigger = self:AnimTrigger('vx_trigger')

    self.ingoreCallBack = false


    self.heroSlgSkills = {self.compChildItemSkill1, self.compChildItemSkill2, self.compChildItemSkill3}
    self.citizenSkills = {self.compChildItemSkillSe1, self.compChildItemSkillSe2, self.compChildItemSkillSe3}

    self.goBubbles = {self.goBubble1, self.goBubble2}
    self.textContents = {self.textContent1, self.textContent2}
end

--- @param param UIOneDaySuccessMediatorParam|CityCitizenResidentFeedbackUIDataProvider
function UIOneDaySuccessMediator:OnOpened(param)
    self.param = param
    g_Game.SoundManager:Play("sfx_ui_get_heropet")
    self.closeing = false

    -- 十连时的队列数据
    self:SetUpQueuedData()

    -- 资源栏，这版本隐藏
    self:SetupResourceBar()

    -- 下方抽卡按钮
    self:SetupDrawBtns()

    -- 抽卡结果的场景group切换，这版本只有英雄
    self:SetupResultGroup()

    -- 战斗类型、风格
    self:SetupTags()

    -- 立绘或模型
    self:SetupHeroPaint()

    -- 台词气泡
    self:SetupDialogBubbles()

    -- 技能信息
    self:SetupSkills()

    -- 新获得的New标签及重复获得的转化信息
    self:SetupNewlyAcquire()

    -- 入场动效
    self:PlayEnterVxAnim()
    self:SetUI3DCameraEnable(true)

    g_Game.EventManager:TriggerEvent(EventConst.UI_HERO_RESCUE_SHOW_HIDE_BUBBLE, false)
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, false)
    g_Game.UIManager.ui3DViewManager:SetRenderShadow(false)
end

function UIOneDaySuccessMediator:OnClose()
    if self._injectedProvider then
        local v = self._injectedProvider
        self._injectedProvider = nil
        v:Release()
    end
    if self.ingoreCallBack then
        return
    end
    if self.closeCallback then
        self.closeCallback()
    end
    ModuleRefer.HeroModule:SkipTimeline()
    if not self.param or not self.param.dontCloseUI3DView then
        g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
        g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
    end
    g_Game.EventManager:TriggerEvent(EventConst.UI_HERO_RESCUE_SHOW_HIDE_BUBBLE, true)
    g_Game.EventManager:TriggerEvent(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, true)

    g_Game.UIManager.ui3DViewManager:SetRenderShadow(true)
end

function UIOneDaySuccessMediator:SetUpQueuedData()
    self._injectedProvider = nil
    self.closeCallback = nil
    self.heroId = nil
    local param = self.param
    if param then
        if param.is and param:is(CityCitizenResidentFeedbackUIDataProvider) then
            self._injectedProvider = param
            local next = self._injectedProvider:Dequeue()
            self.heroId = next.citizenConfig:HeroId()
        else
            self.heroId = param.heroId
            self.closeCallback = param.closeCallback
        end
    end
    self.heroCfg = ConfigRefer.Heroes:Find(self.heroId)
    self.isHero = self.heroCfg:Type() == HeroType.Heros
end

function UIOneDaySuccessMediator:SetupResourceBar()
    local coinId = ConfigRefer.ConstMain:UniversalCoin()
    local item = ConfigRefer.Item:Find(coinId)
    local iconData = {
        iconName = item:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId),
        isShowPlus = false,
    }
    self.compChildResource:FeedData(iconData)
    local coinId2 = ConfigRefer.ConstMain:UniversalCoin2()
    local item2 = ConfigRefer.Item:Find(coinId2)
    local iconData2 = {
        iconName = item2:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId2),
        isShowPlus = false,
    }
    self.compChildResource1:FeedData(iconData2)

    self.compChildResource:SetVisible(false) -- 【【英雄】英雄获得界面，隐藏资源栏】https://www.tapd.cn/31821045/bugtrace/bugs/view?bug_id=1131821045001214068
    self.compChildResource1:SetVisible(false)
end

function UIOneDaySuccessMediator:SetupDrawBtns()
    self.goGroupBtns:SetActive(false)
end

function UIOneDaySuccessMediator:SetupResultGroup()
    local isHero = self.isHero
    self.goGroupHero:SetActive(isHero)
    self.goGroupCitizen:SetActive(not isHero)
end

function UIOneDaySuccessMediator:SetupTags()
    local heroCfg = self.heroCfg
    local isHero = self.isHero
    local index = heroCfg:Quality() + 1
    self.compChildTagPosition:SetVisible(isHero)
    if isHero then
        self.compChildTagPosition:FeedData({battleType = heroCfg:BattleType()})
    end
    local associatedTagInfo = heroCfg:AssociatedTagInfo()
    local cfg = ConfigRefer.AssociatedTag:Find(associatedTagInfo)
    self.goTagStyle:SetActive(cfg ~= nil)
    if cfg then
        self:LoadSprite(cfg:Icon(), self.imgIconStyle)
        self.textStyle.text = I18N.Get(cfg:Name())
    end
    g_Game.SpriteManager:LoadSprite(QUALITY[index], self.imgBaseQuality)
    g_Game.SpriteManager:LoadSprite(QUALITY_CIRCLE[index], self.imgBaseQualityCircle)
    self.imgIconQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(heroCfg:Quality()))
end

function UIOneDaySuccessMediator:SetupHeroPaint()
    local heroCfg = self.heroCfg
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    if resCell:ShowModel() and resCell:ShowModel() > 0 then
        self.voiceHandle = g_Game.SoundManager:PlayAudio(resCell:ShowVoiceRes())
        ModuleRefer.HeroModule:SkipTimeline()
        local inPlaceId = 1
        g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(),ConfigRefer.ArtResource:Find(resCell:ShowModel()):Path(), ConfigRefer.ArtResource:Find(resCell:AcquireBackground()):Path(), nil, function(viewer)
            if not viewer then
                return
            end
            self.ui3dModel = viewer
            local scale = ConfigRefer.ArtResource:Find(resCell:ShowModel()):ModelScale()
            self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3(scale,scale,scale))
            self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30,322.46,0))

            local x = resCell:AcquireModelPosition(1) > 0 and resCell:AcquireModelPosition(1) or 0
            local y = resCell:AcquireModelPosition(2) > 0 and resCell:AcquireModelPosition(2) or -1
            local z = resCell:AcquireModelPosition(3) > 0 and resCell:AcquireModelPosition(3) or 0
            self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(x, y, z))
            self.ui3dModel:RefreshEnv()
            self.ui3dModel:InitVirtualCameraSetting(self:GetShowCameraSetting())
            self.ui3dModel:UseShadowPiece(true)
            self.animHandle = g_Game.SoundManager:Play(resCell:ShowAnimationVoice())
            if resCell:LookatMe() then
                self.ui3dModel:AddHeroAimRig()
            end
            local showTimeline = resCell:ShowAnimationVFX()
            self.isPlayAni = true
            if showTimeline and showTimeline ~= "" then
                if self.ui3dModel then
                    self.ui3dModel.curModelGo:SetActive(false)
                end
                local callback = function()
                    if self.ui3dModel then
                        self.ui3dModel.curModelGo:SetActive(true)
                        self.ui3dModel:BindShadowPieceModel(self.ui3dModel.curModelGo)
                        self.ui3dModel:ChangeRigBuilderState(true)
                    end
                    self.ui3dModel:InitVirtualCameraSetting(self:GetCameraSetting())
                end
                local onCreate = function(go)
                    self.ui3dModel:BindShadowPieceModel(go)
                end
                ModuleRefer.HeroModule:LoadTimeline(resCell:ShowAnimationVFX(), self.ui3dModel.moduleRoot, callback, onCreate)
            else
                self.aniName = resCell:ShowAnimation()
                self.ui3dModel:PlayAnim(self.aniName)
            end
        end, inPlaceId)
    end
    self.textName.text = I18N.Get(heroCfg:Name())
end

function UIOneDaySuccessMediator:SetupDialogBubbles()
    local heroCfg = self.heroCfg
    local heroResId = heroCfg:ClientResCfg()
    local heroResCfg = ConfigRefer.HeroClientRes:Find(heroResId)
    for i = 1, #self.goBubbles do
        if i <= heroResCfg:GetHeroDialogLength() then
            self.goBubbles[i]:SetActive(true)
            self.textContents[i].text = I18N.Get(heroResCfg:GetHeroDialog(i))
        else
            self.goBubbles[i]:SetActive(false)
        end
    end
end

function UIOneDaySuccessMediator:SetupSkills()
    local heroCfg = self.heroCfg
    local isHero = self.isHero
    if isHero then
        for i = 1, #self.heroSlgSkills do
            local isShow = i <= heroCfg:SlgSkillDisplayLength()
            self.heroSlgSkills[i]:SetVisible(isShow)
            if isShow then
                local slgSkillId = heroCfg:SlgSkillDisplay(i)
                local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
                local skillParam = {}
                skillParam.skillId = slgSkillCell:SkillId()
                skillParam.index = i
                skillParam.isSlg = true
                skillParam.skillLevel = 1
                skillParam.isLock = i == 3
                if heroCfg:CardsDisplayLength() >= i then
                    skillParam.cardId = heroCfg:CardsDisplay(i)
                end
                skillParam.clickCallBack = function()
                    self:ChangeTipsState(true)
                    self.compTipsSkillCard:ShowHeroSkillTips(skillParam.skillId, skillParam.cardId, skillParam.isLock, skillParam.skillLevel, slgSkillCell)
                end
                self.heroSlgSkills[i]:FeedData(skillParam)
            end
        end
    else
        for i = 1, #self.citizenSkills do
            local isShow = i <= heroCfg:CitizenSkillCfgLength()
            self.citizenSkills[i]:SetVisible(isShow)
            if isShow then
                local citizenSkillId = heroCfg:CitizenSkillCfg(i)
                local citizenSkillCfg = ConfigRefer.CitizenSkillInfo:Find(citizenSkillId)
                local data = {}
                data.icon = citizenSkillCfg:Icon()
                data.name = I18N.Get(citizenSkillCfg:Name())
                data.clickCallBack = function()
                    self:ChangeTipsState(true)
                    self.compTipsSkillCard:ShowSocSkillTips(citizenSkillId)
                end
                self.citizenSkills[i]:FeedDataCustomData(data)
            end
        end
    end
end

function UIOneDaySuccessMediator:SetupNewlyAcquire()
    local param = self.param
    local heroCfg = self.heroCfg
    if param and param.transItemId then
        local isOld = param.transItemId and param.transItemId > 0
        self.goNew:SetActive(not isOld)
        self.goImgNewGold:SetActive(heroCfg:Quality() >= HeroQuality.Golden and not isOld)
        self.goRepetition:SetActive(false) -- 【【英雄】英雄获得界面，隐藏转化信息】
        if isOld then
            local itemCfg = ConfigRefer.Item:Find(param.transItemId)
            g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgItemPet)
        end
    else
        self.goNew:SetActive(false)
        self.goRepetition:SetActive(false)
    end
end

function UIOneDaySuccessMediator:PlayEnterVxAnim()
    self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
end

function UIOneDaySuccessMediator:ChangeTipsState(isShow)
    self.showTips = isShow
    self.compTipsSkillCard:SetVisible(isShow)
end

function UIOneDaySuccessMediator:OnBtnBaseClicked()
    if self.showTips then
        self:ChangeTipsState(false)
        return
    end
    self:SetUI3DCameraEnable(true)
    if self.selectType then
        return
    end
    if self._injectedProvider and not self._injectedProvider:IsEmpty() then
        self:StopAllAnim()
        self:SetVisible(false, nil)
        self:SetVisible(true, self._injectedProvider)
        self:OnOpened(self._injectedProvider)
    else
        if self.closeing then
            return
        end
        self.closeing = true
        local heroId = self.heroId or ConfigRefer.ConstMain:OptRewardHeroId()
        local heroCfg = ConfigRefer.Heroes:Find(heroId)
        if heroCfg:Quality() >= HeroQuality.Golden then
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom4, Delegate.GetOrCreate(self, self.BackToPrevious))
        else
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom2, Delegate.GetOrCreate(self, self.BackToPrevious))
        end
    end
end

function UIOneDaySuccessMediator:OnBtnCompClamClicked(args)
    self:SetUI3DCameraEnable(true)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
    g_Game.UIManager:Close(self.runtimeId)
end

function UIOneDaySuccessMediator:OnBtnOneClicked(args)
    self:SetUI3DCameraEnable(true)
    local callBack = function()
        local gachaId = ConfigRefer.GachaType:Find(self.selectType):GachaId()
        local oneDrawCost = ConfigRefer.Gacha:Find(gachaId):OneDrawCost()
        local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(oneDrawCost)[1]
        ModuleRefer.HeroCardModule:DoGacha(costItem, wrpc.GachaDrawType.GachaDrawType_ONE, self.selectType)
    end
    ModuleRefer.HeroCardModule:OnResultClose(callBack)
    self.ingoreCallBack = true
    g_Game.UIManager:Close(self.runtimeId)
end

function UIOneDaySuccessMediator:OnBtnTenClicked(args)
    self:SetUI3DCameraEnable(true)
    local callBack = function()
        local gachaId = ConfigRefer.GachaType:Find(self.selectType):GachaId()
        local tenDrawCost = ConfigRefer.Gacha:Find(gachaId):TenDrawCost()
        local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(tenDrawCost)[1]
        ModuleRefer.HeroCardModule:DoGacha(costItem, wrpc.GachaDrawType.GachaDrawType_TEN, self.selectType)
    end
    ModuleRefer.HeroCardModule:OnResultClose(callBack)
    self.ingoreCallBack = true
    g_Game.UIManager:Close(self.runtimeId)
end

function UIOneDaySuccessMediator:GetShowCameraSetting()
    local cameraSetting = {}
    for i = 1, 2 do
        local singleSetting = {}
        singleSetting.fov = ConfigRefer.ConstMain:HeroEuipShowMoveFOV(i)
        singleSetting.nearCp = ConfigRefer.ConstMain:HeroEuipShowMoveNCP(i)
        singleSetting.farCp = ConfigRefer.ConstMain:HeroEuipShowMoveFCP(i)
        if i == 1 then
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipShowCameraMove(1), ConfigRefer.ConstMain:HeroEuipShowCameraMove(2), ConfigRefer.ConstMain:HeroEuipShowCameraMove(3))
        else
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:HeroEuipShowCameraMove(4), ConfigRefer.ConstMain:HeroEuipShowCameraMove(5), ConfigRefer.ConstMain:HeroEuipShowCameraMove(6))
        end
        cameraSetting[i] = singleSetting
    end
    return cameraSetting
end

function UIOneDaySuccessMediator:GetCameraSetting()
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

function UIOneDaySuccessMediator:SetUI3DCameraEnable(enable)
    if self.ui3dModel then
        self.ui3dModel:ChangeCameraState(enable)
    else
        g_Game.EventManager:TriggerEvent(EventConst.CHANGE_CAMERA_STATE, enable)
    end
end

return UIOneDaySuccessMediator
