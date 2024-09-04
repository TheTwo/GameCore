local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local ProtocolId = require("ProtocolId")
local ActivityShopConst = require("ActivityShopConst")
local DBEntityPath = require("DBEntityPath")
local NotificationType = require("NotificationType")
local SyncPayGroupRedDotParameter = require("SyncPayGroupRedDotParameter")
local PayGoodsGroupType = require("PayGoodsGroupType")
local EventConst = require("EventConst")
local ArtResourceUtils = require("ArtResourceUtils")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local TimerUtility = require("TimerUtility")
local FunctionClass = require("FunctionClass")
local PayGoodsShopItemDetailDataProvider = require("PayGoodsShopItemDetailDataProvider")
local PayType = require("PayType")
local PayByItemGroupParameter = require("PayByItemGroupParameter")
---@class ActivityShopModule : BaseModule
local ActivityShopModule = class("ActivityShopModule", BaseModule)

--- Utils ---

function ActivityShopModule._Round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power + 0.5) / power
end

function ActivityShopModule.GoodsIsSoldOutComparator(a, b)
    local priority = {
        [true] = 1,
        [false] = 2,
    }
    local aCfg = ConfigRefer.PayGoodsGroup:Find(a)
    local bCfg = ConfigRefer.PayGoodsGroup:Find(b)
    local aPackId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(a) or aCfg:Goods(aCfg:GoodsLength())
    local bPackId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(b) or bCfg:Goods(bCfg:GoodsLength())
    local aIsSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(aPackId)
    local bIsSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(bPackId)
    local aDiscount = ConfigRefer.PayGoods:Find(aPackId):Discount()
    local bDiscount = ConfigRefer.PayGoods:Find(bPackId):Discount()
    if priority[aIsSoldOut] ~= priority[bIsSoldOut] then
        return priority[aIsSoldOut] > priority[bIsSoldOut]
    elseif aCfg:ShownPriority() ~= bCfg:ShownPriority() then
        return aCfg:ShownPriority() < bCfg:ShownPriority()
    -- elseif aDiscount ~= bDiscount then
    --     return aDiscount > bDiscount
    else
        return a < b
    end
end

--- end of Utils ---

--- Life Cycle ---

function ActivityShopModule:ctor()
    self.isFirstRechargeTimelinePlayed = false
end

function ActivityShopModule:OnRegister()
    self.isforbid = false
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self.playerPayInfo = player.PlayerWrapper2.PlayerPay
    ---@type table<number, boolean>
    self.groupOpenedCache = {}
    self.delayedUpdateRedDotGroupIds = {}
    self._SetNotificationNodes()
    self:InitRedDot()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.GetForbidSwitch, Delegate.GetOrCreate(self, self.RefreshState))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnGroupDataChange))
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
end

function ActivityShopModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.GetForbidSwitch, Delegate.GetOrCreate(self, self.RefreshState))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnGroupDataChange))
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
end

--- end of Life Cycle ---

--- Callbacks ---

function ActivityShopModule:OnGroupDataChange(_, changeTable)
    self:UpdateTabGroupOpenedCache()
    self:InitRedDot()
end

