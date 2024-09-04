local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local UIHeroLocalData = require('UIHeroLocalData')
local LockEquipParameter = require("LockEquipParameter")

local I18N = require('I18N')
local MAX_SUB_ATTR = 3

local HeroEquipDetailsItem = class('HeroEquipDetailsItem', BaseUIComponent)

function HeroEquipDetailsItem:ctor()

end

function HeroEquipDetailsItem:OnCreate()
    self.textTitle = self:Text('p_title')
    self.goLv = self:GameObject('p_lv')
    self.textLv = self:Text('p_text_lv')
    self.btnLock = self:Button('p_btn_lock', Delegate.GetOrCreate(self, self.OnClickLock))
    self.goIconUnlock = self:GameObject('p_icon_unlock')
    self.goIconLock = self:GameObject('p_icon_lock')
    self.imgIconAddtion = self:Image('p_icon_addtion')
    self.textTitleAddtion = self:Text('p_title_addtion')
    self.textSuit = self:Text('p_text_suit')
    self.textTitleAddtionNumber = self:Text('p_title_addtion_number')
    self.imgIconUp = self:Image("p_icon_up")
    self.goItem1 = self:GameObject('p_item_1')
    self.goItemAddtion1 = self:GameObject('p_item_addtion_1')
    self.imgIconAddtion1 = self:Image('p_icon_addtion_1')
    self.textAddtion1 = self:Text('p_text_addtion_1')
    self.textAddtionNumber1 = self:Text('p_text_addtion_number_1')
    self.textAddtionUnlock1 = self:Text('p_text_addtion_unlock_1')
    self.goItem2 = self:GameObject('p_item_2')
    self.goItemAddtion2 = self:GameObject('p_item_addtion_2')
    self.imgIconAddtion2 = self:Image('p_icon_addtion_2')
    self.textAddtion2 = self:Text('p_text_addtion_2')
    self.textAddtionNumber2 = self:Text('p_text_addtion_number_2')
    self.textAddtionUnlock2 = self:Text('p_text_addtion_unlock_2')
    self.goItem3 = self:GameObject('p_item_3')
    self.goItemAddtion3 = self:GameObject('p_item_addtion_3')
    self.imgIconAddtion3 = self:Image('p_icon_addtion_3')
    self.textAddtion3 = self:Text('p_text_addtion_3')
    self.textAddtionNumber3 = self:Text('p_text_addtion_number_3')
    self.textAddtionUnlock3 = self:Text('p_text_addtion_unlock_3')
    self.textTitleSuit = self:Text('p_title_suit', I18N.Get("hero_equip_suit_effect"))
    self.textNameSuit1 = self:Text('p_text_name_suit_1')
    self.imgIconSuit1 = self:Image('p_icon_suit_1')
    self.textDetailSuit1 = self:Text('p_text_detail_suit_1')
    self.goIconLock1 = self:GameObject('p_icon_unlock_1')
    self.textNameSuit2 = self:Text('p_text_name_suit_2')
    self.imgIconSuit2 = self:Image('p_icon_suit_2')
    self.textDetailSuit2 = self:Text('p_text_detail_suit_2')
    self.goIconLock2 = self:GameObject('p_icon_unlock_2')
    self.goEquipmentHero = self:GameObject('p_equipment_hero')
    self.textHint = self:Text('p_text_hint')
    self.goBaseA = self:GameObject("p_base_a")
    self.goBaseB = self:GameObject("p_base_b")
    self.compChildCardHeroS = self:LuaBaseComponent('child_card_hero_s')

    self.attrItems = {self.goItem1, self.goItem2, self.goItem3}
    self.attrShows = {self.goItemAddtion1, self.goItemAddtion2, self.goItemAddtion3}
    self.attrIcons = {self.imgIconAddtion1, self.imgIconAddtion2, self.imgIconAddtion3}
    self.attrTexts = {self.textAddtion1, self.textAddtion2, self.textAddtion3}
    self.attrNums = {self.textAddtionNumber1, self.textAddtionNumber2, self.textAddtionNumber3}
    self.attrHides = {self.textAddtionUnlock1, self.textAddtionUnlock2, self.textAddtionUnlock3}

    self.suitNames = {self.textNameSuit1, self.textNameSuit2}
    self.suitIcons = {self.imgIconSuit1, self.imgIconSuit2}
    self.suitDetails = {self.textDetailSuit1, self.textDetailSuit2}
    self.suitUnlocks = {self.goIconLock1, self.goIconLock2}
