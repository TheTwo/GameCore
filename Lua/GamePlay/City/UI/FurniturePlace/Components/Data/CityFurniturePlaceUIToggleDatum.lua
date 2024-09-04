---@class CityFurniturePlaceUIToggleDatum
---@field new fun(city, image, isSelected, category, canOverlayStorage):CityFurniturePlaceUIToggleDatum
local CityFurniturePlaceUIToggleDatum = class("CityFurniturePlaceUIToggleDatum")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityFurniturePlaceUINodeDatum = require("CityFurniturePlaceUINodeDatum")
local ascending = false

---@param city City
---@param categoryMap table<number, boolean>
---@param notifyNode CS.Notification.NotificationDynamicNode
---@private
function CityFurniturePlaceUIToggleDatum:ctor(city, image, name, isSelected, categoryMap, notifyNode)
    self.city = city
    self.image = image
    self.name = name
    self.isSelected = isSelected
    self.categoryMap = categoryMap
    self.notifyNode = notifyNode

    self:GenerateFurnitureTypeOrderList()
end

function CityFurniturePlaceUIToggleDatum:SetSelected(flag)
    self.isSelected = flag
    return self
end

---@private
function CityFurniturePlaceUIToggleDatum:GenerateFurnitureTypeOrderList()
    ---@type CityFurnitureTypesConfigCell[]
    self.orderList = {}
    for _, cell in ConfigRefer.CityFurnitureTypes:pairs() do
        if self.categoryMap[cell:Category()] and not cell:HideInConstructionMenu() and cell:LevelCfgIdListLength() > 0 then
            table.insert(self.orderList, cell)
        end
    end

    table.sort(self.orderList, function(a, b)
        return a:DisplaySort() > b:DisplaySort()
    end)
end

---@param showPlaced boolean
---@param buildingId number @建筑Id匹配字段，如果小于0时，则无视该字段都算作匹配
function CityFurniturePlaceUIToggleDatum:GetCardDataList(showPlaced, buildingId)
    ---@type CityFurniturePlaceUINodeDatum[]
    self.cardList = {}
    
    local storageMap = self.city.furnitureManager:GetStorageFurnitureMap()
    for _, typCfg in ipairs(self.orderList) do
        local needShowEmpty = true
        local placedList = self.city.furnitureManager:GetPlacedFurnitureList(typCfg:Id(), ascending)
        if #placedList > 0 then
            if showPlaced then
                for _, furniture in ipairs(placedList) do
                    if not furniture:IsLocked() and not furniture:IsFogMask() and (buildingId < 0 or furniture:GetCastleFurniture().BuildingId == buildingId) then
                        local datum = CityFurniturePlaceUINodeDatum.new(self.city)
                        datum:SetPlaced(furniture, true)
                        table.insert(self.cardList, datum)
                    end
                end
            end
            needShowEmpty = false
        end

        if ascending then
            for i = 1, typCfg:LevelCfgIdListLength() do
                local lvCfgId = typCfg:LevelCfgIdList(i)
                local count = storageMap[lvCfgId] or 0
                if count > 0 then
                    if not showPlaced then
                        if typCfg:OverlayInPlaceUI() then
                            local datum = CityFurniturePlaceUINodeDatum.new(self.city)
                            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
                            datum:SetStorage(lvCfg, count, true, false)
                            table.insert(self.cardList, datum)
                        else
                            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
                            for n = 1, count do
                                local datum = CityFurniturePlaceUINodeDatum.new(self.city)
                                datum:SetStorage(lvCfg, 1, false, true)
                                table.insert(self.cardList, datum)
                            end
                        end
                    end
                    needShowEmpty = false
                end
            end
        else
            for i = typCfg:LevelCfgIdListLength(), 1, -1 do
                local lvCfgId = typCfg:LevelCfgIdList(i)
                local count = storageMap[lvCfgId] or 0
                if count > 0 then
                    if not showPlaced then
                        if typCfg:OverlayInPlaceUI() then
                            local datum = CityFurniturePlaceUINodeDatum.new(self.city)
                            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
                            datum:SetStorage(lvCfg, count, true, false)
                            table.insert(self.cardList, datum)
                        else
                            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
                            for n = 1, count do
                                local datum = CityFurniturePlaceUINodeDatum.new(self.city)
                                datum:SetStorage(lvCfg, 1, false, true)
                                table.insert(self.cardList, datum)
                            end
                        end
                    end
                    needShowEmpty = false
                end
            end
        end

        if needShowEmpty and not showPlaced then
            local datum = CityFurniturePlaceUINodeDatum.new(self.city)
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(typCfg:LevelCfgIdList(1))
            datum:SetEmpty(lvCfg)
            table.insert(self.cardList, datum)
        end
    end

    ---@param a CityFurniturePlaceUINodeDatum
    ---@param b CityFurniturePlaceUINodeDatum
    table.sort(self.cardList, function(a, b)
        if a.status ~= b.status then
            return a.status < b.status
        end

        return a.lvCfg:Id() < b.lvCfg:Id()
    end)

    return self.cardList
end

return CityFurniturePlaceUIToggleDatum