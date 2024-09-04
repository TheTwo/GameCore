local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require('ConfigRefer')
local DBEntityPath = require('DBEntityPath')
local TimerUtility = require('TimerUtility')
local Utils = require('Utils')
local UIHelper = require('UIHelper')
---@class ActivityShopMediator : BaseUIMediator
local ActivityShopMediator = class('ActivityShopMediator', BaseUIMediator)

function ActivityShopMediator:ctor()
    ---@type table<number, number[]> @<tabId, pGroupId[]>
    self.openedPackGroupsEachTab = {}

    self.selectTabId = nil

    self.enterTabId = nil
    self.createdMask = 0
    ---@type number[]
    self.dirtyNotifyGroups = {}
    ---@type number[]
    self.redDotMasks = {}
    ---@type table<number, CS.DragonReborn.UI.LuaBaseComponent> @<tabId, comp>
    self.createdComps = {}

    self.createdGo = {}

    self.tabId2CellData = {}

    self.tabId2CellDataIndex = {}

    self.childKeys = {}

    ---@type ChildInitData[]
    self.childDatas = {}
end

function ActivityShopMediator:OnCreate()
    self.tableTabs = self:TableViewPro('p_table_tab')
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.compChildResource = self:LuaObject('child_resource')
    self.goBlock = self:GameObject('p_content')
end

function ActivityShopMediator:OnOpened(params)
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_ACTIVITY_TAB,  Delegate.GetOrCreate(self, self.OnSelectTab))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnTabStateChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath, Delegate.GetOrCreate(self,self.RefreshCoins))
    if type(params) == 'string' then
        self.enterTabId = tonumber(params)
    else
        self.enterTabId = (params or {}).tabId
    end
    self.compChildCommonBack:FeedData({
        title = I18N.Get("activity_shop_name"),
        onClose = function()
            ModuleRefer.ActivityShopModule:SyncGoodsGroupRedDot(self.dirtyNotifyGroups, self.redDotMasks)
            self:BackToPrevious()
        end
    })
    self.compChildResource:SetVisible(false)
    self:UpdateTabs()
    self.tableTabs:SetToggleSelectIndex((self.tabId2CellDataIndex[self.enterTabId] or 1) - 1)
end

function ActivityShopMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_ACTIVITY_TAB,  Delegate.GetOrCreate(self, self.OnSelectTab))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPay.GroupData.MsgPath, Delegate.GetOrCreate(self, self.OnTabStateChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshCoins))
end

function ActivityShopMediator:UpdateDatas()
    self:UpdateTabOpenState()
    self.childDatas = {}
    for _, tab in ConfigRefer.PayTabs:ipairs() do
        if self:IsTabOpen(tab) or tab:Keep() then
            ---@type ChildInitData
            local childData = {}
            childData.childName = tab:PrefabName()
            childData.id = tab:Id()
            childData.priority = tab:Priority()
            childData.isOpen = true
            ---@type ActivityShopTabCellParam
            childData.childOpenParams = {}
            childData.childOpenParams.tabId = tab:Id()
            childData.childOpenParams.openedPackGroups = self.openedPackGroupsEachTab[tab:Id()]
            childData.childOpenParams.isShop = true
            table.insert(self.childDatas, childData)
            self.tabId2CellData[tab:Id()] = childData
            self.tabId2CellDataIndex[tab:Id()] = #self.childDatas
        end
    end
end

function ActivityShopMediator:UpdateTabs()
    self:UpdateDatas()
    self.tableTabs:Clear()
    for _, childData in ipairs(self.childDatas) do
        self.tableTabs:AppendData(childData)
    end
end

---@param tabId number
---@param force boolean @强制刷新
function ActivityShopMediator:OnSelectTab(tabId, force)
    if self.selectTabId == tabId and not force then return end
    self.selectTabId = tabId
    if self.createdMask & (1 << tabId) == 0 then
        self.createdMask = self.createdMask | (1 << tabId)
        self:CreateChild(self.tabId2CellData[tabId])
    else
        self.createdComps[tabId]:FeedData(self.tabId2CellData[tabId].childOpenParams)
    end
    for id, comp in pairs(self.createdComps) do
        comp:SetVisible(id == tabId)
    end
    self:PostOnSelectTab(tabId, force)
