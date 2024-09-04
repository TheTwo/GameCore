local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local HeroEquipQuality = require("HeroEquipQuality")
local ResolveEquipParameter = require("ResolveEquipParameter")
local UIHelper = require('UIHelper')
local BistateButton = require("BistateButton")
local DBEntityPath = require("DBEntityPath")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local HeroEquipResolveUIMediator = class('HeroEquipResolveUIMediator', BaseUIMediator)

function HeroEquipResolveUIMediator:ctor()

end

function HeroEquipResolveUIMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_l')
    self.tableviewprolayoutTableItem = self:TableViewPro('p_table_item')
    self.btnBase = self:Button('p_base_btn', Delegate.GetOrCreate(self, self.OnBtnBaseClicked))

    self.btnChildDropdownL = self:Button('child_dropdown_l', Delegate.GetOrCreate(self, self.OnBtnChildDropdownLClicked))
    self.textLabelLeft = self:Text('p_text_label_left', I18N.Get("equip_allsuit"))
    self.goSuitLeft = self:GameObject('p_suit_left')
    self.imgIconSuitLeft = self:Image('p_icon_suit_left')
    self.goArrowLeft = self:GameObject('arrow_left')
    self.goTableLeft = self:GameObject('p_table_left')
    self.textAllLeft = self:Text('p_text_all_left', I18N.Get("equip_allsuit"))
    self.textSuitNumberLeft = self:Text('p_text_suit_number_left')
    self.compItemSuitLeft = self:LuaBaseComponent('p_item_suit_left')
    self.btnItemAll = self:Button('p_item_all', Delegate.GetOrCreate(self, self.OnClickAllSuit))

    self.btnChildDropdownR = self:Button('child_dropdown_r', Delegate.GetOrCreate(self, self.OnBtnChildDropdownRClicked))
    self.goColorPurpleRight = self:GameObject('p_color_purple')
    self.goColorBlueRight = self:GameObject('p_color_blue')
    self.goColorGreenRight = self:GameObject('p_color_green')
    self.goColorWhiteRight = self:GameObject('p_color_white')
    self.goColorOrangeRight = self:GameObject('p_color_orange')
    self.textLabel = self:Text('p_text_label', I18N.Get("equip_rarity"))
    self.goFilterArrow = self:GameObject('filter_arrow')
    self.goTable = self:GameObject('p_table')
    self.goContent = self:GameObject('p_content')
    self.toggleTogglea = self:Button("p_toggle_a", Delegate.GetOrCreate(self, self.OnClickQuality))
    self.textLeftA = self:Text('p_text_a', I18N.Get("equip_rarity"))
    self.toggleToggleb = self:Button("p_toggle_b", Delegate.GetOrCreate(self, self.OnClickStrength))
    self.textLeftB = self:Text('p_text_b', I18N.Get("equip_strengthen_level"))
    self.toggleChildToggleEditor1Right = self:Toggle("child_toggle_editor_1", Delegate.GetOrCreate(self, self.OnClickWhite))
    self.text1Right = self:Text('p_text_1', I18N.Get("equip_quality1"))
    self.toggleChildToggleEditor2Right = self:Toggle("child_toggle_editor_2", Delegate.GetOrCreate(self, self.OnClickGreen))
    self.text2Right = self:Text('p_text_2', I18N.Get("equip_quality2"))
    self.toggleChildToggleEditor3Right = self:Toggle("child_toggle_editor_3", Delegate.GetOrCreate(self, self.OnClickBlue))
    self.text3Right = self:Text('p_text_3', I18N.Get("equip_quality3"))
    self.toggleChildToggleEditor4Right = self:Toggle("child_toggle_editor_4", Delegate.GetOrCreate(self, self.OnClickPurple))
    self.text4Right = self:Text('p_text_4', I18N.Get("equip_quality4"))
    self.toggleChildToggleEditor5Right = self:Toggle("child_toggle_editor_5", Delegate.GetOrCreate(self, self.OnClickOrange))
    self.text5Right = self:Text('p_text_5', I18N.Get("equip_quality5"))
    self.goBaseNone = self:GameObject('p_base_none')
    self.tableviewproTableSelect = self:TableViewPro('p_table_select')
    self.tableviewproTableSelect02 = self:TableViewPro('p_table_base_02')
    self.btnBtnA = self:LuaObject("child_comp_btn_b")
    self.btnResolve = self:LuaObject("child_comp_btn_resolve")
    self.goTipsItem = self:GameObject("p_tips_item")
    self.compChildTipsItem = self:LuaBaseComponent("child_tips_item")
    self.qualitySelects = {self.goColorWhiteRight, self.goColorGreenRight, self.goColorBlueRight, self.goColorPurpleRight, self.goColorOrangeRight}
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.RefreshByItemInfo))
    g_Game.ServiceManager:AddResponseCallback(ResolveEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshByInfo))

    self.compItemSuitLeft.gameObject:SetActive(false)
    self.btnChildDropdownL.gameObject:SetActive(false)
    self.goTipsItem:SetActive(false)
    for i = 1, #self.qualitySelects do
        self.qualitySelects[i]:SetActive(true)
    end
