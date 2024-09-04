local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local UIHeroLocalData = require('UIHeroLocalData')
local ConfigRefer = require('ConfigRefer')
local LockEquipParameter = require("LockEquipParameter")
local UIMediatorNames = require("UIMediatorNames")
local HeroEquipStrengthenInheritParameter = require("_Parameter.HeroEquipStrengthenInheritParameter")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local HeroEquipQuality = require('HeroEquipQuality')
local StrengthenEquipParameter = require("StrengthenEquipParameter")
local EventConst = require("EventConst")
local ItemType = require("ItemType")
local I18N = require('I18N')
local HeroEquipStrengthenUIMediator = class('HeroEquipStrengthenUIMediator', BaseUIMediator)

local QUALITY_COLOR = {
    CS.UnityEngine.Color(174/255, 180/255, 182/255, 255/255),
    CS.UnityEngine.Color(135/255, 167/255, 99/255, 255/255),
    CS.UnityEngine.Color(109/255, 145/255, 188/255, 255/255),
    CS.UnityEngine.Color(170/255, 119/255, 200/255, 255/255),
    CS.UnityEngine.Color(219/255, 131/255, 88/255, 255/255),
}

local QUALITY_TEXT = {
    I18N.Get("equip_quality1"),
    I18N.Get("equip_quality2"),
    I18N.Get("equip_quality3"),
    I18N.Get("equip_quality4"),
    I18N.Get("equip_quality5"),
}

local STRENGTHEN_ITEMS = {75001, 75002, 75003, 75004, 75005}

function HeroEquipStrengthenUIMediator:ctor()

end

function HeroEquipStrengthenUIMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_m')
    -- self.compChildTabNomal = self:LuaObject('child_tab_btn_nomal')
    -- self.compChildTabInherit = self:LuaObject('child_tab_btn_inherit')
    self.imgBaseFrame = self:Image('p_base_frame')
    self.textT = self:Text('p_text_t')
    self.imgIconItem = self:Image('p_icon_item')

    self.goVxShuzhi = self:GameObject("vx_trigger_shuzhi")
    self.textLvNumber = self:Text('p_text_lv_number')
    self.textLv = self:Text('p_text_lv', I18N.Get("hero_lv"))
    self.textLv1 = self:Text('p_text_lv_1', I18N.Get("hero_lv"))
    self.textLvAdd = self:Text('p_text_lv_add')
    self.goLvAdd = self:GameObject("p_group_lv_2")
    self.imgProgressN = self:Image('p_progress_n')
    self.imgProgressAdd = self:Image('p_progress_add')
    self.sliderPrigress = self:Slider("vx_effect_jindu_zong")
    self.textLvUnmber = self:Text('p_text_lv_unmber_exp', I18N.Get("hero_equip_enhance_exp"))
    self.textLvUnmber = self:Text('p_text_lv_unmber')
    self.textLvUnmberAdd = self:Text('p_text_lv_unmber_add')
    self.goMax = self:GameObject('p_max')
    self.textMax = self:Text('p_text_max', I18N.Get("equip_max"))
    self.imgIconAddtion = self:Image('p_icon_addtion')
    self.textTitleAddtion = self:Text('p_title_addtion')
    self.textTitleAddtionNumber = self:Text('p_title_addtion_number')
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

    self.compChildCapsule = self:LuaBaseComponent('child_resource')
    self.goChildCapsule = self:GameObject('child_resource')
    self.textHint = self:Text('p_text_hint', I18N.Get("equip_strengthen_add"))
    self.textNeed = self:Text('p_text_need', I18N.Get("equip_strengthen_require"))

    self.btnHide = self:Button('p_hide_btn', Delegate.GetOrCreate(self, self.OnBtnHideClicked))
    self.btnChildDropdownR = self:Button('child_dropdown_select', Delegate.GetOrCreate(self, self.OnBtnChildDropdownRClicked))
    self.textFilterLabel = self:Text('p_text_filter_label')
    self.goSortArrow = self:GameObject('sort_arrow')
    self.goSortTable = self:GameObject('p_sort_table')
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
    self.tableviewproTableItemStrengthen = self:TableViewPro('p_table_item_strengthen')

    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.goStatusNomal = self:GameObject('p_status_nomal')
    self.goStatusInherit = self:GameObject('p_status_inherit')
    self.aniTrigger = self:AnimTrigger('vx_trigger')

    self.goIconUp = self:GameObject('p_icon_up')
    self.textTitleAdd = self:Text('p_title_addtion_number_1')
    self.goIconUp2 = self:GameObject('p_icon_up_2')
    self.textTitleAdd2 = self:Text('p_text_addtion_number_2_add')
    self.goIconUp3 = self:GameObject('p_icon_up_3')
    self.textTitleAdd3 = self:Text('p_text_addtion_number_3_add')
    self.goIconUp4 = self:GameObject('p_icon_up_4')
    self.textTitleAdd1 = self:Text('p_text_addtion_number_1_add')

    self.textTN = self:Text('p_text_t_n')
    self.compChildItemStandardSL = self:LuaObject('child_item_standard_s_l')
    self.compChildItemStandardS = self:LuaObject('child_item_standard_s')
    self.tableviewproTableItem = self:TableViewPro('p_table_item')
    self.compChildDropdownL = self:LuaObject('child_dropdown_l')
    self.compChildDropdownR = self:LuaObject('child_dropdown_r')
    self.compInherit = self:LuaObject('p_btn_inherit')

    self.attrItems = {self.goItem1, self.goItem2, self.goItem3}
    self.attrShows = {self.goItemAddtion2, self.goItemAddtion3, self.goItemAddtion1}
    self.attrIcons = {self.imgIconAddtion2, self.imgIconAddtion3, self.imgIconAddtion1}
    self.attrTexts = {self.textAddtion2, self.textAddtion3, self.textAddtion1}
    self.attrNums = {self.textAddtionNumber2, self.textAddtionNumber3, self.textAddtionNumber1}
    self.attrHides = {self.textAddtionUnlock2, self.textAddtionUnlock3, self.textAddtionUnlock1}
    self.attrAddUp = {self.goIconUp2, self.goIconUp3, self.goIconUp4}
    self.attrAddNum = {self.textTitleAdd2, self.textTitleAdd3, self.textTitleAdd1}
    self.selectToggle = {self.toggleChildToggleA, self.toggleChildToggleB, self.toggleChildToggleC, self.toggleChildToggleD, self.toggleChildToggleE}
    --临时隐藏消耗货币
    self.goChildCapsule:SetActive(false)
    self.tabNames = {I18N.Get("equip_strengthen"), I18N.Get("hero_equip_enhance_convert")}
   -- self.tabs = {self.compChildTabNomal, self.compChildTabInherit}
    self.tabGos = {self.goStatusNomal, self.goStatusInherit}
    self.goVxShuzhi:SetActive(false)
    self.selectedEquip = {}
    self.selectedItem = {}

    self.goBtnAdd = self:GameObject('p_btn_add')
    self.goBtnAdd:SetActive(false)
end

function HeroEquipStrengthenUIMediator:OnBtnHideClicked(args)
    self.goSortTable:SetActive(false)
end

function HeroEquipStrengthenUIMediator:OnBtnToggleAClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(1)
    ModuleRefer.HeroModule:RecordEquipStrengthenRecord(1, isSelect and 0 or 1)
    self:ChangeSortTableState(true)
    self:ShowEquips()
end

function HeroEquipStrengthenUIMediator:OnBtnToggleBClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(2)
    ModuleRefer.HeroModule:RecordEquipStrengthenRecord(2, isSelect and 0 or 1)
    self:ChangeSortTableState(true)
    self:ShowEquips()
end

function HeroEquipStrengthenUIMediator:OnBtnToggleCClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(3)
    ModuleRefer.HeroModule:RecordEquipStrengthenRecord(3, isSelect and 0 or 1)
    self:ChangeSortTableState(true)
    self:ShowEquips()
end

function HeroEquipStrengthenUIMediator:OnBtnToggleDClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(4)
    ModuleRefer.HeroModule:RecordEquipStrengthenRecord(4, isSelect and 0 or 1)
    self:ChangeSortTableState(true)
    self:ShowEquips()
end

function HeroEquipStrengthenUIMediator:OnBtnToggleEClicked(args)
    local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(5)
    ModuleRefer.HeroModule:RecordEquipStrengthenRecord(5, isSelect and 0 or 1)
    self:ChangeSortTableState(true)
    self:ShowEquips()
end

