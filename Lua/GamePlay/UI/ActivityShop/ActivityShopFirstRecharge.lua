local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local FunctionClass = require('FunctionClass')
local HeroUIUtilities = require('HeroUIUtilities')
local UIHelper = require("UIHelper")
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local Utils = require('Utils')
---@class ActivityShopFirstRecharge : BaseUIComponent
local ActivityShopFirstRecharge = class('ActivityShopFirstRecharge', BaseUIComponent)

local OFFSET_X_ON_NOT_TAB_SHOW = 118 * 2

local BASE_IMG_QUALITY = {
    'sp_common_base_collect_s_01',
    'sp_common_base_collect_s_01',
    'sp_common_base_collect_s_02',
    'sp_common_base_collect_s_03',
    'sp_common_base_collect_s_04',
}

local PET_ATTR_LEVEL_ICON = {
    'sp_pet_icon_quality_c',
    'sp_pet_icon_quality_c',
    'sp_pet_icon_quality_b',
    'sp_pet_icon_quality_a',
    'sp_pet_icon_quality_s',
}

local PET_ATTR_LEVEL_FRAME = {
    'sp_pet_base_quality_c',
    'sp_pet_base_quality_c',
    'sp_pet_base_quality_b',
    'sp_pet_base_quality_a',
    'sp_pet_base_quality_s',
}

function ActivityShopFirstRecharge:OnCreate()
    self.root = self:GameObject('')
    self.imgImgHero = self:Image('p_img_hero')
    self.textTitle1 = self:Text('p_text_title_1')
    self.textTitle2 = self:Text('p_text_title_2')
    self.textTitle3 = self:Text('p_text_title_3')
    self.textQuality = self:Text('p_text_quantity')
    self.textDetail = self:Text('p_text_detail')
    self.imgBaseQuality = self:Image('p_base_quantity')
    self.tableviewproTableItem = self:TableViewPro('p_table_item')

    self.btnCompB = self:Button('child_comp_btn_e_l', Delegate.GetOrCreate(self, self.OnBtnCompBClicked))
    self.textText = self:Text('p_text')
    self.textExchange = self:Text('p_text_num')

    self.textHint = self:Text('p_text_hint')
    self.btnInfo = self:Button('p_btn_info', Delegate.GetOrCreate(self, self.OnBtnInfoClicked))
    self.textInfo = self:Text('p_text_info', I18N.Get('*活动说明'))
    self.btnHeroDetail = self:Button('p_btn_hero_detail', Delegate.GetOrCreate(self, self.OnBtnHeroDetailClicked))
    self.textHeroDetail = self:Text('p_text_hero_detail', I18N.Get('first_pay_hero_goto'))
    self.btnVideo = self:Button('p_btn_video', Delegate.GetOrCreate(self, self.OnBtnVideoClicked))
    self.textVideo = self:Text('p_text_video', I18N.Get('first_pay_hero_skill'))
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))

    self.discountTag = self:LuaBaseComponent('child_shop_discount_tag')

    self.baseActivity = self:GameObject('vx_base')

    self.goAttr = self:GameObject('aptitude')
    self.attrs = {
        {
            imgBase = self:Image('p_base_1'),
            textAttr = self:Text('p_text_aptitude_1', ConfigRefer.PetConsts:PetAttrCtgrEstm1()),
            imgIconAttr = self:Image('p_icon_aptitude_1'),
        },
        {
            imgBase = self:Image('p_base_2'),
            textAttr = self:Text('p_text_aptitude_2', ConfigRefer.PetConsts:PetAttrCtgrEstm2()),
            imgIconAttr = self:Image('p_icon_aptitude_2'),
        },
        {
            imgBase = self:Image('p_base_3'),
            textAttr = self:Text('p_text_aptitude_3', ConfigRefer.PetConsts:PetAttrCtgrEstm3()),
            imgIconAttr = self:Image('p_icon_aptitude_3'),
        }
    }
    self.aniUI = self:GameObject('ani_ui')
end

