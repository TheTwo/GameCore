---@sceneName:scene_hero_card_main
local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local I18N = require('I18N')
local URPRendererList = require("URPRendererList")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local GachaConfigType = require('GachaConfigType')
local ColorConsts = require('ColorConsts')
local DBEntityPath = require('DBEntityPath')
local TimerUtility = require('TimerUtility')
local UIHelper = require('UIHelper')
local UI3DViewConst = require('UI3DViewConst')
local KingdomMapUtils = require('KingdomMapUtils')
---@class HeroCardMediator:BaseUIMediator
local HeroCardMediator = class('HeroCardMediator',BaseUIMediator)
local GuideUtils = require('GuideUtils')

function HeroCardMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.goContent = self:GameObject('content')
    self.goTabA = self:GameObject('p_tab_a')
    self.goImgSelectA = self:GameObject('p_img_select_a')
    self.btnA = self:Button('p_btn_a', Delegate.GetOrCreate(self, self.OnBtnAClicked))
    self.imgImgA = self:Image('p_img_a')
    self.textA = self:Text('p_text_a', I18N.Get("*限时!"))
    self.goTabB = self:GameObject('p_tab_b')
    self.goImgSelectB = self:GameObject('p_img_select_b')
    self.btnB = self:Button('p_btn_b', Delegate.GetOrCreate(self, self.OnBtnBClicked))
    self.imgImgB = self:Image('p_img_b')
    self.goB = self:Text('p_text_b', I18N.Get("*初级"))
    self.goTabC = self:GameObject('p_tab_c')
    self.goImgSelectC = self:GameObject('p_img_select_c')
    self.btnC = self:Button('p_btn_c', Delegate.GetOrCreate(self, self.OnBtnCClicked))
    self.goImgC = self:GameObject('p_img_c')
    self.textC = self:Text('p_text_c')
    self.goGroupActivity = self:GameObject('p_group_activity')
    self.goGroupB = self:GameObject('p_group_b')
    self.goImgPetB = self:GameObject('p_img_pet_b')
    self.textNameB = self:Text('p_text_name_b', I18N.Get("gacha_cate_junior"))
    self.btnDetailB = self:Button('p_btn_detail_b', Delegate.GetOrCreate(self, self.OnBtnDetailBClicked))
    self.textDetailB = self:Text('p_text_detail_b', I18N.Get("gacha_info"))
    self.textNameC = self:Text('p_text_name_c', I18N.Get("gacha_cate_senior"))
    self.btnDetailC = self:Button('p_btn_detail_c', Delegate.GetOrCreate(self, self.OnBtnDetailCClicked))
    self.textDetailC = self:Text('p_text_detail_c', I18N.Get("gacha_info"))
    self.btnSsr = self:Button('p_btn_ssr', Delegate.GetOrCreate(self, self.OnBtnSsrClicked))
    self.sliderProgress = self:Slider('p_progress')
    self.goSelected = self:GameObject('p_selected')
    self.imgImg = self:Image('p_img')
    self.goRedDot = self:GameObject('reddot')
    self.textNum = self:Text('p_text_num')
    self.compResource1 = self:LuaObject('p_resource_1')
    self.compResource2 = self:LuaObject('p_resource_2')
    self.compResource3 = self:LuaObject('p_resource_3')
    self.btnExchange = self:Button('p_btn_exchange', Delegate.GetOrCreate(self, self.OnBtnExchangeClicked))
    self.textExchange = self:Text('p_text_exchange', I18N.Get("gacha_shop"))
    self.btnOne = self:Button('p_btn_one', Delegate.GetOrCreate(self, self.OnBtnOneClicked))
    self.imgIconOne = self:Image('p_icon_one')
    self.textNumOne = self:Text('p_text_num_one')
    self.textOne = self:Text('p_text_one', I18N.Get("gacha_tern_1"))
    self.btnFree = self:Button('p_btn_free', Delegate.GetOrCreate(self, self.OnBtnFreeClicked))
    self.textFree = self:Text('p_text_free')
    self.textNumGreenAl = self:Text('p_text_num_green_al', I18N.Get("gacha_free"))
    self.textFreeTime = self:Text('p_text_free_time')
    self.textTip = self:Text('p_text_tip', I18N.Get("gacha_tips_sr"))
    self.btnTen = self:Button('p_btn_ten', Delegate.GetOrCreate(self, self.OnBtnTenClicked))
    self.imgIconTen = self:Image('p_icon_ten')
    self.textNumTen = self:Text('p_text_num_ten')
    self.textTen = self:Text('p_text_ten', I18N.Get("gacha_tern_10"))
    self.goTipSr = self:GameObject('p_tip_sr')
    self.textTip = self:Text('p_text_tip', I18N.Get("gacha_tips_sr"))
    self.btnToggleSet = self:Button('p_toggle_set', Delegate.GetOrCreate(self, self.OnBtnToggleSetClicked))
    self.goStatusA = self:GameObject('p_status_a')
    self.goStatusB = self:GameObject('p_status_b')
    self.textSkip = self:Text('p_text_skip', I18N.Get("gacha_no_anim"))
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    -- self.textFree.gameObject:SetActive(false)
    self.goTipSr:SetActive(true)
    self:PreloadUI3DView()
