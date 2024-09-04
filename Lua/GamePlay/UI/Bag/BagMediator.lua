local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local FunctionClass = require('FunctionClass')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local PackType = require("PackType")
local GuideUtils = require("GuideUtils")
local TimeFormatter = require('TimeFormatter')
local UseLimitType = require('UseLimitType')
local UIMediatorNames = require('UIMediatorNames')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require("TimerUtility")
local UsePetEggParameter = require('UsePetEggParameter')
local NotificationType = require('NotificationType')
local ItemDataProviderSimpleFactory = require('ItemDataProviderSimpleFactory')
---@class BagMediator : BaseUIMediator
local BagMediator = class('BagMediator', BaseUIMediator)

function BagMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.compHudResource = self:LuaObject("child_hud_resources")
    self.tableviewproTableList = self:TableViewPro('p_table_list')
    self.goGroupRight = self:GameObject('p_group_right')
    self.compChildTipsItem = self:LuaBaseComponent('child_tips_item')
    self.goGroupNum = self:GameObject('p_group_num')
    self.textNum = self:Text('p_text_num')
    self.textInputBox = self:Text('p_text_input_box')
    self.inputfieldInputBoxClick = self:InputField('p_input_box_click', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.textInputBoxClick = self:Text('p_text_input_box_click')
    self.textItemNum = self:Text('p_text_item_num')
    self.btnConfirm = self:Button('p_btn_confirm', Delegate.GetOrCreate(self, self.OnBtnConfirmClicked))
    self.textConfirm = self:Text('p_text_confirm')
    self.goGroupBagEmpty = self:GameObject('p_group_bag_empty')
    self.textEmpty = self:Text('p_text_empty')
    self.btnBack = self:LuaBaseComponent('child_common_btn_back')
    self.setBar = self:LuaBaseComponent('child_set_bar')
    self.compSideTabAll = self:LuaObject('p_btn_side_tab_all')
    self.compSideTab1 = self:LuaObject('p_btn_side_tab_1')
    self.compSideTab2 = self:LuaObject('p_btn_side_tab_2')
    self.compSideTab3 = self:LuaObject('p_btn_side_tab_3')
    self.compSideTab4 = self:LuaObject('p_btn_side_tab_4')
    self.compSideTab5 = self:LuaObject('p_btn_side_tab_5')
    self.compSideTab6 = self:LuaObject('p_btn_side_tab_6')
    self.textLimit = self:Text('p_text_limit')
    self.goTime = self:GameObject('p_time')
    self.textTime = self:Text('p_text_time')
    self.goGroupRight:SetActive(false)
    self.goGroupBagEmpty:SetActive(false)

    self.goBtns = self:GameObject('p_btns')
    self.btnOpen1 = self:Button('p_btn_open_1', Delegate.GetOrCreate(self, self.OnBtnOpen1Clicked))
    self.textOpen1 = self:Text('p_text_open_1')
    self.btnOpen2 = self:Button('p_btn_open_2', Delegate.GetOrCreate(self, self.OnBtnOpen2Clicked))
    self.textOpen2 = self:Text('p_text_open_2')

    self.animation = self:BindComponent('p_group_right', typeof(CS.UnityEngine.Animation))
    self.tabs = {self.compSideTabAll, self.compSideTab1, self.compSideTab2, self.compSideTab3, self.compSideTab4, self.compSideTab5, self.compSideTab6}
    self.clickActions = {
        Delegate.GetOrCreate(self, self.OnSelectAll), Delegate.GetOrCreate(self, self.OnSelect1), Delegate.GetOrCreate(self, self.OnSelect2), Delegate.GetOrCreate(self, self.OnSelect3),
        Delegate.GetOrCreate(self, self.OnSelect4), Delegate.GetOrCreate(self, self.OnSelect5), Delegate.GetOrCreate(self, self.OnSelect6),
    }
    self.tabNames = {
        I18N.Get("backpack_type_all"), I18N.Get("backpack_type_resource"), I18N.Get("backpack_type_chest"), I18N.Get("backpack_type_hero"), I18N.Get("backpack_type_equip"),
        I18N.Get("backpack_type_pet"), I18N.Get("backpack_type_other"),
    }

        -- 不知道干什么的组件
    self.p_equipment_hero = self:GameObject('p_equipment_hero')
    if self.p_equipment_hero then
        self.p_equipment_hero:SetVisible(false)
    end
end

function BagMediator:OnBtnOpen1Clicked(args)
    if ModuleRefer.PetModule:CheckIsFullPet() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_num_upperbound_des"))
        return
    end
    ModuleRefer.ToastModule:BlockPower()
    local itemCfg = ModuleRefer.InventoryModule:GetConfigByUid(self.curSelectUid)
    local msg = UsePetEggParameter.new()
    msg.args.ItemCfgId = itemCfg:Id()
    msg.args.Num = 1
    msg:Send()
end

function BagMediator:OnBtnOpen2Clicked(args)
    if ModuleRefer.PetModule:CheckIsFullPet() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_num_upperbound_des"))
        return
    end
    ModuleRefer.ToastModule:BlockPower()
    local itemCfg = ModuleRefer.InventoryModule:GetConfigByUid(self.curSelectUid)
    local itemCount = ModuleRefer.InventoryModule:GetAmountByUid(self.curSelectUid)
    local petEmptyCount = ModuleRefer.PetModule:GetEmptyPetCount()
    local useNum = itemCfg:UseNumLength() > 0 and itemCfg:UseNum(1) or 0
    local canUseCount = math.min(petEmptyCount, itemCount, useNum)
    local msg = UsePetEggParameter.new()
    msg.args.ItemCfgId = itemCfg:Id()
    msg.args.Num = canUseCount
    msg:Send()
end

function BagMediator:OnBtnConfirmClicked()
    ---@type ItemDataProviderSimpleFactory
    local factory = ItemDataProviderSimpleFactory.new()
    local itemCfg = ModuleRefer.InventoryModule:GetConfigByUid(self.curSelectUid)
    local itemDataProvider = factory:Create(itemCfg)
    if itemDataProvider:CanUse() then
        if itemDataProvider:GetFunctionClass() == FunctionClass.OpenPetEgg then
            itemDataProvider:Use(1)
        else
            itemDataProvider:Use(self.curInputNum or 1)
        end
    end
end

function BagMediator:OnSelectAll()
    self:PlayHideTab()
    self.curSelecType = PackType.All
    self:RefreshItemContent()
end

function BagMediator:OnSelect1()
    self:PlayHideTab()
    self.curSelecType = PackType.Resource
    self:RefreshItemContent()
end

function BagMediator:OnSelect2()
    self:PlayHideTab()
    self.curSelecType = PackType.Box
    self:RefreshItemContent()
end

function BagMediator:OnSelect3()
    self:PlayHideTab()
    self.curSelecType = PackType.Hero
    self:RefreshItemContent()
end

function BagMediator:OnSelect4()
    self:PlayHideTab()
    self.curSelecType = PackType.Equip
    self:RefreshItemContent()
end

function BagMediator:OnSelect5()
    self:PlayHideTab()
    self.curSelecType = PackType.Pet
    self:RefreshItemContent()
end

function BagMediator:OnSelect6()
    self:PlayHideTab()
    self.curSelecType = PackType.Other
    self:RefreshItemContent()
end

function BagMediator:OnBtnExitClicked()
    g_Game.UIManager:CloseByName(require('UIMediatorNames').BagMediator)
end

function BagMediator:OnShow()
    self:InitStaticText()
    self:InitItems()
end

function BagMediator:OnOpened()
    ModuleRefer.InventoryModule:ForceInitCache()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerBagChange))
    self.btnBack:FeedData({title = I18N.Get("backpack_title"), backBtnFunc = Delegate.GetOrCreate(self, self.OnBtnExitClicked)})
    for i = 1, #self.tabs do
        local tab = self.tabs[i]
        tab:FeedData({index = i, onClick = self.clickActions[i], btnName = self.tabNames[i], isLocked = false})
        tab:SetStatus(i == 1 and 0 or 1)
    end
    self:InitRedDots(true)
