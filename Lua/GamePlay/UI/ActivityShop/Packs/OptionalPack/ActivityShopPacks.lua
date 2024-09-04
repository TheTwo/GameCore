local BaseUIComponent = require('BaseUIComponent')
local I18N = require('I18N')
local ActivityShopConst = require('ActivityShopConst')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local TimeFormatter = require('TimeFormatter')
---@class ActivityShopPacks : BaseUIComponent
local ActivityShopPacks = class('ActivityShopPacks', BaseUIComponent)

function ActivityShopPacks._Round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power + 0.5) / power
end

function ActivityShopPacks:OnCreate()
    self.titleText = self:Text('p_title_option', I18N.Get(ActivityShopConst.I18N_KEYS.TITLE_OPTION))
    -- self.timeRemainText = self:Text('p_time_optiaon', I18N.Get(ActivityShopConst.I18N_KEYS.TIME_OPTION))
    self.timeText = self:Text('p_time_optiaon_1')
    self.imgTime = self:Image('icon_time')
    ---@type table<number, ActivityShopPackComponet>
    self.packs = {}
    for i = 1, ActivityShopConst.PACK_NUM do -- TODO 替换为配置项
        -- self.packs[i] = self:LuaObject('p_pack_' .. i)
        self.packs[i] = {}
        self.packs[i].packOff = self:GameObject('p_pack_off_' .. i)
        self.packs[i].packOn = self:GameObject('p_pack_on_' .. i)
        self.packs[i].discountTag = self:LuaObject('child_shop_discount_tag_' .. i)
        self.packs[i].textPrice = self:Text('p_text_price_' .. i)
        self.packs[i].soldOutMark = self:GameObject('p_pack_sold_out_' .. i)
        self.packs[i].textSoldOut = self:Text('p_text_pack_sold_out_' .. i, ActivityShopConst.I18N_KEYS.SOLD_OUT)
    end

    ---@type ActivityShopPackOptionContent
    self.optionContent = self:LuaObject('option_content')
    self.contentAnim = self:BindComponent('option_content', typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function ActivityShopPacks:OnFeedData(param)
    if not param then
        return
    end
    self.tabId = param.tabId
    self.packGroups = {}
    self.openTabIndex = nil
    local tabCfg = ConfigRefer.PayTabs:Find(self.tabId)
    for i = 1, tabCfg:GoodsGroupsLength() do
        self.packGroups[i] = ConfigRefer.PayGoodsGroup:Find(tabCfg:GoodsGroups(i))
        self.packs[i].packId = self.packGroups[i]:Goods(1)
        local packCfg = ConfigRefer.PayGoods:Find(self.packs[i].packId)
        local discount = packCfg:Discount()
        local quality = packCfg:DiscountQuality()
        local payId = packCfg:PayPlatformId()
        local pay = ConfigRefer.PayPlatform:Find(payId)
        local isSoldOut, curNum, limitNum = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(self.packs[i].packId, true)
        local payInfo = ModuleRefer.PayModule:GetProductData(pay:FPXProductId())
        self.packs[i].index = i
        self.packs[i].price = payInfo.amount
        self.packs[i].currency = payInfo.currency
        self.packs[i].isSoldOut = isSoldOut
        self.packs[i].limitNum = limitNum
        self.packs[i].curNum = curNum
        self.packs[i].discountTag:FeedData({
            discount = discount,
            quality = quality,
            isSoldOut = isSoldOut,
        })
        self.packs[i].textPrice.text = string.format('%s %.2f', self.packs[i].currency, self.packs[i].price)
        self.packs[i].OnClick = function()
            self:OnSelectPack(i)
        end
        self.packs[i].packOn:SetActive(false)
        self:PointerClick('pack_close_' .. i, self.packs[i].OnClick)
        self:SetPackIconStatus(i, self.packs[i].isSoldOut)
        if not isSoldOut and not self.openTabIndex then
            self.openTabIndex = i
        end
    end
    self.optionContent:SetVisible(false)
    self.imgTime.gameObject:SetActive(false)
    self:OnSelectPack(self.openTabIndex)
    -- self:RemainingTimeTicker()
end

function ActivityShopPacks:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_CUSTOM_PACK, Delegate.GetOrCreate(self, self.OnSelectPack))
end

function ActivityShopPacks:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_CUSTOM_PACK, Delegate.GetOrCreate(self, self.OnSelectPack))
end

function ActivityShopPacks:RemainingTimeTicker()
    local timeSec = ModuleRefer.ActivityShopModule:GetTabRemainingTime(self.tabId)
    self.timeText.text = I18N.GetWithParams(ActivityShopConst.I18N_KEYS.TIME_DETAIL_OPTION, TimeFormatter.SimpleFormatTime(timeSec))
end

function ActivityShopPacks:OnSelectPack(index, isDataOnly)
    ---@class PackInfo
    ---@field packId number
    ---@field index number
    ---@field price number
    ---@field currency string
    ---@field isSoldOut boolean
    ---@field limitNum number
    ---@field curNum number
    ---@type PackInfo
    local info = {}
    info.packId = self.packs[index].packId
    info.index = self.packs[index].index
    info.price = self.packs[index].price
    info.currency = self.packs[index].currency
    info.isSoldOut = self.packs[index].isSoldOut
    info.limitNum = self.packs[index].limitNum
    info.curNum = self.packs[index].curNum
    if info.isSoldOut then
        return
    end

    self.optionContent:FeedData(info)

    if isDataOnly then
        return
    end

    for i = 1, #self.packs do
        self.packs[i].packOn:SetActive(i == index)
        self.packs[i].packOff:SetActive(i ~= index)
    end
    self.optionContent:SetVisible(true)
    self.contentAnim:PlayAll(CS.FpAnimation.CommonTriggerType.OnEnable)
end

function ActivityShopPacks:SetPackIconStatus(i, isSoldOut)
    self.packs[i].soldOutMark:SetActive(isSoldOut)
end

function ActivityShopPacks:UpdatePacks()
    for i = 1, #self.packs do
        local packId = self.packGroups[i]:Goods(1)
        local isSoldOut, curNum, limitNum = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(packId, true)
        if self.packs[i].isSoldOut ~= isSoldOut then
            self.packs[i].isSoldOut = isSoldOut
            self.packs[i].limitNum = limitNum
            self.packs[i].curNum = curNum
            self:OnSelectPack(i, true)
            self:SetPackIconStatus(i, self.packs[i].isSoldOut)
        end
    end
end

return ActivityShopPacks