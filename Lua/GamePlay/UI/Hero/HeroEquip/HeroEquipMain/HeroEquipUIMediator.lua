local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require('UIHelper')
local UIHeroLocalData = require('UIHeroLocalData')
local HeroEquipType = require("HeroEquipType")
local UIMediatorNames = require("UIMediatorNames")
local ItemType = require("ItemType")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local NotificationType = require("NotificationType")
local WearEquipParameter = require("WearEquipParameter")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require('I18N')
local HeroEquipUIMediator = class('HeroEquipUIMediator', BaseUIMediator)

local EQUIP_SHOW_TYPE = {HeroEquipType.Head, HeroEquipType.Clothes, HeroEquipType.Belt, HeroEquipType.Shoes, HeroEquipType.Weapon}

local EQUIP_QUALITY_TEXT = {
    "equip_quality1",
    "equip_quality2",
    "equip_quality3",
    "equip_quality4",
    "equip_quality5",
}

function HeroEquipUIMediator:ctor()

end

function HeroEquipUIMediator:OnCreate()
    self.goItemNone = self:GameObject('p_item_none')
    self.imgItemIcon = self:Image('p_item_icon')
    self.textHintItem = self:Text('p_text_hint_item', I18N.Get("equip_nomatch"))
    self.tableviewproTableItem = self:TableViewPro('p_table_item')
    self.btnDropdown = self:Button('p_btn_dropdown', Delegate.GetOrCreate(self, self.OnBtnDropdownClicked))
    self.goIconRise = self:GameObject('p_icon_rise')
    self.goIconFall = self:GameObject('p_icon_fall')
    self.btnChildDropdownL = self:Button('child_dropdown_l', Delegate.GetOrCreate(self, self.OnBtnChildDropdownLClicked))
    self.textLabel = self:Text('p_text_label', I18N.Get("equip_allsuit"))
    self.imgSuit = self:Image("p_icon_suit")
    self.goArrow = self:GameObject('arrow')
    self.goTable = self:GameObject('p_table')

    self.btnItemAll = self:Button('p_item_all', Delegate.GetOrCreate(self, self.OnClickAllSuit))
    self.textAll = self:Text('p_text_all', I18N.Get("equip_allsuit"))
    self.textSuitNumber = self:Text('p_text_suit_number')
    self.compItemSuit = self:LuaBaseComponent('p_item_suit')

    self.btnChildDropdownR = self:Button('child_dropdown_r', Delegate.GetOrCreate(self, self.OnBtnChildDropdownRClicked))
    self.textFilterLabel = self:Text('p_text_filter_label')
    self.goSortArrow = self:GameObject('sort_arrow')
    self.goSortTable = self:GameObject('p_sort_table')

    -- self.toggleToggleA = self:Button("p_toggle_a", Delegate.GetOrCreate(self, self.OnClickQuality))
    -- self.textA = self:Text('p_text_a', I18N.Get("equip_rarity"))
    -- self.toggleToggleB = self:Button("p_toggle_b", Delegate.GetOrCreate(self, self.OnClickStrength))
    -- self.textB = self:Text('p_text_b', I18N.Get("equip_strengthen_level"))

    self.btnHide = self:Button('p_hide_btn', Delegate.GetOrCreate(self, self.OnBtnHideClicked))
    self.btnToggleA = self:Button('p_toggle_a', Delegate.GetOrCreate(self, self.OnBtnToggleAClicked))
    self.toggleChildToggleA = self:Toggle('child_toggle_a')
    self.textA = self:Text('p_text_a', "equip_quality1")
    self.btnToggleB = self:Button('p_toggle_b', Delegate.GetOrCreate(self, self.OnBtnToggleBClicked))
    self.toggleChildToggleB = self:Toggle('child_toggle_b')
    self.textB = self:Text('p_text_b', "equip_quality2")
    self.btnToggleC = self:Button('p_toggle_c', Delegate.GetOrCreate(self, self.OnBtnToggleCClicked))
    self.toggleChildToggleC = self:Toggle('child_toggle_c')
    self.textC = self:Text('p_text_c', "equip_quality3")
    self.btnToggleD = self:Button('p_toggle_d', Delegate.GetOrCreate(self, self.OnBtnToggleDClicked))
    self.toggleChildToggleD = self:Toggle('child_toggle_d')
    self.textD = self:Text('p_text_d', "equip_quality4")
    self.btnToggleE = self:Button('p_toggle_e', Delegate.GetOrCreate(self, self.OnBtnToggleEClicked))
    self.toggleChildToggleE = self:Toggle('child_toggle_e')
    self.textE = self:Text('p_text_e', "equip_quality5")






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
    self.btnCompDecom = self:Button('p_comp_decom', Delegate.GetOrCreate(self, self.OnBtnCompDecomClicked))
    self.btnCompStrength = self:Button('p_comp_strength', Delegate.GetOrCreate(self, self.OnBtnCompStrengthClicked))
    self.textStrength = self:Text('p_text_strength', I18N.Get("equip_btn_strengthen"))
    self.btnCompExchange = self:Button('p_comp_exchange', Delegate.GetOrCreate(self, self.OnBtnCompExchangeClicked))
    self.textExchange = self:Text('p_text_exchange', I18N.Get("equip_btn_replace"))
    self.btnCompUnload = self:Button('p_comp_unload', Delegate.GetOrCreate(self, self.OnBtnCompUnloadClicked))
    self.textUnload = self:Text('p_text_unload', I18N.Get("equip_btn_unequipped"))
    self.textHintRight = self:Text('p_text_hint_right', I18N.Get("equip_choose"))
    self.compChildSuitDetail = self:LuaBaseComponent('child_suit_detail')
    self.btnContrast = self:Button('p_btn_contrast', Delegate.GetOrCreate(self, self.OnBtnContrastClicked))
    self.compChildCommonBack = self:LuaBaseComponent('child_common_btn_back')
    self.compChildReddotDefaultEditorHead = self:LuaObject('child_reddot_default_editor_head')
    self.compChildReddotDefaultEditorClothes = self:LuaObject('child_reddot_default_editor_clothes')
    self.compChildReddotDefaultEditorBelt = self:LuaObject('child_reddot_default_editor_belt')
    self.compChildReddotDefaultEditorShoes = self:LuaObject('child_reddot_default_editor_shoes')
    self.compChildReddotDefaultEditorWeapon = self:LuaObject('child_reddot_default_editor_weapon')

    self.selectIcons = {self.goImgSelectWeapon, self.goImgSelectHead, self.goImgSelectClothes, self.goImgSelectBelt,self.goImgSelectShoes}
    self.selectShowGos = {self.goStatusNWeapon, self.goStatusNHead, self.goStatusNClothes, self.goStatusNBelt, self.goStatusNShoes}
    self.selectEmptyGos = {self.goStatusNoneWeapon, self.goStatusNoneHead, self.goStatusNoneClothes, self.goStatusNoneBelt, self.goStatusNoneShoes}
    self.qualityFrames = {self.imgBaseFrameWeapon, self.imgBaseFrameHead, self.imgBaseFrameClothes, self.imgBaseFrameBelt, self.imgBaseFrameShoes}
    self.itemIcons = {self.imgIconItemWeapon, self.imgIconItemHead, self.imgIconItemClothes, self.imgIconItemBelt, self.imgIconItemShoes}
    self.itemLvTexts = {self.textLvWeapon, self.textLvHead, self.textLvClothes, self.textLvBelt, self.textLvShoes}
    self.selectToggle = {self.toggleChildToggleA, self.toggleChildToggleB, self.toggleChildToggleC, self.toggleChildToggleD, self.toggleChildToggleE}
    g_Game.EventManager:AddListener(EventConst.HERO_ONCLICK_EQUIP, Delegate.GetOrCreate(self, self.OnSelectEquip))
    g_Game.EventManager:AddListener(EventConst.HERO_DATA_UPDATE,Delegate.GetOrCreate(self,self.RefreshByChangeHero))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnItemDataChanged))
    ModuleRefer.InventoryModule:AddCountChangeByTypeListener(ItemType.HeroEquip, Delegate.GetOrCreate(self, self.RefreshByInfo))
    g_Game.ServiceManager:AddResponseCallback(WearEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshByInfo))

    self.compItemSuit.gameObject:SetActive(false)
    self.imgSuit.gameObject:SetActive(false)
    self.btnChildDropdownL.gameObject:SetActive(false)
