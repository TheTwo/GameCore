local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local ShoppingParameter = require("ShoppingParameter")
local SdkWrapper = require('SdkWrapper')
local UIHelper = require("UIHelper")
local GuideUtils = require("GuideUtils")
local CommodityItemDetailDataProvider = require("CommodityItemDetailDataProvider")

---@class ShopItemCell:BaseTableViewProCell
local ShopItemCell = class('ShopItemCell',BaseTableViewProCell)

---@class ShopItemCellData
---@field commodityId number
---@field tabId number
---@field buyNum number
---@field isFree boolean

local QUALITY = {
    CS.UnityEngine.Color(166/255, 166/255, 166/255, 255/255),
    CS.UnityEngine.Color(137/255, 169/255, 101/255, 255/255),
    CS.UnityEngine.Color(109/255, 145/255, 187/255, 255/255),
    CS.UnityEngine.Color(175/255, 117/255, 209/255, 255/255),
    CS.UnityEngine.Color(234/255, 159/255, 115/255, 255/255),
}

function ShopItemCell:OnCreate(param)
    self.selfGo = self:GameObject('')
    self.btnItem = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemClicked))
    self.imgFrame = self:Image('p_frame')
    self.imgLine = self:Image('p_line')
    self.goDiscount = self:GameObject('p_discount')
    self.textDiscount = self:Text('p_text_discount')
    self.imgItem = self:Image('p_item')
    self.textName = self:Text('p_text_name')
    self.goLimit = self:GameObject('p_limit')
    self.goOld = self:GameObject('p_old')
    self.textLimit = self:Text('p_text_limit', I18N.Get("shop_saleslimited"))
    self.textLimit1 = self:Text('p_text_limit_1')
    self.goMoney = self:GameObject('p_money')
    self.goMoneySinglepay = self:GameObject('money_singlepay')
    self.imgIconMoney = self:Image('p_icon_money')
    self.textMoney = self:Text('p_text_money')
    self.textMoneyOld = self:Text('p_text_money_old')
    self.imgIconMoneyOld = self:Image('p_icon_money_old')
    self.goMoneyDoublepay = self:GameObject('money_doublepay')
    self.imgIconMoney1 = self:Image('p_icon_money_1')
    self.textMoney1 = self:Text('p_text_money_1')
    self.textMoneyOld1 = self:Text('p_text_money_old_1')
    self.imgIconMoney2 = self:Image('p_icon_money_2')
    self.textMoney2 = self:Text('p_text_money_2')
    self.textMoneyOld2 = self:Text('p_text_money_old_2')
    self.goSold = self:GameObject('p_sold')
    self.goLock = self:GameObject('p_lock')
    self.textLock = self:Text('p_text_lock')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto', "goto")
    self.textLockItem = self:Text('p_text_lock_item')
    self.textSold = self:Text('p_text_sold', I18N.Get("shop_soldout"))
    self.goFree = self:GameObject('p_free')
    self.imgIconFree = self:Image('p_icon_free')
    self.textFree = self:Text('p_text_free')
end


