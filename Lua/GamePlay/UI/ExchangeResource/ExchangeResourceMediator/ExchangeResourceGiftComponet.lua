local BaseUIComponent = require("BaseUIComponent")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local Delegate = require("Delegate")
---@class ExchangeResourceGiftComponet : BaseUIComponent
local ExchangeResourceGiftComponet = class("ExchangeResourceGiftComponet", BaseUIComponent)

function ExchangeResourceGiftComponet:ctor()
end

function ExchangeResourceGiftComponet:OnCreate()
    self.imgGift = self:Image("p_img_gift")
    ---@see CommonDiscountTag
    self.luaDiscountTag = self:LuaObject("child_shop_discount_tag")
    self.tableItem = self:TableViewPro("p_table_item")
    self.textName = self:Text("p_text_name")
    self.btnBuy = self:Button("p_btn_buy", Delegate.GetOrCreate(self, self.OnClickBuy))
    self.textBtnBuy = self:Text("p_text_e")
    self.textPrice = self:Text("p_text_num_e")
    self.goIcon = self:GameObject("p_icon_e")
    self.goBtnResource = self:GameObject("p_resouce_e")
end

---@param pGroupId number
function ExchangeResourceGiftComponet:OnFeedData(pGroupId)
    self.goBtnResource:SetActive(false)
    self.groupId = pGroupId
    self.groupCfg = ConfigRefer.PayGoodsGroup:Find(pGroupId)

    self.textName.text = I18N.Get(self.groupCfg:Name())

    local goodsId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(pGroupId)
    self.goodsId = goodsId
    local goodsCfg = ConfigRefer.PayGoods:Find(goodsId)
    self:LoadSprite(goodsCfg:Icon(), self.imgGift)
    local price, currency = ModuleRefer.ActivityShopModule:GetGoodsPrice(goodsId)
    self.textBtnBuy.text = ("%s %.2f"):format(currency, price)

    local goodCfg = ConfigRefer.PayGoods:Find(goodsId)
    local itemGroupId = goodCfg:ItemGroupId()
    local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
    for _, item in ipairs(items) do
        ---@type StarItemIconData
        local data = {}
        data.itemIconData = item
        data.starCount = 0
        self.tableItem:AppendData(data)
    end

    ---@type CommonDiscountTagParam
    local data = {}
    data.discount = goodCfg:Discount()
    data.quality = goodCfg:DiscountQuality()
    data.isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(goodsId)
    self.luaDiscountTag:FeedData(data)

    self.goIcon:SetActive(false)
end

function ExchangeResourceGiftComponet:OnClickBuy()
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.goodsId, nil, true, false)
end

return ExchangeResourceGiftComponet