local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local BattlePassConst = require("BattlePassConst")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local ItemTableMergeHelper = require("ItemTableMergeHelper")
---@class BattlePassUnlockAdvanceMediator : BaseUIMediator
local BattlePassUnlockAdvanceMediator = class("BattlePassUnlockAdvanceMediator", BaseUIMediator)
local I18N_KEYS = BattlePassConst.I18N_KEYS

function BattlePassUnlockAdvanceMediator:OnCreate()
    -- card 1
    self.textTitle1 = self:Text('p_text_title_1', I18N_KEYS.PAY_SENIOR_TITLE)
    self.textSubTitle1 = self:Text('p_text_subtitle', I18N_KEYS.PAT_SENIOR_SUBTITLE)
    self.tableReward1 = self:TableViewPro('p_table_detail_1')

    self.textUnlockedRewards = self:Text('p_text_unlocked_rewards', I18N_KEYS.PAY_UNLOCKED_REWARDS)
    self.tableUnlockedRewards = self:TableViewPro('p_table_unlocked_rewards')

    self.btnBuyNormalUpgrade = self:Button('p_btn_e_1', Delegate.GetOrCreate(self, self.OnBtnBuyNormalUpgradeClicked))
    self.goBuy1 = self:GameObject('p_btn_e_1')
    self.textBuy1 = self:Text('p_text_e_1')
    self.goSoldOut1 = self:GameObject('p_sold_out_1')
    self.textSoldOut1 = self:Text('p_text_sold_out', I18N_KEYS.PAY_SOLD_OUT)
    ---@see CommonDiscountTag
    self.luaTag1 = self:LuaObject('child_shop_discount_tag_1')

    -- card 2
    self.textTitle2 = self:Text('p_text_title_2', I18N_KEYS.PAY_SUPER_TITLE)
    self.textSubTitle2 = self:Text('p_text_subtitle_2', I18N_KEYS.PAY_SUPER_SUBTITLE)
    self.tableReward2 = self:TableViewPro('p_table_detail_2')
    self.textCard2Desc1 = self:Text('p_text_desc_1', I18N_KEYS.PAY_SUPER_DESC1)
    self.textCard2Desc2 = self:Text('p_text_desc_2', I18N_KEYS.PAY_SUPER_DESC2)

    self.btnBuySupremeUpgrade = self:Button('child_comp_btn_e_l', Delegate.GetOrCreate(self, self.OnBtnBuySupremeUpgradeClicked))
    self.goBuy2 = self:GameObject('child_comp_btn_e_l')
    self.textBuy2 = self:Text('p_text_e')
    self.goSoldOut2 = self:GameObject('p_sold_out_2')
    self.textSoldOut2 = self:Text('p_text_sold_out_2', I18N_KEYS.PAY_SOLD_OUT)

    self.luaTag2 = self:LuaObject('child_shop_discount_tag_2')

    self.textDesc = self:Text('p_text_desc_about', I18N_KEYS.PAY_HINT)
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))

    self.vxTrigger = self:AnimTrigger('trigger')
end

function BattlePassUnlockAdvanceMediator:ctor()
    self.vipGoodsId = nil
    self.svipGoodsId = nil
    ---@type CS.UnityEngine.UI.Button
    self.clickedBtn = nil
end

function BattlePassUnlockAdvanceMediator:OnOpened(param)
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    self:UpdateGoodsId()

    self:UpdateCard1Table()
    self:UpDateCard1Btn()

    self:UpdateCard2Table()
    self:UpDateCard2Btn()

    g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_UNLOCK_VIP_OPEN)
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
end

function BattlePassUnlockAdvanceMediator:OnClose()
    g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_UNLOCK_VIP_CLOSE)
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
end

function BattlePassUnlockAdvanceMediator:UpdateGoodsId()
    self.vipGoodsId = ModuleRefer.BattlePassModule:GetVIPGoodsByCfgId(self.cfgId)
    self.svipGoodsId = ModuleRefer.BattlePassModule:GetSVIPGoodsByCfgId(self.cfgId)
    if ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.vipGoodsId) then
        self.svipGoodsId = ModuleRefer.BattlePassModule:GetReplaceGoodsByCfgId(self.cfgId) or self.svipGoodsId
    end
    local packId1 = self.vipGoodsId
    local packCfg1 = ConfigRefer.PayGoods:Find(packId1)
    ---@type CommonDiscountTagParam
    local data = {}
    data.discount = packCfg1:Discount()
    data.isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(packId1)
    data.quality = packCfg1:DiscountQuality()
    self.luaTag1:FeedData(data)

    local packId2 = self.svipGoodsId
    local packCfg2 = ConfigRefer.PayGoods:Find(packId2)
    ---@type CommonDiscountTagParam
    local data2 = {}
    data2.discount = packCfg2:Discount()
    data2.isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(packId2)
    data2.quality = packCfg2:DiscountQuality()
    self.luaTag2:FeedData(data2)
