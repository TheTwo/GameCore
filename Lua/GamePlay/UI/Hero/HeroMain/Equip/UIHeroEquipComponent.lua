local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local HeroEquipType = require("HeroEquipType")
local NotificationType = require("NotificationType")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local WearEquipParameter = require("WearEquipParameter")
local I18N = require('I18N')

---@class UIHeroEquipComponent : BaseUIComponent
local UIHeroEquipComponent = class('UIHeroEquipComponent', BaseUIComponent)

local EQUIP_SHOW_TYPE = {HeroEquipType.Head, HeroEquipType.Clothes, HeroEquipType.Belt, HeroEquipType.Shoes, HeroEquipType.Weapon}

function UIHeroEquipComponent:ctor()
    self.module = ModuleRefer.HeroModule
    self.Inventory = ModuleRefer.InventoryModule
end

function UIHeroEquipComponent:OnCreate()
    self.btnItemHead = self:Button('p_item_head', Delegate.GetOrCreate(self, self.OnBtnItemHeadClicked))
    self.goImgSelectHead = self:GameObject('p_img_select_head')
    self.goStatusNHead = self:GameObject('p_status_n_head')
    self.imgBaseFrameHead = self:Image('p_base_frame_head')
    self.imgIconItemHead = self:Image('p_icon_item_head')
    self.textLvHead = self:Text('p_text_lv_head')
    self.goStatusNoneHead = self:GameObject('p_status_none_head')
    self.btnItemClothes = self:Button('p_item_clothes', Delegate.GetOrCreate(self, self.OnBtnItemClothesClicked))
    self.goImgSelectClothes = self:GameObject('p_img_select_clothes')
    self.goStatusNClothes = self:GameObject('p_status_n_clothes')
    self.imgBaseFrameClothes = self:Image('p_base_frame_clothes')
    self.imgIconItemClothes = self:Image('p_icon_item_clothes')
    self.textLvClothes = self:Text('p_text_lv_clothes')
    self.goStatusNoneClothes = self:GameObject('p_status_none_clothes')
    self.btnItemShoes = self:Button('p_item_shoes', Delegate.GetOrCreate(self, self.OnBtnItemShoesClicked))
    self.goImgSelectShoes = self:GameObject('p_img_select_shoes')
    self.goStatusNShoes = self:GameObject('p_status_n_shoes')
    self.imgBaseFrameShoes = self:Image('p_base_frame_shoes')
    self.imgIconItemShoes = self:Image('p_icon_item_shoes')
    self.textLvShoes = self:Text('p_text_lv_shoes')
    self.goStatusNoneShoes = self:GameObject('p_status_none_shoes')
    self.btnItemBelt = self:Button('p_item_belt', Delegate.GetOrCreate(self, self.OnBtnItemBeltClicked))
    self.goImgSelectBelt = self:GameObject('p_img_select_belt')
    self.goStatusNBelt = self:GameObject('p_status_n_belt')
    self.imgBaseFrameBelt = self:Image('p_base_frame_belt')
    self.imgIconItemBelt = self:Image('p_icon_item_belt')
    self.textLvBelt = self:Text('p_text_lv_belt')
    self.goStatusNoneBelt = self:GameObject('p_status_none_belt')
    self.btnItemWeapon = self:Button('p_item_weapon', Delegate.GetOrCreate(self, self.OnBtnItemWeaponClicked))
    self.goImgSelectWeapon = self:GameObject('p_img_select_weapon')
    self.goStatusNWeapon = self:GameObject('p_status_n_weapon')
    self.imgBaseFrameWeapon = self:Image('p_base_frame_weapon')
    self.imgIconItemWeapon = self:Image('p_icon_item_weapon')
    self.textLvWeapon = self:Text('p_text_lv_weapon')
    self.goStatusNoneWeapon = self:GameObject('p_status_none_weapon')
    self.textTitle = self:Text('p_text_title', I18N.Get("hero_equip"))
    self.textBasics = self:Text('p_text_basics', I18N.Get("hero_equip_buff"))
    self.tableviewproTableAddtion = self:TableViewPro('p_table_addtion')
    self.goTableAddtion = self:GameObject('p_table_addtion')
    self.textTitleSuit = self:Text('p_title_suit', I18N.Get("hero_equip_suit_effect"))
    self.goSuit1 = self:GameObject("p_suit_name_1")
    self.textNameSuit1 = self:Text('p_text_name_suit_1')
    self.imgIconSuit1 = self:Image('p_icon_suit_1')
    self.textDetailSuit1 = self:Text('p_text_detail_suit_1')
    self.goUnlockSuit1 = self:GameObject("p_icon_unlock_1")
    self.goLockSuit1 = self:GameObject("p_icon_lock_1")
    self.goSuit2 = self:GameObject("p_suit_name_2")
    self.textNameSuit2 = self:Text('p_text_name_suit_2')
    self.imgIconSuit2 = self:Image('p_icon_suit_2')
    self.textDetailSuit2 = self:Text('p_text_detail_suit_2')
    self.goUnlockSuit2 = self:GameObject("p_icon_unlock_2")
    self.goLockSuit2 = self:GameObject("p_icon_lock_2")
    self.goEmpty = self:GameObject("p_empty")
    self.textEmpty = self:Text("p_text_empty", "hero_equip_blank")
    self.textDetailSuitNone = self:Text('p_text_detail_suit_none', I18N.Get("hero_equip_nosuit"))
    self.compChildReddotDefaultEditorHead = self:LuaObject('child_reddot_default_editor_head')
    self.compChildReddotDefaultEditorClothes = self:LuaObject('child_reddot_default_editor_clothes')
    self.compChildReddotDefaultEditorBelt = self:LuaObject('child_reddot_default_editor_belt')
    self.compChildReddotDefaultEditorShoes = self:LuaObject('child_reddot_default_editor_shoes')
    self.compChildReddotDefaultEditorWeapon = self:LuaObject('child_reddot_default_editor_weapon')
    -- self.btnCompEdit = self:Button('p_comp_btn_edit', Delegate.GetOrCreate(self, self.OnBtnCompEditClicked))
    -- self.textEdit = self:Text('p_text_edit', I18N.Get("hero_equip_btn_replace"))
    self.btnCompRemove = self:Button('p_comp_btn_remove', Delegate.GetOrCreate(self, self.OnBtnCompRemoveClicked))
    self.textRemove = self:Text('p_text_remove', "equip_quick_get_off")
    self.compCompBenEquip = self:LuaObject('p_comp_ben_equip')


    self.selectIcons = {self.goImgSelectWeapon, self.goImgSelectHead, self.goImgSelectClothes, self.goImgSelectBelt,self.goImgSelectShoes}
    self.selectShowGos = {self.goStatusNWeapon, self.goStatusNHead, self.goStatusNClothes, self.goStatusNBelt, self.goStatusNShoes}
    self.selectEmptyGos = {self.goStatusNoneWeapon, self.goStatusNoneHead, self.goStatusNoneClothes, self.goStatusNoneBelt, self.goStatusNoneShoes}
    self.qualityFrames = {self.imgBaseFrameWeapon, self.imgBaseFrameHead, self.imgBaseFrameClothes, self.imgBaseFrameBelt, self.imgBaseFrameShoes}
    self.itemIcons = {self.imgIconItemWeapon, self.imgIconItemHead, self.imgIconItemClothes, self.imgIconItemBelt, self.imgIconItemShoes}
    self.itemLvTexts = {self.textLvWeapon, self.textLvHead, self.textLvClothes, self.textLvBelt, self.textLvShoes}

    self.suitGos = {self.goSuit1, self.goSuit2}
    self.suitNames = {self.textNameSuit1, self.textNameSuit2}
    self.suitIcons = {self.imgIconSuit1, self.imgIconSuit2}
    self.suitDetails = {self.textDetailSuit1, self.textDetailSuit2}
    self.suitUnlocks = {self.goUnlockSuit1, self.goUnlockSuit2}
    self.suitLocks = {self.goLockSuit1, self.goLockSuit2}
