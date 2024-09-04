---Scene Name : scene_construction_popup_upgrade_troop
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require("I18N")
local CityWorkI18N = require("CityWorkI18N")
local EventConst = require("EventConst")
local CityAttrType = require("CityAttrType")
local FPXSDKBIDefine = require("FPXSDKBIDefine")

---@class CityWorkFurnitureUpgradePopupUIMediator:BaseUIMediator
local CityWorkFurnitureUpgradePopupUIMediator = class('CityWorkFurnitureUpgradePopupUIMediator', BaseUIMediator)

function CityWorkFurnitureUpgradePopupUIMediator:OnCreate()
    ---@type CommonPopupBackComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")
    self._p_text_content = self:Text("p_text_content", CityWorkI18N.UI_FurnitureLevelUpPopup_Desc)
    
    ---@type CityWorkFurnitureUpgradePopupUICell
    self._p_item_1 = self:LuaObject("p_item_1")
    ---@type CityWorkFurnitureUpgradePopupUICell
    self._p_item_2 = self:LuaObject("p_item_2")
    ---@type CityWorkFurnitureUpgradePopupUICell
    self._p_item_3 = self:LuaObject("p_item_3")
    ---@type CityWorkFurnitureUpgradePopupUICell
    self._p_item_4 = self:LuaObject("p_item_4")

    self._p_item_list = {
        self._p_item_1,
        self._p_item_2,
        self._p_item_3,
        self._p_item_4,
    }
end

---@param city City
function CityWorkFurnitureUpgradePopupUIMediator:OnOpened(city)
    self.city = city

    self:RefreshTitle()
    self:RefreshContent()

    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
end

function CityWorkFurnitureUpgradePopupUIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnPaySuccess))
end

function CityWorkFurnitureUpgradePopupUIMediator:RefreshTitle()
    ---@type CommonBackButtonData
    self.backButtonData = {}
    self.backButtonData.title = I18N.Get(CityWorkI18N.UI_FurnitureLevelUpPopup_Title)
    self.backButtonData.hideClose = false
    self._child_popup_base_l:FeedData(self.backButtonData)
end

function CityWorkFurnitureUpgradePopupUIMediator:RefreshContent()
    self.currentMonitorFurMap = {}
    self.upgradeContentList = {}
    local castleFurnitureMap = self.city:GetCastle().CastleFurniture
    local currentCount = 0
    local queueCount = self.city.furnitureManager:GetUpgradeQueueMaxCount()
    local goodGroupId = self.city.furnitureManager:GetUpgradeGoodGroupId()
    local goodIds = self.city.furnitureManager:GetUpgradeGoodIds()
    for id, castleFurniture in pairs(castleFurnitureMap) do
        if castleFurniture.LevelUpInfo.Working then
            if castleFurniture.LevelUpInfo.CurProgress < castleFurniture.LevelUpInfo.TargetProgress then
                table.insert(self.upgradeContentList, {
                    city = self.city,
                    furnitureId = id,
                    isUnlock = true,
                    goodId = goodIds[currentCount + 1] or 0,
                    goodGroupId = goodGroupId,
                    canPurchase = true
                })
                self.currentMonitorFurMap[id] = true
                currentCount = currentCount + 1
            end
        end
    end

    for i = currentCount + 1, queueCount do
        table.insert(self.upgradeContentList, {
            city = self.city,
            furnitureId = nil,
            isUnlock = true,
            goodId = goodIds[currentCount + 1] or 0,
            goodGroupId = goodGroupId,
            canPurchase = true
        })
        currentCount = currentCount + 1
    end

    for i = currentCount + 1, #goodIds do
        local goodId = goodIds[i]
        local times = ModuleRefer.ActivityShopModule:GetGoodsPurchasedTimes(goodId, true)
        local isGroupOpen = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(goodGroupId)
        local currentGoodsId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(goodGroupId)
        table.insert(self.upgradeContentList, {
            city = self.city,
            furnitureId = nil,
            isUnlock = times > 0,
            goodId = goodId,
            goodGroupId = goodGroupId,
            canPurchase = isGroupOpen and currentGoodsId == goodId
        })
    end

    for i = 1, #self._p_item_list do
        local cell = self._p_item_list[i]
        local data = self.upgradeContentList[i]
        cell:FeedData(data)
    end
end

function CityWorkFurnitureUpgradePopupUIMediator:OnPaySuccess()
    self:RefreshContent()
end

function CityWorkFurnitureUpgradePopupUIMediator:OnFurnitureUpdate(city, batchEvt)
    if self.city ~= city then return end
    
    local dirty = false
    for id, flag in pairs(batchEvt.Change) do
        if self.currentMonitorFurMap[id] then
            local castleFurniture = self.city.furnitureManager:GetCastleFurniture(id)
            if castleFurniture.LevelUpInfo.Working and castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress then
                dirty = true
                break
            end
        end
    end

    if dirty then
        self:RefreshContent()
    end
end

return CityWorkFurnitureUpgradePopupUIMediator