function ShopItemCell:OnFeedData(shopInfo)
    self.commodityId = shopInfo.commodityId
    self.tabId = shopInfo.tabId
    self.buyNum = shopInfo.buyNum
    self.isFree = shopInfo.isFree
    local commodityCfg = ConfigRefer.ShopCommodity:Find(self.commodityId)
    self.isUnlock = true
    local sysEntryId = commodityCfg:SystemSwitch()
    if sysEntryId > 0 then
        self.isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysEntryId)
        if not self.isUnlock then
            local systemCfg = ConfigRefer.SystemEntry:Find(sysEntryId)
            if self.textLock then
                self.textLock.text = I18N.GetWithParams(systemCfg:LockedTips(), systemCfg:LockedTipsPrm())
            elseif self.textLockItem then
                self.textLockItem.text = I18N.GetWithParams(systemCfg:LockedTips(), systemCfg:LockedTipsPrm())
            end
        end
    end
    self.goFree:SetActive(self.isFree)
    self.goLock:SetActive(not self.isUnlock)
    local relateItemCfg = ConfigRefer.Item:Find(commodityCfg:RefItem())
    self.imgLine.color = QUALITY[relateItemCfg:Quality()]
    self.imgFrame.color = QUALITY[relateItemCfg:Quality()]
    g_Game.SpriteManager:LoadSprite(relateItemCfg:Icon(), self.imgItem)
    self.textName.text = I18N.Get(relateItemCfg:NameKey())
    local isSingleCost = commodityCfg:CostItemLength() == 1
    local limitCount = commodityCfg:Count()
    local isLimit = limitCount > 0
    local isSoldOut = isLimit and self.buyNum >= limitCount
    if self.goMoneySinglepay then
        self.goMoneySinglepay:SetActive(isSingleCost and self.isUnlock and not self.isFree and not isSoldOut)
    end
    if self.goMoneyDoublepay then
        self.goMoneyDoublepay:SetActive(self.isUnlock and not isSingleCost and not self.isFree and not isSoldOut)
    end
    UIHelper.SetGray(self.selfGo, isSoldOut)
    if self.goMoney then
        self.goMoney:SetActive(self.isUnlock and not self.isFree)
    end
    local discount = commodityCfg:Discount()
    local isHasDiscount = discount > 0
    if isHasDiscount then
        self.textDiscount.text = "-" .. discount .. "%"
    end
    self.goDiscount:SetActive(isHasDiscount)
    self.goOld:SetActive(isHasDiscount)
    if isSingleCost then
        local moneyCostId = commodityCfg:CostItem(1)
        g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(moneyCostId):Icon(), self.imgIconMoney)
        g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(moneyCostId):Icon(), self.imgIconMoneyOld)
        local moneyCost = commodityCfg:CostItemCount(1)
        self.textMoney.text = moneyCost
        self.textMoneyOld.gameObject:SetActive(isHasDiscount)
        if isHasDiscount then
            local showDiscount = 100 - discount
            self.textMoneyOld.text = math.floor((moneyCost * 100) / showDiscount)
        end
    else
        local moneyCostId = commodityCfg:CostItem(1)
        g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(moneyCostId):Icon(), self.imgIconMoney1)
        local moneyCost = commodityCfg:CostItemCount(1)
        self.textMoney1.text = moneyCost
        self.textMoneyOld1.gameObject:SetActive(isHasDiscount)
        if isHasDiscount then
            local showDiscount = 100 - discount
            self.textMoneyOld1.text = (moneyCost * 100) / showDiscount
        end
        local moneyCostId2 = commodityCfg:CostItem(2)
        g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(moneyCostId2):Icon(), self.imgIconMoney2)
        local moneyCost2 = commodityCfg:CostItemCount(2)
        self.textMoney2.text = moneyCost2
        self.textMoneyOld2.gameObject:SetActive(isHasDiscount)
        if isHasDiscount then
            local showDiscount = 100 - discount
            self.textMoneyOld2.text = (moneyCost2 * 100) / showDiscount
        end
    end
    if isLimit then
        self.goSold:SetActive(isSoldOut)
        self.goLimit:SetActive(self.isUnlock and not self.isFree)
        self.textLimit1.text = self.buyNum .. "/" .. limitCount
    else
        self.goSold:SetActive(false)
        self.goLimit:SetActive(false)
    end
    if self.isFree then
        local isDirectFree = self.buyNum == 0
        local videoId = commodityCfg:AdVideo()
        if isDirectFree then
            self.imgIconFree.gameObject:SetActive(false)
            self.textFree.text = I18N.Get("daily_btn_freefresh")
        else
            if videoId and videoId > 0 then
                local videoCfg = ConfigRefer.RewardVideo:Find(videoId)
                self.textFree.text = I18N.Get(videoCfg:ButtonName())
                local canWatchVideo, canClaimReward, _ = ModuleRefer.RewardVideoModule:GetRewardVideoStatus(videoId)
                if canClaimReward then
                    self.imgIconFree.gameObject:SetActive(false)
                elseif canWatchVideo then
                    self.imgIconFree.gameObject:SetActive(true)
                    g_Game.SpriteManager:LoadSprite(videoCfg:ButtonIcon(), self.imgIconFree)
                end
            else
                self.imgIconFree.gameObject:SetActive(false)
            end
        end
    end
    if self.btnGoto then
        self.btnGoto.gameObject:SetActive(commodityCfg:Goto() > 0)
    end
