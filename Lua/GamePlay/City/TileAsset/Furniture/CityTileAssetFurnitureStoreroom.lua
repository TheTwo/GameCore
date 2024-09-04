local CityTileAssetFurniture = require("CityTileAssetFurniture")
---@class CityTileAssetFurnitureStoreroom:CityTileAssetFurniture
---@field new fun():CityTileAssetFurnitureStoreroom
---@field super CityTileAssetFurniture
local CityTileAssetFurnitureStoreroom = class("CityTileAssetFurnitureStoreroom", CityTileAssetFurniture)
local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local EnumStatus = {
    Empty = 0,
    Small = 1,
    Middle = 2,
    Full = 3,
}

function CityTileAssetFurnitureStoreroom:ctor()
    CityTileAssetFurnitureStoreroom.super.ctor(self)
    ---@type table<number, CS.StatusRecordParent>
    self.itemIdToStatusMap = {}
end

---@param go CS.UnityEngine.GameObject
---@param userdata any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function CityTileAssetFurnitureStoreroom:OnAssetLoaded(go, userdata, handle)
    CityTileAssetFurniture.OnAssetLoaded(self, go, userdata, handle)

    ---@type CS.FXAttachPointHolder
    local handle = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if handle == nil then return end

    self:InitStatusCompCache(handle)
    self:InitMaxStockCache()
    self:InitStockStatusCache()

    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLvUpChanged))
end

function CityTileAssetFurnitureStoreroom:OnAssetUnload(go, fade)
    table.clear(self.itemIdToStatusMap)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLvUpChanged))
    CityTileAssetFurniture.OnAssetUnload(self, go, fade)
end

function CityTileAssetFurnitureStoreroom:Refresh()
    CityTileAssetFurniture.Refresh(self)
    self:UpdateStockStatusCache()
end

---@param handle CS.FXAttachPointHolder
function CityTileAssetFurnitureStoreroom:InitStatusCompCache(handle)
    local storeroomCfg = ConfigRefer.CityConfig:StoreroomDisplay()
    table.clear(self.itemIdToStatusMap)

    local woodTrans = handle:GetAttachPoint("wood")
    if Utils.IsNotNull(woodTrans) then
        local woodStatus = woodTrans:GetComponent(typeof(CS.StatusRecordParent))
        local woodItem = storeroomCfg:WoodItemId()
        if Utils.IsNotNull(woodStatus) and woodItem > 0 then
            self.itemIdToStatusMap[woodItem] = woodStatus
        end
    end

    local metalTrans = handle:GetAttachPoint("Metal")
    if Utils.IsNotNull(metalTrans) then
        local metalStatus = metalTrans:GetComponent(typeof(CS.StatusRecordParent))
        local metalItem = storeroomCfg:MetalItemId()
        if Utils.IsNotNull(metalStatus) and metalItem > 0 then
            self.itemIdToStatusMap[metalItem] = metalStatus
        end
    end

    local rolinTrans = handle:GetAttachPoint("Red")
    if Utils.IsNotNull(rolinTrans) then
        local rolinStatus = rolinTrans:GetComponent(typeof(CS.StatusRecordParent))
        local rolinItem = storeroomCfg:RolinItemId()
        if Utils.IsNotNull(rolinStatus) and rolinItem > 0 then
            self.itemIdToStatusMap[rolinItem] = rolinStatus
        end
    end

    local tomatoTrans = handle:GetAttachPoint("Tomato")
    if Utils.IsNotNull(tomatoTrans) then
        local tomatoStatus = tomatoTrans:GetComponent(typeof(CS.StatusRecordParent))
        local tomatoItem = storeroomCfg:TomatoItemId()
        if Utils.IsNotNull(tomatoStatus) and tomatoItem > 0 then
            self.itemIdToStatusMap[tomatoItem] = tomatoStatus
        end
    end

    local vegetableTrans = handle:GetAttachPoint("Vegetables")
    if Utils.IsNotNull(vegetableTrans) then
        local vegetableStatus = vegetableTrans:GetComponent(typeof(CS.StatusRecordParent))
        local vegetableItem = storeroomCfg:VegetableItemId()
        if Utils.IsNotNull(vegetableStatus) and vegetableItem > 0 then
            self.itemIdToStatusMap[vegetableItem] = vegetableStatus
        end
    end

    local meatTrans = handle:GetAttachPoint("Meat")
    if Utils.IsNotNull(meatTrans) then
        local meatStatus = meatTrans:GetComponent(typeof(CS.StatusRecordParent))
        local meatItem = storeroomCfg:MeatItemId()
        if Utils.IsNotNull(meatStatus) and meatItem > 0 then
            self.itemIdToStatusMap[meatItem] = meatStatus
        end
    end

    self.smallRate = math.clamp01(storeroomCfg:SmallRate())
    self.middleRate = math.clamp01(storeroomCfg:MiddleRate())
    self.fullRate = math.clamp01(storeroomCfg:FullRate())