function ActivityShopFirstRecharge:OnFeedData(param)
    if not param then
        return
    end
    if self.aniUI then
        self.aniUI:SetActive(true)
    end
    self.isShop = param.isShop
    self.shouldOffset = param.shouldOffset
    self.openedPackGroups = param.openedPackGroups
    self.popId = param.popId
    self.tabId = param.tabId
    self.tabCfg = ConfigRefer.PayTabs:Find(self.tabId)
    self.popCfg = ConfigRefer.PopUpWindow:Find(self.popId)
    self:Init()
end

function ActivityShopFirstRecharge:OnShow()
   g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPurchased))
end

function ActivityShopFirstRecharge:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPurchased))
end

function ActivityShopFirstRecharge:Init()
    self:SetShopObjsVisiable(self.isShop)
    if self.isShop then
        self.packGroupId = self.openedPackGroups[1]
    else
        self.packGroupId = ConfigRefer.PopUpWindow:Find(self.popId):PayGroup()
    end

    if self.shouldOffset then
        -- self.root.transform.localPosition = CS.UnityEngine.Vector3(
        --     self.root.transform.localPosition.x - OFFSET_X_ON_NOT_TAB_SHOW,
        --     self.root.transform.localPosition.y, self.root.transform.localPosition.z)
    end
    local groupCfg = ConfigRefer.PayGoodsGroup:Find(self.packGroupId)
    for i = 1, groupCfg:GoodsLength() do
        local packId = groupCfg:Goods(i)
        if not ModuleRefer.ActivityShopModule:IsGoodsSoldOut(packId) then
            self.packId = packId
            break
        end
    end
    local packCfg = ConfigRefer.PayGoods:Find(self.packId)
    local discount = packCfg:Discount()
    local discountQuality = packCfg:DiscountQuality()
    self.discountTag:FeedData({
        discount = discount,
        quality = discountQuality,
    })
    self.textTitle1.text = I18N.Get(packCfg:Name())
    self.textDetail.text = I18N.Get(packCfg:Desc())
    if self.textTitle2 then
        self.textTitle2.text = '+1'
    end
    local itemGroupId = packCfg:ItemGroupId()
    self:FillItemsTable(itemGroupId)
    local payId = packCfg:PayPlatformId()
    local pay = ConfigRefer.PayPlatform:Find(payId)
    local payInfo = ModuleRefer.PayModule:GetProductData(pay:FPXProductId())
    if payInfo then
        local price = payInfo.amount
        local currency = payInfo.currency
        self.textText.text = string.format('%s %.2f', currency, price)
    end
    local cfg = self.tabCfg or self.popCfg
    if cfg then
        self.heroId = cfg:GotoHero()
        self.petId = cfg:GotoPet()
        self.demoIds = {}
        for i = 1, cfg:DemoVideosLength() do
            local demoId = cfg:DemoVideos(i)
            table.insert(self.demoIds, demoId)
        end
    end
    self.btnInfo.gameObject:SetActive(false)
    self.btnHeroDetail.gameObject:SetActive(self.heroId and self.heroId > 0 or self.petId and self.petId > 0)
    self.btnVideo.gameObject:SetActive(self.demoIds and #self.demoIds > 0)
    if self.petId and self.petId > 0 then
        self.goAttr:SetActive(true)
        self:SetPetAttrs(1, 5)
        self:SetPetAttrs(2, 5)
        self:SetPetAttrs(3, 4) -- 这个版本写死
    end

    self.textExchange.text = '+' .. ModuleRefer.ActivityShopModule:GetGoodsExchangePointsNum(self.packId)
end

function ActivityShopFirstRecharge:OnFirstPayStateChange()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local firstPayState = player.PlayerWrapper2.PlayerPay.FirstPayState
    if firstPayState < wds.FirstPayState.FirstPayState_PayNotReceiveReward then
        self.textText.text = I18N.Get('first_pay_gotopay_button')
        self.textHint.text = I18N.Get('first_pay_gotopay_txt')
        self.textHint:SetVisible(true)
    elseif firstPayState == wds.FirstPayState.FirstPayState_PayNotReceiveReward then
        self.textText.text = I18N.Get('first_pay_claim_button')
        self.textHint:SetVisible(false)
    else
        -- 已领取
    end
end

function ActivityShopFirstRecharge:SetShopObjsVisiable(isShop)
    if Utils.IsNull(self.baseActivity) then
        self.baseActivity = self:GameObject('vx_base')
    end
    self.btnClose.gameObject:SetActive(not isShop)
    self.baseActivity:SetActive(isShop)
end

function ActivityShopFirstRecharge:FillItemsTable(itemGroupId)
    local rewards = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
    self.tableviewproTableItem:Clear()
    for i, reward in ipairs(rewards) do
        local name = reward.configCell:NameKey()
        local quality = reward.configCell:Quality() - 2
        local count = reward.count
        if i == 1 then
            self.shouldShowHeroGet = reward.configCell:FunctionClass() == FunctionClass.AddHero
            self.textTitle3.text = I18N.Get(name)
            self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(quality))
            self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(quality))
            g_Game.SpriteManager:LoadSprite(BASE_IMG_QUALITY[quality + 2], self.imgBaseQuality)
        end
        local data = {}
        data.configCell = reward.configCell
        data.count = count
        data.showTips = true
        self.tableviewproTableItem:AppendData(data)
    end
