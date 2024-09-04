local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local DBEntityPath = require('DBEntityPath')
local I18N = require('I18N')
local ShopType = require('ShopType')
local TimeFormatter = require("TimeFormatter")
local TimerUtility = require('TimerUtility')
local UIMediatorNames = require('UIMediatorNames')

---@class UIShopMeidatorParameter
---@field tabIndex number
---@field backNoAni boolean

---@class UIShopMeidator : BaseUIMediator
local UIShopMeidator = class('UIShopMeidator', BaseUIMediator)

function UIShopMeidator:ctor()
    BaseUIMediator.ctor(self)
    self._backNoAni = false
end

function UIShopMeidator:OnCreate()
    ---@see CommonBackButtonComponent
    self.child_common_btn_back = self:LuaBaseComponent("child_common_btn_back")
    self.tableviewproGroupTab = self:TableViewPro('p_group_tab')
    self.tableviewproTable = self:TableViewPro('p_table')
    self.goTable = self:GameObject('p_table')
    self.goTime = self:GameObject('p_time')
    self.textCd = self:Text('p_text_cd', I18N.Get("shop_refreshtime"))
    self.textAdTime = self:Text('p_text_ad_time')
    self.compChildCapsule = self:LuaBaseComponent('child_btn_capsule_editor_1')
    self.compChildCapsule1 = self:LuaBaseComponent('child_btn_capsule_editor_2')
    self.content = self.goTable.transform:Find("Viewport/Content")
    self.resourceList = {self.compChildCapsule, self.compChildCapsule1}
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_SHOP_TAB, Delegate.GetOrCreate(self, self.OnClickTab))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Store.MsgPath,Delegate.GetOrCreate(self,self.UpdateStore))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.RewardVideos.MsgPath,Delegate.GetOrCreate(self,self.UpdateStore))
    g_Game.EventManager:AddListener(EventConst.RECORD_CONTENT_POS, Delegate.GetOrCreate(self, self.RecordPos))
end

function UIShopMeidator:RecordPos()
	self.recordPos = self.content.localPosition
end

function UIShopMeidator:UpdateStore()
    self:RefreshTabs(self.selectTabId)
    if self.recordPos then
        self.delayTimer = TimerUtility.DelayExecute(function()
            self.content.localPosition = self.recordPos
            self.recordPos = nil
        end, 0.1)
	end
end

function UIShopMeidator:GetStoreInfo()
    return ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper.Store.Stores or {}
end

---@param param string|UIShopMeidatorParameter
function UIShopMeidator:OnOpened(param)
    local selectTabId
    if type(param) == 'string' then
        selectTabId = tonumber(param)
    elseif param then
        selectTabId = param.tabIndex
        self._backNoAni = param.backNoAni or false
    end
    self.selectTabId = nil
    ---@type CommonBackButtonData
    local backParameter = {}
    backParameter.title = I18N.Get("shop_title")
    backParameter.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self.child_common_btn_back:FeedData(backParameter)
    self:RefreshTabs(selectTabId)
    ModuleRefer.PetModule:SetAllowSyncPetPopUpQueue(false)
end

function UIShopMeidator:RefreshTabs(selectTabId)
    local shopTabs = {}
    local storeInfos = self:GetStoreInfo()
    for _, v in ConfigRefer.Shop:ipairs() do
        local tabId = v:Id()
        if v:Type() == ShopType.Personal or v:Type() == ShopType.Alliance or v:Type() == ShopType.ClimbTower then
            if storeInfos[tabId] and storeInfos[tabId].Open then
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

function UIShopMeidator:OnClickTab(tabId)
    self.tableviewproGroupTab:SetToggleSelect(tabId)
    self.selectTabId = tabId
    self:RefreshMoneys()
    self:RefreshShopItems()
    self:RefreshShopTime()
end

function UIShopMeidator:RefreshShopItems()
    self.tableviewproTable:Clear()
    local storeInfos = self:GetStoreInfo()
    local products = storeInfos[self.selectTabId].Products
    local freeProducts = storeInfos[self.selectTabId].FreeProducts
    local showIds = {}
    for itemId, _ in pairs(products) do
        showIds[#showIds + 1] = {id = itemId, isFree = freeProducts[itemId] ~= nil}
    end
    table.sort(showIds, function(a, b)
        if a.isFree ~= b.isFree then
            return a.isFree
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
    self.tableviewproTable:RefreshAllShownItem(false)
end

function UIShopMeidator:RefreshShopTime()
    local storeInfos = self:GetStoreInfo()
    local refrshTime = storeInfos[self.selectTabId].NextRefreshTime.Seconds
    local isHasRefreshTime = refrshTime > 0
    self.goTime:SetActive(isHasRefreshTime)
    if isHasRefreshTime then
        if self.tickTimer then
            TimerUtility.StopAndRecycle(self.tickTimer)
            self.tickTimer = nil
        end
        if not self.tickTimer then
            self:RefreshTimeText(refrshTime)
            self.tickTimer = TimerUtility.IntervalRepeat(function() self:RefreshTimeText(refrshTime) end, 0.5, -1)
        end
    end
end

function UIShopMeidator:RefreshTimeText(refrshTime)
    local remainTime = refrshTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    if remainTime > 0 then
        self.textAdTime.text = TimeFormatter.SimpleFormatTime(remainTime)
    else
        self:RecycleTimer()
        self.goTime:SetActive(false)
    end
end

function UIShopMeidator:RecycleTimer()
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
end

function UIShopMeidator:RefreshMoneys()
    local tabCfg = ConfigRefer.Shop:Find(self.selectTabId)
    for i = 1, #self.resourceList do
        local isShow = i <= tabCfg:CurrencyLength()
        self.resourceList[i].gameObject:SetActive(isShow)
        if isShow then
            local moneyId = tabCfg:Currency(i)
            local moneyCfg = ConfigRefer.Item:Find(moneyId)
            local moneyCount =  ModuleRefer.InventoryModule:GetAmountByConfigId(moneyId)
            local data = {}
            data.iconName = moneyCfg:Icon()
            data.content = moneyCount
            data.onClick = function()
                ---@type CommonItemDetailsParameter
                local data = {}
                data.itemId = moneyId
                data.itemType = require("CommonItemDetailsDefine").ITEM_TYPE.ITEM
                g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, data)
            end
            self.resourceList[i]:FeedData(data)
        end
    end
end


function UIShopMeidator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_SHOP_TAB, Delegate.GetOrCreate(self, self.OnClickTab))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Store.MsgPath,Delegate.GetOrCreate(self,self.UpdateStore))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.RewardVideos.MsgPath,Delegate.GetOrCreate(self,self.UpdateStore))
    g_Game.EventManager:RemoveListener(EventConst.RECORD_CONTENT_POS, Delegate.GetOrCreate(self, self.RecordPos))
    self:RecycleTimer()
    ModuleRefer.PetModule:SetAllowSyncPetPopUpQueue(true)
end

function UIShopMeidator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

return UIShopMeidator
