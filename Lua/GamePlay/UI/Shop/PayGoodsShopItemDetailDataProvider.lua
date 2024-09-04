local BaseShopItemDetailDataProvider = require('BaseShopItemDetailDataProvider')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local PayType = require('PayType')
---@class PayGoodsShopItemDetailDataProvider : BaseShopItemDetailDataProvider
local PayGoodsShopItemDetailDataProvider = class('PayGoodsShopItemDetailDataProvider', BaseShopItemDetailDataProvider)

---@param id number
---@param chooseItems number[]
function PayGoodsShopItemDetailDataProvider:ctor(id, chooseItems)
    self.super.ctor(self, id)
    self._chooseItems = chooseItems
    self.goodsCfg = ConfigRefer.PayGoods:Find(self._id)

    self._onBuyClick = function()
        if ModuleRefer.ActivityShopModule:GetGoodPayType(self._id) ~= PayType.Recharge then
            ModuleRefer.ActivityShopModule:PurchaseWithGameItemOrFree(self._id, self._chooseItems)
        else
            ModuleRefer.PayModule:BuyGoods(self._id, self._chooseItems)
        end
    end
end

function PayGoodsShopItemDetailDataProvider:GetName()
    return I18N.Get(self.goodsCfg:Name())
end

function PayGoodsShopItemDetailDataProvider:GetDesc()
    return I18N.Get(ModuleRefer.ActivityShopModule:GetGoodParameterizedDesc(self._id))
end

function PayGoodsShopItemDetailDataProvider:GetDiscountTagParam()
    ---@type CommonDiscountTagParam
    local ret = {}
    ret.discount = self.goodsCfg:Discount()
    ret.quality = self.goodsCfg:DiscountQuality()
    ret.isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self._id)
    return ret
end

function PayGoodsShopItemDetailDataProvider:GetIcon()
    return self.goodsCfg:Icon()
end

function PayGoodsShopItemDetailDataProvider:GetBuyLimit()
    return self.goodsCfg:BuyLimit()
end

function PayGoodsShopItemDetailDataProvider:GetPriceText()
    if ModuleRefer.ActivityShopModule:GetGoodPayType(self._id) == PayType.ItemGroup then
        local item = ModuleRefer.ActivityShopModule:GetPayItem(self._id)
        return string.format('%s %d', I18N.Get(item.configCell:NameKey()), item.count)
    else
        local price, currency = ModuleRefer.ActivityShopModule:GetGoodsPrice(self._id)
        return string.format('%s %.2f', currency, price)
    end
end

function PayGoodsShopItemDetailDataProvider:GetBoughtTimes()
    return ModuleRefer.ActivityShopModule:GetGoodsPurchasedTimes(self._id)
end

function PayGoodsShopItemDetailDataProvider:GetPurchaseableCount()
    return self:GetBuyLimit() - self:GetBoughtTimes()
end

function PayGoodsShopItemDetailDataProvider:GetGoodsItemList()
    local ret = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(self.goodsCfg:ItemGroupId())
    local extra = self._chooseItems
    if extra then
        for _, groupId in ipairs(extra) do
            local itemInfo = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(groupId)[1]
            table.insert(ret, itemInfo)
        end
    end
    for _, item in ipairs(ret) do
        item.itemId = item.id
        item.itemCount = item.count
        item.id = nil
        item.count = nil
    end
    return ret
end

function PayGoodsShopItemDetailDataProvider:GetExchangeNum()
    return ModuleRefer.ActivityShopModule:GetGoodsExchangePointsNum(self._id)
end

return PayGoodsShopItemDetailDataProvider