end

function ActivityShopFirstRecharge:SetPetAttrs(index, quality)
    g_Game.SpriteManager:LoadSprite(PET_ATTR_LEVEL_ICON[quality], self.attrs[index].imgIconAttr)
    g_Game.SpriteManager:LoadSprite(PET_ATTR_LEVEL_FRAME[quality], self.attrs[index].imgBase)
end

function ActivityShopFirstRecharge:OnPurchased()
    -- if not self.heroId or self.heroId <= 0 or not self.shouldShowHeroGet then
    --     return
    -- end
    -- ---@type UIAsyncDataProvider
    -- local provider = UIAsyncDataProvider.new()
    -- local name = UIMediatorNames.UIOneDaySuccessMediator
    -- local param = {heroId = self.heroId}
    -- local check = UIAsyncDataProvider.CheckTypes.CheckAll ~ UIAsyncDataProvider.CheckTypes.DoNotShowInGuidance
    -- provider:Init(name, nil, check, nil, nil, param)
    -- g_Game.UIAsyncManager:AddAsyncMediator(provider)

    -- self:Init()
end

function ActivityShopFirstRecharge:OnBtnCompBClicked(args)
    ModuleRefer.ActivityShopModule:PurchaseGoods(self.packId, nil, false)
end

function ActivityShopFirstRecharge:OnBtnInfoClicked(args)
    local desc = I18N.Get('first_pay_activityinfo')
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnInfo.transform, content = desc})
end

function ActivityShopFirstRecharge:OnBtnHeroDetailClicked(args)
    if self.heroId > 0 then
        local heroType = ConfigRefer.Heroes:Find(self.heroId):Type()
        g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator, {id = self.heroId, type = heroType})
    elseif self.petId > 0 then
        local petType = ConfigRefer.Pet:Find(self.petId):Type()
        g_Game.UIManager:Open(UIMediatorNames.UIPetMediator, {selectedType = petType})
    end
end

function ActivityShopFirstRecharge:OnBtnVideoClicked(args)
    local data = {}
    for _, demoId in ipairs(self.demoIds) do
        local demoCfg = ConfigRefer.GuideDemo:Find(demoId)
        local demo = {
            imageId = demoCfg:Pic(),
            videoId = demoCfg:Video(),
            title = demoCfg:Title(),
            desc = demoCfg:Desc(),
        }
        table.insert(data, demo)
    end
    g_Game.UIManager:Open(UIMediatorNames.GuideDemoUIMediator, {data = data})
end

function ActivityShopFirstRecharge:OnBtnCloseClicked(args)
    self:GetParentBaseUIMediator():CloseSelf()
end

return ActivityShopFirstRecharge
