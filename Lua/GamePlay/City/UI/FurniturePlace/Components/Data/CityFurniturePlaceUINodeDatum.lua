---@class CityFurniturePlaceUINodeDatum
---@field new fun():CityFurniturePlaceUINodeDatum
local CityFurniturePlaceUINodeDatum = class("CityFurniturePlaceUINodeDatum")
local ConfigRefer = require("ConfigRefer")
local QualityColorHelper = require("QualityColorHelper")
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")
local CityFurniturePlaceCityStateData = require("CityFurniturePlaceCityStateData")
local Status = {Placed = 0, Storage = 1, Empty = 2}

---@param city City
function CityFurniturePlaceUINodeDatum:ctor(city)
    self.city = city
end

---@param furniture CityFurniture
function CityFurniturePlaceUINodeDatum:SetPlaced(furniture, showLevel)
    self.status = Status.Placed
    self.furniture = furniture
    self.lvCfg = self.furniture.furnitureCell
    self.typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCfg:Type())
    self.showStorageNumber = false
    self.showLevel = showLevel
    self.showName = true
    self.showTag = true
    self.showScore = true
    return self
end

---@param lvCfg CityFurnitureLevelConfigCell
function CityFurniturePlaceUINodeDatum:SetStorage(lvCfg, count, showStorageNumber, showLevel)
    self.status = Status.Storage
    self.lvCfg = lvCfg
    self.typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCfg:Type())
    self.count = count
    self.showStorageNumber = showStorageNumber
    self.showLevel = showLevel
    self.showName = true
    self.showTag = true
    self.showScore = true
    return self
end

function CityFurniturePlaceUINodeDatum:SetEmpty(lvCfg)
    self.status = Status.Empty
    self.lvCfg = lvCfg
    self.typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCfg:Type())
    self.showStorageNumber = false
    self.showLevel = false
    self.showName = true
    self.showTag = false
    self.showScore = false
    return self
end

function CityFurniturePlaceUINodeDatum:GetQualityBackground()
    return QualityColorHelper.GetSpHeroFrameCircleImg(self.lvCfg:Quality())
end

function CityFurniturePlaceUINodeDatum:GetImage()
    return self.typCfg:Image()
end

function CityFurniturePlaceUINodeDatum:GetLevel()
    return self.lvCfg:Level()
end

function CityFurniturePlaceUINodeDatum:IsPlaced()
    return self.status == Status.Placed
end

function CityFurniturePlaceUINodeDatum:IsEmpty()
    return self.status == Status.Empty
end

function CityFurniturePlaceUINodeDatum:IsStorage()
    return self.status == Status.Storage
end

function CityFurniturePlaceUINodeDatum:SetRecommend(flag)
    self.isRecommend = flag
end

function CityFurniturePlaceUINodeDatum:GotoId()
    local itemCfg = ConfigRefer.Item:Find(self.lvCfg:RelItem())
    if not itemCfg then return 0 end

    return itemCfg:UseGoto()
end

function CityFurniturePlaceUINodeDatum:IsFull()
    local placed = self.city.furnitureManager:GetFurnitureCountByLvCfgId(self.lvCfg:Id(), false, true)
    local limit = self.city.furnitureManager:GetFurniturePlacedLimitCount(self.lvCfg:Id())
    return placed >= limit
end

function CityFurniturePlaceUINodeDatum:GetStorageText()
    local storageMap = self.city.furnitureManager:GetStorageFurnitureMap()
    local storageCount = storageMap[self.lvCfg:Id()] or 0
    -- local allCount = self.city.furnitureManager:GetFurnitureCountByLvCfgId(self.lvCfg:Id())
    return I18N.GetWithParams("backpack_own_num", storageCount)
end

function CityFurniturePlaceUINodeDatum:GetFurnitureName()
    return I18N.Get(self.typCfg:Name())
end

function CityFurniturePlaceUINodeDatum:GetFurnitureBriefDesc()
    return I18N.Get(self.typCfg:BriefDescription())
end

function CityFurniturePlaceUINodeDatum:CreateCityStateData()
    return CityFurniturePlaceCityStateData.new(self)
end

function CityFurniturePlaceUINodeDatum:GetPrefabName()
    if self.lvCfg then
        local model = ArtResourceUtils.GetItem(self.lvCfg:Model())
        if model then
            return model
        end
    end
    return string.Empty
end

function CityFurniturePlaceUINodeDatum:GetName()
    if self.typCfg then
        return I18N.Get(self.typCfg:Name())
    end
    return string.Empty
end

function CityFurniturePlaceUINodeDatum:GetScore()
    if self.lvCfg then
        return self.lvCfg:AddScore()
    end
    return 0
end

function CityFurniturePlaceUINodeDatum:GetBuffTagList()
    local ret = {}
    if self.lvCfg then
        for i = 1, self.lvCfg:RoomTagsLength() do
            table.insert(ret, self.lvCfg:RoomTags(i))
        end
    end
    return ret
end

function CityFurniturePlaceUINodeDatum:GetTableViewCellName()
    local postfix = self:GetTableViewCellNamePostfix()
    return ("Furniture_%d%s"):format(self.typCfg:Id(), postfix)
end

---@private
function CityFurniturePlaceUINodeDatum:GetTableViewCellNamePostfix()
    if self:IsStorage() then
        return string.Empty
    elseif self:IsEmpty() then
        return "_emtpy"
    elseif self:IsPlaced() then
        return "_placed"
    end
    return "_unknown"
end

function CityFurniturePlaceUINodeDatum:TriggerGuideFinger()
    self.triggerGuide = true
end

function CityFurniturePlaceUINodeDatum:ClearTriggerGuideFinger()
    self.triggerGuide = nil
end

function CityFurniturePlaceUINodeDatum:GetPlacedText()
    if self.furniture == nil then return I18N.Get("ui_placed") end
    
    local castleFurniture = self.furniture:GetCastleFurniture()
    if castleFurniture == nil then return I18N.Get("ui_placed") end

    local buildingId = castleFurniture.BuildingId
    local building = self.city.legoManager:GetLegoBuilding(buildingId)
    if building == nil then return I18N.Get("ui_placed") end

    return I18N.Get(building:GetNameI18N())
end

return CityFurniturePlaceUINodeDatum