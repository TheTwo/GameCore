---scene: scene_hero_card_show_ten
local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
---@class HeroCardShowTenMediator : BaseUIMediator
local HeroCardShowTenMediator = class('HeroCardShowTenMediator',BaseUIMediator)

---@class HeroCardShowTenMediatorParam
---@field selectType number
---@field result table {items:any, tid:number}
---@field closeCallback fun()
---@field isSingle boolean

function HeroCardShowTenMediator:OnCreate()
    self.compResource1 = self:LuaObject('p_resource_1')
    self.compResource2 = self:LuaObject('p_resource_2')
    self.compResource3 = self:LuaObject('p_resource_3')
    self.luaCardSingle = self:LuaObject('child_hero_card')
    self.compChildHeroCard01 = self:LuaObject('child_hero_card_01')
    self.compChildHeroCard02 = self:LuaObject('child_hero_card_02')
    self.compChildHeroCard03 = self:LuaObject('child_hero_card_03')
    self.compChildHeroCard04 = self:LuaObject('child_hero_card_04')
    self.compChildHeroCard05 = self:LuaObject('child_hero_card_05')
    self.compChildHeroCard06 = self:LuaObject('child_hero_card_06')
    self.compChildHeroCard07 = self:LuaObject('child_hero_card_07')
    self.compChildHeroCard08 = self:LuaObject('child_hero_card_08')
    self.compChildHeroCard09 = self:LuaObject('child_hero_card_09')
    self.compChildHeroCard10 = self:LuaObject('child_hero_card_10')
    self.btnCompClam = self:Button('p_comp_btn_clam', Delegate.GetOrCreate(self, self.OnBtnCompClamClicked))
    self.textClam = self:Text('p_text_clam', I18N.Get("gacha_result_confim"))
    self.btnOne = self:Button('p_btn_one', Delegate.GetOrCreate(self, self.OnBtnOneClicked))
    self.textOne = self:Text('p_text_one', I18N.Get("gacha_result_more_1"))
    self.imgIconOne = self:Image('p_icon_one')
    self.textNumOne = self:Text('p_text_num_one')
    self.btnTen = self:Button('p_btn_ten', Delegate.GetOrCreate(self, self.OnBtnTenClicked))
    self.textTen = self:Text('p_text_ten', I18N.Get("gacha_result_more_10"))
    self.imgIconTen = self:Image('p_icon_ten')
    self.textNumTen = self:Text('p_text_num_ten')
    self.btnShare = self:Button('p_btn_share', Delegate.GetOrCreate(self, self.OnBtnShareClicked))
    self.textGet = self:Text('p_text_get', I18N.Get("gacha_result_point_got"))
    self.imgIcon = self:Image('icon')
    self.textGetNum = self:Text('p_text_get_num')
    self.btnShare.gameObject:SetActive(false)
    ---@type HeroCardPreviewItem[]
    self.items = {self.compChildHeroCard01, self.compChildHeroCard02, self.compChildHeroCard03, self.compChildHeroCard04, self.compChildHeroCard05,
        self.compChildHeroCard06, self.compChildHeroCard07, self.compChildHeroCard08, self.compChildHeroCard09, self.compChildHeroCard10}

    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

---@param params HeroCardShowTenMediatorParam
function HeroCardShowTenMediator:OnOpened(params)
    self.selectType = params.selectType
    self.result = params.result
    self.isSingle = params.isSingle
    self.closeCallback = params.closeCallback
    self:RefreshScore()
    self:RefreshCoins()
    self:RefreshBtns()
    self:RefreshItems()
    ModuleRefer.ToastModule:IngoreBlockPower()
    if self.isSingle then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    else
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

function HeroCardShowTenMediator:OnClose(param)
    if self.closeCallback then
        self.closeCallback()
    end
end

function HeroCardShowTenMediator:RefreshScore()
    local gachaId = ConfigRefer.GachaType:Find(self.selectType):GachaId()
    local itemGroupId = ConfigRefer.Gacha:Find(gachaId):RewardItemGroup()
    local score = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)[1]
    local itemId = score.configCell:Id()
    local count = score.count * 10
    if self.isSingle then
        count = score.count
    end
    local itemCfg = ConfigRefer.Item:Find(itemId)
    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIcon)
    self.textGetNum.text = "x" .. count
