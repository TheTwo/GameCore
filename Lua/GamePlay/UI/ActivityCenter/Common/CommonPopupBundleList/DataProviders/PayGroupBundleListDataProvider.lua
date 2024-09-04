local BasePopupBundleListDataProvider = require("BasePopupBundleListDataProvider")
local ConfigRefer = require("ConfigRefer")
local PayGroupBundleListCellParameter = require("PayGroupBundleListCellParameter")
local I18N = require("I18N")
---@class PayGroupBundleListDataProvider : BasePopupBundleListDataProvider
local PayGroupBundleListDataProvider = class("PayGroupBundleListDataProvider", BasePopupBundleListDataProvider)

function PayGroupBundleListDataProvider:ctor(pGroupId)
    self.cfg = ConfigRefer.PayGoodsGroup:Find(pGroupId)
end

function PayGroupBundleListDataProvider:GetTitle()
    return I18N.Get(self.cfg:Name())
end

function PayGroupBundleListDataProvider:GetCellDatas()
    local result = {}
    for i = 1, self.cfg:GoodsLength() do
        local goodsId = self.cfg:Goods(i)
        local cell = PayGroupBundleListCellParameter.new(goodsId)
        table.insert(result, cell)
    end
    return result
end

return PayGroupBundleListDataProvider