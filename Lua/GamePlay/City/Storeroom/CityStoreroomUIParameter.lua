local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityStoreroomUIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityStoreroomUIParameter
local CityStoreroomUIParameter = class("CityStoreroomUIParameter", CityCommonRightPopupUIParameter)
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local CityStoreroomUITitleData = require("CityStoreroomUITitleData")
local CityStoreroomI18N = require("CityStoreroomI18N")
local CityStoreroomUIGridData = require("CityStoreroomUIGridData")
local CityStoreroomUIGridItemData = require("CityStoreroomUIGridItemData")
local CityStoreroomUIGridFoodItemData = require("CityStoreroomUIGridFoodItemData")
local ItemType = require("ItemType")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")

function CityStoreroomUIParameter:ctor(cellTile)
    CityCommonRightPopupUIParameter.ctor(self, cellTile)
    self.city = cellTile:GetCity()
end

---@return {title:CityStoreroomUITitleData, grid:CityStoreroomUIGridData}[]
function CityStoreroomUIParameter:GetData()
    local ret = {}
    if ConfigRefer.CityConfig:StorageShowBasicResourcesLength() > 0 then
        local basicResources = {}
        for i = 1, ConfigRefer.CityConfig:StorageShowBasicResourcesLength() do
            local itemId = ConfigRefer.CityConfig:StorageShowBasicResources(i)
            local amount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
            if amount > 0 then
                table.insert(basicResources, {itemCfg = ConfigRefer.Item:Find(itemId), count = amount})
            end
        end
        
        if #basicResources > 0 then
            table.sort(basicResources, function(l, r)
                return l.itemCfg:Sort() < r.itemCfg:Sort()
            end)
            local contentData = {
                title = CityStoreroomUITitleData.new(I18N.Get(CityStoreroomI18N.UITitle_BasicResource)),
                grid = CityStoreroomUIGridData.new()
            }
            for i, v in ipairs(basicResources) do
                contentData.grid:AddCell(CityStoreroomUIGridItemData.new(v.itemCfg, v.count))
            end
            table.insert(ret, contentData)
        end
    end
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.cellTile:GetCell().singleId]
    if castleFurniture and castleFurniture.StockRoomInfo.FoodInfo:Count() > 0 then
        local food = {}
        local allBlood = 0
        for id, blood in pairs(castleFurniture.StockRoomInfo.FoodInfo) do
            local itemCfg = ConfigRefer.Item:Find(id)
            table.insert(food, {itemCfg = itemCfg, blood = blood})
            allBlood = allBlood + blood
        end

        table.sort(food, function(l, r)
            return l.itemCfg:Sort() < r.itemCfg:Sort()
        end)

        local contentData = {
            title = CityStoreroomUITitleData.new(I18N.Get(CityStoreroomI18N.UITitle_Fooed), allBlood),
            grid = CityStoreroomUIGridData.new()
        }
        for i, v in ipairs(food) do
            contentData.grid:AddCell(CityStoreroomUIGridFoodItemData.new(v.itemCfg, v.blood))
        end
        table.insert(ret, contentData)
    end
    
    if ConfigRefer.CityConfig:StorageShowResourcesLength() > 0 then
        local resources = {}
        for i = 1, ConfigRefer.CityConfig:StorageShowResourcesLength() do
            local itemId = ConfigRefer.CityConfig:StorageShowResources(i)
            local amount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
            if amount > 0 then
                table.insert(resources, {itemCfg = ConfigRefer.Item:Find(itemId), count = amount})
            end
        end
        
        if #resources > 0 then
            table.sort(resources, function(l, r)
                return l.itemCfg:Sort() < r.itemCfg:Sort()
            end)
            local contentData = {
                title = CityStoreroomUITitleData.new(I18N.Get(CityStoreroomI18N.UITitle_Resource)),
                grid = CityStoreroomUIGridData.new()
            }
            for i, v in ipairs(resources) do
                contentData.grid:AddCell(CityStoreroomUIGridItemData.new(v.itemCfg, v.count))
            end
            table.insert(ret, contentData)
        end
    end
    
    return ret
end

function CityStoreroomUIParameter:GetTitle()
    return self.cellTile:GetName()
end

---@param mediator CityStoreroomUIMediator
function CityStoreroomUIParameter:OnMediatorOpened(mediator)
    self.mediator = mediator
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
end

function CityStoreroomUIParameter:OnMediatorClosed(mediator)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    self.mediator = nil
end

function CityStoreroomUIParameter:OnFurnitureUpdate(city, batchEvt)
    if not self.mediator then return end
    if city ~= self.city then return end
    if not batchEvt.Change then return end
    if not batchEvt.Change[self.cellTile:GetCell().singleId] then return end
    self.mediator:UpdateStoreroomDisplay()
end

return CityStoreroomUIParameter