function HeroEquipStrengthenUIMediator:ShowEquips()
    local equips = ModuleRefer.HeroModule:GetAllEquipsWithoutEquip()
    local showEquips = self:SortAndFilterEquips(equips)
    self.tableviewproTableItemStrengthen:Clear()
    for _, itemId in ipairs(STRENGTHEN_ITEMS) do
        self.tableviewproTableItemStrengthen:AppendData({isItem = true, itemId = itemId})
    end
    for _, info in ipairs(showEquips) do
        local uid = info.ID
        if uid ~= self.itemComponentId then
            self.tableviewproTableItemStrengthen:AppendData({isItem = false, uid = uid})
        end
    end
    self.tableviewproTableItemStrengthen:RefreshAllShownItem(false)
end

function HeroEquipStrengthenUIMediator:SortAndFilterEquips(equips)
    local filterLists = {}
    local isSelectAll = true
    local selectQuality = {}
    for i =1, #self.selectToggle do
        local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(i)
        if not isSelect then
            isSelectAll = false
        else
            selectQuality[i] = true
        end
    end
    if isSelectAll then
        filterLists = equips
    else
        for _, item in ipairs(equips) do
            local cfg = ConfigRefer.HeroEquip:Find(item.EquipInfo.ConfigId)
            local quality = cfg:Quality()
            if selectQuality[quality] then
                filterLists[#filterLists + 1] = item
            end
        end
    end
    local sortFunction = function(a, b)
        local equipInfoA = a.EquipInfo
        local equipInfoB = b.EquipInfo
        local cfgA = ConfigRefer.HeroEquip:Find(equipInfoA.ConfigId)
        local qualityCfgA = cfgA:Quality()
        local cfgB = ConfigRefer.HeroEquip:Find(equipInfoB.ConfigId)
        local qualityCfgB = cfgB:Quality()
        local strengthLvA = equipInfoA.StrengthenLevel
        local strengthLvB = equipInfoB.StrengthenLevel
        if qualityCfgA ~= qualityCfgB then
            return qualityCfgA < qualityCfgB
        else
            local typeA = cfgA:Type()
            local typeB = cfgB:Type()
            if strengthLvA ~= strengthLvB then
                return strengthLvA > strengthLvB
            elseif typeA ~= typeB then
                return typeA < typeB
            else
                return a.ID < b.ID
            end
        end
    end
    table.sort(filterLists, sortFunction)
    return filterLists
end

function HeroEquipStrengthenUIMediator:OnBtnChildDropdownRClicked()
    self:ChangeSortTableState(not self.goSortTable.activeSelf)
end

function HeroEquipStrengthenUIMediator:ChangeSortTableState(isShow)
    self.goSortTable:SetActive(isShow)
    self.goSortArrow.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, not isShow and 0 or 180)
    local isSelectAll = true
    local isUnselectAll = true
    local selectText = ""
    for i =1, #self.selectToggle do
        local isSelect = ModuleRefer.HeroModule:GetEquipStrengthenRecord(i)
        self.selectToggle[i].isOn = isSelect
        if not isSelect then
            isSelectAll = false
        else
            isUnselectAll = false
            selectText = selectText .. " " .. I18N.Get(QUALITY_TEXT[i])
        end
    end
    if isSelectAll then
        self.textFilterLabel.text = I18N.Get("hero_equip_enhance_quan")
    elseif isUnselectAll then
        self.textFilterLabel.text = I18N.Get("hero_equip_select_blank")
        --ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("*未选择任何品质"))
    else
        self.textFilterLabel.text = selectText
    end
end


function HeroEquipStrengthenUIMediator:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(StrengthenEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.StrengthEquip))
    g_Game.ServiceManager:RemoveResponseCallback(HeroEquipStrengthenInheritParameter.GetMsgId(), Delegate.GetOrCreate(self,self.InheritEquip))
    g_Game.EventManager:RemoveListener(EventConst.HERO_ONCLICK_STRENGTHEN, Delegate.GetOrCreate(self, self.OnSelectEquip))
end

