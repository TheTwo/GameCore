local BaseTableViewProCell = require('BaseTableViewProCell')
local ExchangeResourceStatic = require('ExchangeResourceStatic')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local SupplyItemDataProvider = require('SupplyItemDataProvider')
---@class ItemUseOrPayCell:BaseTableViewProCell
local ItemUseOrPayCell = class('ItemUseOrPayCell', BaseTableViewProCell)

---@class ItemUseOrPayCellData
---@field type number
---@field info ExchangeResourceMediatorItemInfo
---@field isFromHUD boolean

function ItemUseOrPayCell:ctor()
    self.btnArgs = nil
end

function ItemUseOrPayCell:OnCreate()
    ---@see BaseItemIcon
    self.luaItem = self:LuaObject('child_item_standard_s')
    self.imgItemIcon = self:Image('p_icon')
    self.textItemName = self:Text('p_text_item_name')
    self.textInfo = self:Text('p_text_info')
    self.btnGoto = self:Button('child_comp_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto')
    self.btnPay = self:Button('p_btn_pay', Delegate.GetOrCreate(self, self.OnBtnPayClicked))
    self.goGroupBubble = self:GameObject('p_goup_bubble')
    self.btnBubble = self:Button('p_goup_bubble', Delegate.GetOrCreate(self, self.OnBtnBubbleClicked))
    self.textBubble = self:Text('p_text_bubble')
    self.statusCtrler = self:StatusRecordParent("")
    self.textBtnPay = self:Text('p_text_e')
    self.imgIconPay = self:Image('p_icon_e')
    self.textNumPayGreen = self:Text('p_text_num_green_e')
    self.textNumPayRed = self:Text('p_text_num_red_e')
    self.textNumPay = self:Text('p_text_num_e')
end

---@param data ItemUseOrPayCellData
function ItemUseOrPayCell:OnFeedData(data)
    self.type = data.type
    self.data = data
    if self.type == ExchangeResourceStatic.CellType.Supply then
        self:InitSupplyCell(data)
    elseif self.type == ExchangeResourceStatic.CellType.Pay then
        self:InitPayCell(data)
    elseif self.type == ExchangeResourceStatic.CellType.OneKeySupply then
        self:InitOneKeySupplyCell(data)
    elseif self.type == ExchangeResourceStatic.CellType.Harvest then
        self:InitHarvestCell(data)
    elseif self.type == ExchangeResourceStatic.CellType.PayAndUse then
        self:InitPayAndUseCell(data)
    end
end

---@param data ItemUseOrPayCellData
function ItemUseOrPayCell:InitSupplyCell(data)
    self.statusCtrler:ApplyStatusRecord(2)
    local itemCfgId = data.info.id
    local provider = SupplyItemDataProvider.new(itemCfgId, self.btnGoto.transform)
    self.btnArgs = {}
    self.btnArgs.provider = provider
    local cur = provider:GetInventoryQuantity()
    local needed = data.info.num // provider:GetSupplyQuantity()
    local maxUsageNum = math.min(cur, needed)
    self.goGroupBubble:SetActive(maxUsageNum > 0)
    self.textBubble.text = ("x%d"):format(maxUsageNum)
    self.btnArgs.maxUsageNum = maxUsageNum
    ---@type ItemIconData
    local iconData = {}
    iconData.configCell = ConfigRefer.Item:Find(itemCfgId)
    iconData.showCount = false
    iconData.count = cur
    self.luaItem:FeedData(iconData)
    self.textItemName.text = I18N.Get(iconData.configCell:NameKey())
    self.textInfo.text = I18N.Get(iconData.configCell:DescKey())
    self.textGoto.text = I18N.Get("/*使用")
end

---@param data ItemUseOrPayCellData
function ItemUseOrPayCell:InitPayCell(data)
    self.statusCtrler:ApplyStatusRecord(1)
    local itemCfg = ConfigRefer.Item:Find(data.info.id)
    local itemName = I18N.Get(itemCfg:NameKey())
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    local exchangeCfg = getMoreCfg:Exchange()
    if not exchangeCfg then return end
    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgItemIcon)
    self.textItemName.text = itemName
    self.textInfo.text = I18N.GetWithParams("getmore_des_yijianbuchong", itemName, data.info.num)
    self.textBtnPay.text = I18N.Get("/*购买")
    local currencyId = exchangeCfg:Currency()
    local currencyCfg = ConfigRefer.Item:Find(currencyId)
    self.currencyCfg = currencyCfg
    self.neededCurrency = exchangeCfg:CurrencyCount() * data.info.num
    self.curCurrency = ModuleRefer.InventoryModule:GetAmountByConfigId(currencyId)
    g_Game.SpriteManager:LoadSprite(currencyCfg:Icon(), self.imgIconPay)
    self.textNumPay.text = (" / %d"):format(self.neededCurrency)
    self.textNumPayGreen.text = self.curCurrency
    self.textNumPayRed.text = self.curCurrency
    self.textNumPayGreen.gameObject:SetActive(self.curCurrency >= self.neededCurrency)
    self.textNumPayRed.gameObject:SetActive(self.curCurrency < self.neededCurrency)
end

---@param data ItemUseOrPayCellData
function ItemUseOrPayCell:InitOneKeySupplyCell(data)
    self.statusCtrler:ApplyStatusRecord(0)
    local itemCfg = ConfigRefer.Item:Find(data.info.id)
    local itemName = I18N.Get(itemCfg:NameKey())
    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgItemIcon)
    self.textGoto.text = I18N.Get("getmore_name_yijianbuchong")
    self.textItemName.text = itemName
    self.textInfo.text = I18N.GetWithParams("getmore_des_yijianbuchong", itemName, data.info.num)
end