end

function HeroCardMediator:PreloadUI3DView()
	self:SetAsyncLoadFlag()
	---@type UI3DViewerParam
	local data = {}
	data.envPath = "mdl_ui3d_background_hero_card"
    local cameraSettings = self:GetShowCameraSetting()
    g_Game.UIManager.ui3DViewManager:InitCameraTransform(cameraSettings[1])
	data.callback = function(viewer)
		self:RemoveAsyncLoadFlag()
	end
	g_Game.UIManager:SetupUI3DView(self:GetRuntimeId(), UI3DViewConst.ViewType.ModelViewer, data)
end

function HeroCardMediator:OnOpened()
    -- g_Game.UIManager:SetZBlurVisible(false)
    ModuleRefer.ToastModule:BlockToast()
    self.compChildCommonBack:FeedData({title = I18N.Get("system_gacha_title")})
    self:InitGachaType()
    self:InitGachaTab()
    self:RefreshCachaBtn()
    self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.RefreshCachaBtn), 1, -1)
    self:LoadEnv()
    self:RefreshCoins()
    self:RefreshIsSkip()
    self:RefreshCustomSelect()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshCoins))
    for _, config in ConfigRefer.GachaType:ipairs() do
        ModuleRefer.InventoryModule:AddCountChangeListener(config:ShowItemId(), Delegate.GetOrCreate(self, self.RefreshCoins))
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Gacha.MsgPath, Delegate.GetOrCreate(self, self.RefreshCustomSelect))
    g_Game.EventManager:AddListener(EventConst.HERO_CARD_SHOW_UI, Delegate.GetOrCreate(self, self.ChangeUIState))
    g_Game.EventManager:AddListener(EventConst.CHANGE_CAMERA_STATE, Delegate.GetOrCreate(self, self.Change3DCameraEnable))

    KingdomMapUtils.SetGlobalCityMapParamsId(false)
end

function HeroCardMediator:OnClose(param)
    ModuleRefer.ToastModule:IngoreBlockToast()
    if self.ui3dModel then
        self.ui3dModel:ChangeCameraRender(URPRendererList.UI3D)
    end
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshCoins))
    for _, config in ConfigRefer.GachaType:ipairs() do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(config:ShowItemId(), Delegate.GetOrCreate(self, self.RefreshCoins))
    end
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Gacha.MsgPath, Delegate.GetOrCreate(self, self.RefreshCustomSelect))
    g_Game.EventManager:RemoveListener(EventConst.HERO_CARD_SHOW_UI, Delegate.GetOrCreate(self, self.ChangeUIState))
    g_Game.EventManager:RemoveListener(EventConst.CHANGE_CAMERA_STATE, Delegate.GetOrCreate(self, self.Change3DCameraEnable))
    if ModuleRefer.GuideModule:IsGuideFinished(30) then
        return
    end
    GuideUtils.GotoByGuide(30)

    KingdomMapUtils.SetGlobalCityMapParamsId(KingdomMapUtils.IsMapState())
end

function HeroCardMediator:InitGachaType()
    for _, config in ConfigRefer.GachaType:ipairs() do
        if config:Type() == GachaConfigType.Advanced then
            self.curSelectType = config:Id()
        end
    end
end

function HeroCardMediator:InitGachaTab()

end

function HeroCardMediator:RefreshCachaBtn()
    local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
    local gachaPoolInfo = (gachaInfo.Data or {})[self.curSelectType]
    local freeTime = gachaPoolInfo and gachaPoolInfo.NextFreeTime or 0
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local isFree = freeTime ~= 0 and curTime >= freeTime
    self.btnOne.gameObject:SetActive(not isFree)
    self.btnFree.gameObject:SetActive(isFree)
    self.textFreeTime.gameObject:SetActive(not isFree)
    if freeTime > 0 and not isFree then
        self.textFreeTime.text = I18N.Get("gacha_free_cd") .. TimeFormatter.SimpleFormatTime(freeTime - curTime)
    end