end

function HeroEquipUIMediator:OnOpened(param)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("equip"),
        backBtnFunc = Delegate.GetOrCreate(self, self.OnBtnExitClicked)
    })
    self.isSortByQuality = true
    self.isForwardSort = true
    self.filterSuitId = 0
    self.suitItems = {}
    self.curHeroCfgId = param.heroCfgId
    self:ChangeEquipType(param.equipType)
    self:RefreshDownEquips()
    self:ChangeSuitTableState(false)
    self:ChangeSortTableState(false)
    local equipWeaponSub = ModuleRefer.NotificationModule:GetDynamicNode("EquipWeaponSub" .. self.curHeroCfgId, NotificationType.EQUIP_WEAPON_SUB)
    local equipHeadSub = ModuleRefer.NotificationModule:GetDynamicNode("EquipHeadSub" .. self.curHeroCfgId, NotificationType.EQUIP_HEAD_SUB)
    local equipClothSub = ModuleRefer.NotificationModule:GetDynamicNode("EquipClothSub" .. self.curHeroCfgId, NotificationType.EQUIP_CLOTH_SUB)
    local equipBeltSub = ModuleRefer.NotificationModule:GetDynamicNode("EquipBeltSub" .. self.curHeroCfgId, NotificationType.EQUIP_BELT_SUB)
    local equipShoeSub = ModuleRefer.NotificationModule:GetDynamicNode("EquipShoeSub" .. self.curHeroCfgId, NotificationType.EQUIP_SHOE_SUB)
    ModuleRefer.NotificationModule:AttachToGameObject(equipWeaponSub, self.compChildReddotDefaultEditorWeapon.go, self.compChildReddotDefaultEditorWeapon.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipHeadSub, self.compChildReddotDefaultEditorHead.go, self.compChildReddotDefaultEditorHead.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipClothSub, self.compChildReddotDefaultEditorClothes.go, self.compChildReddotDefaultEditorClothes.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipBeltSub, self.compChildReddotDefaultEditorBelt.go, self.compChildReddotDefaultEditorBelt.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(equipShoeSub, self.compChildReddotDefaultEditorShoes.go, self.compChildReddotDefaultEditorShoes.redDot)
end

function HeroEquipUIMediator:OnBtnExitClicked()
    g_Game.UIManager:CloseByName(require('UIMediatorNames').HeroEquipUIMediator)
end

function HeroEquipUIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.HERO_ONCLICK_EQUIP, Delegate.GetOrCreate(self, self.OnSelectEquip))
    g_Game.EventManager:RemoveListener(EventConst.HERO_DATA_UPDATE,Delegate.GetOrCreate(self,self.RefreshByChangeHero))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnItemDataChanged))
    ModuleRefer.InventoryModule:RemoveCountChangeByTypeListener(ItemType.HeroEquip, Delegate.GetOrCreate(self, self.RefreshByInfo))
    g_Game.EventManager:TriggerEvent(EventConst.HERO_UI_CHANGE_CAMERA, 1)
    g_Game.ServiceManager:RemoveResponseCallback(WearEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshByInfo))
