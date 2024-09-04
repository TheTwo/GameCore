local BaseUIComponent = require("BaseUIComponent")
local ActivityShopConst = require("ActivityShopConst")
local Delegate = require('Delegate')
local ColorConsts = require("ColorConsts")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
---@class CommonShopGroupInfo : BaseUIComponent
local CommonShopGroupInfo = class('CommonShopGroupInfo', BaseUIComponent)
---@scene scene_child_shop_activity_detail

---@class ShopGroupInfoParam
---@field titleDescText string
---@field tagText string
---@field nameText string
---@field remainTimePrefixText string
---@field btnText string
---@field btnHintText string
---@field detailDescText string
---@field infoText string
---@field rechargePoints number
---@field quality number
---@field type number @ActivityShopConst.GROUP_DETAIL_TYPE
---@field rewardList table<number, ItemIconData>
---@field showDiscountTag boolean
---@field showCountDown boolean
---@field showInfoBtn boolean
---@field showRechargePoints boolean
---@field discountTagParam CommonDiscountTagParam | nil
---@field timerParam CommonTimerData | nil
---@field onBtnClick fun()

---@class ShopGroupInfoSimplifiedParam
---@field payGroupId number
---@field type number @ActivityShopConst.GROUP_DETAIL_TYPE
---@field tagText string
---@field remainTimePrefixText string
---@field btnHintText string
---@field infoText string
---@field showDiscountTag boolean
---@field showInfoBtn boolean
---@field showRechargePoints boolean

local TYPE_STATUS = {
    [ActivityShopConst.GROUP_DETAIL_TYPE.HERO] = 0,
    [ActivityShopConst.GROUP_DETAIL_TYPE.PET] = 1,
}

local QUALITY_COLOR = {
    ColorConsts.quality_white,
    ColorConsts.quality_green,
    ColorConsts.quality_blue,
    ColorConsts.quality_purple,
    ColorConsts.quality_orange,
}

