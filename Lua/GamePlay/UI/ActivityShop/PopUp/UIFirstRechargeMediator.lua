---scene: scene_common_popup_activity
local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require('UIMediatorNames')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local DBEntityPath = require('DBEntityPath')
local TimerUtility = require('TimerUtility')
local Utils = require('Utils')
local FPXSDKBIDefine = require('FPXSDKBIDefine')
---@class UIFirstRechargeMediator : BaseUIMediator
local UIFirstRechargeMediator = class('UIFirstRechargeMediator',BaseUIMediator)

---@class UIFirstRechargeMediatorParam
---@field isFromHud boolean
---@field openPopId number

function UIFirstRechargeMediator:ctor()
    ---@type table<number, PopUpTabCellParam>
    self.id2CellData = {}
    ---@type table<string, BaseUIComponent>
    self.templatesNameMap = {}
    ---@type PopUpTabCellParam[]
    self.tableCellDatas = {}
    self.popIds = {}
end

function UIFirstRechargeMediator:OnCreate(param)
    self.goTabs = self:GameObject('tabs')
    self.tableTabs = self:TableViewPro('p_table_tab')
    self.templatesNameMap['child_shop_activity'] = self:LuaObject('child_shop_activity')
    self.templatesNameMap['child_shop_activity_hero'] = self:LuaObject('child_shop_activity_hero')
    self.templatesNameMap['child_shop_activity_pet'] = self:LuaObject('child_shop_activity_pet')
    self.templatesNameMap['child_shop_activity_item'] = self:LuaObject('child_shop_activity_item')
    self.templatesNameMap['child_shop_activity_turntable'] = self:LuaObject('child_shop_activity_turntable')
    for _, template in pairs(self.templatesNameMap) do
        template:SetVisible(false)
    end
end

---@param param UIFirstRechargeMediatorParam
function UIFirstRechargeMediator:OnOpened(param)
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_POPUP_TAB,  Delegate.GetOrCreate(self, self.OnSelectTab))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnTabStateChanged))

    self.param = param
    self.isFromHud = (param or {}).isFromHud
    self.openPopId = (param or {}).openPopId
    self.isShop = false
    local popIds = ModuleRefer.LoginPopupModule:GetPopIdsByMediatorName(UIMediatorNames.UIFirstRechargeMediator, false, true)
    for _, id in ipairs(popIds) do
        local pop = ConfigRefer.PopUpWindow:Find(id)
        local groupId = pop:PayGroup()
        local isGroupAvaliable = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
        if isGroupAvaliable then
            table.insert(self.popIds, id)
        end
    end
    self:UpdateCellDatas()
    self:UpdateTabs()
    if #self.popIds <= 1 then
        if #self.popIds == 0 then
            self:CloseSelf()
            return
        end
        self.goTabs:SetActive(false)
        self:OnSelectTab(self.popIds[1], true)
    else
        if self.openPopId then
            self.tableTabs:SetToggleSelect(self.id2CellData[self.openPopId])
        else
            local pIds = ModuleRefer.LoginPopupModule:GetPopIds(true)
            for _, id in ipairs(pIds) do
                if table.ContainsValue(self.popIds, id) then
                    self.tableTabs:SetToggleSelect(self.id2CellData[id])
                    return
                end
            end
            local i, _ = next(self.tableCellDatas)
            self.tableTabs:SetToggleSelectIndex(i - 1)
        end
    end
end

function UIFirstRechargeMediator:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function UIFirstRechargeMediator:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function UIFirstRechargeMediator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_POPUP_TAB,  Delegate.GetOrCreate(self, self.OnSelectTab))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnTabStateChanged))

    if not self.isFromHud then
        ModuleRefer.LoginPopupModule:OnPopupShown(self.popIds)
    end
end

function UIFirstRechargeMediator:UpdateCellDatas()
    table.clear(self.tableCellDatas)
    for _, id in ipairs(self.popIds) do
        local popCfg = ConfigRefer.PopUpWindow:Find(id)
        local childName = popCfg:PrefabName()
        if not childName or childName == '' then
            g_Logger.ErrorChannel('拍脸礼包', 'PopUpWindow id: %d has no prefab name', id)
            goto continue
        end
        ::continue::
        ---@type PopUpTabCellParam
        local data = {}
        data.popId = id
        data.isShop = self.isShop
        data.childName = childName
        data.forceUpdate = id == self.selectedTab
        self.id2CellData[id] = data
        table.insert(self.tableCellDatas, data)
    end
    table.sort(self.tableCellDatas, function(a, b)
        return a.popId < b.popId
    end)