end

function HeroEquipUIMediator:RefreshByChangeHero(changedMap)
    self:ChangeSuitTableState(false)
    self:ChangeSortTableState(false)
    self:RefreshDownEquips()
    if self.refreshList then
        for _, uid in ipairs(self.refreshList) do
            self.tableviewproTableItem:UpdateData(uid)
        end
        self.tableviewproTableItem:SetToggleSelect(self.refreshList[1])
    end
end

function HeroEquipUIMediator:OnItemDataChanged(_, changedData)
    local _,_,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if changed then
        for _, v in pairs(changed) do
            for _, item in pairs(v) do
                if item.EquipInfo and item.EquipInfo.ConfigId and item.EquipInfo.ConfigId > 0 then
                    self.tableviewproTableItem:UpdateData(item.ID)
                    self.tableviewproTableItem:SetToggleSelect(item.ID)
                    return
                end
            end
        end
    end
end


function HeroEquipUIMediator:RefreshByInfo()
    self:RefreshComponent()
    self:RefreshDownEquips()
end

function HeroEquipUIMediator:RefreshComponent()
    self:ChangeSuitTableState(false)
    self:ChangeSortTableState(false)
    self:ChangeEquipType(self.curEquipType)
end

function HeroEquipUIMediator:ChangeEquipType(equipType)
    for i = 1, #self.selectIcons do
        self.selectIcons[EQUIP_SHOW_TYPE[i]]:SetActive(EQUIP_SHOW_TYPE[i] == equipType)
    end
    if self.curEquipType ~= equipType then
        self.curSelectEquip = nil
    end
    self.curEquipType = equipType
    if self.curEquipType == EQUIP_SHOW_TYPE[5] then
        ModuleRefer.GuideModule:CallGuide(31)
    end
    self:RefreshEquipByType()
