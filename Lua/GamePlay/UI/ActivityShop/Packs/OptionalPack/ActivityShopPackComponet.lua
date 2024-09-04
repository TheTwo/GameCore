local BaseUIComponent = require('BaseUIComponent')
local ActivityShopConst = require('ActivityShopConst')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
---@class ActivityShopPackComponet : BaseUIComponent
local ActivityShopPackComponet = class('ActivityShopPackComponet', BaseUIComponent)

function ActivityShopPackComponet._Round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power + 0.5) / power
end

function ActivityShopPackComponet:OnCreate()
    self.packIconStatusCtrl = {}
    self:PointerClick('pack_close', Delegate.GetOrCreate(self, self.OnClick))
end

function ActivityShopPackComponet:OnFeedData(param)
    self.packIconStatusCtrl[ActivityShopConst.PACK_STATUS.LOCKED] = self.packOff
    self.packIconStatusCtrl[ActivityShopConst.PACK_STATUS.UNLOCKED] = self.packOn

    self.packId = param.packId
    self.index = param.index
    local packCfg = ConfigRefer.PayGoods:Find(self.packId)
    local discount = packCfg:Discount()
    local payId = packCfg:PayPlatformId()
    local pay = ConfigRefer.PayPlatform:Find(payId)
    self.price = self._Round(pay:Price(), 2)
    self.currency = pay:Currency()

    self.textPrice.text = string.format('%s %.2f', self.currency, self.price)
    self.textDiscount.text = string.format('%d%%', discount * ActivityShopConst.DISCOUNT_COFF)

    local player = ModuleRefer.PlayerModule:GetPlayer()
    self:SetIconStatus(ActivityShopConst.PACK_STATUS.LOCKED) -- TODO: 替换为真实数据
end

function ActivityShopPackComponet:SetIconStatus(status)
    for k, icon in pairs(self.packIconStatusCtrl) do
        icon:SetActive(k == status)
    end
    self.soldOutMark:SetActive(status == ActivityShopConst.PACK_STATUS.UNLOCKED)
end

function ActivityShopPackComponet:OnClick()
    local info  = {}
    info.packId = self.packId
    info.index = self.index
    info.price = self.price
    info.currency = self.currency
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_CUSTOM_PACK, info)
end

return ActivityShopPackComponet