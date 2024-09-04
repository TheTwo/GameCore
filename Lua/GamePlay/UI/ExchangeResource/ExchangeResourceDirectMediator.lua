---scene: scene_getmore_popup_resources_buy
local BaseUIMediator = require ('BaseUIMediator')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local CastleWorkSpeedUpByItemsParameter = require("CastleWorkSpeedUpByItemsParameter")
local ExchangeResourceStatic = require('ExchangeResourceStatic')
local ClientDataKeys = require('ClientDataKeys')
local UseMultiItemsParameter = require('UseMultiItemsParameter')
local SupplyItemDataProvider = require('SupplyItemDataProvider')
local FPXSDKBIDefine = require('FPXSDKBIDefine')
---@class ExchangeResourceDirectMediator : BaseUIMediator
local ExchangeResourceDirectMediator = class('ExchangeResourceDirectMediator', BaseUIMediator)

---@class ExchangeResourceDirectMediatorParam
---@field itemInfos ExchangeResourceMediatorItemInfo[]
---@field type number
---@field isFromHUD boolean
---@field userData any
---@field isOverflow boolean

function ExchangeResourceDirectMediator:ctor()
    self.errorFlag = false
    self.noMoreDisplay = false
    self.exitWithRequestSuccess = false
    self.setBarValue = 1
end

function ExchangeResourceDirectMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_m')
    self.textDetail = self:Text('p_text_detail', I18N.Get("getmore_text_01"))
    self.tableviewproTableResources = self:TableViewPro('p_table_resources')
    self.textNum = self:Text('p_text_num')
    self.imgIconResource = self:Image('p_icon_resource')
    ---@see BistateButton
    self.compChildCompB = self:LuaObject('child_comp_btn_b')

    self.goSliderBar = self:GameObject('p_group_set_bar')
    ---@see CommonNumberSlider
    self.luaSliderBar = self:LuaObject('child_set_bar')
    self.inputField = self:InputField('p_Input_quantity', nil, Delegate.GetOrCreate(self, self.OnEditEnd))
    self.textMaxQuantity = self:Text('p_text_input_quantity')

    self.goHint = self:GameObject('p_hint')
    self.toggle = self:Toggle("child_toggle", Delegate.GetOrCreate(self, self.OnToggle))
    self.textToggle = self:Text("p_text_hint", I18N.Get("alliance_battle_confirm2"))
end

---@param param ExchangeResourceMediatorItemInfo[] | ExchangeResourceDirectMediatorParam
function ExchangeResourceDirectMediator:OnShow(param)
    if not param then
        return
    end
    self.userdata = param.userData
    self.itemInfos = param.itemInfos or param
    self.isFromHUD = param.isFromHUD
    self.isOverflow = param.isOverflow
    self.type = param.type or ExchangeResourceStatic.DirectExchangePanelType.Default
    if self.type == ExchangeResourceStatic.DirectExchangePanelType.Default then
        self:InitDefault()
    elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.Supply then
        self:InitSupply()
    elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.SpeedUp then
        self:InitSpeedUp()
    elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.PayAndUse then
        self:InitPayAndUse()
    end
    g_Game.ServiceManager:AddResponseCallback(ExchangeMultiItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnExchange))
    g_Game.ServiceManager:AddResponseCallback(CastleWorkSpeedUpByItemsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnSpeedUp))
end

function ExchangeResourceDirectMediator:InitDefault()
    self.compChildPopupBaseM:FeedData({title = I18N.Get("getmore_title_c")})
    local costItemId
    local totalCost = 0
    self.goSliderBar:SetActive(false)
    self.goHint:SetActive(false)
    self.tableviewproTableResources:Clear()
    for _, item in ipairs(self.itemInfos) do
        local itemCfg = ConfigRefer.Item:Find(item.id)
        local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
        if not getMoreCfg then
            g_Logger.Error("GetMoreConfig is nil, itemId:%s", item.id)
            return
        end
        costItemId = getMoreCfg:Exchange():Currency()
        local costNum = getMoreCfg:Exchange():CurrencyCount()
        local exchangeNum = getMoreCfg:Exchange():Count()
        if exchangeNum <= 0 then
            exchangeNum = 1
        end
        local exchangeInt = math.ceil((item.num / exchangeNum))
        local realExchangeNum = exchangeInt * exchangeNum
        totalCost = totalCost + exchangeInt * costNum
        local iconData = {}
        iconData.configCell = itemCfg
        iconData.count = realExchangeNum
        iconData.showTips = true
        self.tableviewproTableResources:AppendData(iconData)
    end
    local costCfg = ConfigRefer.Item:Find(costItemId)
    if costCfg then
        g_Game.SpriteManager:LoadSprite(costCfg:Icon(), self.imgIconResource)
    end
    self.textNum.text = totalCost
    local upButton = {}
    upButton.buttonText =  I18N.Get("getmore_botton_01")
    upButton.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    self.compChildCompB:FeedData(upButton)
    local isEnough = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId) >= totalCost
    self.compChildCompB:SetEnabled(isEnough)