end

---@param childData ChildInitData
function ActivityShopMediator:CreateChild(childData)
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self:GetCSUIMediator(), childData.childName, "content", function(go)
        if Utils.IsNotNull(go) then
            local comp = self:LuaBaseComponent(childData.childName)
            comp:FeedData(childData.childOpenParams)
            comp:SetVisible(true)
            self.createdComps[childData.id] = comp
            self.goBlock:SetActive(false)
        end
    end, true)
end

function ActivityShopMediator:UpdateTabOpenState()
    self.openedPackGroupsEachTab = {}
    for _, tab in ConfigRefer.PayTabs:ipairs() do
        self.openedPackGroupsEachTab[tab:Id()] = {}
        for i = 1, tab:GoodsGroupsLength() do
            local groupId = tab:GoodsGroups(i)
            local isOpen = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
            local isSoldOut = ModuleRefer.ActivityShopModule:IsGoodsGroupSoldOut(groupId)
            local shouldKeep = ConfigRefer.PayGoodsGroup:Find(groupId):Keep()
            if (isOpen and not isSoldOut) or (isSoldOut and shouldKeep) then
                table.insert(self.openedPackGroupsEachTab[tab:Id()], groupId)
            end
        end
    end
end

function ActivityShopMediator:IsTabOpen(tab)
    return #self.openedPackGroupsEachTab[tab:Id()] > 0
end

function ActivityShopMediator:DelayUpdateRedDot(tabId)
    self.dirtyNotifyGroups = {}
    self.redDotMasks = {}
    for _, groupId in ipairs(self.openedPackGroupsEachTab[tabId]) do
        if ModuleRefer.ActivityShopModule:IsGoodsGroupNew(groupId) then
            table.insert(self.dirtyNotifyGroups, groupId)
            table.insert(self.redDotMasks, 0)
        end
    end
end

function ActivityShopMediator:PostOnSelectTab(tabId, isRefresh)
    self:RefreshCoins()
    if not isRefresh then
        self:DelayUpdateRedDot(tabId)
        ModuleRefer.ActivityShopModule:SyncGoodsGroupRedDot(self.dirtyNotifyGroups, self.redDotMasks)
    end
end

function ActivityShopMediator:RefreshCoins()
    local tab = ConfigRefer.PayTabs:Find(self.selectTabId)
    if tab:CoinTypeLength() == 0 then
        self.compChildResource:SetVisible(false)
        return
    end
    local coinId = tab:CoinType(1)
    if coinId and coinId ~= 0 then
        self.compChildResource:SetVisible(true)
        local coinCfg = ConfigRefer.Item:Find(coinId)
        local iconData2 = {
            iconName = coinCfg:Icon(),
            content = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId),
            isShowPlus = false,
        }
        self.compChildResource:FeedData(iconData2)
    else
        self.compChildResource:SetVisible(false)
    end
end

function ActivityShopMediator:OnTabStateChanged(_, changeTable)
    if ModuleRefer.ActivityShopModule:IsOnlyRedDotChanged(changeTable) then return end
    TimerUtility.DelayExecuteInFrame(function()
        self:UpdateTabOpenState()
        local hasTabClosed = false
        for tabId, _ in pairs(self.createdComps) do
            if not self:IsTabOpen(ConfigRefer.PayTabs:Find(tabId)) then
                self.createdComps[tabId]:SetVisible(false)
                UIHelper.DeleteUIComponent(self.createdComps[tabId])
                self.createdComps[tabId] = nil
                self.createdMask = self.createdMask & ~(1 << tabId)
                hasTabClosed = true
                if self.selectTabId == tabId then
                    self.selectTabId = nil
                end
            end
        end
        if hasTabClosed then
            self:UpdateTabs()
            local i, _ = next(self.childDatas)
            self.tableTabs:SetToggleSelectIndex(i - 1)
        elseif self.selectTabId then
            self:OnSelectTab(self.selectTabId, true)
        end
    end, 1)
end

return ActivityShopMediator