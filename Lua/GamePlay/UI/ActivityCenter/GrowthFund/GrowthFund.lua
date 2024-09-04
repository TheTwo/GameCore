local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
local DBEntityPath = require('DBEntityPath')
local ItemTableMergeHelper = require('ItemTableMergeHelper')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
---@class GrowthFund : BaseUIComponent
local GrowthFund = class('GrowthFund', BaseUIComponent)

local I18N_KEYS = GrowthFundConst.I18N_KEYS

function GrowthFund:OnCreate()
    self.textTitle = self:Text('p_text_title', I18N_KEYS.MAIN_TITLE)

    self.btnBase = self:Button('p_btn_base', Delegate.GetOrCreate(self, self.OnBtnBaseClicked))

    -- group roof
    self.textTitleFree = self:Text('p_text_title_free', I18N_KEYS.FREE_REWARD_TITLE)
    self.btnFree = self:Button('p_btn_free', Delegate.GetOrCreate(self, self.OnBtnFreeClicked))

    self.textTitleBetter = self:Text('p_text_title_better', I18N_KEYS.PAY_REWARD_TITLE)
    self.btnBetter = self:Button('p_btn_better', Delegate.GetOrCreate(self, self.OnBtnBetterClicked))

    self.textHint = self:Text('p_text_hint')
    self.goHint = self:GameObject('p_btn')

    self.textHintNormal = self:Text('p_text_hint_1')

    self.goGroupBtnBetter = self:GameObject('p_group_btn_better')
    self.btnPurchaseBetter = self:Button('p_btn_purchase_better', Delegate.GetOrCreate(self, self.OnBtnPurchaseBetterClicked))
    self.textBtnPurchaseBetter = self:Text('p_text_e')
    self.textBoughtBetter = self:Text('p_text_bought', 'progress_fund_description_5')
    self.textPurchaseBetter = self:Text('p_text_purchase')

    self.btnPetDetail = self:Button('p_btn_pet_detail', Delegate.GetOrCreate(self, self.OnBtnPetDetailClicked))

    self.goGroupBtnNormal = self:GameObject('p_group_btn_normal')
    self.btnPurchaseNormal = self:Button('p_btn_purchase_1', Delegate.GetOrCreate(self, self.OnBtnPurchaseNormalClicked))
    self.textBtnPurchaseNormal = self:Text('p_text_1')
    self.textBoughtNormal = self:Text('p_text_bought_1', 'progress_fund_description_5')
    self.textPurchaseNormal = self:Text('p_text_purchas_1')

    self.tableReward = self:TableViewPro('p_table_list')

    ---@see CommonDiscountTag
    self.luaDiscountTagNormal = self:LuaObject("child_shop_discount_tag_normal")
    self.luaDiscountTagBetter = self:LuaObject("child_shop_discount_tag_better")

    self.vxTrigger = self:AnimTrigger('vx_trigger')
    self.isFirstOpen = true
end

function GrowthFund:OnFeedData()
    self.cfgId = ModuleRefer.GrowthFundModule:GetCurOpeningGrowthFundCfgId()
    self.curLvl = ModuleRefer.GrowthFundModule:GetProgressByCfgId(self.cfgId)
    self:UpdateUI()
    self.firstClaimableLevel = ModuleRefer.GrowthFundModule:GetFirstClaimableNodeIndex(self.cfgId)
    if not self.firstClaimableLevel then
        self.tableReward:SetDataFocus(self.curLvl - 1, 0, CS.TableViewPro.MoveSpeed.None)
    elseif self.firstClaimableLevel == #ModuleRefer.GrowthFundModule:GetRewardInfosByCfgId(self.cfgId) then
        self.firstClaimableLevel = self.firstClaimableLevel - 1
        self.tableReward:SetDataFocus(self.firstClaimableLevel - 2, 0, CS.TableViewPro.MoveSpeed.None)
    else
        self.tableReward:SetDataFocus(self.firstClaimableLevel - 2, 0, CS.TableViewPro.MoveSpeed.None)
    end
    local maxLv = #ModuleRefer.GrowthFundModule:GetRewardInfosByCfgId(self.cfgId)
    self.textPurchaseBetter.text = I18N.GetWithParams(I18N_KEYS.PURCHASE_TIPS_BETTER, ModuleRefer.GrowthFundModule:GetTotalSpeciesByLevel(self.cfgId, maxLv, true))
    self.textPurchaseNormal.text = I18N.GetWithParams(I18N_KEYS.PURCHASE_TIPS_NORMAL, ModuleRefer.GrowthFundModule:GetTotalSpeciesByLevel(self.cfgId, maxLv, false))
    self.goGroupBtnBetter:SetActive(not self.isVipSoldOut)
    self.goGroupBtnNormal:SetActive(not self.isNormalSoldOut)
    if not self.isNormalSoldOut then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
    if not self.isVipSoldOut then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

function GrowthFund:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,
    Delegate.GetOrCreate(self, self.OnDataChanged))
end

function GrowthFund:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,
    Delegate.GetOrCreate(self, self.OnDataChanged))
end

function GrowthFund:OnDataChanged()
    self:UpdateRoof()
    self:UpdateBottom()
end

function GrowthFund:UpdateUI()
    self:UpdateRoof()
    self:UpdateTable()
    self:UpdateBottom()
end