end

function HeroEquipResolveUIMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.RefreshByItemInfo))
    g_Game.ServiceManager:RemoveResponseCallback(ResolveEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshByInfo))
end

function HeroEquipResolveUIMediator:OnBtnBaseClicked(args)
    self.goTipsItem:SetActive(false)
end

function HeroEquipResolveUIMediator:OnShow(param)
    self.compChildPopupBaseM:FeedData({
        title = I18N.Get("equip_break"),
        backBtnFunc = Delegate.GetOrCreate(self, self.OnBtnExitClicked)
    })
    self.isSortByQuality = true
    self.filterSuitId = 0
    self.selectColors = {true, true, true, true}
    self.selectSuitItems = {}
    self.suitItems = {}
    self.selectItemUid2Data = {}
    self.param = param
    self:RefreshByInfo()
    self:ChangeSuitTableState(false)
    self:ChangeSortTableState(false)

    local buttonChoose = {}
    buttonChoose.onClick = Delegate.GetOrCreate(self, self.OnBtnChooseClicked)
    buttonChoose.buttonText =  I18N.Get("equip_dis_btn")

    buttonChoose.buttonState = BistateButton.BUTTON_TYPE.BROWN
    self.btnBtnA:OnFeedData(buttonChoose)

    local buttonReslove = {}
    buttonReslove.onClick = Delegate.GetOrCreate(self, self.OnBtnResloveClicked)
    buttonReslove.buttonText =  I18N.Get("equip_break")

    self.btnResolve:OnFeedData(buttonReslove)

    self.tableviewproTableSelect02:Clear()
    for i = 1, 20 do
        self.tableviewproTableSelect02:AppendData(i)
    end
end