end

function UIHeroEquipComponent:OnBtnCompRemoveClicked(args)
    local param = WearEquipParameter.new()
    param.args.HeroId = self.selectHero.id
    param.args.IsWear = false
    param:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_quick_get_off_tips"))
        end
    end)
end

function UIHeroEquipComponent:OnClickEquipAll(args)
    local param = WearEquipParameter.new()
    param.args.HeroId = self.selectHero.id
    for _, equipType in ipairs(EQUIP_SHOW_TYPE) do
        local equipInfo = ModuleRefer.HeroModule:GetEquipByType(self.selectHero.id, equipType)
        local isHasEquip = equipInfo and next(equipInfo)
        if not isHasEquip then
            local equip = ModuleRefer.HeroModule:GetCanEquipItemByType(equipType)
            if equip then
                param.args.EquipItemIds:Add(equip.ID)
            end
        end
    end
    param.args.IsWear = true
    param:Send()
end

function UIHeroEquipComponent:OnClickEquipAllDisabled(args)
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_quick_get_on_tips"))
end

function UIHeroEquipComponent:OnBtnCompEditClicked(args)
    self:OpenEquipUI(HeroEquipType.Head)
end

function UIHeroEquipComponent:OnShow(param)
    self.parentMediator = self:GetParentBaseUIMediator()
    self.selectHero = self.parentMediator:GetSelectHero()
    local btnData = {}
    btnData.buttonText = I18N.Get("equip_quick_get_on")
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickEquipAll)
    btnData.disableClick = Delegate.GetOrCreate(self, self.OnClickEquipAllDisabled)
    self.compCompBenEquip:FeedData(btnData)
    self:RefreshEquipList()
    self:RefreshAttribute()
    self:RefreshSuitList()
    local equipWeaponMain = ModuleRefer.NotificationModule:GetDynamicNode("EquipWeaponMain" .. self.selectHero.id, NotificationType.EQUIP_WEAPON_MAIN)
    local equipHeadMain = ModuleRefer.NotificationModule:GetDynamicNode("EquipHeadMain" .. self.selectHero.id, NotificationType.EQUIP_HEAD_MAIN)
    local equipClothMain = ModuleRefer.NotificationModule:GetDynamicNode("EquipClothMain" .. self.selectHero.id, NotificationType.EQUIP_CLOTH_MAIN)
    local equipBeltMain = ModuleRefer.NotificationModule:GetDynamicNode("EquipBeltMain" .. self.selectHero.id, NotificationType.EQUIP_BELT_MAIN)
    local equipShoeMain = ModuleRefer.NotificationModule:GetDynamicNode("EquipShoeMain" .. self.selectHero.id, NotificationType.EQUIP_SHOE_MAIN)
    ModuleRefer.NotificationModule:AttachToGameObject(equipWeaponMain, self.compChildReddotDefaultEditorWeapon.go, self.compChildReddotDefaultEditorWeapon.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipHeadMain, self.compChildReddotDefaultEditorHead.go, self.compChildReddotDefaultEditorHead.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipClothMain, self.compChildReddotDefaultEditorClothes.go, self.compChildReddotDefaultEditorClothes.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipBeltMain, self.compChildReddotDefaultEditorBelt.go, self.compChildReddotDefaultEditorBelt.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipShoeMain, self.compChildReddotDefaultEditorShoes.go, self.compChildReddotDefaultEditorShoes.redDot)