end

function CityTileAssetFurnitureStoreroom:InitMaxStockCache()
    self.maxCountMap = {}
    self.hotSpringFurnitureId = 0
    
    local city = self:GetCity()
    ---@type CityFurniture
    local furniture = city.furnitureManager:GetFurnitureByTypeCfgId(ConfigRefer.CityConfig:HotSpringFurniture())
    local detailCfg
    if furniture then
        self.hotSpringFurnitureId = furniture.singleId
        detailCfg = ConfigRefer.HotSpringDetail:Find(furniture.furnitureCell:HotSpringDetailInfo())
    end
    local maxTime = ModuleRefer.CastleAttrModule:SimpleGetValue(CityAttrType.MaxOfflineBenefitTime) / 3600

    if detailCfg then
        for i = 1, detailCfg:AdditionProductsLength() do
            local productInfo = detailCfg:AdditionProducts(i)
            local itemGroup = ConfigRefer.ItemGroup:Find(productInfo:Product())
            if itemGroup then
                local output = ItemGroupHelper.GetPossibleOutput(itemGroup)
                for _, info in ipairs(output) do
                    self.maxCountMap[info.id] = (self.maxCountMap[info.id] or 0) + info.minCount * maxTime
                end
            end
        end
    end
end

function CityTileAssetFurnitureStoreroom:InitStockStatusCache()
    self.statusMap = self:GetStockStatus()
    for itemId, statusComp in pairs(self.itemIdToStatusMap) do
        statusComp:ApplyStatusRecord(self.statusMap[itemId] or EnumStatus.Empty)
    end
end

function CityTileAssetFurnitureStoreroom:UpdateStockStatusCache()
    local statusMap = self:GetStockStatus()
    for itemId, statusComp in pairs(self.itemIdToStatusMap) do
        local status = statusMap[itemId] or EnumStatus.Empty
        if status ~= self.statusMap[itemId] then
            self.statusMap[itemId] = status
            statusComp:ApplyStatusRecord(status)
        end
    end
end

function CityTileAssetFurnitureStoreroom:GetStockStatus()
    local castleFurniture = self.tileView.tile:GetCastleFurniture()
    local stockInfo = castleFurniture.StockRoomInfo.Benefits
    local statusMap = {}
    
    for itemId, status in pairs(self.itemIdToStatusMap) do
        local count = math.floor(stockInfo[itemId] or 0)
        local statusEnum = EnumStatus.Empty
        if self.maxCountMap[itemId] then
            if count >= self.maxCountMap[itemId] * self.fullRate then
                statusEnum = EnumStatus.Full
            elseif count >= self.maxCountMap[itemId] * self.middleRate then
                statusEnum = EnumStatus.Middle
            elseif count >= self.maxCountMap[itemId] * self.smallRate then
                statusEnum = EnumStatus.Small
            end
        end
        statusMap[itemId] = statusEnum
    end
    return statusMap
end

---@param batchEvt {Event:string, Change:table<number, boolean>}
function CityTileAssetFurnitureStoreroom:OnLvUpChanged(city, batchEvt)
    if city ~= self.tileView.tile:GetCity() then return end
    if batchEvt.Change[self.hotSpringFurnitureId] == nil then return end
    self:InitMaxStockCache()
    self:InitStockStatusCache()
end

return CityTileAssetFurnitureStoreroom