end

function BagMediator:OnClose(param)
    self:StopTimer()
    self:InitRedDots(true)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerBagChange))
    BaseUIMediator.OnClose(self, param)
end

function BagMediator:InitRedDots(show)
    local notificationModule = ModuleRefer.NotificationModule
    self.compSideTabAll:ShowNotificationNode(true)
    self.compSideTab6:ShowNotificationNode(true)
    local redNodeAll = self.compSideTabAll:GetNotificationNode()
    local redNodeOther = self.compSideTab6:GetNotificationNode()
    local node = notificationModule:GetDynamicNode("WORLD_EVENT_USEITEM", NotificationType.WORLD_EVENT_USEITEM)
    if show then
        notificationModule:AttachToGameObject(node, redNodeAll.go, redNodeAll.redDot)
        notificationModule:AttachToGameObject(node, redNodeOther.go, redNodeOther.redDot)
    else
        notificationModule:RemoveFromGameObject(redNodeAll.go, false)
        notificationModule:RemoveFromGameObject(redNodeOther.go, false)
    end
end

function BagMediator:InitStaticText()
    self.textEmpty.text = I18N.Get("backpack_none")
    self.textNum.text = I18N.Get("backpack_choose_num")
    self.textOpen1.text = I18N.Get("treasure_option") .. " x1"