function HeroEquipStrengthenUIMediator:OnShow(itemComponentId)
    self.compChildPopupBaseM:FeedData({title = I18N.Get("equip_strengthen")})
    -- for i = 1, #self.tabs do
    --     local callback = function()
    --         self:RefrehSelectState(i)
    --     end
    --     self.tabs[i]:FeedData({callback = callback, text = self.tabNames[i]})
    -- end
    if not itemComponentId then
        return
    end
    self.itemComponentId = itemComponentId
    g_Logger.LogChannel('StrengthenEquipParameter','CurEquipId: %d', itemComponentId)
    self:RefrehSelectState(1)
    self:ChangeSortTableState(false)
    self:ShowEquips()
    g_Game.ServiceManager:AddResponseCallback(StrengthenEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.StrengthEquip))
    g_Game.ServiceManager:AddResponseCallback(HeroEquipStrengthenInheritParameter.GetMsgId(), Delegate.GetOrCreate(self,self.InheritEquip))
    g_Game.EventManager:AddListener(EventConst.HERO_ONCLICK_STRENGTHEN, Delegate.GetOrCreate(self, self.OnSelectEquip))
end

function HeroEquipStrengthenUIMediator:StrengthEquip()
    self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    self:RefreshPanelDetails()
end

function HeroEquipStrengthenUIMediator:InheritEquip()
    self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
    self:RefreshPanelDetails()
end

function HeroEquipStrengthenUIMediator:RefrehSelectState(index)
    -- for i = 1, #self.tabs do
    --     self.tabs[i]:ChangeSelectTab(i == index)
    --     self.tabGos[i]:SetActive(i == index)
    -- end
    self.index = index
    self:RefreshPanelDetails()
end

function HeroEquipStrengthenUIMediator:RefreshPanelDetails()
    self.item = (ModuleRefer.InventoryModule:GetItemInfoByUid(self.itemComponentId) or {})
    self.equipInfo = self.item.EquipInfo
    if not self.equipInfo then
        return
    end
    self:RefreshAttrs()
    self:RefreshLvAndExp()
    self:RefreshProgress()
    if self.index == 1 then
        self:RefreshStrength()
    elseif self.index == 2 then
        self:RefreshInherit()
    end
end

function HeroEquipStrengthenUIMediator:RefreshStrength()
    local buttonParamStartWork = {}
    buttonParamStartWork.onClick = Delegate.GetOrCreate(self, self.OnBtnCompALU2EditorClicked)
    buttonParamStartWork.buttonText = I18N.Get("equip_strengthen")
    buttonParamStartWork.disableClick = function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_strength_put_nothing"))
    end
    self.compChildCompB:OnFeedData(buttonParamStartWork)
    self:RefreshBaseInfo()
    self.compChildCompB:SetEnabled(false)
    self:ShowEquips()
end

function HeroEquipStrengthenUIMediator:RefreshBaseInfo()
    local equipCfg = ConfigRefer.HeroEquip:Find(self.equipInfo.ConfigId)
    self.imgBaseFrame.color = QUALITY_COLOR[equipCfg:Quality()]
    self:LoadSprite(equipCfg:Icon(), self.imgIconItem)
    self.textT.text = I18N.Get(equipCfg:Name())
end

function HeroEquipStrengthenUIMediator:RefreshLvAndExp()
    self.textLvNumber.text = self.equipInfo.StrengthenLevel
    self.goLvAdd:SetActive(false)
    self.imgProgressAdd.fillAmount = 0
    self.sliderPrigress.value = 0
    self.textLvUnmberAdd.gameObject:SetActive(false)
end

function HeroEquipStrengthenUIMediator:RefreshProgress()
    local equipCfg = ConfigRefer.HeroEquip:Find(self.equipInfo.ConfigId)
    local expCfgId = ConfigRefer.HeroEquipStrengthen:Find(equipCfg:Strengthen()):StrengthenExp()
    local expCfg = ConfigRefer.ExpTemplate:Find(expCfgId)
    self.isMax = self.equipInfo.StrengthenLevel == expCfg:MaxLv()
    self.goMax.gameObject:SetActive(self.isMax)
    self.isAddMax = self.isMax
    if self.isMax then
        local curLevelExp = expCfg:ExpLv(self.equipInfo.StrengthenLevel)
        self.textLvUnmber.text = curLevelExp .. "/" .. curLevelExp
        self.imgProgressN.fillAmount = 1
    else
        local nextLevelExp = expCfg:ExpLv(self.equipInfo.StrengthenLevel + 1)
        local curLevelExp = self.equipInfo.StrengthenExp - ModuleRefer.HeroModule:GetStrengthLvTotalExp(self.equipInfo.ConfigId, self.equipInfo.StrengthenLevel)
        self.textLvUnmber.text = curLevelExp .. "/" .. nextLevelExp
        self.imgProgressN.fillAmount = curLevelExp / nextLevelExp
    end
    self.goIconUp:SetActive(false)
    self.textTitleAdd.gameObject:SetActive(false)
    self.goLvAdd:SetActive(false)
    self.textLvAdd.text = ""
    self.textLv.color = CS.UnityEngine.Color(0/255, 0/255, 0/255, 255/255)
    --self.textLvNumber.color = CS.UnityEngine.Color(0/255, 0/255, 0/255, 255/255)
    for i = 1, 3 do
        self.attrAddUp[i]:SetActive(false)
        self.attrAddNum[i].gameObject:SetActive(false)
    end
