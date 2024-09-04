local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require("TimerUtility")
local UIMediatorNames = require("UIMediatorNames")
local KingdomMapUtils = require("KingdomMapUtils")

---@class MapFogLodExploreUIMediator : BaseUIMediator
---@field inputfieldInputQuantity CS.UnityEngine.UI.InputField
---@field compChildPopupBaseS CommonPopupBackComponent
---@field compChildSetBar CommonNumberSlider
---@field compChildCompB BistateButton
---@field compChildCommonQuantity CommonPairsQuantity
---@field compChildCommonResource CommonResourceBtn
local MapFogLodExploreUIMediator = class("MapFogLodExploreUIMediator", BaseUIMediator)

function MapFogLodExploreUIMediator:OnCreate()
    self.compChildPopupBaseS = self:LuaObject('child_popup_base_s')
    self.goStatusBar = self:GameObject("status_bar")
    self.imgItemIcon = self:Image('icon_light')
    self.btnItemIcon = self:Button('icon_light')
    self.textItemName = self:Text('p_title_detail')
    self.textItemDesc = self:Text('p_text_detail')
    self.textTitle = self:Text('p_text_title', 'Mist_tips_selectamount')
    self.inputfieldInputQuantity = self:BindComponent('p_Input_quantity', typeof(CS.UnityEngine.UI.InputField))
    self.textInputQuantity = self:Text('p_text_input_quantity')
    self.compChildSetBar = self:LuaObject('child_set_bar')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.imgItemIconReq = self:Image('p_icon_item_bl')
    self.textItemCount = self:Text('p_text_num_green_bl')
    self.textItemCountRed = self:Text('p_text_num_red_bl')
    self.textItemCountReq = self:Text('p_text_num_wilth_bl')
    self.compChildCommonResource = self:LuaObject('child_resource')
    self.goStatusExplore = self:GameObject("status_explore")
    self.textExplore = self:Text('p_text_explore', "Radar_mist_glowstick_goto")
    self.btnCancel = self:Button('p_btn_cancel', Delegate.GetOrCreate(self, self.OnCancelClicked))
    self.textCancel = self:Text('p_text_cancel', "cancle")
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnGotoClicked))
    self.textGoto = self:Text('p_text_goto', "world_qianwang")

    -- self:PointerDown("icon_light", Delegate.GetOrCreate(self, self.OnPressItemIcon))
    -- self:PointerUp("icon_light", Delegate.GetOrCreate(self, self.OnReleaseItemIcon))
    self.btnItem = self:Button("icon_light_1", Delegate.GetOrCreate(self, self.OnItemIconClick))
end

function MapFogLodExploreUIMediator:OnShow(param)
    local baseData = {}
    baseData.title = I18N.Get("mist_btn_explore")
    self.compChildPopupBaseS:FeedData(baseData)

    local itemID = ConfigRefer.ConstMain:AddExploreValueItemId()
    local itemIcon = ConfigRefer.Item:Find(itemID):Icon()

    g_Game.SpriteManager:LoadSprite(itemIcon, self.imgItemIcon)
    self.textItemName.text = I18N.Get(ConfigRefer.Item:Find(itemID):NameKey())
    self.textItemDesc.text = ModuleRefer.MapFogModule:ShowUnlockItemTip()

    local isGoto = param
    self.goStatusBar:SetVisible(not isGoto)
    self.goStatusExplore:SetVisible(isGoto)

    if not isGoto then
        self:UpdateItemSlideBar()
    end
end

function MapFogLodExploreUIMediator:OnHide(param)
    self.inputfieldInputQuantity.onValueChanged:RemoveListener(Delegate.GetOrCreate(self, self.OnInputValueChanged))
    self.inputfieldInputQuantity.onEndEdit:RemoveListener(Delegate.GetOrCreate(self, self.OnInputSubmit))
end

function MapFogLodExploreUIMediator:UpdateGoTo()
    
end