end

function BattlePassUnlockAdvanceMediator:UpdateCard1Table()
    local vipGoodsCfg = ConfigRefer.PayGoods:Find(self.vipGoodsId)
    local vipItemGroupId = vipGoodsCfg:ItemGroupId()
    local vipItemsData = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(vipItemGroupId)
    self.tableReward1:Clear()
    for _, data in ipairs(vipItemsData) do
        local param ={
            itemId = data.id,
            itemCount = data.count,
        }
        self.tableReward1:AppendData(param)
    end

    self.tableUnlockedRewards:Clear()
    local lvl = ModuleRefer.BattlePassModule:GetMaxLevelByCfgId(self.cfgId)
    self.textUnlockedRewards.gameObject:SetActive(lvl > 0)
    local rewards = {}
    for i = 1, lvl do
        local rewardNode = ModuleRefer.BattlePassModule:GetRewardInfosByCfgId(self.cfgId)[i]
        local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardNode.adv)
        for _, item in ipairs(items) do
            table.insert(rewards, item)
        end
    end
    rewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(rewards)
    table.sort(rewards, function(a, b)
        return a.configCell:Quality() > b.configCell:Quality()
    end)
    for _, data in ipairs(rewards) do
        local param ={
            itemId = data.configCell:Id(),
            itemCount = data.count,
        }
        self.tableUnlockedRewards:AppendData(param)
    end
end

function BattlePassUnlockAdvanceMediator:UpDateCard1Btn()
    local isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.vipGoodsId)
                        or ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.svipGoodsId)
    self.goBuy1:SetActive(not isSoldOut)
    self.goSoldOut1:SetActive(isSoldOut)
    if not isSoldOut then
        local price, priceType = ModuleRefer.ActivityShopModule:GetGoodsPrice(self.vipGoodsId)
        self.textBuy1.text = string.format("%s %.2f", priceType, price)
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

function BattlePassUnlockAdvanceMediator:UpdateCard2Table()
    local svipGoodsCfg = ConfigRefer.PayGoods:Find(self.svipGoodsId)
    local svipItemGroupId = svipGoodsCfg:ItemGroupId()
    local svipItemsData = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(svipItemGroupId)
    self.tableReward2:Clear()
    for _, data in ipairs(svipItemsData) do
        local param ={
            itemId = data.id,
            itemCount = data.count,
        }
        self.tableReward2:AppendData(param)
    end
end

function BattlePassUnlockAdvanceMediator:UpDateCard2Btn()
    local isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.svipGoodsId)
    self.goBuy2:SetActive(not isSoldOut)
    self.goSoldOut2:SetActive(isSoldOut)
    if not isSoldOut then
        local price, priceType = ModuleRefer.ActivityShopModule:GetGoodsPrice(self.svipGoodsId)
        self.textBuy2.text = string.format("%s %.2f", priceType, price)
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
end

function BattlePassUnlockAdvanceMediator:OnBtnCloseClicked()
    self:CloseSelf()
end

function BattlePassUnlockAdvanceMediator:OnBtnBuyNormalUpgradeClicked()
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.vipGoodsId)
    self.clickedBtn = self.btnBuyNormalUpgrade
end

function BattlePassUnlockAdvanceMediator:OnBtnBuySupremeUpgradeClicked()
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.svipGoodsId)
    self.clickedBtn = self.btnBuySupremeUpgrade
end

function BattlePassUnlockAdvanceMediator:OnPaySuccess()
    self:UpdateGoodsId()
    self:UpDateCard1Btn()
    self:UpdateCard2Table()
    self:UpDateCard2Btn()
    self:AutoClaimReward()
end

function BattlePassUnlockAdvanceMediator:AutoClaimReward()
    if ModuleRefer.BattlePassModule:IsAnyNodeRewardCanClaim(self.cfgId) then
        ModuleRefer.BattlePassModule:ClaimReward(BattlePassConst.NORMAL_BP_ACT_ID, BattlePassConst.REWARD_CLAIM_TYPE.ALL,
            nil, self.clickedBtn.transform)
    end
end

return BattlePassUnlockAdvanceMediator