function ActivityShopModule:OnPaySuccess()
    if not self.lastPurchasedGoodId then
        return
    end
    if self.isPurchaseGem then
        local data = {
            goodsId = self.lastPurchasedGoodId,
        }
        g_Game.UIManager:Open(UIMediatorNames.ActivityShopGemsRewardPopupMediator, data)
        return
    end
    local gId = ConfigRefer.PayGoods:Find(self.lastPurchasedGoodId):ItemGroupId()
    if self:IsFree(self.lastPurchasedGoodId) then
        ---@type UIRewardMediatorParameter
        local data = {}
        data.itemInfo = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(gId)
        ModuleRefer.RewardModule:ShowDefaultReward(data)
        return
    end
    local itemArray = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(gId)
    if not itemArray then return end
    if self.lastChoseItems then
        for _, groupId in ipairs(self.lastChoseItems) do
            local item = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(groupId)[1]
            table.insert(itemArray, item)
        end
    end
    local icon = ConfigRefer.PayGoods:Find(self.lastPurchasedGoodId):Icon()
    local data = {
        itemArray = itemArray,
        icon = ArtResourceUtils.GetUIItem(icon),
    }
    local isAddHero = false
    for _, item in ipairs(itemArray) do
        if item.configCell:FunctionClass() == FunctionClass.AddHero then
            isAddHero = true
            break
        end
    end
    local delayFrames = 1
    if isAddHero then
        delayFrames = 10
    end
    TimerUtility.DelayExecuteInFrame(function()
        ---@type UIAsyncDataProvider
        local provider = UIAsyncDataProvider.new()
        provider:Init(UIMediatorNames.ActivityShopPackRewardPopupMediator,
                    UIAsyncDataProvider.PopupTimings.AnyTime,
                    UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator,
                    UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable,
                    false, data)
        provider:SetOtherMediatorCheckType(0)
        provider:AddOtherMediatorBlackList(UIMediatorNames.UIShopBuyPopupMeidator)
        provider:AddOtherMediatorBlackList(UIMediatorNames.UIOneDaySuccessMediator)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end, delayFrames)
end

--- end of Callbacks ---

--- Data Update ---

function ActivityShopModule:UpdateTabGroupOpenedCache()
    for _, tab in ConfigRefer.PayTabs:ipairs() do
        for i = 1, tab:GoodsGroupsLength() do
            local groupId = tab:GoodsGroups(i)
            local isOpen = self:IsGoodsGroupOpen(groupId)
            self.groupOpenedCache[groupId] = isOpen
        end
    end
end

function ActivityShopModule:RefreshState(isSuccess, reply, rpc)
    if not isSuccess then return end
    self.isforbid = reply.Forbid
end

--- end of Data Update ---

--- Reddots ---

function ActivityShopModule:IsOnlyRedDotChanged(changeTable)
    if not changeTable then
        return false
    end
    for _, e in pairs(changeTable) do
        for k, _ in pairs(e) do
            if k ~= 'RedDotMask' then
                return false
            end
        end
    end
    return true
end

function ActivityShopModule._SetNotificationNodes()
    local hudNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        ActivityShopConst.NotificationNodeNames.ActivityShopEntry, NotificationType.ACTIVITY_SHOP_HUD)
    for _, tab in ConfigRefer.PayTabs:ipairs() do
        local tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
            ActivityShopConst.NotificationNodeNames.ActivityShopTab .. tab:Id(), NotificationType.ACTIVITY_SHOP_TAB)
        ModuleRefer.NotificationModule:AddToParent(tabNode, hudNode)
        for i = 1, tab:GoodsGroupsLength() do
            local groupId = tab:GoodsGroups(i)
            local packNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
                ActivityShopConst.NotificationNodeNames.ActivityShopPack .. groupId, NotificationType.ACTIVITY_SHOP_PACK)
            ModuleRefer.NotificationModule:AddToParent(packNode, tabNode)
        end
        if tab:Id() == ActivityShopConst.DALIY_TAB_ID then
            local giftNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
                ActivityShopConst.NotificationNodeNames.ActivityShopPack .. ActivityShopConst.DALIY_GIFT_PSEUDO_ID,
                NotificationType.ACTIVITY_SHOP_PACK)
            ModuleRefer.NotificationModule:AddToParent(giftNode, tabNode)
        end
    end
end

function ActivityShopModule:InitRedDot()
    self:UpdateRedDotByGroupId(ActivityShopConst.DALIY_GIFT_PSEUDO_ID, self:IsDailyRewardCanClaim())
    for _, tab in ConfigRefer.PayTabs:ipairs() do
        local isTabNew = false
        for i = 1, tab:GoodsGroupsLength() do
            local groupId = tab:GoodsGroups(i)
            local isNew = self:IsGoodsGroupNew(groupId)
            self:UpdateRedDotByGroupId(groupId, isNew)
            isTabNew = isTabNew or isNew
        end
    end
