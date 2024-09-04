local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local TimerUtility = require('TimerUtility')
local ActivityShopGemsCell = class('ActivityShopGemsCell',BaseTableViewProCell)

function ActivityShopGemsCell:OnCreate(param)
    self.imgPay = self:Image('p_btn_pay')
    self.btnPay = self:Button('p_btn_pay', Delegate.GetOrCreate(self, self.OnBtnPayClicked))
    self.imgIconCoin = self:Image('p_icon_coin')
    self.textQuantity = self:Text('p_text_quantity')
    self.imgIconCoinS = self:Image('p_icon_coin_s')
    self.textPrice = self:Text('p_text_price')
    self.goTag = self:GameObject('p_tag')
    self.goBaseFirst = self:GameObject('p_base_first')
    self.goBaseAdd = self:GameObject('p_base_add')
    self.textTag = self:Text('p_text_tag')
    self.textAdd = self:Text('p_text_add')
    self.textTagFirst = self:Text('p_text_tag_first')
    self.textAddFirst = self:Text('p_text_add_first')

    self.textExchangePoints = self:Text('p_text_num')
    self.goExchangePoints = self:GameObject('p_btn_recharge_points')
    ---@type CS.FpAnimation.FpAnimationCommonTrigger
    self.vxTrigger = self:AnimTrigger('p_tag')
    self.goTag:SetActive(true)
end

function ActivityShopGemsCell:OnFeedData(param)
    self.textPrice.text = ""
    self.textAdd.text = ""
    self.textQuantity.text = ""
    self.textTag.text = ""
    self.textTagFirst.text = ""
    self.textAddFirst.text = ""
    self.goodId = param.goodId
    self.isforbid = param.isforbid
    self.shouldPlayAnim = param.shouldPlayAnim or false
    local goodCfg = ConfigRefer.PayGoods:Find(self.goodId)
    self:LoadSprite(goodCfg:Icon(), self.imgIconCoin)
    self:LoadSprite(goodCfg:BaseIcon(), self.imgPay)
    local itemArray = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(goodCfg:ItemGroupId())
    local item = itemArray[1]
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(item.id):Icon(), self.imgIconCoinS)
    self.textQuantity.text = I18N.Get(goodCfg:Name())
    local payPlatformId = goodCfg:PayPlatformId()
    local payPlatformCfg = ConfigRefer.PayPlatform:Find(payPlatformId)
    local isUseFunplusDiamond = ModuleRefer.PayModule:IsUseFunplusDiamond()
    if isUseFunplusDiamond then
        self.textPrice.text = I18N.Get(payPlatformCfg:Name()) .. " " .. payPlatformCfg:FunplusDiamond()
    else
        local productInfos = ModuleRefer.PayModule:GetProductData(payPlatformCfg:FPXProductId())
        self.textPrice.text = productInfos.price
    end
    local isFirstDouble = goodCfg:IsFirstDouble()
    if isFirstDouble then
        self.textAddFirst.text = "+" .. item.count
    end
    self.textTagFirst.text = I18N.Get("top_up_tag_txt_1")
    local rewardItemGroupId = goodCfg:ExtraItemGroupId()
    if rewardItemGroupId > 0 then
        local rewardItemArray = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(rewardItemGroupId)
        local rewardItem = rewardItemArray[1]
        self.textTag.text = I18N.Get(ConfigRefer.Item:Find(rewardItem.id):NameKey())
        self.textAdd.text = "+" .. rewardItem.count
    end
    local isFirst = self:CheckIsFirst(self.goodId)
    if self.shouldPlayAnim then
        self:RefreshTagActive(true) -- 播放动画时，Tag显隐交给动画控制
        TimerUtility.DelayExecute(function ()
            self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        end, 1)
    else
        if not isFirst then
            self.vxTrigger:FinishAll(FpAnimTriggerEvent.Custom1)
        end
        self:RefreshTagActive(isFirst)
    end

    self.textExchangePoints.text = '+' .. ModuleRefer.ActivityShopModule:GetGoodsExchangePointsNum(self.goodId)
end

--- 根据是否首充刷新Tag显隐
---@param isFirst boolean
function ActivityShopGemsCell:RefreshTagActive(isFirst)
    self.textAddFirst.gameObject:SetActive(isFirst)
    self.textTagFirst.gameObject:SetActive(isFirst)
    self.textAdd.gameObject:SetActive(not isFirst)
    self.textTag.gameObject:SetActive(not isFirst)
    self.goBaseFirst:SetActive(isFirst)
end

function ActivityShopGemsCell:CheckIsFirst(goodId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local productId2Times = player.PlayerWrapper2.PlayerPay.ProductId2Times
    return not (productId2Times[goodId] and productId2Times[goodId] > 0)
end

function ActivityShopGemsCell:OnBtnPayClicked(args)
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.goodId, nil, false, true)
end

return ActivityShopGemsCell