function HeroEquipResolveUIMediator:RefreshByItemInfo(_, changedTable)
    local addItems = changedTable.Add or {}
    local removeItems = changedTable.Remove or {}
    local newLockList = {}
    local oldLockList = {}
    local newUnlockList = {}
    local oldUnlockList = {}
    for itemUid, itemInfo in pairs(addItems) do
        if itemInfo.EquipInfo and next(itemInfo.EquipInfo) then
            if itemInfo.EquipInfo.IsLock then
                newLockList[itemUid] = true
            else
                newUnlockList[itemUid] = true
            end
        end
    end
    for itemUid, itemInfo in pairs(removeItems) do
        if itemInfo.EquipInfo and next(itemInfo.EquipInfo) then
            if not itemInfo.EquipInfo.IsLock then
                if newLockList[itemUid] then
                    oldLockList[#oldLockList + 1] = itemUid
                end
            else
                if newUnlockList[itemUid] then
                    oldUnlockList[#oldUnlockList + 1] = itemUid
                end
            end
        end
    end
    for _, itemUid in ipairs(oldLockList) do  --新加锁列表
        self:RemoveSelectItem(itemUid)
    end
    for _, itemUid in ipairs(oldUnlockList) do  --新解锁列表
        self:UpdateLeftData(itemUid)
    end
end

function HeroEquipResolveUIMediator:RefreshByInfo()
    self.selectItemUid2Data = {}
    self:RefreshLeftComponent()
    self:RefreshRightComponent()
    self.btnResolve:SetEnabled(false)
end

function HeroEquipResolveUIMediator:RemoveSelectItem(itemUid)
    if self.selectItemUid2Data[itemUid] then
        self.selectItemUid2Data[itemUid] = nil
        self:RefreshRightComponent()
        self:UpdateLeftData(itemUid)
        self.goTipsItem:SetActive(false)
    end
end

function HeroEquipResolveUIMediator:AddSelectItem(data)
    if not self.selectItemUid2Data[data.ID] then
        if self:GetSelectTotal() < ConfigRefer.ConstMain:EquipResolveNumLimit() then
            self.selectItemUid2Data[data.ID] = data
            self:RefreshRightComponent()
            self:UpdateLeftData(data.ID)
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_break_noempty"))
        end
    end
    self.btnResolve:SetEnabled(self:GetSelectTotal() > 0)
end

function HeroEquipResolveUIMediator:GetSelectTotal()
    local count = 0
    for _, _ in pairs(self.selectItemUid2Data) do
        count = count + 1
    end
    return count
end

function HeroEquipResolveUIMediator:CheckIsSelected(itemUid)
    return self.selectItemUid2Data[itemUid] ~= nil
end

function HeroEquipResolveUIMediator:UpdateLeftData(itemUid)
    self.tableviewprolayoutTableItem:UpdateData(itemUid)
end

function HeroEquipResolveUIMediator:RefreshLeftComponent()
    local equips = ModuleRefer.HeroModule:GetAllEquipsWithoutEquip()
    local showEquips = self:SortAndFilterEquips(equips)
    self.tableviewprolayoutTableItem:Clear()
    local showTables = math.ceil(#showEquips / 5) * 5
    for i = 1, showTables do
        if showEquips[i] then
            self.tableviewprolayoutTableItem:AppendData(showEquips[i].ID)
        else
            self.tableviewprolayoutTableItem:AppendData(-1)
        end
    end
end

function HeroEquipResolveUIMediator:RefreshRightComponent()
    local isHasSelect = next(self.selectItemUid2Data) ~= nil
    self.goBaseNone:SetActive(not isHasSelect)
    self.tableviewproTableSelect:Clear()
    if isHasSelect then
        for _, info in pairs(self.selectItemUid2Data) do
            self.tableviewproTableSelect:AppendData(info)
        end
    end
end

function HeroEquipResolveUIMediator:SortAndFilterEquips(equips)
    local filterLists = {}
    if self.filterSuitId and self.filterSuitId > 0 then
        for _, singleEquip in ipairs(equips) do
            local cfg = ConfigRefer.HeroEquip:Find(singleEquip.EquipInfo.ConfigId)
            if cfg:SuitId() == self.filterSuitId then
                filterLists[#filterLists + 1] = singleEquip
            end
        end
    else
        filterLists = equips
    end
    local sortFunction = function(a, b)
        local qualityCfgA = ConfigRefer.HeroEquip:Find(a.EquipInfo.ConfigId):Quality()
        local qualityCfgB = ConfigRefer.HeroEquip:Find(b.EquipInfo.ConfigId):Quality()
        local strengthLvA = a.EquipInfo.StrengthenLevel
        local strengthLvB = b.EquipInfo.StrengthenLevel
        if self.isSortByQuality then
            if qualityCfgA ~= qualityCfgB then
                return qualityCfgA < qualityCfgB
            else
                if strengthLvA ~= strengthLvB then
                    return strengthLvA > strengthLvB
                else
                    return a.ID < b.ID
                end
            end
        else
            if strengthLvA ~= strengthLvB then
                return strengthLvA < strengthLvB
            else
                if qualityCfgA ~= qualityCfgB then
                    return qualityCfgA > qualityCfgB
                else
                    return a.ID < b.ID
                end
            end
        end
    end
    table.sort(filterLists, sortFunction)
    return filterLists
end

function HeroEquipResolveUIMediator:OnClickQuality()
    self.isSortByQuality = true
    self:RefreshLeftComponent()
    self:ChangeSortTableState(false)
end

function HeroEquipResolveUIMediator:OnClickStrength()
    self.isSortByQuality = false
    self:RefreshLeftComponent()
    self:ChangeSortTableState(false)
end

function HeroEquipResolveUIMediator:OnClickAllSuit()
    self.filterSuitId = 0
    self:RefreshLeftComponent()
    self:ChangeSuitTableState(false)
end


function HeroEquipResolveUIMediator:ChangeSuitTableState(isShow)
    self.goTableLeft:SetActive(isShow)
    self.goArrowLeft.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, not isShow and 0 or 180)
    if self.filterSuitId and self.filterSuitId > 0 then
        local suitCfg = ConfigRefer.Suit:Find(self.filterSuitId)
        self:LoadSprite(suitCfg:Icon(), self.imgIconSuitLeft)
        self.goSuitLeft:SetActive(true)
        self.textLabelLeft.text = I18N.Get(suitCfg:Name())
    else
        self.goSuitLeft:SetActive(false)
        self.textLabelLeft.text = I18N.Get("equip_allsuit")
    end
end

function HeroEquipResolveUIMediator:ChangeSortTableState(isShow)
    self.goTable:SetActive(isShow)
    self.goFilterArrow.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, not isShow and 0 or 180)
    if self.isSortByQuality then
        self.textLabel.text = I18N.Get("equip_rarity")
    else
        self.textLabel.text = I18N.Get("equip_strengthen_level")
    end
end

function HeroEquipResolveUIMediator:OnBtnChildDropdownLClicked()
    if not self.goTableLeft.activeSelf then --每次显示都刷新一次内容
        self:RefreshFilterContent()
        self:ChangeSortTableState(false)
    end
    self:ChangeSuitTableState(not self.goTableLeft.activeSelf)
    self.goTipsItem:SetActive(false)
end

function HeroEquipResolveUIMediator:OnBtnChildDropdownRClicked()
    if not self.goTable.activeSelf then
        self:ChangeSuitTableState(false)
    end
    self:ChangeSortTableState(not self.goTable.activeSelf)
    self.goTipsItem:SetActive(false)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.goContent.transform)
end

function HeroEquipResolveUIMediator:RefreshFilterContent()
    local totalCount, suits = ModuleRefer.HeroModule:GetAllSuitCfgListInfoWithoutEquip()
    self.textSuitNumberLeft.text = totalCount
    for _, suit in ipairs(suits) do
        suit.onClick = function()
            self:RefreshBySuitId(suit.id)
        end
        local comp = self.suitItems[suit.id]
        if not comp then
            comp = UIHelper.DuplicateUIComponent(self.compItemSuitLeft, self.compItemSuitLeft.gameObject.transform.parent)
            comp.gameObject:SetActive(true)
            self.suitItems[suit.id] = comp
        end
        comp:FeedData(suit)
    end
end

function HeroEquipResolveUIMediator:RefreshBySuitId(suitId)
    self.filterSuitId = suitId
    self:RefreshLeftComponent()
    self:ChangeSuitTableState(false)
end

function HeroEquipResolveUIMediator:OnClickPurple(isOn)
    self.selectColors[HeroEquipQuality.Purple] = isOn
    self:ChangeLeftColorState()
end

function HeroEquipResolveUIMediator:OnClickBlue(isOn)
    self.selectColors[HeroEquipQuality.Blue] = isOn
    self:ChangeLeftColorState()
end

function HeroEquipResolveUIMediator:OnClickGreen(isOn)
    self.selectColors[HeroEquipQuality.Green] = isOn
    self:ChangeLeftColorState()
end

function HeroEquipResolveUIMediator:OnClickWhite(isOn)
    self.selectColors[HeroEquipQuality.White] = isOn
    self:ChangeLeftColorState()
end

function HeroEquipResolveUIMediator:OnClickOrange(isOn)
    self.selectColors[HeroEquipQuality.Gold] = isOn
    self:ChangeLeftColorState()
end

function HeroEquipResolveUIMediator:ChangeLeftColorState()
    for i = 1, #self.qualitySelects do
        self.qualitySelects[i]:SetActive(self.selectColors[i])
    end
end

function HeroEquipResolveUIMediator:OnBtnChooseClicked()
    local equips = ModuleRefer.HeroModule:GetAllSelectEquipsByLimit(self.filterSuitId, self.selectColors)
    local isOverflow = false
    for _, equip in pairs(equips) do
        if self:GetSelectTotal() < ConfigRefer.ConstMain:EquipResolveNumLimit() then
            self:AddSelectItem(equip)
        else
            isOverflow = true
        end
    end
    if isOverflow then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_dis_tips"))
    end
    self.goTipsItem:SetActive(false)
end

function HeroEquipResolveUIMediator:CheckIsHasStrengthOrHighQuality()
    local isHasStrenth, isHighQuality
    for _, itemInfo in pairs(self.selectItemUid2Data) do
        if itemInfo.EquipInfo.StrengthenLevel > 0 then
            isHasStrenth = true
        end
        local equipCfg = ConfigRefer.HeroEquip:Find(itemInfo.EquipInfo.ConfigId)
        if equipCfg:Quality() >= HeroEquipQuality.Gold then
            isHighQuality = true
        end
    end
    return isHasStrenth, isHighQuality
end

function HeroEquipResolveUIMediator:OnBtnResloveClicked()
    local isHasStrenth, isHighQuality = self:CheckIsHasStrengthOrHighQuality()
    if isHasStrenth then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        if isHasStrenth then
            local rate = math.floor(ConfigRefer.ConstMain:EquipResolveReturnItemRate() * 100)
            dialogParam.content = I18N.Get("equip_warning_strengthened") .. '\n' .. I18N.Get("equip_warning_break_back") .. string.format("%02d", rate) .. "%"
            dialogParam.onConfirm = function(context)
                self:HintHasHighQuality(isHighQuality)
                return true
            end
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        self:HintHasHighQuality(isHighQuality)
    end
end

function HeroEquipResolveUIMediator:HintHasHighQuality(isHighQuality)
    if isHighQuality then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        if isHighQuality then
            dialogParam.content = I18N.Get("equip_warning_highquality")
            dialogParam.onConfirm = function(context)
                self:ResolveEquip()
                return true
            end
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        self:ResolveEquip()
    end
end

function HeroEquipResolveUIMediator:ResolveEquip()
    if self:GetSelectTotal() <= 0 then
        return
    end
    local param = ResolveEquipParameter.new()
    for itemUid, _ in pairs(self.selectItemUid2Data) do
        param.args.EquipItemIds:Add(itemUid)
    end
    self.goTipsItem:SetActive(false)
    param:Send()
end

function HeroEquipResolveUIMediator:ShowItemDetails(data)
    if self.selectDetailsDataId == data.ID then
        self.goTipsItem:SetActive(not self.goTipsItem.activeSelf)
    else
        self.goTipsItem:SetActive(true)
    end
    self.selectDetailsDataId = data.ID
    local param = {}
    param.itemUid = data.ID
    param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
    self.compChildTipsItem:FeedData(param)
end

function HeroEquipResolveUIMediator:OnBtnExitClicked()
    g_Game.UIManager:CloseByName(require('UIMediatorNames').HeroEquipResolveUIMediator)
end

return HeroEquipResolveUIMediator