end

function HeroCardMediator:LoadEnv()
    local dogPath = "mdl_ui3d_background_hero_card_pet"
    local envPath = "mdl_ui3d_background_hero_card"
    --g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
    g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(),dogPath, envPath, nil, function(viewer)
        if not viewer then
            return
        end
        self.ui3dModel = viewer
        self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3.one)
        self.ui3dModel:SetModelAngles(CS.UnityEngine.Vector3.zero)
        self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3.zero)
        self.ui3dModel:RefreshEnv()
        self.ui3dModel:InitVirtualCameraSetting(self:GetShowCameraSetting())
        self.ui3dModel:ChangeCameraRender(URPRendererList.GaCha)
    end)

    CS.RenderPiplineUtil.SetShadowDistance(10)

end

function HeroCardMediator:GetShowCameraSetting()
    local cameraSetting = {}
    for i = 1, 2 do
        local singleSetting = {}
        singleSetting.fov = ConfigRefer.ConstMain:GachaMoveFOV(1)
        singleSetting.nearCp = ConfigRefer.ConstMain:GachaMoveNCP(1)
        singleSetting.farCp = ConfigRefer.ConstMain:GachaMoveFCP(1)
        if i == 1 then
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:GachaCameraMove(1), ConfigRefer.ConstMain:GachaCameraMove(2), ConfigRefer.ConstMain:GachaCameraMove(3))
            singleSetting.rotation = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:GachaCameraRot(1), ConfigRefer.ConstMain:GachaCameraRot(2), ConfigRefer.ConstMain:GachaCameraRot(3))
        else
            singleSetting.localPos = CS.UnityEngine.Vector3(ConfigRefer.ConstMain:GachaCameraMove(4), ConfigRefer.ConstMain:GachaCameraMove(5), ConfigRefer.ConstMain:GachaCameraMove(6))
            singleSetting.rotation =CS.UnityEngine.Vector3(ConfigRefer.ConstMain:GachaCameraRot(4), ConfigRefer.ConstMain:GachaCameraRot(5), ConfigRefer.ConstMain:GachaCameraRot(6))
        end
        cameraSetting[i] = singleSetting
    end
    return cameraSetting
end

function HeroCardMediator:RefreshCoins()
    local coinId = ConfigRefer.ConstMain:UniversalCoin()
    local item = ConfigRefer.Item:Find(coinId)
    local iconData = {
        iconName = item:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId),
        isShowPlus = false,
    }
    self.compResource1:FeedData(iconData)
    local coinId2 = ConfigRefer.ConstMain:UniversalCoin2()
    local item2 = ConfigRefer.Item:Find(coinId2)
    local iconData2 = {
        iconName = item2:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId2),
        isShowPlus = false,
    }
    self.compResource2:FeedData(iconData2)
    local gachaCoin = ConfigRefer.GachaType:Find(self.curSelectType):ShowItemId()
    local item3 = ConfigRefer.Item:Find(gachaCoin)
    local iconData3 = {
        iconName = item3:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(gachaCoin),
        isShowPlus = false,
    }
    self.compResource3:FeedData(iconData3)

    local gachaId = ConfigRefer.GachaType:Find(self.curSelectType):GachaId()
    local oneDrawCost = ConfigRefer.Gacha:Find(gachaId):OneDrawCost()
    local oneCostItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(oneDrawCost)[1]
    g_Game.SpriteManager:LoadSprite(oneCostItem.configCell:Icon(), self.imgIconOne)
    self.textNumOne.text = "x" .. oneCostItem.count
    local oneCurNum = ModuleRefer.InventoryModule:GetAmountByConfigId(oneCostItem.configCell:Id())
    if oneCurNum >= oneCostItem.count then
        self.textNumOne.text = "x" .. oneCostItem.count
    else
        self.textNumOne.text = UIHelper.GetColoredText("x" .. oneCostItem.count, ColorConsts.warning)
    end
    local tenDrawCost = ConfigRefer.Gacha:Find(gachaId):TenDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(tenDrawCost)[1]
    g_Game.SpriteManager:LoadSprite(costItem.configCell:Icon(), self.imgIconTen)
    local curNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItem.configCell:Id())
    if curNum >= costItem.count then
        self.textNumTen.text = "x" .. costItem.count
    else
        self.textNumTen.text = UIHelper.GetColoredText("x" .. costItem.count, ColorConsts.warning)
    end