end

function HeroEquipStrengthenUIMediator:RefreshAttrs()
    local mainAttri = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(self.itemComponentId, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
    if not mainAttri then
        return
    end
    local mainCfg = ConfigRefer.AttrElement:Find(mainAttri.type)
    g_Game.SpriteManager:LoadSprite(mainCfg:Icon(), self.imgIconAddtion)
    self.textTitleAddtion.text = I18N.Get(mainAttri.name)
    self.textTitleAddtionNumber.text = ModuleRefer.AttrModule:GetAttrValueShowTextByType(mainCfg, mainAttri.value)
    local strengthenLvList = ModuleRefer.HeroModule:GetStrengthenConditionList(self.equipInfo.ConfigId)
    local strengthCount = #strengthenLvList
    for i = 1, 3 do
        if i <= strengthCount then
            local attr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(self.itemComponentId, i + 1)
            local hasAttr = attr ~= nil
            self.attrItems[i]:SetActive(hasAttr)
            self.attrHides[i].gameObject:SetActive(not hasAttr)
            if hasAttr then
                local cfg = ConfigRefer.AttrElement:Find(attr.type)
                g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.attrIcons[i])
                self.attrTexts[i].text = I18N.Get(attr.name)
                self.attrNums[i].text =  ModuleRefer.AttrModule:GetAttrValueShowTextByType(cfg, attr.value)
            else
                self.attrHides[i].text = I18N.GetWithParams("equip_newattr", strengthenLvList[i])
            end
        else
            self.attrItems[i]:SetActive(false)
            self.attrHides[i].gameObject:SetActive(false)
        end
    end
end

function HeroEquipStrengthenUIMediator:OnBtnCompALU2EditorClicked()
    local param = StrengthenEquipParameter.new()
    param.args.EquipItemId = self.itemComponentId
    g_Logger.LogChannel('StrengthenEquipParameter','StrengthenEquipId: %d', self.itemComponentId)
    for itemId, count in pairs(self.selectedItem or {}) do
        if count > 0 then
            param.args.ItemIds:Add(itemId)
            param.args.ItemNums:Add(count)
            g_Logger.LogChannel('StrengthenEquipParameter','SelectItemCfgId: %d Count: %d', itemId, count)
        end
    end
    for uid, selected in pairs(self.selectedEquip or {}) do
        if selected then
            param.args.ConsumeEquipItemIds:Add(uid)
            g_Logger.LogChannel('StrengthenEquipParameter','SelectEquipId: %d', uid)
        end
    end
    param:Send()
    local totalAddExp = self.totalAddExp or 0
    local canStrengthLv, _, _, _ = ModuleRefer.HeroModule:GetCanStrengthLv(self.equipInfo, totalAddExp)
    if canStrengthLv > self.equipInfo.StrengthenLevel then
        self.goVxShuzhi:SetActive(false)
        self.goVxShuzhi:SetActive(true)
        local item = (ModuleRefer.InventoryModule:GetItemInfoByUid(self.itemComponentId) or {})
        local itemName = I18N.Get(ConfigRefer.Item:Find(item.ConfigId):NameKey())
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("equip_strength_sucess_level", itemName, canStrengthLv))
    end
    self.totalAddExp = 0
    self.selectedEquip = {}
    self.selectedItem = {}
end

