local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local ShopType = require('ShopType')
local NotificationType = require('NotificationType')
local DBEntityPath = require('DBEntityPath')
local Delegate = require('Delegate')

---@class ShopModule : BaseModule
local ShopModule = class('ShopModule',BaseModule)

function ShopModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Store.Stores.MsgPath,Delegate.GetOrCreate(self,self.RefreshRedPoint))
end

function ShopModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Store.Stores.MsgPath,Delegate.GetOrCreate(self,self.RefreshRedPoint))
end

function ShopModule:GetStoreInfo()
    return ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper.Store.Stores or {}
end

function ShopModule:CreateRedPointLogicTree()
    self.createRedLogicTree = true
    local hudShopNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("HudShopNode", NotificationType.SHOP_FREE_DOT)
    for _, v in ConfigRefer.Shop:ipairs() do
        local tabId = v:Id()
        local tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("ShopTab" .. tabId, NotificationType.SHOP_FREE_DOT)
        ModuleRefer.NotificationModule:AddToParent(tabNode, hudShopNode)
        for i = 1, v:FixedItemLength() do
            local itemNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("ShopItem" .. v:FixedItem(i), NotificationType.SHOP_FREE_DOT)
            ModuleRefer.NotificationModule:AddToParent(itemNode, tabNode)
        end
        for i = 1, v:RandomItemLength() do
            local itemNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("ShopItem" .. v:RandomItem(i), NotificationType.SHOP_FREE_DOT)
            ModuleRefer.NotificationModule:AddToParent(itemNode, tabNode)
        end
    end
end

function ShopModule:RefreshRedPoint()
    if not self.createRedLogicTree then
        self:CreateRedPointLogicTree()
    end
    local storeInfos = self:GetStoreInfo()
    for _, v in ConfigRefer.Shop:ipairs() do
        local tabId = v:Id()
        local tabOpen = storeInfos[tabId] and storeInfos[tabId].Open
        if storeInfos[tabId] == nil then
            g_Logger.Error('PlayerWrapper.Store.Stores tabId %s is nil', tabId)
            goto continue
        end

        local freeProducts = storeInfos[tabId].FreeProducts
        for i = 1, v:FixedItemLength() do
            local itemId = v:FixedItem(i)
            local itemFree = freeProducts[itemId]
            if itemFree and itemFree >= 2 then
                itemFree = false
            end
            local itemNode = ModuleRefer.NotificationModule:GetDynamicNode("ShopItem" .. itemId, NotificationType.SHOP_FREE_DOT)
            local show = itemFree and tabOpen
            ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(itemNode, show and 1 or 0)
        end
        for i = 1, v:RandomItemLength() do
            local itemId = v:RandomItem(i)
            local itemNode = ModuleRefer.NotificationModule:GetDynamicNode("ShopItem" .. itemId, NotificationType.SHOP_FREE_DOT)
            local itemFree = freeProducts[itemId]
            if itemFree and itemFree >= 2 then
                itemFree = false
            end
            local show = itemFree and tabOpen
            ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(itemNode, show and 1 or 0)
        end

        ::continue::
    end
end

return ShopModule