end

function UIHeroEquipComponent:RefreshEquipList()
    self.compCompBenEquip:SetVisible(false)
    self.btnCompRemove.gameObject:SetActive(false)
    self.goEmpty:SetActive(true)
    for index, equipType in ipairs(EQUIP_SHOW_TYPE) do
        self:RefreshSingleEquip(index, equipType)
    end
end

function UIHeroEquipComponent:RefreshSingleEquip(index, equipType)
    local equipInfo = ModuleRefer.HeroModule:GetEquipByType(self.selectHero.id, equipType)
    local isHasEquip = equipInfo and next(equipInfo)
    local selectIndex = EQUIP_SHOW_TYPE[index]
    self.selectIcons[selectIndex]:SetActive(false)
    self.selectShowGos[selectIndex]:SetActive(isHasEquip)
    self.selectEmptyGos[selectIndex]:SetActive(not isHasEquip)
    if isHasEquip then
        self.goEmpty:SetActive(false)
        if equipInfo.StrengthenLevel > 0 then
            self.itemLvTexts[selectIndex].text = "+" .. equipInfo.StrengthenLevel
            self.itemLvTexts[selectIndex].gameObject:SetActive(true)
        else
            self.itemLvTexts[selectIndex].gameObject:SetActive(false)
        end
        local equipId = equipInfo.ConfigId
        local equipCfg = ConfigRefer.HeroEquip:Find(equipId)
        self:LoadSprite(equipCfg:BaseMap(), self.qualityFrames[selectIndex])
        self:LoadSprite(equipCfg:Icon(), self.itemIcons[selectIndex])
        self.btnCompRemove.gameObject:SetActive(true)
    else
        self.compCompBenEquip:SetVisible(true)
    end
end

function UIHeroEquipComponent:RefreshAttribute()
    local attributeLists = ModuleRefer.HeroModule:GetAllEquipAttributeList(self.selectHero.id)
    self.tableviewproTableAddtion:Clear()
    local count = 1
    if attributeLists then
        local totalAttributes = ModuleRefer.HeroModule:GetShowAttribute(attributeLists.attributes)
        for i = 1, ConfigRefer.ConstMain:HeroSESubAttrTypeLength() do
            local displayKey = ConfigRefer.ConstMain:HeroSESubAttrType(i)
            local clientKey =  ModuleRefer.HeroModule:GetAttrDiaplayRelativeAttrType(displayKey)
            if totalAttributes[clientKey] and totalAttributes[clientKey].value > 0 then
                local value = ModuleRefer.AttrModule:GetAttrValueShowTextByType(ConfigRefer.AttrElement:Find(clientKey), totalAttributes[clientKey].value)
                local showBase = count % 2 == 0
                count = count + 1
                self.tableviewproTableAddtion:AppendData({type = clientKey, value = value, showBase = showBase})
            end
        end
    end