end

function HeroCardMediator:RefreshIsSkip()
    local isSkip = ModuleRefer.HeroCardModule:GetSkipState()
    self.goStatusB:SetActive(isSkip)
end

function HeroCardMediator:RefreshCustomSelect()
    local cfg = ConfigRefer.GachaType:Find(self.curSelectType)
    local isShowChose = cfg:ChosenConfigId() and cfg:ChosenConfigId() > 0
    self.btnSsr.gameObject:SetActive(isShowChose)
    if cfg:Type() == GachaConfigType.Advanced then
        local maxSelect = cfg:ChosenLoopTimes()
        local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
        local gachaPoolInfo = (gachaInfo.Data or {})[self.curSelectType]
        local customSSRTimes = gachaPoolInfo and gachaPoolInfo.SSRCount or 0
        self.textNum.text = customSSRTimes .. "/" .. maxSelect
        self.sliderProgress.value = customSSRTimes / maxSelect
        local curSelectItemId = gachaPoolInfo and gachaPoolInfo.ChosenItem or 0
        local isSelected = curSelectItemId > 0
        self.goSelected:SetActive(isSelected)
        self.goRedDot:SetActive(not isSelected)
        if isSelected then
            g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(curSelectItemId):Icon(), self.imgImg)
        elseif ModuleRefer.HeroCardModule:IsShowSelect() then
            ModuleRefer.HeroCardModule:SetIsShowSelect(false)
            --g_Game.UIManager:Open(UIMediatorNames.HeroCardSelectMediator, self.curSelectType)
        end
    end
end

function HeroCardMediator:OnBtnAClicked(args)
    -- body
end

function HeroCardMediator:OnBtnBClicked(args)
    -- body
end

function HeroCardMediator:OnBtnCClicked(args)
    -- body
end

function HeroCardMediator:OnBtnDetailBClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.HeroCardPopupMediator, self.curSelectType)
end

function HeroCardMediator:OnBtnDetailCClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.HeroCardPopupMediator, self.curSelectType)
end

function HeroCardMediator:OnBtnSsrClicked(args)
    --g_Game.UIManager:Open(UIMediatorNames.HeroCardSelectMediator, self.curSelectType)
end

function HeroCardMediator:OnBtnExchangeClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator, {tabIndex = ConfigRefer.ConstMain:GachaShopId()})
end

function HeroCardMediator:OnBtnFreeClicked(args)
    self:OnBtnOneClicked(true)
end

function HeroCardMediator:OnBtnOneClicked(isFree)
    local gachaId = ConfigRefer.GachaType:Find(self.curSelectType):GachaId()
    local oneDrawCost = ConfigRefer.Gacha:Find(gachaId):OneDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(oneDrawCost)[1]
    ModuleRefer.HeroCardModule:DoGacha(costItem, wrpc.GachaDrawType.GachaDrawType_ONE, self.curSelectType, isFree)
end

function HeroCardMediator:OnBtnTenClicked(args)
    local gachaId = ConfigRefer.GachaType:Find(self.curSelectType):GachaId()
    local tenDrawCost = ConfigRefer.Gacha:Find(gachaId):TenDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(tenDrawCost)[1]
    ModuleRefer.HeroCardModule:DoGacha(costItem, wrpc.GachaDrawType.GachaDrawType_TEN, self.curSelectType)
end

function HeroCardMediator:OnBtnToggleSetClicked(args)
    local isSkip = ModuleRefer.HeroCardModule:GetSkipState()
    ModuleRefer.HeroCardModule:SetSkipState(not isSkip)
    self:RefreshIsSkip()
end

function HeroCardMediator:Change3DCameraEnable(isEnable)
    if self.ui3dModel then
        self.ui3dModel:ChangeCameraState(isEnable)
    end
end

function HeroCardMediator:ChangeUIState(isShow)
    self.goContent:SetActive(isShow)
    self.compChildCommonBack:SetVisible(isShow)
    if isShow then
        g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_DOG_INIT)
    end
    self:Change3DCameraEnable(true)
    if self.ui3dModel then
        self.ui3dModel:ChangeCinemachineBlend(0.5)
        self.ui3dModel:InitVirtualCameraSetting(self:GetShowCameraSetting())
        self.ui3dModel:EnableVirtualCamera(isShow and 1 or 2)
    end
end

return HeroCardMediator