local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local UseItemParameter = require('UseItemParameter')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local AcitivityShopType = require('AcitivityShopType')
local ConvertPieceToAdornmentParameter = require('ConvertPieceToAdornmentParameter')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ExchangeResourceStatic = require('ExchangeResourceStatic')
local CityWorkType = require('CityWorkType')
local UIHelper = require('UIHelper')
local TimeFormatter = require('TimeFormatter')

---@class UseItemCell:BaseTableViewProCell
local UseItemCell = class('UseItemCell',BaseTableViewProCell)

function UseItemCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaObject('child_item_standard_s')
    self.textItemName = self:Text('p_text_item_name')
    self.textInfo = self:Text('p_text_info')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.btnChildCompGoto = self:Button('child_comp_btn_goto', Delegate.GetOrCreate(self, self.OnBtnChildCompGotoClicked))
    self.textGoto = self:Text('p_text_goto', I18N.Get("energy_btn_use"))
    -- self.btnChildCompGoto.gameObject:SetActive(false)

    self.buttonBubble = self:Button("p_goup_bubble", Delegate.GetOrCreate(self, self.OnClickBubble))
    self.textBubble = self:Text("p_text_bubble")
    self.statusCtrler = self:StatusRecordParent("")
    self.imgIcon = self:Image('p_icon')

    self.btnPay = self:Button('p_btn_pay', Delegate.GetOrCreate(self, self.OnBtnPayClicked))
    self.textBtnPay = self:Text('p_text_e')
    self.imgIconPay = self:Image('p_icon_e')
    self.textNumPayGreen = self:Text('p_text_num_green_e')
    self.textNumPayRed = self:Text('p_text_num_red_e')
    self.textNumPay = self:Text('p_text_num_e')
end

function UseItemCell:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

function UseItemCell:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

function UseItemCell:OnRecycle()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
end

---@param param GetMoreItemCellDataProvider | GetMoreSupplyCellDataProvider
function UseItemCell:OnFeedData(param)
    self.provider = param

    self.statusCtrler:ApplyStatusRecord(param:GetStatusIndex())

    self.textItemName.text = param:GetName()
    self.textInfo.text = param:GetDesc()

    local data = {}
    data.buttonText = param:GetExchangeBtnText()
    data.onClick = function () param:OnExchange() end
    self.compChildCompB:FeedData(data)
    self.compChildCompB:SetEnabled(param:CanExchage())

    self.textBubble.text = param:GetBubbleText()
    self.buttonBubble:SetVisible(param:ShowBubble())

    if param:IsItemCell() then
        local curCurrency = param:GetCurrencyInventory()
        local singlePrice = param:GetSinglePrice()
        self.textBtnPay.text = param:GetPayButtonText()
        self.textNumPay.text = ("")
        self.textNumPayGreen.text = singlePrice
        self.textNumPayRed.text = singlePrice
        self.textNumPayGreen.gameObject:SetActive(curCurrency >= singlePrice)
        self.textNumPayRed.gameObject:SetActive(curCurrency < singlePrice)
        self.compChildItemStandardS:FeedData(param:GetIconData())
        g_Game.SpriteManager:LoadSprite(param:GetCurrencyIcon(), self.imgIconPay)
    elseif param:IsSupplyCell() then
        g_Game.SpriteManager:LoadSprite(param:GetIcon(), self.imgIcon)
    end

    if param:ShouldOverrideStatus() then
        self.compChildCompB:SetVisible(param:ShowExchange())
        self.btnChildCompGoto.gameObject:SetActive(param:ShowGoto())
        self.btnPay.gameObject:SetActive(param:ShowPay())
    end
end

function UseItemCell:OnBtnChildCompGotoClicked(args)
    self.provider:OnGoto()
end

function UseItemCell:OnBtnPayClicked()
    self.provider:OnPay()
end

function UseItemCell:OnClickBubble()
    self.provider:OnBubbleClick()
end

function UseItemCell:OnSecTick()
    if self.provider and self.provider:ShouldTickUpdate() then
        self.textInfo.text = self.provider:GetDesc()
    end
end

return UseItemCell
