---scene: scene_common_popup_buy
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ArtResourceUtils = require('ArtResourceUtils')
local ActivityShopConst = require('ActivityShopConst')
local BaseShopItemDetailDataProvider = require('BaseShopItemDetailDataProvider')
---@class UIShopBuyPopupMeidator : BaseUIMediator
local UIShopBuyPopupMeidator = class('UIShopBuyPopupMeidator', BaseUIMediator)

---@class UIShopBuyPopupCommodityParameter
---@field provider BaseShopItemDetailDataProvider
---@field title string

function UIShopBuyPopupMeidator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_m')
    self.imgItem = self:Image('p_item')
    self.imgItemSmall = self:Image('p_item_s')
    self.textName = self:Text('p_text_name')
    self.goMoney = self:GameObject('money')
    self.goMoney1 = self:GameObject('money_1')

    self.goOld1 = self:GameObject('p_old_1')
    self.goNew1 = self:GameObject('p_new_1')
    self.goOld2 = self:GameObject('p_old_2')
    self.goNew2 = self:GameObject('p_new_2')

    self.imgIconMoney1 = self:Image('p_icon_money_1')
    self.textMoney1 = self:Text('p_text_money_1')
    self.textMoneyOld1 = self:Text('p_text_money_old_1')
    self.imgIconOldMoney1 = self:Image('p_icon_money_old_1')
    self.goMoney2 = self:GameObject('money_2')
    self.imgIconMoney2 = self:Image('p_icon_money_2')
    self.imgIconOldMoney2 = self:Image('p_icon_money_old_2')
    self.textMoney2 = self:Text('p_text_money_2')
    self.textMoneyOld2 = self:Text('p_text_money_old_2')
    self.goSold = self:GameObject('p_sold')
    self.textSold = self:Text('p_text_sold', I18N.Get("shop_soldout"))
    self.textDetail = self:Text('p_text_detail')
    self.textDetailCellSize = self:BindComponent('p_text_detail', typeof(CS.CellSizeComponent))
    self.inputfieldInputQuantity = self:InputField('p_Input_quantity', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.textInput = self:Text('p_text_input')
    self.textLimited = self:Text('p_text_limited', I18N.Get("shop_purchaselimited"))
    self.textLimit = self:Text('p_text_limit', I18N.Get("shop_purchaselimited"))
    self.textInputQuantity = self:Text('p_text_input_quantity')
    self.compChildSetBar = self:LuaBaseComponent('child_set_bar')
    self.btnLeftS = self:Button('p_left_s', Delegate.GetOrCreate(self, self.OnBtnLeftSClicked))
    self.btnLeftD = self:Button('p_left_d', Delegate.GetOrCreate(self, self.OnBtnLeftDClicked))
    self.imgLeftIcon = self:Image('p_left_icon')
    self.textLeft = self:Text('p_left_text')
    self.goRight = self:GameObject('p_right_btn')
    self.goLeft = self:GameObject('p_left_btn')
    self.btnRightS = self:Button('p_right_s', Delegate.GetOrCreate(self, self.OnBtnRightSClicked))
    self.btnRightD = self:Button('p_right_d', Delegate.GetOrCreate(self, self.OnBtnRightDClicked))
    self.imgRightIcon = self:Image('p_right_icon')
    self.textRight = self:Text('p_right_text')
    self.goCapsule = self:GameObject('capsule')
    self.compChildCapsule = self:LuaBaseComponent('child_btn_capsule_editor_1')
    self.compChildCapsule1 = self:LuaBaseComponent('child_btn_capsule_editor_2')
    self.goDiscount = self:GameObject('p_discount')
    self.textDiscount = self:Text('p_text_discount')
    self.resourceList = {self.compChildCapsule, self.compChildCapsule1}

    self.tableItems = self:TableViewPro('p_table_detail')
    self.btnBuy = self:Button('p_btn_buy', Delegate.GetOrCreate(self, self.OnBtnBuyClicked))
    self.textBtnBuy = self:Text('p_text_e')

    self.goNumSlider = self:GameObject('p_num_sel')
    self.discountTag = self:LuaBaseComponent('child_shop_discount_tag')
    self.imgQualityBaseGift = self:Image('p_base_gift')
    self.imgQualityBaseStore = self:Image('p_frame')

    self.btnExchange = self:Button('p_btn_recharge_points')
    self.textExchangeNum = self:Text('p_text_num')

    self.imgCircle = self:Image('p_circle')
    self.imgLine = self:Image('p_line')

    self.btnsDisplayCtrl = {
        self.goLeft,
        self.goRight,
        self.btnBuy.gameObject
    }
end

---@param param UIShopBuyPopupCommodityParameter
function UIShopBuyPopupMeidator:OnOpened(param)
    if not param then
        return
    end
    self.provider = param.provider
    self:InitCommon(param)
end

---@param param UIShopBuyPopupCommodityParameter
function UIShopBuyPopupMeidator:InitCommon(param)
    local provider = param.provider
    local title = I18N.Get(param.title)

    self.compChildPopupBaseM:FeedData({title = title})

    self:InitItemInfoLeft(provider)
    self:InitInfoTable(provider)
    self:InitInfoBottom(provider)
    self:InitResource(provider)
end

---@param provider BaseShopItemDetailDataProvider
function UIShopBuyPopupMeidator:InitItemInfoLeft(provider)
    -- 商品图片
    self.imgItem.gameObject:SetActive(not provider:UseSmallItemIcon())
    self.imgItemSmall.gameObject:SetActive(provider:UseSmallItemIcon())

    self.imgQualityBaseGift.gameObject:SetActive(provider:UseGiftBase())
    self.imgQualityBaseStore.gameObject:SetActive(provider:UseStoreBase())

    local icon = provider:GetIcon()

    if type(icon) == 'number' then
        icon = ArtResourceUtils.GetUIItem(icon)
    end
    if provider:UseSmallItemIcon() then
        g_Game.SpriteManager:LoadSprite(icon, self.imgItemSmall)
    else
        g_Game.SpriteManager:LoadSprite(icon, self.imgItem)
    end

    -- 限购
    local limit = provider:GetBuyLimit()
    if limit then
        self.textLimited.text = I18N.GetWithParams(ActivityShopConst.I18N_KEYS.LIMIT_TIMES, limit)
    end
    self.textLimited.gameObject:SetActive(limit > 0)

    -- 商品名
    self.textName.text = provider:GetName()

    -- 折扣信息
    if provider:UseCommonDiscountTag() then
        self.discountTag:SetVisible(true)
        local discountTagParam = provider:GetDiscountTagParam()
        self.discountTag:FeedData(discountTagParam)
    else
        self.discountTag:SetVisible(false)
        local discount = provider:GetDiscount()
        self.goDiscount:SetActive(discount > 0)
        self.textDiscount.text = "-" .. discount .. "%"
    end

    if provider:UseStoreBase() then
        local color = provider:GetQualityColor()
        self.imgQualityBaseStore.color = color
        self.imgCircle.color = color
        self.imgLine.color = color
    end
end

---@param provider BaseShopItemDetailDataProvider
function UIShopBuyPopupMeidator:InitInfoTable(provider)
    local desc = provider:GetDesc()
    local textHeight = CS.DragonReborn.UI.UIHelper.CalcTextHeight(desc, self.textDetail, self.textDetailCellSize.Width)
    self.tableItems:Clear()
    self.tableItems:AppendDataEx(desc, self.textDetailCellSize.Width, textHeight, 1)

    local itemList = provider:GetGoodsItemList()
    for _, item in ipairs(itemList) do
        self.tableItems:AppendData(item, 0)
    end

    local petPreviewDatas = provider:GetPetEggPreviewDatas()
    if petPreviewDatas and #petPreviewDatas > 0 then
        self.tableItems:AppendData(petPreviewDatas, 2)
    end
end

---@param provider BaseShopItemDetailDataProvider
function UIShopBuyPopupMeidator:InitInfoBottom(provider)
    local showSlider = provider:ShowSlider()
    local canBuyCount = provider:GetPurchaseableCount()
    if showSlider then
        local setBarData = {}
        setBarData.minNum = math.min(1, canBuyCount)
        setBarData.maxNum = canBuyCount or 99
        setBarData.oneStepNum = 1
        setBarData.curNum = math.min(1, canBuyCount)
        setBarData.intervalTime = 0.1
        setBarData.callBack = function(value)
            self:OnEndEdit(value)
        end
        self.compChildSetBar:FeedData(setBarData)
        self.inputfieldInputQuantity.text = math.min(1, canBuyCount)
    end
    self.goNumSlider:SetActive(showSlider and canBuyCount > 1)

    self.textInputQuantity.text = "/" .. canBuyCount

    local mask = provider:BtnShowMask()
    for i, btns in ipairs(self.btnsDisplayCtrl) do
        btns:SetActive((1 << (i - 1)) & mask > 0)
    end

    if (self.provider:BtnShowMask() & BaseShopItemDetailDataProvider.BtnShowBitMask.Center ~= 0) then
        self.textBtnBuy.text = I18N.Get(provider:GetPriceText())

        local exchangeNum = provider:GetExchangeNum()
        self.textExchangeNum.gameObject:SetActive(exchangeNum > 0)
        self.textExchangeNum.text = '+' .. exchangeNum
    else
        self:RefreshBtns(1)
    end
end

---@param provider BaseShopItemDetailDataProvider
function UIShopBuyPopupMeidator:InitResource(provider)
    local cfgs = provider:GetPriceItemCfgs()
    for i = 1, #self.resourceList do
        local isShow = i <= #cfgs
        self.resourceList[i].gameObject:SetActive(isShow)
        if isShow then
            local moneyId = cfgs[i]:Id()
            local moneyCfg = ConfigRefer.Item:Find(moneyId)
            local moneyCount = ModuleRefer.InventoryModule:GetAmountByConfigId(moneyId)
            local data = {}
            data.iconName = moneyCfg:Icon()
            data.content = moneyCount
            self.resourceList[i]:FeedData(data)
        end
    end
end

function UIShopBuyPopupMeidator:OnEndEdit(inputText)
    local canbuyCount = self.provider:GetPurchaseableCount()
    local inputNum = tonumber(inputText)
    if not inputNum or inputNum < 1 then
        inputNum = 1
    end
    if inputNum > canbuyCount then
        inputNum = canbuyCount
    end
    self.inputfieldInputQuantity.text = inputNum
    self.compChildSetBar.Lua:OutInputChangeSliderValue(inputNum)
    self:RefreshBtns(inputNum)
end

function UIShopBuyPopupMeidator:RefreshBtns(inputNum)
    if (self.provider:BtnShowMask() & BaseShopItemDetailDataProvider.BtnShowBitMask.Center ~= 0) then
        return
    end
    local priceItemCfgs = self.provider:GetPriceItemCfgs()
    local prices = self.provider:GetPrices()
    local moneyCost = prices[1]
    local moneyCount = ModuleRefer.InventoryModule:GetAmountByConfigId(priceItemCfgs[1]:Id())
    local isEnough = moneyCount >= moneyCost * inputNum and inputNum > 0
    self.btnLeftS.gameObject:SetActive(isEnough)
    self.btnLeftD.gameObject:SetActive(not isEnough)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(priceItemCfgs[1]:Id()):Icon(), self.imgLeftIcon)
    self.textLeft.text = moneyCost * inputNum
    local isSingleCost = #priceItemCfgs == 1
    self.goRight:SetActive(not isSingleCost)
    if not isSingleCost then
        local moneyCostId2 = priceItemCfgs[2]:Id()
        local moneyCost2 = prices[2]
        local moneyCount2 = ModuleRefer.InventoryModule:GetAmountByConfigId(moneyCostId2)
        local isEnough2 = moneyCount2 >= moneyCost2 * inputNum
        self.btnRightS.gameObject:SetActive(isEnough2)
        self.btnRightD.gameObject:SetActive(not isEnough2)
        g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(moneyCostId2):Icon(), self.imgRightIcon)
        self.textRight.text = moneyCost2 * inputNum
    end
end

function UIShopBuyPopupMeidator:OnBtnLeftSClicked()
    local id = self.provider:GetPriceItemCfgs()[1]:Id()
    self.provider:OnBuyClick(nil, id, tonumber(self.inputfieldInputQuantity.text))
    self:CloseSelf()
end

function UIShopBuyPopupMeidator:OnBtnLeftDClicked()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("shop_coin_insufficient"))
end

function UIShopBuyPopupMeidator:OnBtnRightSClicked()
    local id = self.provider:GetPriceItemCfgs()[2]:Id()
    self.provider:OnBuyClick(nil, id, tonumber(self.inputfieldInputQuantity.text))
    self:CloseSelf()
end

function UIShopBuyPopupMeidator:OnBtnRightDClicked()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("shop_coin_insufficient"))
end

function UIShopBuyPopupMeidator:OnBtnBuyClicked()
    self.provider:OnBuyClick()
    self:CloseSelf()
end

return UIShopBuyPopupMeidator