function HeroEquipStrengthenUIMediator:OnSelectEquip(data)
    self.selectedEquip = self.selectedEquip or {}
    if data.uid then
        self.selectedEquip[data.uid] = data.isSelect
        g_Logger.LogChannel('StrengthenEquipParameter','EquipId: %d', data.uid)
    end
    self.selectedItem = self.selectedItem or {}
    if data.itemId then
        self.selectedItem[data.itemId] = data.count
        g_Logger.LogChannel('StrengthenEquipParameter','ItemId: %d Count: %d', data.itemId, data.count)

    end
    local addExp = 0
    for uid, selected in pairs(self.selectedEquip) do
        if selected then
            local item = ModuleRefer.InventoryModule:GetItemInfoByUid(uid)
            local equipId = item.EquipInfo.ConfigId
            local equipCfg = ConfigRefer.HeroEquip:Find(equipId)
            local itemGruopId = equipCfg:BreakItemGroup()
            local items = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(itemGruopId)
            for _, single in ipairs(items) do
                local itemCfg = ConfigRefer.Item:Find(single.id)
                if itemCfg:Type() == ItemType.EquipStrengthenStuff then
                    addExp = addExp + tonumber(itemCfg:UseParam(1)) * single.count
                end
            end
            addExp = addExp + math.floor(item.EquipInfo.StrengthenExp * ConfigRefer.ConstMain:EquipResolveReturnItemRate())
        end
    end
    for itemId, count in pairs(self.selectedItem) do
        if count > 0 then
            local itemCfg = ConfigRefer.Item:Find(itemId)
            if itemCfg:UseParamLength() >= 1 then
                addExp = addExp + tonumber(itemCfg:UseParam(1)) * count
            end
        end
    end
    self.totalAddExp = addExp
    self.compChildCompB:SetEnabled(self.totalAddExp > 0 and not self.isMax)
    self:RefresAddExpState(addExp)
end

function HeroEquipStrengthenUIMediator:RefresAddExpState(totalAddExp)
    local canStrengthLv, lastExp, isMax, strengthLvExp = ModuleRefer.HeroModule:GetCanStrengthLv(self.equipInfo, totalAddExp)
    self.goMax.gameObject:SetActive(isMax)
    self.textLvUnmberAdd.gameObject:SetActive(true)
    self.isAddMax = isMax
    if totalAddExp > 0 and not isMax then
        self.textLvUnmberAdd.text = "+" .. totalAddExp
        self.imgProgressAdd.fillAmount = lastExp / strengthLvExp
        self.textLvUnmber.text = lastExp .. "/" .. strengthLvExp
        self.sliderPrigress.value = (lastExp / strengthLvExp) * 1000
    else
        if isMax then
            local strengthenId = ConfigRefer.HeroEquip:Find(self.equipInfo.ConfigId):Strengthen()
            local expTempId = ConfigRefer.HeroEquipStrengthen:Find(strengthenId):StrengthenExp()
            local expTemp = ConfigRefer.ExpTemplate:Find(expTempId)
            local maxLv = expTemp:MaxLv()
            local maxExp = expTemp:ExpLv(maxLv)
            self.textLvUnmberAdd.text = "+" .. totalAddExp
            self.imgProgressAdd.fillAmount = 1
            self.textLvUnmber.text = maxExp .. "/" .. maxExp
            self.sliderPrigress.value = (lastExp / maxExp) * 1000
        end
    end
    if totalAddExp == 0 then
        self.textLvUnmberAdd.text = ""
        self.imgProgressAdd.fillAmount = 0
    end
    if canStrengthLv > self.equipInfo.StrengthenLevel then
        self.imgProgressN.fillAmount = 0
        self.goLvAdd:SetActive(true)
        self.textLvAdd.text = canStrengthLv
        self.textLv.color = CS.UnityEngine.Color(130/255, 135/255, 147/255, 255/255)
        --self.textLvNumber.color = CS.UnityEngine.Color(130/255, 135/255, 147/255, 255/255)

        self.goIconUp:SetActive(true)
        self.textTitleAdd.gameObject:SetActive(true)
        local mainAttri = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(self.itemComponentId, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN, canStrengthLv)
        if mainAttri then
            self.textTitleAdd.text =  ModuleRefer.AttrModule:GetAttrValueShowTextByType(ConfigRefer.AttrElement:Find(mainAttri.type), mainAttri.value)
        else
            self.textTitleAdd.text = ""
        end
        local strengthenLvList = ModuleRefer.HeroModule:GetStrengthenConditionList(self.equipInfo.ConfigId)
        local strengthCount = #strengthenLvList
        for i = 1, 3 do
            if i <= strengthCount then
                local attr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(self.itemComponentId, i + 1, canStrengthLv)
                local hasAttr = attr ~= nil
                self.attrAddUp[i]:SetActive(hasAttr)
                self.attrAddNum[i].gameObject:SetActive(hasAttr)
                if hasAttr then
                    self.attrAddNum[i].text = ModuleRefer.AttrModule:GetAttrValueShowTextByType(ConfigRefer.AttrElement:Find(attr.type), attr.value)
                end
            end
        end
    else
        self:RefreshProgress()
        self.goIconUp:SetActive(false)
        self.textTitleAdd.gameObject:SetActive(false)
        self.goLvAdd:SetActive(false)
        self.textLvAdd.text = ""
        self.textLv.color = CS.UnityEngine.Color(0/255, 0/255, 0/255, 255/255)
        --self.textLvNumber.color = CS.UnityEngine.Color(0/255, 0/255, 0/255, 255/255)
        for i = 1, 3 do
            self.attrAddUp[i]:SetActive(false)
            self.attrAddNum[i].gameObject:SetActive(false)
        end
    end
