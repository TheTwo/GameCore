local BaseUIComponent = require("BaseUIComponent")
local ConfigRefer = require("ConfigRefer")
local ActivityShopConst = require("ActivityShopConst")
local ModuleRefer = require("ModuleRefer")
local CommonGotoDetailDefine = require("CommonGotoDetailDefine")
local Delegate = require("Delegate")
---@class BaseActivityPack : BaseUIComponent
---@field param BaseActivityPackParam
---@field openedPackGroups table<number, number>
---@field tabId number
---@field tabCfg ConfigRefer.PayTabs
---@field packGroupId number
---@field groupInfoParam ShopGroupInfoSimplifiedParam
---@field gotoDetailParam CommonGotoDetailParam
local BaseActivityPack = class("BaseActivityPack", BaseUIComponent)

---@class BaseActivityPackParam
---@field openedPackGroups table<number, number>
---@field tabId number
---@field isShop boolean
---@field popId number

function BaseActivityPack:OnCreate()
    self.imgQuality = self:Image("p_base_quantity")
    ---@see CommonShopGroupInfo
    self.luaGroupDetail = self:LuaObject("child_shop_activity_detail")
    ---@see CommonGotoDetail
    self.luaGotoDetail = self:LuaObject("child_activity_detail")
    ---@see CommonDiscountTag
    self.luaDiscountTag = self:LuaObject("child_shop_discount_tag")
    self.btnClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseBtnClick))
    self:PostOnCreate()
end

---@param param BaseActivityPackParam
function BaseActivityPack:OnFeedData(param)
    self.param = param
    self.openedPackGroups = param.openedPackGroups
    self.tabId = param.tabId
    self.tabCfg = ConfigRefer.PayTabs:Find(self.tabId)
    self.isShop = self.param.isShop
    self.popId = self.param.popId
    self.popCfg = ConfigRefer.PopUpWindow:Find(self.popId)
    if self.isShop then
        self.packGroupId = self.openedPackGroups[1]
    else
        self.packGroupId = ConfigRefer.PopUpWindow:Find(self.popId):PayGroup()
    end
    if self.btnClose then
        self.btnClose.gameObject:SetActive(not self.isShop)
    end
    if self.luaDiscountTag then
        local packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(self.packGroupId)
        local packCfg = ConfigRefer.PayGoods:Find(packId)
        ---@type CommonDiscountTagParam
        local data = {}
        data.discount = packCfg:Discount()
        data.isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsSoldOut(packId)
        data.quality = packCfg:DiscountQuality()
        self.luaDiscountTag:FeedData(data)
    end
    self:InitGroupInfoParam()
    self:InitGroupInfo()
    self:InitGotoDetailParam()
    self:InitGotoDetail()
    self:InitQualityBase()
    self:PostOnFeedData(param)
end

function BaseActivityPack:InitQualityBase()
    local packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(self.packGroupId)
    local packCfg = ConfigRefer.PayGoods:Find(packId)
    if not packCfg then
        return
    end
    local quality = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(packCfg:ItemGroupId())[1].configCell:Quality()
    g_Game.SpriteManager:LoadSprite(ActivityShopConst.BASE_IMG_QUALITY[quality], self.imgQuality)
end

function BaseActivityPack:InitGroupInfoParam()
    ---@type ShopGroupInfoSimplifiedParam
    local param = {}
    param.payGroupId = self.packGroupId
    param.type = ActivityShopConst.GROUP_DETAIL_TYPE.HERO
    param.showDiscountTag = true
    param.showRechargePoints = true
    self.groupInfoParam = param
    self:PostInitGroupInfoParam()
end

function BaseActivityPack:InitGroupInfo()
    self.luaGroupDetail:FeedData(self.groupInfoParam)
end

function BaseActivityPack:InitGotoDetailParam()
    ---@type CommonGotoDetailParam
    local param = {}
    param.displayMask = CommonGotoDetailDefine.DISPLAY_MASK.BTN_GOTO
    param.type = CommonGotoDetailDefine.TYPE.HERO
    param.configId = (self.tabCfg or self.popCfg):GotoHero()
    param.videoId = {}
    for i = 1, (self.tabCfg or self.popCfg):DemoVideosLength() do
        table.insert(param.videoId, (self.tabCfg or self.popCfg):DemoVideos(i))
    end
    if #(param.videoId or {}) > 0 then
        param.displayMask = param.displayMask | CommonGotoDetailDefine.DISPLAY_MASK.BTN_VIDEO
    end
    self.gotoDetailParam = param
    self:PostInitGotoDetailParam()
end

function BaseActivityPack:InitGotoDetail()
    if not self.luaGotoDetail then
        return
    end
    self.luaGotoDetail:FeedData(self.gotoDetailParam)
end

function BaseActivityPack:OnCloseBtnClick()
    self:GetParentBaseUIMediator():CloseSelf()
end

---@virtual
function BaseActivityPack:PostOnCreate()
end

---@virtual
function BaseActivityPack:PostOnFeedData(param)
end

---@virtual
function BaseActivityPack:PostInitGroupInfoParam()
end

---@virtual
function BaseActivityPack:PostInitGotoDetailParam()
end

function BaseActivityPack:GetRelatedRewardCfgId()
    return (self.gotoDetailParam or {}).configId
end

return BaseActivityPack