local QUALITY_TEXT = {
    'equip_quality1',
    'equip_quality2',
    'equip_quality3',
    'equip_quality4',
    'equip_quality5',
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

function CommonShopGroupInfo:OnCreate()
    self.textTitleDesc = self:Text("p_text_title_1")
    self.textTag = self:Text("p_text_title_2")
    self.textName = self:Text("p_text_title_3")
    self.textQuality = self:Text("p_text_quantity")
    self.textRemainTime = self:Text("p_text_title_4")
    self.goTimer = self:GameObject("p_text_title_4")
    self.textDetailDesc = self:Text("p_text_detail")

    self.btnPurchase = self:Button("child_comp_btn_e_l", Delegate.GetOrCreate(self, self.OnBtnClick))
    self.textBtn = self:Text("p_text_e")
    self.textBtnHint = self:Text("p_text_hint")
    self.btnRechargePoints = self:Button("p_btn_recharge_points")
    self.textRechargePoints = self:Text("p_text_num")

    self.btnInfo = self:Button("p_btn_info", Delegate.GetOrCreate(self, self.OnInfoClick))

    self.tableReward = self:TableViewPro("p_table_item")

    self.discountTag = self:LuaObject("child_shop_discount_tag")
    self.Timer = self:LuaObject("child_time")

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

    self.statusCtrl = self:StatusRecordParent("")
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:OnFeedData(param)
    if not param then return end
    if param.payGroupId then
        param = self:FillSimplifiedParam(param)
    end
    self:InitStaticTexts(param)
    self:InitTable(param)
    self:InitBtnFunc(param)
    self:InitTimer(param)
    self:InitDiscountTag(param)
    self:InitQuality(param)
    self:InitRechargePoints(param)
    self:InitInfoBtn(param)
    self:SetType(param)
end

---@param param ShopGroupInfoSimplifiedParam
---@return ShopGroupInfoParam
function CommonShopGroupInfo:FillSimplifiedParam(param)
    local packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(param.payGroupId)
    local packCfg = ConfigRefer.PayGoods:Find(packId)
    if not packCfg then
        g_Logger:ErrorChannel("CommonShopGroupInfo", "礼包组%d未开启或不包含任何可用礼包", param.payGroupId)
        param.titleDescText = ""
        param.nameText = ""
        param.quality = 1
        param.btnText = ""
        param.detailDescText = ""
        param.rechargePoints = 0
        param.rewardList = {}
        param.discountTagParam = {
            discount = 0,
            quality = 1,
            isSoldOut = true,
        }
        param.showCountDown = false
        param.timerParam = nil
        param.onBtnClick = nil
        return param
    end
    local discount = packCfg:Discount()
    local discountQuality = packCfg:DiscountQuality()

    local itemGroupId = packCfg:ItemGroupId()
    local rewardList = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)

    local price, priceType = ModuleRefer.ActivityShopModule:GetGoodsPrice(packId)

    param.titleDescText = I18N.Get(packCfg:Name())
    if param.type then
        param.nameText = I18N.Get(rewardList[1].configCell:NameKey())
    else
        param.nameText = I18N.Get(packCfg:Name())
    end
    param.quality = rewardList[1].configCell:Quality()
    param.btnText = string.format('%s %.2f', priceType, price)
    param.detailDescText = ModuleRefer.ActivityShopModule:GetGoodParameterizedDesc(packId)
    param.rechargePoints = ModuleRefer.ActivityShopModule:GetGoodsExchangePointsNum(packId)
    param.rewardList = rewardList
    param.discountTagParam = {
        discount = discount,
        quality = discountQuality,
        isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(packId),
    }
    param.showCountDown = ConfigRefer.PayGoodsGroup:Find(param.payGroupId):Countdown()
    param.timerParam = {
        endTime = ModuleRefer.ActivityShopModule:GetRemainingTime(param.payGroupId) +
                    g_Game.ServerTime:GetServerTimestampInSeconds(),
        needTimer = true,
        intervalTime = 1
    }
    param.onBtnClick = function()
        ModuleRefer.ActivityShopModule:PurchaseGoods(packId, nil, false)
    end
    return param
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitStaticTexts(param)
    self.textTitleDesc.text = param.titleDescText
    self.textTag.text = param.tagText
    self.textName.text = param.nameText
    self.textRemainTime.text = param.remainTimePrefixText
    self.textBtn.text = param.btnText
    self.textBtnHint.text = param.btnHintText
    self.textDetailDesc.text = param.detailDescText
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitTable(param)
    self.tableReward:Clear()
    for _, v in ipairs(param.rewardList) do
        self.tableReward:AppendData(v)
    end
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitBtnFunc(param)
    self.onBtnClick = param.onBtnClick
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitTimer(param)
    self.goTimer:SetActive(param.showCountDown)
    if not param.showCountDown then return end
    self.Timer:FeedData(param.timerParam)
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitDiscountTag(param)
    if not param.showDiscountTag then
        self.discountTag:SetVisible(false)
        return
    end
    self.discountTag:SetVisible(true)
    self.discountTag:FeedData(param.discountTagParam)
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitQuality(param)
    local quality = param.quality
    self.textQuality.text = I18N.Get(QUALITY_TEXT[quality])
    self.textQuality.color = UIHelper.TryParseHtmlString(QUALITY_COLOR[quality])
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitRechargePoints(param)
    local show = param.showRechargePoints or false
    if not show or not self.btnRechargePoints or not self.textRechargePoints then return end
    self.btnRechargePoints.gameObject:SetActive(show)
    self.textRechargePoints.text = '+' .. param.rechargePoints
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:InitInfoBtn(param)
    local show = param.showInfoBtn or false
    self.btnInfo.gameObject:SetActive(show)
    self.infoContent = param.infoText or ''
end

---@param param ShopGroupInfoParam
function CommonShopGroupInfo:SetType(param)
    local type = param.type or ActivityShopConst.GROUP_DETAIL_TYPE.HERO
    local status = TYPE_STATUS[type]
    self.statusCtrl:ApplyStatusRecord(status)
    if type == ActivityShopConst.GROUP_DETAIL_TYPE.PET then
        self:SetPetAttrs(1, 5)
        self:SetPetAttrs(2, 5)
        self:SetPetAttrs(3, 5)
    end
end

function CommonShopGroupInfo:SetPetAttrs(index, quality)
    g_Game.SpriteManager:LoadSprite(PET_ATTR_LEVEL_ICON[quality], self.attrs[index].imgIconAttr)
    g_Game.SpriteManager:LoadSprite(PET_ATTR_LEVEL_FRAME[quality], self.attrs[index].imgBase)
end

function CommonShopGroupInfo:OnBtnClick()
    if self.onBtnClick then
        self.onBtnClick()
    end
end

function CommonShopGroupInfo:OnInfoClick()
    ---@type TextToastMediatorParameter
    local param = {
        content = self.infoContent,
        clickTransfrom = self.btnInfo.transform,
    }
    ModuleRefer.ToastModule:ShowTextToast(param)
end

return CommonShopGroupInfo