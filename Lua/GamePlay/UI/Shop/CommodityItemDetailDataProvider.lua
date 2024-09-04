local BaseShopItemDetailDataProvider = require('BaseShopItemDetailDataProvider')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local QualityColorHelper = require('QualityColorHelper')
local ShoppingParameter = require('ShoppingParameter')
local EventConst = require('EventConst')
---@class CommodityItemDetailDataProvider : BaseShopItemDetailDataProvider
local CommodityItemDetailDataProvider = class('CommodityItemDetailDataProvider', BaseShopItemDetailDataProvider)

---@param id number
---@param tabId number
function CommodityItemDetailDataProvider:ctor(id, tabId)
    self.super.ctor(self, id)
    self._tabId = tabId
    self.commodityCfg = ConfigRefer.ShopCommodity:Find(self._id)
    self.itemCfg = ConfigRefer.Item:Find(self.commodityCfg:RefItem())

    self._onBuyClick = function(costId, num)
        local param = ShoppingParameter.new()
        param.args.StoreConfId = self._tabId
        param.args.BoughtItemID = self._id
        param.args.Num = num
        param.args.CostItemId = costId
        param:Send()
        g_Game.EventManager:TriggerEvent(EventConst.RECORD_CONTENT_POS)
    end
end

function CommodityItemDetailDataProvider:GetItemCfg()
    return self.itemCfg
end

function CommodityItemDetailDataProvider:GetName()
    return I18N.Get(self.itemCfg:NameKey())
end

function CommodityItemDetailDataProvider:GetDesc()
    return I18N.Get(self.itemCfg:DescKey())
end

function CommodityItemDetailDataProvider:GetDiscount()
    return self.commodityCfg:Discount()
end

function CommodityItemDetailDataProvider:GetIcon()
    return self.itemCfg:Icon()
end

function CommodityItemDetailDataProvider:GetQualityColor()
    local quality = self.itemCfg:Quality()
    return QualityColorHelper.GetQualityColor(quality, QualityColorHelper.Type.Item)
end

function CommodityItemDetailDataProvider:GetBuyLimit()
    return self.commodityCfg:Count()
end

function CommodityItemDetailDataProvider:GetBoughtTimes()
    local shopInfo = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper.Store.Stores or {}
    local products = shopInfo[self._tabId].Products
    local freeProducts = shopInfo[self._tabId].FreeProducts
    local boughtTimes = 0
    if products[self._id] then
        boughtTimes = products[self._id]
    else
        boughtTimes = freeProducts[self._id]
    end
    return boughtTimes
end

function CommodityItemDetailDataProvider:GetPurchaseableCount()
    local buyLimit = self:GetBuyLimit()
    if buyLimit == 0 then
        buyLimit = math.huge
    end
    local countByLimit =  buyLimit - self:GetBoughtTimes()
    local countByPrice = math.huge
    local prices = self:GetPrices()
    for i, item in ipairs(self:GetPriceItemCfgs()) do
        local price = prices[i]
        local count = ModuleRefer.InventoryModule:GetAmountByConfigId(item:Id())
        countByPrice = math.min(countByPrice, math.floor(count / price))
    end
    return math.min(countByLimit, countByPrice)
end

function CommodityItemDetailDataProvider:GetPriceItemCfgs()
    local ret = {}
    for i = 1, self.commodityCfg:CostItemLength() do
        local costItem = self.commodityCfg:CostItem(i)
        local itemCfg = ConfigRefer.Item:Find(costItem)
        table.insert(ret, itemCfg)
    end
    return ret
end

function CommodityItemDetailDataProvider:GetPrices()
    local ret = {}
    for i = 1, self.commodityCfg:CostItemCountLength() do
        local price = self.commodityCfg:CostItemCount(i)
        table.insert(ret, price)
    end
    return ret
end

return CommodityItemDetailDataProvider