end

function HeroEquipUIMediator:RefreshEquipByType()
    local equips = ModuleRefer.HeroModule:GetAllEquipsByEquipType(self.curEquipType)
    local showEquips = self:SortAndFilterEquips(equips)
    local isHasEquips = showEquips and #showEquips > 0
    self.goItemNone:SetActive(not isHasEquips)
    self.tableviewproTableItem.gameObject:SetActive(isHasEquips)
    self.textHintRight.gameObject:SetActive(not isHasEquips)
    local selectUid = nil
    if isHasEquips then
        local curEquipItemInfo = ModuleRefer.HeroModule:GetEquipItemByType(self.curHeroCfgId, self.curEquipType)
        self.tableviewproTableItem:Clear()
        for _, info in ipairs(showEquips) do
            local uid = info.uid
            local item = info.item
            self.tableviewproTableItem:AppendData(uid)
            if self.curSelectEquip then
                if item.ID == self.curSelectEquip.ID then
                    selectUid = uid
                end
            elseif curEquipItemInfo then
                if item.ID == curEquipItemInfo.ID then
                    selectUid = uid
                end
            end
        end
        self.tableviewproTableItem:RefreshAllShownItem(false)
        if selectUid then
            self.tableviewproTableItem:SetFocusData(selectUid)
            self.tableviewproTableItem:SetToggleSelect(selectUid)
        else
            self.tableviewproTableItem:SetToggleSelect(showEquips[1].uid)
        end
        self:RefreshBtnsStatus()
    else
        local curEquipItemInfo = ModuleRefer.HeroModule:GetEquipItemByType(self.curHeroCfgId, self.curEquipType)
        if curEquipItemInfo then
            local data = ModuleRefer.InventoryModule:GetItemInfoByUid(curEquipItemInfo.ID)
            self:OnSelectEquip(data)
        else
            self.compChildSuitDetail.gameObject:SetActive(false)
            self.curSelectEquip = nil
            self:RefreshBtnsStatus()
        end

    end
end