end

function UIFirstRechargeMediator:UpdateContent(id)
    if self.goTabs.activeSelf then
        self.tableTabs:SetToggleSelect(self.id2CellData[id])
    else
        self:OnSelectTab(id, true)
    end
end

function UIFirstRechargeMediator:OnFrameTick()
    if g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIGuideFingerMediator) then
        self:CloseSelf()
    end
end

function UIFirstRechargeMediator:UpdateTabs()
    self.tableTabs:Clear()
    for _, data in ipairs(self.tableCellDatas) do
        self.tableTabs:AppendData(data)
    end
end

function UIFirstRechargeMediator:OnSelectTab(id, force)
    if self.selectedTab == id and not force then
        return
    end

    self.selectedTab = id
    local packGroupId = ConfigRefer.PopUpWindow:Find(id):PayGroup()
    ModuleRefer.ActivityShopModule:SyncGoodsGroupRedDot({packGroupId}, {0})
    local data = self.id2CellData[id]
    local childName = data.childName
    for name, template in pairs(self.templatesNameMap) do
        template:SetVisible(name == childName)
    end
    self.templatesNameMap[childName]:FeedData(data)
    -- bi打点
    local popCfg = ConfigRefer.PopUpWindow:Find(id)
    local payGroupCfg = ConfigRefer.PayGoodsGroup:Find(popCfg:PayGroup())
    local payGroupName = payGroupCfg:StringId()
    local payGoodCfg = ConfigRefer.PayGoods:Find(ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(payGroupCfg:Id()))
    local payGoodName = payGoodCfg:StringName()
    local keyMap = FPXSDKBIDefine.ExtraKey.condition_bundle_mediator
    local extraData = {}
    extraData[keyMap.bundle_name] = payGroupName
    extraData[keyMap.paygoods_name] = payGoodName
    local groupIds = {}
    for _, pid in ipairs(self.popIds) do
        local cfg = ConfigRefer.PopUpWindow:Find(pid)
        table.insert(groupIds, cfg:PayGroup())
    end
    extraData[keyMap.bundle_include_id] = groupIds
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.condition_bundle_mediator, extraData)
end

function UIFirstRechargeMediator:OnTabStateChanged(_, changedData)
    if ModuleRefer.ActivityShopModule:IsOnlyRedDotChanged(changedData) then
        return
    end
    TimerUtility.DelayExecuteInFrame(function()
        local oldPopIds = {}
        Utils.CopyArray(self.popIds, oldPopIds)
        self.popIds = {}
        local popIds = ModuleRefer.LoginPopupModule:GetPopIdsByMediatorName(UIMediatorNames.UIFirstRechargeMediator, false, true)
        for _, id in ipairs(popIds) do
            local pop = ConfigRefer.PopUpWindow:Find(id)
            local groupId = pop:PayGroup()
            local isGroupAvaliable = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
            if isGroupAvaliable then
                table.insert(self.popIds, id)
            end
        end
        if #self.popIds == 0 then
            self:CloseSelf()
            return
        elseif #self.popIds == 1 then
            self.goTabs:SetActive(false)
        else
            self.goTabs:SetActive(true)
        end
        for _, id in ipairs(oldPopIds) do
            local popCfg = ConfigRefer.PopUpWindow:Find(id)
            local groupId = popCfg:PayGroup()
            local isOpen = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
            if not isOpen then
                if self.selectedTab == id then
                    self.selectedTab = nil
                    local data = self.id2CellData[id]
                    local template = self.templatesNameMap[data.childName]
                    template:SetVisible(false)
                end
            end
        end
        self:UpdateCellDatas()
        self:UpdateTabs()
        if self.selectedTab then
            self:UpdateContent(self.selectedTab)
        else
            local i, _ = next(self.tableCellDatas)
            local id = self.tableCellDatas[i].popId
            self:UpdateContent(id)
        end
    end, 1)
end

return UIFirstRechargeMediator