end

function ActivityShopModule:UpdateRedDotByGroupId(groupId, shouldShow)
    local groupNode = ModuleRefer.NotificationModule:GetDynamicNode(
        ActivityShopConst.NotificationNodeNames.ActivityShopPack .. groupId, NotificationType.ACTIVITY_SHOP_PACK)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(groupNode, shouldShow and 1 or 0)
end

function ActivityShopModule:SyncGoodsGroupRedDot(groups, redDotMasks)
    if not groups or not redDotMasks then
        return
    end
    local msg = SyncPayGroupRedDotParameter.new()
    msg.args.Groups:AddRange(groups)
    msg.args.RedDotMasks:AddRange(redDotMasks)
    msg:Send()
end

--- end of Reddots ---

--- Other Interfaces ---

--- 活动商店是否开启
---@return boolean
function ActivityShopModule:IsActivityShopOpen()
    local sysId = ActivityShopConst.SYSTEM_ENTRY_ID
    local isOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysId)
    return isOpen
end

--- 每日礼物是否可领取
---@return boolean
function ActivityShopModule:IsDailyRewardCanClaim()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then return false end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local nextCanClaimTime = player.PlayerWrapper2.PlayerPay.NextDailyRewardDayBegin.Seconds
    return curTime > nextCanClaimTime
end

--- 商品是否售罄
---@param goodsId number
---@param shouldReturnNums boolean @是否返回已购买数量和限购数量
---@return boolean | boolean, number, number
function ActivityShopModule:IsGoodsSoldOut(goodsId, shouldReturnNums)
    local limit = ConfigRefer.PayGoods:Find(goodsId):BuyLimit()
    if not limit or limit == 0 then
        limit = math.huge
    end
    local boughtNums = self.playerPayInfo.ProductId2TimesPeriod[goodsId] or 0
    local isSoldOut = boughtNums >= limit
    if shouldReturnNums then
        return isSoldOut, boughtNums, limit
    end
    return isSoldOut
end

--- 商品组是否售罄
---@param goodsGroupId number
---@return boolean
function ActivityShopModule:IsGoodsGroupSoldOut(goodsGroupId)
    local groupCfg = ConfigRefer.PayGoodsGroup:Find(goodsGroupId)
    for i = 1, groupCfg:GoodsLength() do
        local goodsId = groupCfg:Goods(i)
        if not self:IsGoodsSoldOut(goodsId) then
            return false
        end
    end
    return true
end

--- 商品组是否新开启
---@param pGroupId number
---@return boolean
function ActivityShopModule:IsGoodsGroupNew(pGroupId)
    local groupData = self.playerPayInfo.GroupData[pGroupId]
    if not groupData then
        return false
    end
    return groupData.RedDotMask > 0
end

--- 商品组是否开启
---@param pGroupId number
---@return boolean
function ActivityShopModule:IsGoodsGroupOpen(pGroupId)
    if not pGroupId then return false end
    local groupData = self.playerPayInfo.GroupData[pGroupId]
    if not groupData then
        return false
    end
    return groupData.OpenState == 1
end

--- 获取商品组中第一个可用（未售罄）的商品id
---@param pGroupId number
---@return number
function ActivityShopModule:GetFirstAvaliableGoodInGroup(pGroupId)
    if not self:IsGoodsGroupOpen(pGroupId) then
        return nil
    end
    local groupCfg = ConfigRefer.PayGoodsGroup:Find(pGroupId)
    for i = 1, groupCfg:GoodsLength() do
        local goodsId = groupCfg:Goods(i)
        if not self:IsGoodsSoldOut(goodsId) then
            return goodsId
        end
    end
    return groupCfg:Goods(1)
end