end

function BagMediator:OnPlayerBagChange(_, changedTable)
    local refreshAll = false
    local addItems = changedTable.Add or {}
    local removeItems = changedTable.Remove or {}
    for itemUid, _ in pairs(addItems) do
        if not removeItems[itemUid] then
            refreshAll = true
            break
        end
    end
    if not refreshAll then
        for itemUid, _ in pairs(removeItems) do
            if not addItems[itemUid] then
                refreshAll = true
                break
            end
        end
    end
    if refreshAll then
        self:InitItems()
    else
        for itemUid, _ in pairs(addItems) do
            local cfg = ConfigRefer.Item:Find(addItems[itemUid].ConfigId)
            if cfg and not cfg:UseAuto() then
                self.tableviewproTableList:UpdateData(itemUid)
                self.tableviewproTableList:AppendCellCustomName(cfg:NameKey())
            end
        end
        self:RefreshRightContent()
        if self.curSelectUid then
            self.tableviewproTableList:SetToggleSelect(self.curSelectUid)
        end
    end
end

function BagMediator:GetCoinPos()
    return self.compHudResource:GetCoinPos()
end

function BagMediator:GetMoneyPos()
    return self.compHudResource:GetMoneyPos()
end

function BagMediator:GetResCellPos(index)
    return self.compHudResource:GetResCellPos(index)
end

function BagMediator:InitItems()
    self.curSelectUid = nil
    self.curInputNum = nil
    self.curTypeItemList = {}
    local allItems = ModuleRefer.InventoryModule:GetCastleItems()
    self.goGroupRight:SetActive(false)
    if next(allItems) == nil then
        self.tableviewproTableList:Clear()
        self.goGroupBagEmpty:SetActive(true)
        return
    end
    self.curTypeItemList[PackType.All] = self.curTypeItemList[PackType.All] or {}
    local count = 1
    for _, item in pairs(allItems) do
        local itemConfig = ModuleRefer.InventoryModule:GetConfigByUid(item.ID)
        if itemConfig then
            local itemType = itemConfig:Class()
            if itemType > PackType.All then
                count = count + 1
                local functionClass = itemConfig:FunctionClass()
                local typ = itemConfig:Type()
                local quality = itemConfig:Quality()
                table.insert(self.curTypeItemList[PackType.All], {item.ID, itemConfig, functionClass, typ, quality})
                self.curTypeItemList[itemType] = self.curTypeItemList[itemType] or {}
                table.insert(self.curTypeItemList[itemType], {item.ID, itemConfig, functionClass, typ, quality})
            end
        end
    end
    local sortFunc = function(a, b)
        local isBoxA = a[3] == FunctionClass.OpenBox
        local isBoxB = b[3] == FunctionClass.OpenBox
        if isBoxA ~= isBoxB then
            return isBoxA
        else
            if a[5] ~= b[5] then
                return a[5] > b[5]
            else
                return a[4] > b[4]
            end
        end
    end
    for _, itemList in ipairs(self.curTypeItemList) do
        table.sort(itemList, sortFunc)
    end
    self:OnSelectAll()
end

function BagMediator:PlayHideTab()

end

function BagMediator:RefreshItemContent()
    self.goGroupRight:SetActive(false)
    if not self.curSelecType then
        return
    end
    for i = 1, #self.tabs do
        local isSelect = self.curSelecType == i
        self.tabs[i]:SetStatus(isSelect and 0 or 1)
    end
    self.tableviewproTableList:Clear()
    local selectItems = self.curTypeItemList[self.curSelecType]
    local isEmpty = not (selectItems and next(selectItems))
    self.goGroupBagEmpty:SetActive(isEmpty)
    if isEmpty then
        return
    end
    for _, item in ipairs(selectItems) do
        self.tableviewproTableList:AppendData(item[1])
        self.tableviewproTableList:AppendCellCustomName(ModuleRefer.InventoryModule:GetConfigByUid(item[1]):NameKey())
    end