function ItemUseOrPayCell:InitHarvestCell(data)
    self.statusCtrler:ApplyStatusRecord(2)
    self.textItemName.text = I18N.Get("/*收取产出")
    self.textGoto.text = I18N.Get("/*收取")
    self.textInfo.text = I18N.Get("/*收取产出")
    self.goGroupBubble:SetActive(false)
    ---@type ItemIconData
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(data.info.id)
    itemData.showCount = false
    self.luaItem:FeedData(itemData)
end

function ItemUseOrPayCell:InitPayAndUseCell(data)
    self.statusCtrler:ApplyStatusRecord(3)
    local itemCfgId = data.info.id
    local itemCfg = ConfigRefer.Item:Find(itemCfgId)
    ---@type ItemIconData
    local iconData = {}
    iconData.configCell = ConfigRefer.Item:Find(itemCfgId)
    iconData.showCount = false
    iconData.count = 0
    self.luaItem:FeedData(iconData)
    self.textItemName.text = I18N.Get(iconData.configCell:NameKey())
    self.textInfo.text = I18N.Get(iconData.configCell:DescKey())
    self.textBtnPay.text = I18N.Get("getmore_name_buyanduse")
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return end
    local exchangeCfg = getMoreCfg:Exchange()
    if not exchangeCfg then return end
    local currencyId = exchangeCfg:Currency()
    local currencyCfg = ConfigRefer.Item:Find(currencyId)
    self.currencyCfg = currencyCfg
    self.neededCurrency = exchangeCfg:CurrencyCount()
    self.curCurrency = ModuleRefer.InventoryModule:GetAmountByConfigId(currencyId)
    g_Game.SpriteManager:LoadSprite(currencyCfg:Icon(), self.imgIconPay)
    self.textNumPay.text = ("")
    self.textNumPayGreen.text = self.neededCurrency
    self.textNumPayRed.text = self.neededCurrency
    self.textNumPayGreen.gameObject:SetActive(self.curCurrency >= self.neededCurrency)
    self.textNumPayRed.gameObject:SetActive(self.curCurrency < self.neededCurrency)
end

function ItemUseOrPayCell:OnBtnPayClicked()
    if self.type == ExchangeResourceStatic.CellType.PayAndUse then
        self:OnBtnPayClicked_PayAndUse()
    elseif self.type == ExchangeResourceStatic.CellType.Pay then
        self:OnBtnPayClicked_Pay()
    end
end

function ItemUseOrPayCell:OnBtnPayClicked_Pay()
    if self.curCurrency < self.neededCurrency then
        local lackNum = self.neededCurrency - self.curCurrency
        local coinName = I18N.Get(self.currencyCfg:NameKey())
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("getmore_title_c")
        dialogParam.content = I18N.GetWithParams("gacha_insufficient_tips_2", lackNum, coinName)
        dialogParam.onConfirm = function ()
            g_Game.UIManager:Open(UIMediatorNames.ActivityShopMediator, {tabId = 9})
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        local parameter = ExchangeMultiItemParameter.new()
        parameter.args.TargetItemConfigId:Add(self.data.info.id)
        parameter.args.TargetItemCount:Add(self.data.info.num)
        parameter:Send()
    end
end

function ItemUseOrPayCell:OnBtnPayClicked_PayAndUse()
    local id = self.data.info.id
    local provider = SupplyItemDataProvider.new(id)
    local expectedNum = math.ceil(self.data.info.num / provider:GetSupplyQuantity())
    ---@type ExchangeResourceDirectMediatorParam
    local data = {}
    data.itemInfos = {{id = id, num = expectedNum}}
    data.type = ExchangeResourceStatic.DirectExchangePanelType.PayAndUse
    data.isFromHUD = self.data.isFromHUD
    g_Game.UIManager:Open(UIMediatorNames.ExchangeResourceDirectMediator, data)
end

function ItemUseOrPayCell:OnBtnGotoClicked()
    if self.type == ExchangeResourceStatic.CellType.Supply then
        ---@type SupplyItemDataProvider
        local provider = self.btnArgs.provider
        provider:Use(1)
    elseif self.type == ExchangeResourceStatic.CellType.OneKeySupply then
        local itemSupplyInfo = {}
        local itemCfg = ConfigRefer.Item:Find(self.data.info.id)
        local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
        for i = 1, getMoreCfg:SupplyItemLength() do
            local id = getMoreCfg:SupplyItem(i)
            local provider = SupplyItemDataProvider.new(id)
            ---@type ItemSupplyInfo
            local data = {}
            data.id = id
            data.supplyNum = provider:GetSupplyQuantity()
            data.inventory = provider:GetInventoryQuantity()
            if data.inventory > 0 then
                itemSupplyInfo[#itemSupplyInfo + 1] = data
            end
        end
        local cost = ExchangeResourceStatic.GetOneKeySupplyCost(itemSupplyInfo, self.data.info.num)
        ---@type ExchangeResourceDirectMediatorParam
        local exchangeData = {}
        exchangeData.itemInfos = cost
        exchangeData.type = ExchangeResourceStatic.DirectExchangePanelType.Supply
        g_Game.UIManager:Open(UIMediatorNames.ExchangeResourceDirectMediator, exchangeData)
    elseif self.type == ExchangeResourceStatic.CellType.Harvest then
        ModuleRefer.CityModule.myCity:ClaimTargetResAutoGenStock(self.data.info.id)
    elseif self.type == ExchangeResourceStatic.CellType.PayAndUse then
    end
end

function ItemUseOrPayCell:OnBtnBubbleClicked()
    if self.type == ExchangeResourceStatic.CellType.Supply then
        ---@type SupplyItemDataProvider
        local provider = self.btnArgs.provider
        provider:Use(self.btnArgs.maxUsageNum)
    end
end

return ItemUseOrPayCell