--- 获取商品价格和货币类型
---@param goodsId number
---@return number, string
function ActivityShopModule:GetGoodsPrice(goodsId)
    local packCfg = ConfigRefer.PayGoods:Find(goodsId)
    if not packCfg then return 0, "" end
    local payId = packCfg:PayPlatformId()
    local pay = ConfigRefer.PayPlatform:Find(payId)
    local payInfo = ModuleRefer.PayModule:GetProductData(pay:FPXProductId())
    local price = payInfo.amount
    local currency = payInfo.currency
    return price, currency
end

--- 获取商品已购买次数
---@param goodsId number
---@param isPeriod boolean
---@return number
function ActivityShopModule:GetGoodsPurchasedTimes(goodsId, isPeriod)
    if isPeriod then
        return self.playerPayInfo.ProductId2TimesPeriod[goodsId] or 0
    end
    return self.playerPayInfo.ProductId2Times[goodsId] or 0
end

--- 获取商品充值积分
---@param goodsId number
---@return number
function ActivityShopModule:GetGoodsExchangePointsNum(goodsId)
    local packCfg = ConfigRefer.PayGoods:Find(goodsId)
    local exchangePointsGid = packCfg:TopUpItemGroup()
    if exchangePointsGid == 0 then
        -- g_Logger.Error(("PayGoods Id %d 没有配置充值积分"):format(goodsId))
        return 0
    end
    local points = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(exchangePointsGid)[1].count
    return points
end

--- 获取页签剩余时间
---@param tabId number
---@return number
function ActivityShopModule:GetTabRemainingTime(tabId)
    local maxRemainingTime = 0
    local tab = ConfigRefer.PayTabs:Find(tabId)
    if tab then
        for j = 1, tab:GoodsGroupsLength() do
            local remainingTime = self:GetRemainingTime(tab:GoodsGroups(j))
            if remainingTime > maxRemainingTime then
                maxRemainingTime = remainingTime
            end
        end
    end
    return maxRemainingTime
end

--- 获取商品组剩余时间
---@param pGroupId number
---@return number
function ActivityShopModule:GetRemainingTime(pGroupId)
    local goodsGroup = ConfigRefer.PayGoodsGroup:Find(pGroupId)
    local groupType = goodsGroup:Type()
    local durationTime = goodsGroup:DurationTime() / 1e9
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then return 0 end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if groupType == PayGoodsGroupType.Period then
        if not player.PlayerWrapper2.PlayerPay.GroupData[pGroupId] then
            return 0
        end
        return (player.PlayerWrapper2.PlayerPay.GroupData[goodsGroup:Id()].NextRefreshUpdateTime or curTime)
                - curTime
    end
    local startTime = player.PlayerWrapper2.PlayerPay.GroupData[goodsGroup:Id()].OpenTime
    local remainingTime = startTime + durationTime - curTime
    return remainingTime
end

--- 获取页签剩余时间（天、时、分、秒）
---@param tabId number
---@return number, number, number, number
function ActivityShopModule:GetTabRemainingTimeInDHMS(tabId)
    local remainingTime = self:GetTabRemainingTime(tabId)
    local day = math.floor(remainingTime / 86400)
    local hour = math.floor((remainingTime % 86400) / 3600)
    local minute = math.floor((remainingTime % 3600) / 60)
    local second = math.floor(remainingTime % 60)
    return day, hour, minute, second
end

---@param pGroupId number
---@return CommonDiscountTagParam
function ActivityShopModule:GetDiscountTagParamByGroupId(pGroupId)
    local goodId = self:GetFirstAvaliableGoodInGroup(pGroupId)
    if not goodId then
        local groupCfg = ConfigRefer.PayGoodsGroup:Find(pGroupId)
        goodId = groupCfg:Goods(1)
    end
    return self:GetDiscountTagParamByGoodId(goodId)
end

---@param pGoodId number
---@return CommonDiscountTagParam
function ActivityShopModule:GetDiscountTagParamByGoodId(pGoodId)
    ---@type CommonDiscountTagParam
    local dummy = {
        discount = 0,
        quality = 0,
        isSoldOut = true,
    }
    local packCfg = ConfigRefer.PayGoods:Find(pGoodId)
    if not packCfg then return dummy end
    local discount = packCfg:Discount()
    local discountQuality = packCfg:DiscountQuality()
    local isSoldOut = self:IsGoodsSoldOut(pGoodId)
    local discountTagParam = {
        discount = discount,
        quality = discountQuality,
        isSoldOut = isSoldOut,
    }
    return discountTagParam