end

function HeroEquipStrengthenUIMediator:RefreshInherit()
    local equipCfg = ConfigRefer.HeroEquip:Find(self.equipInfo.ConfigId)
    self.textTN.text = I18N.Get(equipCfg:Name())
    self.compChildItemStandardSL:SetVisible(false)
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(self.item.ConfigId)
    itemData.showCount = false
    itemData.showRightCount = self.equipInfo.StrengthenLevel > 0
    itemData.count = self.equipInfo.StrengthenLevel
    itemData.onClick = function()
        local param = {}
        param.itemUid = self.itemComponentId
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    end
    self.compChildItemStandardS:FeedData(itemData)
    if not self.initInherit then
        self.initInherit = true
        local leftData = {}
        local leftItems = {}
        leftItems[#leftItems + 1] = {id = 0, showText = I18N.Get("hero_equip_enhance_lv")}
        leftData.defaultId = 0
        self.selectEquipT = 0
        for _, v in ConfigRefer.HeroEquipBuild:ipairs() do
            leftItems[#leftItems + 1] = {id = v:Level(), showText = I18N.Get("T" .. v:Level() .. "_Forg")}
        end
        leftData.items = leftItems
        leftData.onSelect = function(id)
            self.selectEquipT = id
            self:FilterEquip()
        end
        leftData.onClick = function()
            self.compChildDropdownR:HideSelf()
        end
        self.compChildDropdownL:FeedData(leftData)

        local rightData = {}
        local rightItems = {}
        rightItems[#rightItems + 1] = {id = 0, showText = I18N.Get("hero_equip_enhance_quan")}
        rightData.defaultId = 0
        self.selectEquipQuality = 0
        for i = 1, HeroEquipQuality.Gold do
            rightItems[#rightItems + 1] = {id = i, showText = QUALITY_TEXT[i]}
        end
        rightData.items = rightItems
        rightData.onSelect = function(id)
            self.selectEquipQuality = id
            self:FilterEquip()
        end
        rightData.onClick = function()
            self.compChildDropdownL:HideSelf()
        end
        self.compChildDropdownR:FeedData(rightData)

        self.compInherit:FeedData({
            onClick = Delegate.GetOrCreate(self, self.OnConfirmButtonClick),
            buttonText = I18N.Get("hero_equip_enhance_convert_btn"),
        })
    end
    self:FilterEquip()
    self.compInherit:SetEnabled(false)
end

function HeroEquipStrengthenUIMediator:FilterEquip()
    local equips = ModuleRefer.InventoryModule:GetAllEquips()
    local filterEquips = {}
    for _, equip in ipairs(equips) do
        local item = equip.item
        local equipCfg = ConfigRefer.HeroEquip:Find(item.EquipInfo.ConfigId)
        if (self.selectEquipT == 0 or self.selectEquipT == equipCfg:Tier()) and
        (self.selectEquipQuality == 0 or self.selectEquipQuality == equipCfg:Quality()) and item.EquipInfo.StrengthenExp > 0 then
            filterEquips[#filterEquips + 1] = item
        end
    end
    local sort = function(a, b)
        local qualityA = ConfigRefer.HeroEquip:Find(a.EquipInfo.ConfigId):Quality()
        local qualityB = ConfigRefer.HeroEquip:Find(b.EquipInfo.ConfigId):Quality()
        if qualityA ~= qualityB then
            return qualityA > qualityB
        else
            return a.EquipInfo.StrengthenExp > b.EquipInfo.StrengthenExp
        end
    end
    table.sort(filterEquips, sort)
    self.tableviewproTableItem:Clear()
    for _, equip in ipairs(filterEquips) do
        if equip.ID ~= self.itemComponentId then
            local data = {}
            data.configCell = ConfigRefer.Item:Find(equip.ConfigId)
            data.showCount = false
            data.showRightCount = equip.EquipInfo.StrengthenLevel > 0
            data.count = equip.EquipInfo.StrengthenLevel
            data.onClick = function()
                local newEquip = ModuleRefer.InventoryModule:GetItemInfoByUid(equip.ID)
                self:AddToInherit(newEquip)
            end
            self.tableviewproTableItem:AppendData(data)
        end
    end
end

function HeroEquipStrengthenUIMediator:AddToInherit(equip)
    if equip.EquipInfo.StrengthenExp <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_equip_enhance_convert_tips_content4"))
        return
    end
    local callback = function()
        self.selectEquip = equip
        self.compChildItemStandardSL:SetVisible(true)
        local itemData = {}
        itemData.configCell = ConfigRefer.Item:Find(equip.ConfigId)
        itemData.showCount = false
        itemData.showRightCount = equip.EquipInfo.StrengthenLevel > 0
        itemData.count = equip.EquipInfo.StrengthenLevel
        itemData.onClick = function()
            local param = {}
            param.itemUid = equip.ID
            param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
            g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
        end
        self.compChildItemStandardSL:FeedData(itemData)
        self:RefreshInheritAttrs()
    end
    if equip.EquipInfo.IsLock then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        dialogParam.content = I18N.Get("hero_equip_enhance_convert_tips_content3")
        dialogParam.confirmLabel = I18N.Get("hero_equip_enhance_convert_tips_cancel")
        dialogParam.cancelLabel = I18N.Get("hero_equip_enhance_convert_tips_unlock")
        dialogParam.onConfirm = function()
            return true
        end
        dialogParam.onCancel = function(context)
            local param = LockEquipParameter.new()
            param.args.EquipItemId = equip.ID
            param.args.IsLock = not equip.EquipInfo.IsLock
            param:Send()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        callback()
    end

end

function HeroEquipStrengthenUIMediator:RefreshInheritAttrs()
    self:RefresAddExpState(self.selectEquip.EquipInfo.StrengthenExp)
    self.compInherit:SetEnabled(true)
end

function HeroEquipStrengthenUIMediator:OnConfirmButtonClick()
    local callback = function()
        local param = HeroEquipStrengthenInheritParameter.new()
        param.args.FromEquipItemId = self.selectEquip.ID
        param.args.ToEquipItemId = self.itemComponentId
        param:Send()
        local canStrengthLv, _, _, _ = ModuleRefer.HeroModule:GetCanStrengthLv(self.equipInfo, self.selectEquip.EquipInfo.StrengthenExp)
        if canStrengthLv > self.equipInfo.StrengthenLevel then
            self.goVxShuzhi:SetActive(false)
            self.goVxShuzhi:SetActive(true)
        end
    end
    if self.selectEquip.EquipInfo.HeroConfigId > 0 then
        local heroName = ConfigRefer.Heroes:Find(self.selectEquip.EquipInfo.HeroConfigId):Name()
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        dialogParam.content = I18N.Get("hero_equip_enhance_convert_tips_content1") .. I18N.Get(heroName) ..  I18N.Get("hero_equip_enhance_convert_tips_content2")
        dialogParam.confirmLabel = I18N.Get("hero_equip_enhance_convert_tips_cancel")
        dialogParam.cancelLabel = I18N.Get("hero_equip_enhance_convert_tips_confirm")
        dialogParam.onConfirm = function()
            return true
        end
        dialogParam.onCancel = function(context)
            callback()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        callback()
    end
end

return HeroEquipStrengthenUIMediator