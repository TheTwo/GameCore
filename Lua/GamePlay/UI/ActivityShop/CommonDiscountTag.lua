local BaseUIComponent = require('BaseUIComponent')
local ActivityShopConst = require('ActivityShopConst')
---@class CommonDiscountTag : BaseUIComponent
local CommonDiscountTag = class('CommonDiscountTag', BaseUIComponent)

---@class CommonDiscountTagParam
---@field discount number
---@field quality number
---@field isSoldOut boolean

local QUALITY_2_TYPE = {
    [1] = ActivityShopConst.DISCOUNT_TYPE.SMALL,
    [2] = ActivityShopConst.DISCOUNT_TYPE.SMALL,
    [3] = ActivityShopConst.DISCOUNT_TYPE.SMALL,
    [4] = ActivityShopConst.DISCOUNT_TYPE.NORMAL,
    [5] = ActivityShopConst.DISCOUNT_TYPE.BIG,
}

function CommonDiscountTag:OnCreate()
    self.goRoot = self:GameObject('')
    self.imgTagDiscountSmall = self:Image('p_discount_smaller')
    self.imgTagDiscountNormal = self:Image('p_discount_small')
    self.imgTagDiscountbig = self:Image('p_discount_big')
    self.textDiscountBig = self:Text('p_text_discount')
    self.textDiscountNormal = self:Text('p_text_discount_1')
    self.textDiscountSmall = self:Text('p_text_discount_2')

    self.tagDiscountDisplayCtrl = {
        [ActivityShopConst.DISCOUNT_TYPE.SMALL] = self.imgTagDiscountSmall.gameObject,
        [ActivityShopConst.DISCOUNT_TYPE.NORMAL] = self.imgTagDiscountNormal.gameObject,
        [ActivityShopConst.DISCOUNT_TYPE.BIG] = self.imgTagDiscountbig.gameObject,
    }

    self.textDiscountDisplayCtrl = {
        [ActivityShopConst.DISCOUNT_TYPE.SMALL] = self.textDiscountSmall,
        [ActivityShopConst.DISCOUNT_TYPE.NORMAL] = self.textDiscountNormal,
        [ActivityShopConst.DISCOUNT_TYPE.BIG] = self.textDiscountBig,
    }
end

---@param param CommonDiscountTagParam
function CommonDiscountTag:OnFeedData(param)
    param = param or {}
    self.discount = param.discount or 0
    self.quality = param.quality or 1
    self.isSoldOut = param.isSoldOut or false
    local discountType = QUALITY_2_TYPE[self.quality]
    self.goRoot:SetActive(self.discount > 0 and not self.isSoldOut)
    for type, tag in pairs(self.tagDiscountDisplayCtrl) do
        tag:SetActive(type == discountType)
    end
    for type, text in pairs(self.textDiscountDisplayCtrl) do
        text.text = string.format('%.0f%%', self.discount * ActivityShopConst.DISCOUNT_COFF)
        text.gameObject:SetActive(type == discountType)
    end
end

function CommonDiscountTag:SetTextGray(shouldGray)
    for _, text in pairs(self.textDiscountDisplayCtrl) do
        text.IsShowGlow = not shouldGray
    end
end

return CommonDiscountTag