end

---@param goodId number
---@return string
function ActivityShopModule:GetGoodParameterizedDesc(goodId)
    local mainItemNamesStr = ""
    local goodCfg = ConfigRefer.PayGoods:Find(goodId)
    local itemList = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(goodCfg:ItemGroupId())
    for i = 1, goodCfg:DescItemIndexLength() do
        local item = itemList[goodCfg:DescItemIndex(i)]
        if item then
            local itemName = I18N.Get(ConfigRefer.Item:Find(item.id):NameKey())
            if i == 1 then
                mainItemNamesStr = itemName
            else
                mainItemNamesStr = mainItemNamesStr .. ", " .. itemName
            end
        end
    end
    return I18N.GetWithParams(goodCfg:Desc(), mainItemNamesStr)
end

--- 获取首充弹窗id
---@return number
function ActivityShopModule:GetFirstRechargePopId()
    return 60
end

function ActivityShopModule:GetFirstRechargeBubbleProgress()
    local taskId = ConfigRefer.CityConfig:FirstRechargeNpcTimerTask()
    ---@type TaskItemDataProvider
    local provider = require("TaskItemDataProvider").new(taskId)
    local receiveTime = provider:GetTaskReceiveTimeSec()
    local duration = provider:GetTaskConditionParam(1, 1, 1)
    local endTime = receiveTime + duration
    return {
        startTime = receiveTime,
        endTime = endTime,
    }
end

function ActivityShopModule:OpenPopMediatorByPGroupId(pGroupId)
    local popIds = ModuleRefer.LoginPopupModule:GetAllAvailablePopIdsForPayGroups()
    local popId = 0
    for _, id in ipairs(popIds) do
        local popCfg = ConfigRefer.PopUpWindow:Find(id)
        if popCfg:PayGroup() == pGroupId then
            popId = id
            break
        end
    end
    if popId == 0 then
        g_Logger.ErrorChannel("ActivityShopModule", "当前礼包未开启, id: %d", pGroupId)
        return
    end
    ---@type UIFirstRechargeMediatorParam
    local data = {}
    data.isFromHud = true
    data.openPopId = popId
    g_Game.UIManager:Open(UIMediatorNames.UIFirstRechargeMediator, data)
end

function ActivityShopModule:GetGoodPayType(goodsId)
    local packCfg = ConfigRefer.PayGoods:Find(goodsId)
    if not packCfg then return 0 end
    return packCfg:PayType()
end

function ActivityShopModule:IsFree(goodsId)
    return self:GetGoodPayType(goodsId) == PayType.Free
end

---@param goodsId number
---@return ItemIconData
function ActivityShopModule:GetPayItem(goodsId)
    if self:GetGoodPayType(goodsId) ~= PayType.ItemGroup then
        return nil
    end
    local packCfg = ConfigRefer.PayGoods:Find(goodsId)
    local itemGroupId = packCfg:PayItemGroupId()
    local itemArray = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
    return itemArray[1]
end

---@private
function ActivityShopModule:PurchaseWithGameItemOrFree(goodId, chooseItems)
    local item = self:GetPayItem(goodId)
    local need = item.count
    local have = ModuleRefer.InventoryModule:GetAmountByConfigId(item.configCell:Id())
    if have < need then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("/*道具不足"))
        return
    end

    local msg = PayByItemGroupParameter.new()
    msg.args.GoodsId = goodId
    if chooseItems then
        msg.args.ChooseItemGroups:AddRange(chooseItems)
    end
    msg:SendOnceCallback(nil, nil, nil, function (_, isSuccess, rsp)
        if isSuccess then
            local id = rsp.GoodsId
            g_Game.EventManager:TriggerEvent(EventConst.PAY_SUCCESS, id)
        end
    end)
