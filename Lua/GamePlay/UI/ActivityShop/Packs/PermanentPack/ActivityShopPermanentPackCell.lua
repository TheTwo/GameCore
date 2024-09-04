local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local ActivityShopConst = require('ActivityShopConst')
local ArtResourceUtils = require('ArtResourceUtils')
local TimerUtility = require('TimerUtility')
local UIHelper = require('UIHelper')
local NotificationType = require('NotificationType')
---@class ActivityShopPermanentPackCell : BaseTableViewProCell
local ActivityShopPermanentPackCell = class('ActivityShopPermanentPackCell', BaseTableViewProCell)

function ActivityShopPermanentPackCell:OnCreate()
    self.goRoot = self:GameObject('p_cell_group') or self:GameObject('root')
    self.imgIcon = self:Image('p_icon_pack')
    self.textPackName = self:Text('p_text_pack_name')
    self.btnBuy = self:Button('p_btn_buy', Delegate.GetOrCreate(self, self.OnBtnBuyClicked))
    self.goBuy = self:GameObject('buy') or self:GameObject('base_btn') or self:GameObject('p_btn_buy')
    self.textBuy = self:Text('p_text_e')
    self.goSoldOut = self:GameObject('p_sold_out')
    self.textSoldOut = self:Text('p_text_sold_out')
    self.textLimit = self:Text('p_text_limited')
    self.vxTrigger = self:AnimTrigger('vx_trigger') or self:AnimTrigger('vx_trigger_1')
    self.discountTag = self:LuaBaseComponent('child_shop_discount_tag')
    self.notifyNode = self:LuaObject('child_reddot_default')
    self.textExchangePoints = self:Text('p_text_num')
    self.btnExchangePoints = self:Button('child_btn_recharge_points')
end

function ActivityShopPermanentPackCell:OnFeedData(param)
    self.groupId = param.packGroupId
    self.index = param.index
    local groupCfg = ConfigRefer.PayGoodsGroup:Find(self.groupId)
    self.packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(self.groupId)
    if not self.packId then
        self.packId = groupCfg:Goods(groupCfg:GoodsLength())
    end

    local packCfg = ConfigRefer.PayGoods:Find(self.packId)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(packCfg:Icon()), self.imgIcon)

    self.textPackName.text = I18N.Get(packCfg:Name())
    local price, currency = ModuleRefer.ActivityShopModule:GetGoodsPrice(self.packId)
    self.textBuy.text = string.format('%s %.2f', currency, price)
    self.textLimit.text = I18N.GetWithParams(ActivityShopConst.I18N_KEYS.GENERAL_LIMIT_TIMES, packCfg:BuyLimit())

    local discount = packCfg:Discount()
    local discountQuality = packCfg:DiscountQuality()
    self.discountTag:FeedData({
        discount = discount,
        quality = discountQuality,
        isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.packId),
    })

    self.textSoldOut.text = I18N.Get(ActivityShopConst.I18N_KEYS.SOLD_OUT)
    self.btnExchangePoints.gameObject:SetActive(true)
    self.textExchangePoints.text = '+' .. ModuleRefer.ActivityShopModule:GetGoodsExchangePointsNum(self.packId)
    local isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.packId)
    self:SetSoldOut(isSoldOut)
    if self.notifyNode then
        local notifyLogicNode = ModuleRefer.NotificationModule:GetDynamicNode(
            ActivityShopConst.NotificationNodeNames.ActivityShopPack .. self.groupId, NotificationType.ACTIVITY_SHOP_PACK)
        ModuleRefer.NotificationModule:AttachToGameObject(notifyLogicNode, self.notifyNode.go, self.notifyNode.redNew)
    end
end

function ActivityShopPermanentPackCell:SetSoldOut(isSoldOut)
    self.goSoldOut:SetActive(isSoldOut)
    self.btnBuy.gameObject:SetActive(not isSoldOut)
    self.goBuy:SetActive(not isSoldOut)
    self.btnExchangePoints.gameObject:SetActive(not isSoldOut)
    UIHelper.SetGray(self.goRoot, isSoldOut)
    self.discountTag.Lua:SetTextGray(isSoldOut)
end

function ActivityShopPermanentPackCell:OnBtnBuyClicked()
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.packId, nil, true)
end

return ActivityShopPermanentPackCell