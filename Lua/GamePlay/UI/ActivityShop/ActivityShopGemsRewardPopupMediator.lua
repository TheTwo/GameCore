local BaseUIMediator = require('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local Delegate = require('Delegate')
local ItemPopType = require("ItemPopType")
---@class ActivityShopGemsRewardPopupMediator : BaseUIMediator
local ActivityShopGemsRewardPopupMediator = class('ActivityShopGemsRewardPopupMediator', BaseUIMediator)

function ActivityShopGemsRewardPopupMediator:OnCreate()
    self.textTitle = self:Text('p_text_subtitle', 'get_top-up_item_title')
    self.imgIcon = self:Image('p_icon_coin')
    self.textNum = self:Text('p_text_num')
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function ActivityShopGemsRewardPopupMediator:OnOpened(param)
    if not param then
        return
    end
    self.id = param.goodsId
    local cfg = ConfigRefer.PayGoods:Find(self.id)
    local gId = cfg:ItemGroupId()
    local icon = ArtResourceUtils.GetUIItem(ConfigRefer.PayGoods:Find(gId):Icon())
    local item = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(gId)[1]
    self.itemId = item.configCell:Id()
    local isFirstPurchase = (ModuleRefer.ActivityShopModule:GetGoodsPurchasedTimes(self.id) - 1) == 0
    local count = item.count
    if isFirstPurchase and cfg:IsFirstDouble() then
        count = count * 2
    else
        local extraGId = cfg:ExtraItemGroupId()
        local extra = 0
        if extraGId > 0 then
            extra = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(extraGId)[1].count
        end
        count = count + extra
    end
    self.count = count
    self.textNum.text = tostring(count)
    g_Game.SpriteManager:LoadSprite(icon, self.imgIcon)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, Delegate.GetOrCreate(self, self.OnAnimFinish))
end

function ActivityShopGemsRewardPopupMediator:OnAnimFinish()
    local data = {
        ItemCount = {self.count},
        ItemID = {self.itemId},
        ProfitReason = wds.enum.ItemProfitType.ItemAddPay,
        PopType = ItemPopType.PopTypeLightReward,
        Pos = {X = 0, Y = 0},
    }
    ModuleRefer.RewardModule:ShowLightReward(data)
    self:CloseSelf()
end

return ActivityShopGemsRewardPopupMediator