end

function BagMediator:SelectItem(Uid)
    self.curSelectUid = Uid
    self:RefreshRightContent()
    self.goGroupRight:SetVisible(false)
    TimerUtility.DelayExecuteInFrame(function()
        self.goGroupRight:SetVisible(true)
        self.animation:Play("anim_vx_ui_bag_group_right_open")
    end, 1)
end

function BagMediator:RefreshRightContent()
    if not self.curSelectUid then
        return
    end
    self.goGroupRight:SetActive(true)
    local itemCfg = ModuleRefer.InventoryModule:GetConfigByUid(self.curSelectUid)
    local itemCount = ModuleRefer.InventoryModule:GetAmountByUid(self.curSelectUid)
    local itemInfo = ModuleRefer.InventoryModule:GetItemInfoByUid(self.curSelectUid)
    if itemInfo.EquipInfo and itemInfo.EquipInfo.ConfigId > 0 then
        local param = {}
        param.itemUid = self.curSelectUid
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.EQUIP
        self.compChildTipsItem:FeedData(param)
    else
        local param = {}
        param.itemId = itemCfg:Id()
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
        self.compChildTipsItem:FeedData(param)
    end
    self.curInputNum = 1
    local isOpenPetEgg = itemCfg:FunctionClass() == FunctionClass.OpenPetEgg
    if itemCfg:UseMulitable() and itemCount > 1 and not isOpenPetEgg then
        self.goGroupNum:SetActive(true)
        self.textInputBox.text = "/" .. tostring(itemCount)
        local useNum = itemCfg:UseNumLength() > 0 and itemCfg:UseNum(1) or 0
        local setBarData = {}
        setBarData.minNum = 1
        setBarData.maxNum = useNum > 0 and math.min(useNum, itemCount) or itemCount
        setBarData.oneStepNum = 1
        setBarData.curNum = 1
        setBarData.intervalTime = 0.1
        setBarData.callBack = function(value)
            self:OnEndEdit(value)
        end
        self.setBar:FeedData(setBarData)
        self.inputfieldInputBoxClick.text = 1
    else
        self.goGroupNum:SetActive(false)
    end
    self.textItemNum.text = I18N.GetWithParams("backpack_own_num", itemCount)

    local factory = ItemDataProviderSimpleFactory.new()
    local itemDataProvider = factory:Create(itemCfg)
    local isCanUse = itemDataProvider:CanUse()
    self.textLimit.gameObject:SetActive(not isCanUse)
    self.textLimit.text = itemDataProvider:GetUnusableHint()
    self.btnConfirm.gameObject:SetActive(isCanUse)
    self.textConfirm.text = I18N.Get(itemDataProvider:GetUseText())
    if itemInfo.ExpireTime then
        local lastTime = itemInfo.ExpireTime - g_Game.ServerTime:GetServerTimestampInSeconds()
        if lastTime > 0 then
            self:StopTimer()
            self.textTime.text = I18N.GetWithParams("backpack_item_expire_time", TimeFormatter.SimpleFormatTimeWithDay(lastTime))
            self.timer = TimerUtility.IntervalRepeat(function()
                local last = itemInfo.ExpireTime - g_Game.ServerTime:GetServerTimestampInSeconds()
                if last > 0 then
                    self.textTime.text = I18N.GetWithParams("backpack_item_expire_time", TimeFormatter.SimpleFormatTimeWithDay(last))
                else
                    self:StopTimer()
                end
            end, 1, -1)
            self.goTime:SetActive(true)
        else
            self.goTime:SetActive(false)
        end
    else
        self.goTime:SetActive(false)
    end
end

function BagMediator:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function BagMediator:OnEndEdit(inputText)
    local inputNum = tonumber(inputText)
    if not inputNum or inputNum <= 0 then
        inputNum = 1
    end
    local itemCount = ModuleRefer.InventoryModule:GetAmountByUid(self.curSelectUid)
    if inputNum >= itemCount then
        inputNum = itemCount
    end
    self.curInputNum = inputNum
    self.inputfieldInputBoxClick.text = inputNum
    self.setBar.Lua:OutInputChangeSliderValue(inputNum)
end

return BagMediator