end

function HeroCardShowTenMediator:RefreshCoins()
    local coinId = ConfigRefer.ConstMain:UniversalCoin()
    local item = ConfigRefer.Item:Find(coinId)
    local iconData = {
        iconName = item:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId),
        isShowPlus = false,
    }
    self.compResource1:FeedData(iconData)
    local coinId2 = ConfigRefer.ConstMain:UniversalCoin2()
    local item2 = ConfigRefer.Item:Find(coinId2)
    local iconData2 = {
        iconName = item2:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId2),
        isShowPlus = false,
    }
    self.compResource2:FeedData(iconData2)
    local gachaCoin = ConfigRefer.GachaType:Find(self.selectType):ShowItemId()
    local item3 = ConfigRefer.Item:Find(gachaCoin)
    local iconData3 = {
        iconName = item3:Icon(),
        content = ModuleRefer.InventoryModule:GetAmountByConfigId(gachaCoin),
        isShowPlus = false,
    }
    self.compResource3:FeedData(iconData3)
end

function HeroCardShowTenMediator:RefreshBtns()
    local gachaId = ConfigRefer.GachaType:Find(self.selectType):GachaId()
    local oneDrawCost = ConfigRefer.Gacha:Find(gachaId):OneDrawCost()
    local oneCostItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(oneDrawCost)[1]
    g_Game.SpriteManager:LoadSprite(oneCostItem.configCell:Icon(), self.imgIconOne)
    local oneCurNum = ModuleRefer.InventoryModule:GetAmountByConfigId(oneCostItem.configCell:Id())
    if oneCurNum >= oneCostItem.count then
        self.textNumOne.text = "x" .. oneCostItem.count
    else
        self.textNumOne.text = UIHelper.GetColoredText("x" .. oneCostItem.count, ColorConsts.warning)
    end

    local tenDrawCost = ConfigRefer.Gacha:Find(gachaId):TenDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(tenDrawCost)[1]
    g_Game.SpriteManager:LoadSprite(costItem.configCell:Icon(), self.imgIconTen)
    local curNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItem.configCell:Id())
    if curNum >= costItem.count then
        self.textNumTen.text = "x" .. costItem.count
    else
        self.textNumTen.text = UIHelper.GetColoredText("x" .. costItem.count, ColorConsts.warning)
    end

    self.btnTen.gameObject:SetActive(not self.isSingle)
end

function HeroCardShowTenMediator:RefreshItems()
    if self.isSingle then
        self.luaCardSingle:SetVisible(true)
        self.luaCardSingle:FeedData(self.result[1])
    else
        for i = 1, #self.items do
            local isShow = self.result[i] ~= nil
            self.items[i]:SetVisible(isShow)
            if isShow then
                self.items[i]:FeedData(self.result[i])
            end
        end
    end
end

function HeroCardShowTenMediator:OnBtnCompClamClicked(args)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
    g_Game.UIManager:Close(self.runtimeId)
end

function HeroCardShowTenMediator:OnBtnOneClicked(args)
    local gachaId = ConfigRefer.GachaType:Find(self.selectType):GachaId()
    local oneDrawCost = ConfigRefer.Gacha:Find(gachaId):OneDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(oneDrawCost)[1]
    ModuleRefer.HeroCardModule:DoGacha(costItem, wrpc.GachaDrawType.GachaDrawType_ONE, self.selectType)
    g_Game.UIManager:Close(self.runtimeId)
end

function HeroCardShowTenMediator:OnBtnTenClicked(args)
    local gachaId = ConfigRefer.GachaType:Find(self.selectType):GachaId()
    local tenDrawCost = ConfigRefer.Gacha:Find(gachaId):TenDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(tenDrawCost)[1]
    ModuleRefer.HeroCardModule:DoGacha(costItem, wrpc.GachaDrawType.GachaDrawType_TEN, self.selectType)
    g_Game.UIManager:Close(self.runtimeId)
end

function HeroCardShowTenMediator:OnBtnShareClicked(args)
    -- body
end

return HeroCardShowTenMediator