end

function HeroEquipDetailsItem:OnShow(param)
end

function HeroEquipDetailsItem:OnOpened(param)
end

function HeroEquipDetailsItem:OnClose(param)
end

---OnFeedData
---@param param itemComponentId|isShowUp|prewHeroCfgId
function HeroEquipDetailsItem:OnFeedData(param)
    if not param then
        return
    end
    self.param = param
    local equipInfo = ModuleRefer.InventoryModule:GetItemInfoByUid(param.itemComponentId).EquipInfo
    local equipCfg = ConfigRefer.HeroEquip:Find(equipInfo.ConfigId)
    self.textTitle.text = I18N.Get(equipCfg:Name())
    self.textSuit.text = I18N.Get(equipCfg:EquipDes())
    if equipInfo.StrengthenLevel > 0 then
        self.goLv:SetActive(true)
        self.textLv.text = "+" .. equipInfo.StrengthenLevel
    else
        self.goLv:SetActive(false)
    end
    self.goIconLock:SetActive(equipInfo.IsLock)
    self.goIconUnlock:SetActive(not equipInfo.IsLock)
    self.imgIconUp.gameObject:SetActive(param.isShowUp)
    local mainAttri = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(param.itemComponentId, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
    if not mainAttri then
        return
    end
    local attrElementCell = ConfigRefer.AttrElement:Find(mainAttri.type)
    g_Game.SpriteManager:LoadSprite(attrElementCell:Icon(), self.imgIconAddtion)
    self.textTitleAddtion.text = I18N.Get(attrElementCell:Name())
    self.textTitleAddtionNumber.text = ModuleRefer.AttrModule:GetAttrValueShowTextByType(ConfigRefer.AttrElement:Find(mainAttri.type), mainAttri.value)
    local strengthenLvList = ModuleRefer.HeroModule:GetStrengthenConditionList(equipInfo.ConfigId)
    local strengthCount = #strengthenLvList
    for i = 1, MAX_SUB_ATTR do
        self.attrItems[i]:SetActive(i <= strengthCount)
        if i <= strengthCount then
            local attr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(param.itemComponentId, i + 1)
            local hasAttr = attr ~= nil
            self.attrShows[i]:SetActive(hasAttr)
            self.attrHides[i].gameObject:SetActive(not hasAttr)
            if hasAttr then
                local attrCell = ConfigRefer.AttrElement:Find(attr.type)
                g_Game.SpriteManager:LoadSprite(attrCell:Icon(), self.attrIcons[i])
                self.attrTexts[i].text = I18N.Get(attrCell:Name())
                self.attrNums[i].text = ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrCell, attr.value)
            else
                self.attrHides[i].text = I18N.GetWithParams("equip_newattr", strengthenLvList[i])
            end
        else
            self.attrShows[i]:SetActive(false)
            self.attrHides[i].gameObject:SetActive(false)
        end
    end
    local hasHero = equipInfo.HeroConfigId ~= nil and equipInfo.HeroConfigId > 0 --装备到英雄身上了
    self.goEquipmentHero:SetActive(hasHero)
    if hasHero then
        local config = ConfigRefer.Heroes:Find(equipInfo.HeroConfigId)
        self.textHint.text = I18N.GetWithParams("equip_equipped", I18N.Get(config:Name()))
        self.goBaseA:SetActive(equipInfo.HeroConfigId == param.prewHeroCfgId)
        self.goBaseB:SetActive(equipInfo.HeroConfigId ~= param.prewHeroCfgId)
        self.compChildCardHeroS:FeedData(equipInfo.HeroConfigId)
    end
    local hasPrewHero = param.prewHeroCfgId ~= nil --当前预览要装备的英雄id
    if hasPrewHero then
        local suitList = ModuleRefer.HeroModule:GetPreviewSuitList(param.prewHeroCfgId, equipInfo.ConfigId) or {}
        local showSuit = {}
        for suitId, suitCount in pairs(suitList) do
            local suitCfg = ConfigRefer.Suit:Find(suitId)
            if suitCfg then
                local singleSuit = {}
                singleSuit.count = suitCount
                singleSuit.suitId = suitId
                singleSuit.suitCfg = suitCfg
                singleSuit.isFull = suitCount >= suitCfg:SuitEffect(2):Num()
                showSuit[#showSuit + 1] = singleSuit
            end
        end
        local sortFunc = function(a, b)
            if a.count == b.count then
                return a.suitId < b.suitId
            else
                return a.count < b.count
            end
        end
        table.sort(showSuit, sortFunc)
        local isFullSuit = showSuit[1] and showSuit[1].isFull
        if isFullSuit then
            local suitInfo = showSuit[1]
            local suitCfg = ConfigRefer.Suit:Find(suitInfo.suitId)
            if suitCfg then
                self.suitNames[1].gameObject:SetActive(true)
                self.suitNames[1].text = I18N.Get(suitCfg:Name()) .. string.format("(%s)", suitInfo.count)
                self:LoadSprite(suitCfg:Icon(), self.suitIcons[1])
                self.suitUnlocks[1]:SetActive(true)
                self.suitDetails[1].text = I18N.Get(suitCfg:SuitEffect(1):Desc())
                self.suitNames[2].gameObject:SetActive(false)
                self.suitUnlocks[2]:SetActive(true)
                self.suitDetails[2].gameObject:SetActive(true)
                self.suitDetails[2].text = I18N.Get(suitCfg:SuitEffect(2):Desc())
            end
        else
            for i = 1, 2 do
                local suitInfo = showSuit[i]
                local isShow = suitInfo ~= nil
                self.suitNames[i].gameObject:SetActive(isShow)
                self.suitDetails[i].gameObject:SetActive(isShow)
                if isShow and suitInfo.suitCfg then
                    self.suitNames[i].text = I18N.Get(suitInfo.suitCfg:Name()) .. string.format("(%s)", suitInfo.count)
                    self:LoadSprite(suitInfo.suitCfg:Icon(), self.suitIcons[1])
                    if suitInfo.count >= suitInfo.suitCfg:SuitEffect(2):Num() then
                        self.suitDetails[i].text = I18N.Get(suitInfo.suitCfg:SuitEffect(2):Desc())
                    else
                        self.suitDetails[i].text = I18N.Get(suitInfo.suitCfg:SuitEffect(1):Desc())
                    end
                    self.suitUnlocks[i]:SetActive(suitInfo.count >= suitInfo.suitCfg:SuitEffect(1):Num())
                end
            end
        end
    else
        local suitId = equipCfg:SuitId()
        local suitCfg = ConfigRefer.Suit:Find(suitId)
        if suitCfg then
            self.suitNames[1].gameObject:SetActive(true)
            self.suitNames[1].text = I18N.Get(suitCfg:Name())
            self:LoadSprite(suitCfg:Icon(), self.suitIcons[1])
            self.suitUnlocks[1]:SetActive(false)
            self.suitDetails[1].text = I18N.Get(suitCfg:SuitEffect(1):Desc())
            self.suitNames[2].gameObject:SetActive(false)
            self.suitUnlocks[2]:SetActive(false)
            self.suitDetails[2].text = I18N.Get(suitCfg:SuitEffect(2):Desc())
        end
    end
end

function HeroEquipDetailsItem:OnClickLock()
    local param = LockEquipParameter.new()
    local equipInfo = ModuleRefer.InventoryModule:GetItemInfoByUid(self.param.itemComponentId).EquipInfo
    param.args.EquipItemId = self.param.itemComponentId
    param.args.IsLock = not equipInfo.IsLock
    param:Send(self.btnLock.transform)
end

return HeroEquipDetailsItem