end

function UIHeroEquipComponent:RefreshSuitList()
    local suitList = ModuleRefer.HeroModule:GetSuitList(self.selectHero.id) or {}
    local showSuit = {}
    for suitId, suitCount in pairs(suitList) do
        local suitCfg = ConfigRefer.Suit:Find(suitId)
        if suitCfg then
            local suitNeedNum = suitCfg:SuitEffect(1):Num()
            if suitCount >= suitNeedNum then
                local singleSuit = {}
                singleSuit.count = suitCount
                singleSuit.suitId = suitId
                singleSuit.suitCfg = suitCfg
                singleSuit.isFull = suitCount >= suitCfg:SuitEffect(2):Num()
                showSuit[#showSuit + 1] = singleSuit
            end
        end
    end
    local isHasSuit= #showSuit ~= 0
    self.textDetailSuitNone.gameObject:SetActive(not isHasSuit)
    if not isHasSuit then
        self.suitGos[1].gameObject:SetActive(false)
        self.suitDetails[1].gameObject:SetActive(false)
        self.suitGos[2].gameObject:SetActive(false)
        self.suitDetails[2].gameObject:SetActive(false)
        return
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
            self.suitGos[1].gameObject:SetActive(true)
            self.suitNames[1].text = I18N.Get(suitCfg:Name()) .. string.format("(%s)", suitInfo.count)
            self:LoadSprite(suitCfg:Icon(), self.suitIcons[1])
            self.suitUnlocks[1].gameObject:SetActive(true)
            self.suitLocks[1].gameObject:SetActive(false)
            self.suitDetails[1].text = I18N.Get(suitCfg:SuitEffect(1):Desc())
            self.suitGos[2].gameObject:SetActive(false)
            self.suitUnlocks[2].gameObject:SetActive(true)
            self.suitLocks[2].gameObject:SetActive(false)
            self.suitDetails[2].gameObject:SetActive(true)
            self.suitDetails[2].text = I18N.Get(suitCfg:SuitEffect(2):Desc())
        end
    else
        for i = 1, 2 do
            local suitInfo = showSuit[i]
            local isShow = suitInfo ~= nil
            self.suitGos[i].gameObject:SetActive(isShow)
            self.suitDetails[i].gameObject:SetActive(isShow)
            if isShow and suitInfo.suitCfg then
                self.suitNames[i].text = I18N.Get(suitInfo.suitCfg:Name()) .. string.format("(%s)", suitInfo.count)
                self:LoadSprite(suitInfo.suitCfg:Icon(), self.suitIcons[i])
                if suitInfo.count >= suitInfo.suitCfg:SuitEffect(2):Num() then
                    self.suitDetails[i].text = I18N.Get(suitInfo.suitCfg:SuitEffect(2):Desc())
                    self.suitUnlocks[i].gameObject:SetActive(false)
                    self.suitLocks[i].gameObject:SetActive(true)
                else
                    self.suitDetails[i].text = I18N.Get(suitInfo.suitCfg:SuitEffect(1):Desc())
                    self.suitUnlocks[i].gameObject:SetActive(true)
                    self.suitLocks[i].gameObject:SetActive(false)
                end
            end
        end
    end
end

function UIHeroEquipComponent:OnBtnItemHeadClicked(args)
    self:OpenEquipUI(HeroEquipType.Head)
end
function UIHeroEquipComponent:OnBtnItemClothesClicked(args)
    self:OpenEquipUI(HeroEquipType.Clothes)
end
function UIHeroEquipComponent:OnBtnItemBeltClicked(args)
    self:OpenEquipUI(HeroEquipType.Belt)
end
function UIHeroEquipComponent:OnBtnItemShoesClicked(args)
    self:OpenEquipUI(HeroEquipType.Shoes)
end
function UIHeroEquipComponent:OnBtnItemWeaponClicked(args)
    self:OpenEquipUI(HeroEquipType.Weapon)
end

function UIHeroEquipComponent:OpenEquipUI(equipType)
    if not self.selectHero:HasHero() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_toast_gethero"))
        return
    end
    local param = {}
    param.equipType = equipType
    param.heroCfgId = self.selectHero.id
    g_Game.UIManager:Open('HeroEquipUIMediator', param)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_UI_CHANGE_CAMERA, 2)
end

return UIHeroEquipComponent