function HeroEquipUIMediator:SortAndFilterEquips(equips)
    local filterLists = {}

    local isSelectAll = true
    local selectQuality = {}
    for i =1, #self.selectToggle do
        local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(i)
        if not isSelect then
            isSelectAll = false
        else
            selectQuality[i] = true
        end
    end

    if self.filterSuitId and self.filterSuitId > 0 then
        for _, singleEquip in ipairs(equips) do
            local item = singleEquip.item
            local cfg = ConfigRefer.HeroEquip:Find(item.EquipInfo.ConfigId)
            local quality = cfg:Quality()
            if cfg:SuitId() == self.filterSuitId then
                if isSelectAll then
                    filterLists[#filterLists + 1] = singleEquip
                elseif selectQuality[quality] then
                    filterLists[#filterLists + 1] = singleEquip
                end
            end
        end
    else
        if isSelectAll then
            filterLists = equips
        else
            for _, singleEquip in ipairs(equips) do
                local item = singleEquip.item
                local cfg = ConfigRefer.HeroEquip:Find(item.EquipInfo.ConfigId)
                local quality = cfg:Quality()
                if selectQuality[quality] then
                    filterLists[#filterLists + 1] = singleEquip
                end
            end
        end
    end
    local sortFunction = function(a, b)
        local itemA = a.item
        local itemB = b.item
        local equipInfoA = itemA.EquipInfo
        local equipInfoB = itemB.EquipInfo
        local qualityCfgA = ConfigRefer.HeroEquip:Find(equipInfoA.ConfigId):Quality()
        local qualityCfgB = ConfigRefer.HeroEquip:Find(equipInfoB.ConfigId):Quality()
        local strengthLvA = equipInfoA.StrengthenLevel
        local strengthLvB = equipInfoB.StrengthenLevel
        if self.isSortByQuality then
            if qualityCfgA ~= qualityCfgB then
                if self.isForwardSort then
                    return qualityCfgA > qualityCfgB
                else
                    return qualityCfgA < qualityCfgB
                end
            else
                if strengthLvA ~= strengthLvB then
                    return strengthLvA > strengthLvB
                else
                    return itemA.ID < itemB.ID
                end
            end
        else
            if strengthLvA ~= strengthLvB then
                if  self.isForwardSort then
                    return strengthLvA > strengthLvB
                else
                    return strengthLvA < strengthLvB
                end
            else
                if qualityCfgA ~= qualityCfgB then
                    return qualityCfgA > qualityCfgB
                else
                    return itemA.ID < itemB.ID
                end
            end
        end
    end
    table.sort(filterLists, sortFunction)
    return filterLists
end

function HeroEquipUIMediator:OnSelectEquip(data)
    self.compChildSuitDetail.gameObject:SetActive(true)
    self.curSelectEquip = data
    local detailsData = {}
    detailsData.itemComponentId = data.ID
    local selectEquipAttr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(data.ID, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
    local curEquipItemInfo = ModuleRefer.HeroModule:GetEquipItemByType(self.curHeroCfgId, self.curEquipType)
    if curEquipItemInfo then
        local curEquipAttr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(curEquipItemInfo.ID, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
        detailsData.isShowUp = selectEquipAttr.value > curEquipAttr.value
    else
        detailsData.isShowUp = false
    end
    detailsData.prewHeroCfgId = self.curHeroCfgId
    self.compChildSuitDetail:FeedData(detailsData)
    self:RefreshBtnsStatus()
end

function HeroEquipUIMediator:RefreshDownEquips()
    for index, equipType in pairs(EQUIP_SHOW_TYPE) do
        self:RefreshSingleEquip(index, equipType)
    end
end

function HeroEquipUIMediator:RefreshSingleEquip(index, equipType)
    local equipInfo = ModuleRefer.HeroModule:GetEquipByType(self.curHeroCfgId, equipType)
    local isHasEquip = equipInfo and next(equipInfo)
    local selectIndex = EQUIP_SHOW_TYPE[index]
    self.selectShowGos[selectIndex]:SetActive(isHasEquip)
    self.selectEmptyGos[selectIndex]:SetActive(not isHasEquip)
    if isHasEquip then
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
    end
end

function HeroEquipUIMediator:RefreshBtnsStatus()
    if self.curSelectEquip then
        self.btnCompDecom.gameObject:SetActive(true)
        self.btnCompStrength.gameObject:SetActive(true)
        local equipHeroCfgId = self.curSelectEquip.EquipInfo.HeroConfigId or 0
        local isEquipSelf = equipHeroCfgId == self.curHeroCfgId
        if isEquipSelf then
            self.btnCompExchange.gameObject:SetActive(false)
            self.btnCompUnload.gameObject:SetActive(true)
            self.textUnload.text = I18N.Get("equip_btn_unequipped")
        else
            local isHasEquip = ModuleRefer.HeroModule:CheckIsHasEquip(self.curHeroCfgId, self.curEquipType)
            if  isHasEquip then
                self.btnCompExchange.gameObject:SetActive(true)
                self.btnCompUnload.gameObject:SetActive(false)
            else
                self.btnCompExchange.gameObject:SetActive(false)
                self.btnCompUnload.gameObject:SetActive(true)
                self.textUnload.text = I18N.Get("equip_btn_equipped")
            end
        end
        local curEquipItemInfo = ModuleRefer.HeroModule:GetEquipItemByType(self.curHeroCfgId, self.curEquipType)
        self.btnContrast.gameObject:SetActive(curEquipItemInfo and curEquipItemInfo.ID ~= self.curSelectEquip.ID)
    else
        self.btnCompDecom.gameObject:SetActive(false)
        self.btnCompStrength.gameObject:SetActive(false)
        self.btnCompExchange.gameObject:SetActive(false)
        self.btnCompUnload.gameObject:SetActive(false)
        self.btnContrast.gameObject:SetActive(false)
    end
end

-- function HeroEquipUIMediator:OnClickQuality()
--     self.isSortByQuality = true
--     self:RefreshComponent()
-- end

-- function HeroEquipUIMediator:OnClickStrength()
--     self.isSortByQuality = false
--     self:RefreshComponent()
-- end

function HeroEquipUIMediator:OnBtnHideClicked(args)
    self.goSortTable:SetActive(false)
end

function HeroEquipUIMediator:OnBtnToggleAClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(1)
    ModuleRefer.HeroModule:RecordEquipSelectRecord(1, isSelect and 0 or 1)
    self.isSortByQuality = true
    self:ChangeSortTableState(true)
    self:ChangeEquipType(self.curEquipType)
end

function HeroEquipUIMediator:OnBtnToggleBClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(2)
    ModuleRefer.HeroModule:RecordEquipSelectRecord(2, isSelect and 0 or 1)
    self.isSortByQuality = true
    self:ChangeSortTableState(true)
    self:ChangeEquipType(self.curEquipType)
end

function HeroEquipUIMediator:OnBtnToggleCClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(3)
    ModuleRefer.HeroModule:RecordEquipSelectRecord(3, isSelect and 0 or 1)
    self.isSortByQuality = true
    self:ChangeSortTableState(true)
    self:ChangeEquipType(self.curEquipType)
end

function HeroEquipUIMediator:OnBtnToggleDClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(4)
    ModuleRefer.HeroModule:RecordEquipSelectRecord(4, isSelect and 0 or 1)
    self.isSortByQuality = true
    self:ChangeSortTableState(true)
    self:ChangeEquipType(self.curEquipType)
end

function HeroEquipUIMediator:OnBtnToggleEClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(5)
    ModuleRefer.HeroModule:RecordEquipSelectRecord(5, isSelect and 0 or 1)
    self.isSortByQuality = true
    self:ChangeSortTableState(true)
    self:ChangeEquipType(self.curEquipType)
end

function HeroEquipUIMediator:OnClickAllSuit()
    self.filterSuitId = 0
    self:RefreshComponent()
end

function HeroEquipUIMediator:OnBtnChildDropdownLClicked()
    if not self.goTable.activeSelf then
        self:RefreshFilterContent()
        self:ChangeSortTableState(false)
    end
    self:ChangeSuitTableState(not self.goTable.activeSelf)
end

function HeroEquipUIMediator:OnBtnChildDropdownRClicked()
    if not self.goSortTable.activeSelf then
        self:ChangeSuitTableState(false)
    end
    self:ChangeSortTableState(not self.goSortTable.activeSelf)
end

function HeroEquipUIMediator:ChangeSuitTableState(isShow)
    self.goTable:SetActive(isShow)
    self.goArrow.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, not isShow and 0 or 180)
    if self.filterSuitId and self.filterSuitId > 0 then
        local suitCfg = ConfigRefer.Suit:Find(self.filterSuitId)
        self:LoadSprite(suitCfg:Icon(), self.imgSuit)
        self.imgSuit.gameObject:SetActive(true)
        self.textLabel.text = I18N.Get(suitCfg:Name())
    else
        self.imgSuit.gameObject:SetActive(false)
        self.textLabel.text = I18N.Get("equip_allsuit")
    end
end

function HeroEquipUIMediator:ChangeSortTableState(isShow)
    self.goSortTable:SetActive(isShow)
    self.goSortArrow.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, not isShow and 0 or 180)
    -- if self.isSortByQuality then
    --     self.textFilterLabel.text = I18N.Get("equip_rarity")
    -- else
    --     self.textFilterLabel.text = I18N.Get("equip_strengthen_level")
    -- end
    local isSelectAll = true
    local isUnselectAll = true
    local selectText = ""
    for i =1, #self.selectToggle do
        local isSelect = ModuleRefer.HeroModule:GetEquipSelectRecord(i)
        self.selectToggle[i].isOn = isSelect
        if not isSelect then
            isSelectAll = false
        else
            isUnselectAll = false
            selectText = selectText .. " " .. I18N.Get(EQUIP_QUALITY_TEXT[i])
        end
    end
    if isSelectAll then
        self.textFilterLabel.text = I18N.Get("hero_equip_enhance_quan")
    elseif isUnselectAll then
        self.textFilterLabel.text = I18N.Get("hero_equip_select_blank")
    else
        self.textFilterLabel.text = selectText
    end
end

function HeroEquipUIMediator:RefreshFilterContent()
    local totalCount, suits = ModuleRefer.HeroModule:GetAllSuitCfgListInfoByType(self.curEquipType)
    self.textSuitNumber.text = totalCount
    for _, suit in ipairs(suits) do
        suit.onClick = function()
            self:RefreshBySuitId(suit.id)
        end
        local comp = self.suitItems[suit.id]
        if not comp then
            comp = UIHelper.DuplicateUIComponent(self.compItemSuit, self.compItemSuit.gameObject.transform.parent)
            comp.gameObject:SetActive(true)
            self.suitItems[suit.id] = comp
        end
        comp:FeedData(suit)
    end
end

function HeroEquipUIMediator:RefreshBySuitId(suitId)
    self.filterSuitId = suitId
    self:RefreshComponent()
end

function HeroEquipUIMediator:OnBtnDropdownClicked()
    self.isForwardSort = not self.isForwardSort
    self.goIconRise:SetActive(self.isForwardSort)
    self.goIconFall:SetActive(not self.isForwardSort)
    self:RefreshComponent()
end

function HeroEquipUIMediator:OnBtnContrastClicked()
    local curEquipItemInfo = ModuleRefer.HeroModule:GetEquipItemByType(self.curHeroCfgId, self.curEquipType)
    local param = {}
    param.prewHeroCfgId = self.curHeroCfgId
    param.leftEquip = self.curSelectEquip
    param.rightEquip =  curEquipItemInfo
    g_Game.UIManager:Open('HeroEquipCompareUIMediator', param)
end

function HeroEquipUIMediator:OnBtnItemHeadClicked()
    self:ChangeEquipType(HeroEquipType.Head)
end

function HeroEquipUIMediator:OnBtnItemClothesClicked()
    self:ChangeEquipType(HeroEquipType.Clothes)
end

function HeroEquipUIMediator:OnBtnItemBeltClicked()
    self:ChangeEquipType(HeroEquipType.Belt)
end

function HeroEquipUIMediator:OnBtnItemShoesClicked()
    self:ChangeEquipType(HeroEquipType.Shoes)
end

function HeroEquipUIMediator:OnBtnItemWeaponClicked()
    self:ChangeEquipType(HeroEquipType.Weapon)
end

function HeroEquipUIMediator:OnBtnCompDecomClicked()
    --g_Game.UIManager:Open('HeroEquipForgeUIMediator')
    g_Game.UIManager:Open('HeroEquipResolveUIMediator')
end

function HeroEquipUIMediator:OnBtnCompStrengthClicked()
    local equipCfg = ConfigRefer.HeroEquip:Find(self.curSelectEquip.EquipInfo.ConfigId)
    local expCfgId = ConfigRefer.HeroEquipStrengthen:Find(equipCfg:Strengthen()):StrengthenExp()
    local expCfg = ConfigRefer.ExpTemplate:Find(expCfgId)
    local isMax = self.curSelectEquip.EquipInfo.StrengthenLevel == expCfg:MaxLv()
    if isMax then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_strength_full_level"))
        return
    end
    g_Game.UIManager:Open('HeroEquipStrengthenUIMediator', self.curSelectEquip.ID)
end

function HeroEquipUIMediator:OnBtnCompExchangeClicked()
    local curEquipItemInfo = ModuleRefer.HeroModule:GetEquipItemByType(self.curHeroCfgId, self.curEquipType)
    local equipHeroCfgId = self.curSelectEquip.EquipInfo.HeroConfigId or 0
    if equipHeroCfgId > 0 then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        local config = ConfigRefer.Heroes:Find(equipHeroCfgId)
        dialogParam.content = I18N.GetWithParams("equip_warning_equipped_another", I18N.Get(config:Name()))
        dialogParam.onConfirm = function(context)
            local param = WearEquipParameter.new()
            param.args.HeroId = self.curHeroCfgId
            param.args.EquipItemIds:Add(self.curSelectEquip.ID)
            param.args.IsWear = true
            param:Send(self.btnCompExchange.transform)
            self.refreshList = {self.curSelectEquip.ID, curEquipItemInfo and curEquipItemInfo.ID or nil}
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        local param = WearEquipParameter.new()
        param.args.HeroId = self.curHeroCfgId
        param.args.EquipItemIds:Add(self.curSelectEquip.ID)
        param.args.IsWear = true
        param:Send()
        self.refreshList = {self.curSelectEquip.ID, curEquipItemInfo and curEquipItemInfo.ID or nil}
    end
end

function HeroEquipUIMediator:OnBtnCompUnloadClicked()
    local equipHeroCfgId = self.curSelectEquip.EquipInfo.HeroConfigId or 0
    local isEquipSelf = equipHeroCfgId == self.curHeroCfgId
    if not isEquipSelf then
        self:OnBtnCompExchangeClicked()
    else
        local param = WearEquipParameter.new()
        param.args.HeroId = self.curHeroCfgId
        param.args.EquipItemIds:Add(self.curSelectEquip.ID)
        param.args.IsWear = false
        param:Send(self.btnCompUnload.transform)
        self.refreshList = {self.curSelectEquip.ID}
    end
end


return HeroEquipUIMediator