end

--- 购买商品
---@param goodId number
---@param chooseItems table<number, number> @itemGroupId[]，用于自选道具，一般不用传
---@param shouldShowDetail boolean @true: 显示商品详情弹窗，false: 显示通用确认弹窗
---@param isPurchaseGem boolean
function ActivityShopModule:PurchaseGoods(goodId, chooseItems, shouldShowDetail, isPurchaseGem)
    if not goodId or goodId <= 0 or not ConfigRefer.PayGoods:Find(goodId) then
        g_Logger.ErrorChannel("ActivityShopModule", "Purchase failed, no such product: %d", goodId or -1)
        return
    end
    if self.isforbid then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("activity_shop_pay_hint_title")
        dialogParam.content = I18N.Get("top_up_disable_message_txt")
        dialogParam.onConfirm = function()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
        return
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local payNumber = player.PlayerWrapper2.PlayerPay.AccPay or 0
    if payNumber >= ConfigRefer.ConstMain:PayMaxNumber() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("activity_shop_pay_limit"))
        return
    end
    local isUseFunplusDiamond = ModuleRefer.PayModule:IsUseFunplusDiamond()
    if not shouldShowDetail then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("activity_shop_pay_hint_title")
        local goodCfg = ConfigRefer.PayGoods:Find(goodId)
        local itemArray = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(goodCfg:ItemGroupId())
        local item = itemArray[1]
        local itemName
        if item then
            itemName = I18N.Get(ConfigRefer.Item:Find(item.id):NameKey())
        else
            itemName = I18N.Get(goodCfg:Name())
        end
        local payPlatformId = goodCfg:PayPlatformId()
        local payPlatformCfg = ConfigRefer.PayPlatform:Find(payPlatformId)
        if self:IsFree(goodId) then
            dialogParam.content = I18N.GetWithParams("/*免费获取{1}?", I18N.Get(goodCfg:Name()))
        elseif isUseFunplusDiamond then
            dialogParam.content = I18N.GetWithParams("activity_shop_pay_hint", payPlatformCfg:FunplusDiamond() .. I18N.Get(payPlatformCfg:Name()), (item or {}).count or 1 .. itemName)
            dialogParam.onConfirm = function()
                g_Logger.Error("top_up_response_txt")
                return true
            end
        elseif self:GetGoodPayType(goodId) == PayType.ItemGroup then
            local item = self:GetPayItem(goodId)
            dialogParam.content = I18N.GetWithParams("/*是否使用{1}*{2}购买此商品?", I18N.Get(item.configCell:NameKey()), item.count)
            dialogParam.onConfirm = function()
                self:PurchaseWithGameItemOrFree(goodId, chooseItems)
                return true
            end
        else
            local productInfos = ModuleRefer.PayModule:GetProductData(payPlatformCfg:FPXProductId())
            dialogParam.content = I18N.GetWithParams("activity_shop_pay_hint", productInfos.price, (item or {}).count or 1 .. itemName)
            dialogParam.onConfirm = function()
                ModuleRefer.PayModule:BuyGoods(goodId, chooseItems)
                return true
            end
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        ---@type PayGoodsShopItemDetailDataProvider
        local provider = PayGoodsShopItemDetailDataProvider.new(goodId, chooseItems)
        provider:UseCommonDiscountTag(true)
        provider:UseStoreBase(false)
        provider:UseGiftBase(true)
        provider:UseSmallItemIcon(false)
        provider:ShowSlider(false)
        provider:BtnShowMask(PayGoodsShopItemDetailDataProvider.BtnShowBitMask.Center)
        g_Game.UIManager:Open(UIMediatorNames.UIShopBuyPopupMeidator, {provider = provider})
    end
    self.lastPurchasedGoodId = goodId
    self.lastChoseItems = chooseItems
    self.isPurchaseGem = isPurchaseGem
end

return ActivityShopModule

--- end of Other Interfaces ---