end

function ExchangeResourceDirectMediator:InitSupply()
    self.compChildPopupBaseM:FeedData({title = I18N.Get("getmore_name_yijianbuchong")})
    self.tableviewproTableResources:Clear()
    self.goSliderBar:SetActive(false)
    self.goHint:SetActive(true)
    self.textDetail.text = I18N.Get("speedup_desc_02")
    if self.isOverflow then
        self.textDetail.text = self.textDetail.text .. "\n" .. I18N.Get("popup_speedup_tips")
    end
    for _, item in ipairs(self.itemInfos) do
        local itemCfg = ConfigRefer.Item:Find(item.id)
        local iconData = {}
        iconData.configCell = itemCfg
        iconData.count = item.num
        iconData.showTips = true
        self.tableviewproTableResources:AppendData(iconData)
    end
    local upButton = {}
    upButton.buttonText =  I18N.Get("getmore_botton_01")
    upButton.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    self.compChildCompB:FeedData(upButton)
    self.compChildCompB:SetEnabled(true)
end

function ExchangeResourceDirectMediator:InitSpeedUp()
    self.compChildPopupBaseM:FeedData({title = I18N.Get("speedup_title_2")})
    self.tableviewproTableResources:Clear()
    self.goSliderBar:SetActive(false)
    self.goHint:SetActive(true)
    self.textDetail.text = I18N.Get("speedup_des_3")
    if self.isOverflow then
        self.textDetail.text = self.textDetail.text .. "\n" .. I18N.Get("popup_speedup_tips")
    end
    for _, item in ipairs(self.itemInfos) do
        local itemCfg = ConfigRefer.Item:Find(item.id)
        local iconData = {}
        iconData.configCell = itemCfg
        iconData.count = item.num
        iconData.showTips = true
        self.tableviewproTableResources:AppendData(iconData)
    end
    local upButton = {}
    upButton.buttonText =  I18N.Get("speedup_title_2")
    upButton.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    self.compChildCompB:FeedData(upButton)
    self.compChildCompB:SetEnabled(true)
end

function ExchangeResourceDirectMediator:InitPayAndUse()
    self.goHint:SetActive(false)
    self.goSliderBar:SetActive(true)
    local item = self.itemInfos[1]

    local maxNum
    if self.isFromHUD then
        maxNum = math.min(item.num, 99)
    else
        maxNum = item.num
    end

    ---@type CommonNumberSliderData
    local setBarData = {}
    setBarData.minNum = 1
    setBarData.maxNum = maxNum
    setBarData.curNum = 1
    setBarData.callBack = Delegate.GetOrCreate(self, self.OnSetBarValueChanged)
    self.luaSliderBar:FeedData(setBarData)
    self.textMaxQuantity.text = ("/%d"):format(maxNum)
    self.inputField.text = "1"
    local itemCfg = ConfigRefer.Item:Find(item.id)
    ---@type ItemIconData
    local iconData = {}
    iconData.configCell = itemCfg
    iconData.showCount = false
    self.tableviewproTableResources:Clear()
    self.tableviewproTableResources:AppendData(iconData)
    self.GetMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.buttonText = I18N.Get("getmore_name_buyanduse")
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    local currencyId, currencyNum = ExchangeResourceStatic.GetExchangeCurrencyItemIdAndSingleNum(item.id)
    if currencyId > 0 then
        local currencyCfg = ConfigRefer.Item:Find(currencyId)
        btnData.icon = currencyCfg:Icon()
        btnData.num1 = currencyNum
        btnData.num2 = ModuleRefer.InventoryModule:GetAmountByConfigId(currencyId)
    end
    if btnData.num2 < btnData.num1 then
        btnData.onClick = function ()
            ModuleRefer.ConsumeModule:GotoShop()
        end
    end
    self.compChildCompB:FeedData(btnData)
end

function ExchangeResourceDirectMediator:OnClickBtn()
    if self.type == ExchangeResourceStatic.DirectExchangePanelType.Default then
        self:OnClickBtnDefault()
    elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.Supply then
        self:OnClickBtnSupply()
    elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.SpeedUp then
        self:OnClickBtnSpeedUp()
    elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.PayAndUse then
        self:OnClickBtnPayAndUse()
    end
end

function ExchangeResourceDirectMediator:OnClickBtnDefault()
    local parameter = ExchangeMultiItemParameter.new()
    for _, item in ipairs(self.itemInfos) do
        parameter.args.TargetItemConfigId:Add(item.id)
        parameter.args.TargetItemCount:Add(item.num)
    end
    parameter:Send()
