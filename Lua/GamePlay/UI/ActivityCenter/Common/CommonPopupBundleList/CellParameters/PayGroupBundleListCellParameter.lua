local BasePopupBundleListCellParameter = require("BasePopupBundleListCellParameter")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local PayType = require("PayType")
---@class PayGroupBundleListCellParameter : BasePopupBundleListCellParameter
local PayGroupBundleListCellParameter = class("PayGroupBundleListCellParameter", BasePopupBundleListCellParameter)

function PayGroupBundleListCellParameter:ctor(id)
    self.id = id
    self.cfg = ConfigRefer.PayGoods:Find(id)
end

function PayGroupBundleListCellParameter:GetName()
    return I18N.Get(self.cfg:Name())
end

function PayGroupBundleListCellParameter:GetRewards()
    local itemGroupId = self.cfg:ItemGroupId()
    return ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId) or {}
end

function PayGroupBundleListCellParameter:GetFreeButtonEnableText()
    return I18N.Get("/*Free")
end

function PayGroupBundleListCellParameter:GetFreeButtonDisableText()
    return I18N.Get("/*Free")
end

function PayGroupBundleListCellParameter:GetPurchaseButtonText()
    if ModuleRefer.ActivityShopModule:GetGoodPayType(self.id) == PayType.ItemGroup then
        return I18N.Get("/*Buy")
    else
        local price, currency = ModuleRefer.ActivityShopModule:GetGoodsPrice(self.id)
        return string.format("%s %.2f", I18N.Get(currency), price)
    end
end

---@return string, number, number
function PayGroupBundleListCellParameter:GetPurchaseButtonItemInfo()
    if ModuleRefer.ActivityShopModule:GetGoodPayType(self.id) == PayType.ItemGroup then
        local item = ModuleRefer.ActivityShopModule:GetPayItem(self.id)
        local need = item.count
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(item.configCell:Id())
        local icon = item.configCell:Icon()
        return icon, need, have
    end
    return nil
end

function PayGroupBundleListCellParameter:GetDiscountTagParam()
    return ModuleRefer.ActivityShopModule:GetDiscountTagParamByGoodId(self.id)
end

function PayGroupBundleListCellParameter:HasNotify()
    return self:CanShowFreeBtn() and self:IsFreeButtonEnable()
end

function PayGroupBundleListCellParameter:IsSoldOut()
    return ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.id)
end

function PayGroupBundleListCellParameter:CanShowFreeBtn()
    return ModuleRefer.ActivityShopModule:IsFree(self.id)
end

function PayGroupBundleListCellParameter:OnClickPurchaseButton()
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.id, nil, true)
end

function PayGroupBundleListCellParameter:OnClickFreeButtonEnable()
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.id, nil, false)
end

return PayGroupBundleListCellParameter