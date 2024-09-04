local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local DBEntityPath = require('DBEntityPath')
local I18N = require('I18N')
local ShopType = require('ShopType')

---@class UISeShopMeidator : BaseUIMediator
local UISeShopMeidator = class('UISeShopMeidator', BaseUIMediator)

function UISeShopMeidator:ctor()

end

function UISeShopMeidator:GetStoreInfo()
    return ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper.Store.Stores or {}
end

function UISeShopMeidator:OnCreate()
    self.tableviewproGroupTab = self:TableViewPro('p_group_tab')
    self.tableviewproTable = self:TableViewPro('p_table')
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.compChildCapsuleEditor1 = self:LuaObject('child_btn_capsule_editor_1')
    self.compChildCapsuleEditor2 = self:LuaObject('child_btn_capsule_editor_2')
    self.resourceList = {self.compChildCapsuleEditor1, self.compChildCapsuleEditor2}
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_SHOP_TAB, Delegate.GetOrCreate(self, self.OnClickTab))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Store.MsgPath,Delegate.GetOrCreate(self,self.UpdateStore))
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.UpdateStore))
end

function UISeShopMeidator:OnOpened(param)
    local selectTabId
    if param then
        selectTabId = param.tabIndex
    end
    local backParameter = {}
    backParameter.title = I18N.Get("setower_systemname_shop")
    self.compChildCommonBack:FeedData(backParameter)
    self.selectTabId = nil
    self:RefreshTabs(selectTabId)
end

function UISeShopMeidator:UpdateStore()
    self:RefreshTabs(self.selectTabId)
end

function UISeShopMeidator:RefreshTabs(selectTabId)
    local shopTabs = {}
    local storeInfos = self:GetStoreInfo()
    for _, v in ConfigRefer.Shop:ipairs() do
        local tabId = v:Id()
        if v:Type() == ShopType.ClimbTower then
            if storeInfos[tabId] then
                shopTabs[#shopTabs + 1] = tabId
            end
        end
    end
    self.tableviewproGroupTab:Clear()
    for _, tabId in ipairs(shopTabs) do
        self.tableviewproGroupTab:AppendData(tabId)
    end
    self.tableviewproGroupTab:RefreshAllShownItem(false)
    if not selectTabId then
        selectTabId = shopTabs[1]
    end
    self:OnClickTab(selectTabId)
end

function UISeShopMeidator:OnClickTab(tabId)
    self.tableviewproGroupTab:SetToggleSelect(tabId)
    self.selectTabId = tabId
    self:RefreshMoneys()
    self:RefreshShopItems()
end

function UISeShopMeidator:RefreshMoneys()
    local tabCfg = ConfigRefer.Shop:Find(self.selectTabId)
    for i = 1, #self.resourceList do
        local isShow = i <= tabCfg:CurrencyLength()
        self.resourceList[i]:SetVisible(isShow)
        if isShow then
            local moneyId = tabCfg:Currency(i)
            local moneyCfg = ConfigRefer.Item:Find(moneyId)
            local moneyCount =  ModuleRefer.InventoryModule:GetAmountByConfigId(moneyId)
            local data = {}
            data.iconName = moneyCfg:Icon()
            data.content = moneyCount
            self.resourceList[i]:FeedData(data)
        end
    end
end

function UISeShopMeidator:RefreshShopItems()
    self.tableviewproTable:Clear()
    local storeInfos = self:GetStoreInfo()
    local tabCfg = ConfigRefer.Shop:Find(self.selectTabId)
    local itemLists = {}
    for i = 1, tabCfg:FixedItemLength() do
        itemLists[tabCfg:FixedItem(i)] = i
    end
    for i = 1, tabCfg:RandomItemLength() do
        itemLists[tabCfg:RandomItem(i)] = tabCfg:FixedItemLength() + i
    end
    local products = storeInfos[self.selectTabId].Products
    local freeProducts = storeInfos[self.selectTabId].FreeProducts
    local showIds = {}
    for itemId, _ in pairs(products) do
        showIds[#showIds + 1] = {id = itemId, isFree = freeProducts[itemId] ~= nil}
    end
    table.sort(showIds, function(a, b)
        if a.isFree ~= b.isFree then
            return a.isFree
        elseif itemLists[a.id] ~= itemLists[b.id] then
            return itemLists[a.id] <  itemLists[b.id]
        else
            return a.id < b.id
        end
    end)
    for _, item in ipairs(showIds) do
        local isFree = item.isFree
        local buyNum = products[item.id]
        if isFree then
            buyNum = freeProducts[item.id]
            if buyNum >= 2 then
                isFree = false
                buyNum = products[item.id]
            end
        end
        self.tableviewproTable:AppendData({isFree = isFree , commodityId = item.id, buyNum = buyNum, tabId = self.selectTabId})
    end
end

function UISeShopMeidator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_SHOP_TAB, Delegate.GetOrCreate(self, self.OnClickTab))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Store.MsgPath,Delegate.GetOrCreate(self,self.UpdateStore))
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.UpdateStore))
end

return UISeShopMeidator