end

function ShopItemCell:OnBtnItemClicked()
    local commodityCfg = ConfigRefer.ShopCommodity:Find(self.commodityId)
    local bugFunc = function()
        local param = ShoppingParameter.new()
        param.args.StoreConfId = self.tabId
        param.args.BoughtItemID = self.commodityId
        param.args.Num = 0
        param.args.CostItemId = 0
        param:Send()
    end
    if self.isFree then
        if self.buyNum == 0 then
            bugFunc()
        elseif self.buyNum == 1 then
            local videoId = commodityCfg:AdVideo()
            if videoId and videoId > 0 then
                local canWatchVideo, canClaimReward, _ = ModuleRefer.RewardVideoModule:GetRewardVideoStatus(videoId)
                if canClaimReward then
                    bugFunc()
                elseif canWatchVideo then
                    self:PlayVideo()
                end
            else
                bugFunc()
            end
        end
        return
    end
    if not self.isUnlock then
        local sysEntryCfg = ConfigRefer.SystemEntry:Find(commodityCfg:SystemSwitch())
        if sysEntryCfg:LockedTipsPrm() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(sysEntryCfg:LockedTips(), sysEntryCfg:LockedTipsPrm()))
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(sysEntryCfg:LockedTips()))
        end
        return
    end
    local limitCount = commodityCfg:Count()
    local isLimit = limitCount > 0
    if isLimit then
        local isSoldOut = self.buyNum >= limitCount
        if isSoldOut then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("shop_com_soldout"))
            return
        end
    end
    ---@type CommodityItemDetailDataProvider
    local provider = CommodityItemDetailDataProvider.new(self.commodityId, self.tabId)
    provider:UseStoreBase(true)
    provider:UseGiftBase(false)
    provider:UseCommonDiscountTag(false)
    provider:UseSmallItemIcon(true)
    provider:ShowSlider(true)
    provider:BtnShowMask(CommodityItemDetailDataProvider.BtnShowBitMask.Left | CommodityItemDetailDataProvider.BtnShowBitMask.Right)
    g_Game.UIManager:Open("UIShopBuyPopupMeidator", {provider = provider})
end

function ShopItemCell:OnBtnGotoClicked()
    local commodityCfg = ConfigRefer.ShopCommodity:Find(self.commodityId)
    local gotoId = commodityCfg:Goto()
    if gotoId > 0 then
        GuideUtils.GotoByGuide(gotoId)
    end
end

function ShopItemCell:OnRewardVideoFinish()
	if not self.waitingForRewardVideoFinish then return end
	self.waitingForRewardVideoFinish = false
end

function ShopItemCell:PlayVideo()
	local has, sdkIronSource = SdkWrapper.TryGetSdkModule(CS.SdkAdapter.SdkModels.SdkIronSource)
	if has then
		local ironSource = sdkIronSource
        local commodityCfg = ConfigRefer.ShopCommodity:Find(self.commodityId)
        local videoId = commodityCfg:AdVideo()
		local params = {
			userid = tostring(ModuleRefer.PlayerModule:GetPlayerId()),
			conf_id = tostring(videoId),
			func_type = "2",
			func_arg1 = tostring(self.tabId),
            func_arg2 = tostring(self.commodityId),
		}
		if not ironSource:ShowVideo(params) then
			ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("rv_video_loadfail"))
		else
			self.waitingForRewardVideoFinish = true
		end
	end
end


return ShopItemCell