end

function ExchangeResourceDirectMediator:OnClickBtnSupply()
    local parameter = UseMultiItemsParameter.new()
    for _, item in ipairs(self.itemInfos) do
        local uid = ModuleRefer.InventoryModule:GetUidByConfigId(item.id)
        parameter.args.Ids2nums:Add(uid, item.num)
    end
    parameter:SendOnceCallback(self.compChildCompB.CSComponent.transform, nil, nil, function(_, isSuccess)
        self:CloseSelf()
    end)
end

function ExchangeResourceDirectMediator:OnClickBtnSpeedUp()
    local holder = self.userdata
    local data = {}

    local speedUpTime = 0
    for _, item in ipairs(self.itemInfos) do
        data[item.id] = item.num
        speedUpTime = speedUpTime + item.supplyNum * item.num
    end

    local keyMap = FPXSDKBIDefine.ExtraKey.build_one_click_speed
    local extraDict = {}
    extraDict[keyMap.type] = holder:GetBIType()
    extraDict[keyMap.id] = holder:GetBIId()
    extraDict[keyMap.speed_time] = speedUpTime
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.build_one_click_speed, extraDict)

    holder:UseMultiItemSpeedUp(data)
    self:CloseSelf()
end

function ExchangeResourceDirectMediator:OnClickBtnPayAndUse()
    local item = self.itemInfos[1]
    local currencyId, currencyNum = ExchangeResourceStatic.GetExchangeCurrencyItemIdAndSingleNum(item.id)
    if currencyId <= 0 then
        g_Logger.ErrorChannel("ExchangeResourceDirectMediator", "Can't find currency id for exchanging, itemId:%s", item.id)
        return
    end
    local parameter = ExchangeMultiItemParameter.new()
    parameter.args.TargetItemConfigId:Add(item.id)
    parameter.args.TargetItemCount:Add(self.setBarValue)
    parameter:SendOnceCallback(self.compChildCompB.CSComponent.transform, nil, nil, function(_, isSuccess)
        if isSuccess then
            if self.userdata then
                self.userdata:UseItemSpeedUp(item.id, self.setBarValue)
            else
                local provider = SupplyItemDataProvider.new(item.id)
                provider:Use(self.setBarValue)
            end
            self.exitWithRequestSuccess = true
            self:CloseSelf()
        end
    end)
end

function ExchangeResourceDirectMediator:OnSetBarValueChanged(value)
    self.setBarValue = value
    self.inputField.text = value
    local item = self.itemInfos[1]
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.buttonText = I18N.Get("getmore_name_buyanduse")
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    local currencyId, currencyNum = ExchangeResourceStatic.GetExchangeCurrencyItemIdAndSingleNum(item.id)
    if currencyId > 0 then
        local currencyCfg = ConfigRefer.Item:Find(currencyId)
        btnData.icon = currencyCfg:Icon()
        btnData.num1 = currencyNum * value
        btnData.num2 = ModuleRefer.InventoryModule:GetAmountByConfigId(currencyId)
    end
    if btnData.num2 < btnData.num1 then
        btnData.onClick = function ()
            ModuleRefer.ConsumeModule:GotoShop()
        end
    end
    self.compChildCompB:FeedData(btnData)
end

function ExchangeResourceDirectMediator:OnEditEnd(text)
    local value = tonumber(text)
    if not value then value = 1 end
    local item = self.itemInfos[1]
    local max = item.num
    value = math.clamp(value, 1, max)
    self.luaSliderBar:OutInputChangeSliderValue(value)
    self:OnSetBarValueChanged(value)
end

function ExchangeResourceDirectMediator:OnToggle(isOn)
    self.noMoreDisplay = isOn
end

function ExchangeResourceDirectMediator:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(ExchangeMultiItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnExchange))
    g_Game.ServiceManager:RemoveResponseCallback(CastleWorkSpeedUpByItemsParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnSpeedUp))
end

function ExchangeResourceDirectMediator:OnClose()
    if self.noMoreDisplay then
        local curTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
        if self.type == ExchangeResourceStatic.DirectExchangePanelType.Supply then
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.NoMoreDisplayExchangePanel_Supply, tostring(curTimeSec))
        elseif self.type == ExchangeResourceStatic.DirectExchangePanelType.SpeedUp then
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.NoMoreDisplayExchangePanel_SpeedUp, tostring(curTimeSec))
        end
    end
end

function ExchangeResourceDirectMediator:OnExchange(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    self:CloseSelf()
end

function ExchangeResourceDirectMediator:OnSpeedUp(isSuccess, reply, rpc)
    if isSuccess then
        self.exitWithRequestSuccess = true
        self:CloseSelf()
    end
end

return ExchangeResourceDirectMediator