function MapFogLodExploreUIMediator:UpdateItemSlideBar()
    local itemID = ConfigRefer.ConstMain:AddExploreValueItemId()
    local itemCount = ModuleRefer.MapFogModule:GetUnlockItemCount()
    local itemIcon = ConfigRefer.Item:Find(itemID):Icon()
    local maxExploreNum = ModuleRefer.MapFogModule:GetMaxUnlockCount()
    local initNum = maxExploreNum

    ---@type CommonNumberSliderData
    local sliderData = {}
    sliderData.curNum = initNum
    sliderData.minNum = 1
    sliderData.maxNum = maxExploreNum
    sliderData.oneStepNum = 1
    sliderData.callBack = Delegate.GetOrCreate(self, self.OnSliderValueChanged)
    self.compChildSetBar:FeedData(sliderData)

    self.textInputQuantity.text = "/" .. tostring(maxExploreNum)
    self.inputfieldInputQuantity.text = tostring(initNum)
    self.inputfieldInputQuantity.onValueChanged:AddListener(Delegate.GetOrCreate(self, self.OnInputValueChanged))
    self.inputfieldInputQuantity.onEndEdit:AddListener(Delegate.GetOrCreate(self, self.OnInputSubmit))

    self:RefreshItemQuantity(initNum)

    ---@type BistateButtonParameter
    local buttonData = {}
    buttonData.buttonText = I18N.Get("mist_btn_explore")
    buttonData.onClick = Delegate.GetOrCreate(self, self.OnExploreClicked)
    self.compChildCompB:FeedData(buttonData)
    g_Game.SpriteManager:LoadSprite(itemIcon, self.imgItemIconReq)

    ---@type CommonResourceBtnData
    local resourceButtonData = {}
    resourceButtonData.iconName = itemIcon
    resourceButtonData.content = tostring(itemCount)
    resourceButtonData.isShowPlus = true
    resourceButtonData.onClick = function()
        local toastParameter = {}
        toastParameter.clickTransform = self.compChildCommonResource.CSComponent.transform
        toastParameter.content = ModuleRefer.MapFogModule:ShowUnlockItemTip()
        ModuleRefer.ToastModule:ShowTextToast(toastParameter)
    end
    self.compChildCommonResource:FeedData(resourceButtonData)
end

function MapFogLodExploreUIMediator:OnSliderValueChanged(value)
    self.inputfieldInputQuantity.text = tostring(value)
end

function MapFogLodExploreUIMediator:OnInputValueChanged(strValue)
    local inputValue = tonumber(strValue)
    if inputValue then
        self.compChildSetBar:ChangeCurNum(inputValue)
        self.compChildSetBar:IgnoreChangeSliderValue()
        self:RefreshItemQuantity(inputValue)
    end

end

function MapFogLodExploreUIMediator:OnInputSubmit()
    local maxExploreNum = ModuleRefer.MapFogModule:GetMaxUnlockCount()

    local inputValue = tonumber(self.inputfieldInputQuantity.text)
    if inputValue < 0 or inputValue > maxExploreNum then
        inputValue = math.clamp(inputValue, 0, maxExploreNum)
        self.inputfieldInputQuantity.text = tostring(inputValue)
        self:RefreshItemQuantity(inputValue)
    end
end

function MapFogLodExploreUIMediator:OnExploreClicked()
    g_Game.UIManager:CloseByName(UIMediatorNames.RadarMediator)
    self:CloseSelf()

    local basicCamera = KingdomMapUtils.GetBasicCamera()
    basicCamera.enableDragging = false
    basicCamera.enablePinch = false
    
    local unlockCount = self.compChildSetBar.curNum
    local mists = ModuleRefer.MapFogModule:GetNeighborMistsCanUnlock(unlockCount)
    local zoomOutDuration = 0.5
    local unlockDuration = 2.5
    ModuleRefer.MapFogModule.isPlayingMultiUnlockEffect = true
    ModuleRefer.MapFogModule:LookAtMists(mists, zoomOutDuration, function()
        ModuleRefer.MapFogModule:UnlockMistCell(mists)
    end)

    TimerUtility.DelayExecute(function()
        basicCamera.enableDragging = true
        basicCamera.enablePinch = true
        ModuleRefer.MapFogModule.isPlayingMultiUnlockEffect = false
    end, unlockDuration + zoomOutDuration)

end

function MapFogLodExploreUIMediator:RefreshItemQuantity(currentValue)
    local costPerMistCell =  ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    local itemID = ConfigRefer.ConstMain:AddExploreValueItemId()
    local itemCount = ModuleRefer.MapFogModule:GetUnlockItemCount()
    local isRed = itemCount < currentValue * costPerMistCell

    if isRed then
        self.textItemCountRed:SetVisible(true)
        self.textItemCount:SetVisible(false)
        self.textItemCountRed.text = tostring(itemCount)
    else
        self.textItemCountRed:SetVisible(false)
        self.textItemCount:SetVisible(true)
        self.textItemCount.text = tostring(itemCount)
    end
    self.textItemCountReq.text = "/" .. tostring(currentValue * costPerMistCell)
end

function MapFogLodExploreUIMediator:OnItemIconClick()
    ---@type CommonItemDetailsParameter
    local param = {}
    param.clickTransform = self.btnItemIcon.transform
    param.itemId = ConfigRefer.ConstMain:AddExploreValueItemId()
    param.itemType = require("CommonItemDetailsDefine").ITEM_TYPE.ITEM
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function MapFogLodExploreUIMediator:OnReleaseItemIcon()
    g_Game.UIManager:CloseByName(UIMediatorNames.PopupItemDetailsUIMediator)
end

function MapFogLodExploreUIMediator:OnCancelClicked()
    self:CloseSelf()
end

function MapFogLodExploreUIMediator:OnGotoClicked()
    ModuleRefer.MapFogModule:GotoCastleNearestMist()
end

return MapFogLodExploreUIMediator