function GrowthFund:UpdateRoof()
    local normalGroupId = ModuleRefer.GrowthFundModule:GetNormalGoodsByCfgId(self.cfgId)
    if normalGroupId and normalGroupId > 0 then
        self.luaDiscountTagNormal:FeedData(ModuleRefer.ActivityShopModule:GetDiscountTagParamByGoodId(normalGroupId))
    end
    local betterGroupId = ModuleRefer.GrowthFundModule:GetVIPGoodsByCfgId(self.cfgId)
    if betterGroupId and betterGroupId > 0 then
        self.luaDiscountTagBetter:FeedData(ModuleRefer.ActivityShopModule:GetDiscountTagParamByGoodId(betterGroupId))
    end
end

function GrowthFund:UpdateTable()
    self.tableReward:Clear()
    self.nodeInfos = ModuleRefer.GrowthFundModule:GetRewardInfosByCfgId(self.cfgId)
    for i = 1, #self.nodeInfos do
        local nodeInfo = self.nodeInfos[i]
        ---@type GrowthFundRewardCellData
        local data = {}
        data.level = nodeInfo.neededProgress
        data.nodeInfo = nodeInfo
        self.tableReward:AppendData(data)
    end
end

function GrowthFund:UpdateBottom()
    local normalpGroupId = ModuleRefer.GrowthFundModule:GetNormalGoodsByCfgId(self.cfgId)
    if normalpGroupId and normalpGroupId > 0 then
        self:SetBtnInfo(self.btnPurchaseNormal, self.textBtnPurchaseNormal, self.textHintNormal, self.textBoughtNormal, normalpGroupId, false)
    end
    local betterpGroupId = ModuleRefer.GrowthFundModule:GetVIPGoodsByCfgId(self.cfgId)
    if betterpGroupId and betterpGroupId > 0 then
        self:SetBtnInfo(self.btnPurchaseBetter, self.textBtnPurchaseBetter, self.textHint, self.textBoughtBetter, betterpGroupId, true)
    end
end

---@param btn CS.UnityEngine.UI.Button
---@param text CS.UnityEngine.UI.Text
---@param hint CS.UnityEngine.UI.Text
---@param soldOutText CS.UnityEngine.UI.Text
---@param payGroupId number
---@param vip boolean
function GrowthFund:SetBtnInfo(btn, text, hint, soldOutText, payGroupId, vip)
    hint.text = I18N.GetWithParams(I18N_KEYS.MAIN_DESC, ModuleRefer.GrowthFundModule:GetTotalSpeciesByLevel(self.cfgId, self.curLvl, vip))
    local price, type = ModuleRefer.ActivityShopModule:GetGoodsPrice(payGroupId)
    local isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(payGroupId)
    if vip then
        self.isVipSoldOut = isSoldOut
    else
        self.isNormalSoldOut = isSoldOut
    end
    text.text = string.format('%s %.2f', type, price)
    btn.gameObject:SetActive(not isSoldOut)
    text.gameObject:SetActive(not isSoldOut)
    soldOutText.gameObject:SetActive(isSoldOut)
    hint.gameObject:SetActive(not isSoldOut)
end

function GrowthFund:OnBtnPurchaseBetterClicked()
    local vipGoodsId = ModuleRefer.GrowthFundModule:GetVIPGoodsByCfgId(self.cfgId)
    ModuleRefer.ActivityShopModule:PurchaseGoods(vipGoodsId, nil, false)
end

function GrowthFund:OnBtnPurchaseNormalClicked()
    local normalGoodsId = ModuleRefer.GrowthFundModule:GetNormalGoodsByCfgId(self.cfgId)
    ModuleRefer.ActivityShopModule:PurchaseGoods(normalGoodsId, nil, false)
end

function GrowthFund:OnBtnBaseClicked()
    ---@type TextToastMediatorParameter
    local data = {}
    data.clickTransform = self.btnBase.transform
    data.content = I18N.Get(I18N_KEYS.BASE_TIPS)
    ModuleRefer.ToastModule:ShowTextToast(data)
end

function GrowthFund:OnBtnFreeClicked()
    ---@type ItemIconData
    local allFreeRewardItemData = {}
    for _, nodeInfo in ipairs(self.nodeInfos) do
        local freeRewardItemData = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(nodeInfo.normal)
        for _, data in ipairs(freeRewardItemData) do
            table.insert(allFreeRewardItemData, data)
        end
    end
    local mergedData = ItemTableMergeHelper.MergeItemDataByItemCfgId(allFreeRewardItemData)
    local param = {}
    local listInfo = {}
    for _, data in pairs(mergedData) do
        local itemId = data.configCell:Id()
        local itemCount = data.count
        table.insert(listInfo, {itemId = itemId, itemCount = itemCount})
    end
    param.listInfo = listInfo
    param.clickTrans = self.btnFree.gameObject.transform
    g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, param)
end

function GrowthFund:OnBtnBetterClicked()
    ---@type ItemIconData
    local allBetterRewardItemData = {}
    for _, nodeInfo in ipairs(self.nodeInfos) do
        local betterRewardItemData = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(nodeInfo.adv)
        for _, data in ipairs(betterRewardItemData) do
            table.insert(allBetterRewardItemData, data)
        end
    end
    local mergedData = ItemTableMergeHelper.MergeItemDataByItemCfgId(allBetterRewardItemData)
    local param = {}
    local listInfo = {}
    for _, data in pairs(mergedData) do
        local itemId = data.configCell:Id()
        local itemCount = data.count
        table.insert(listInfo, {itemId = itemId, itemCount = itemCount})
    end
    param.listInfo = listInfo
    param.clickTrans = self.btnBetter.transform
    g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, param)
end

function GrowthFund:OnBtnPetDetailClicked()
    local petId = GrowthFundConst.PET_ID
    ModuleRefer.PetModule:ShowPetPreview(petId, 'SSS')
end

return GrowthFund