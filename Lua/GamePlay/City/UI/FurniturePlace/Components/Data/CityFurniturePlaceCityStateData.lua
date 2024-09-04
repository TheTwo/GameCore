---@class CityFurniturePlaceCityStateData
---@field new fun():CityFurniturePlaceCityStateData
local CityFurniturePlaceCityStateData = class("CityFurniturePlaceCityStateData")
local ArtResourceUtils = require("ArtResourceUtils")
local CityFurnitureHelper = require("CityFurnitureHelper")
local ModuleRefer = require("ModuleRefer")
local CityWorkI18N = require("CityWorkI18N")

---@param source CityFurniturePlaceUINodeDatum
function CityFurniturePlaceCityStateData:ctor(source)
    self.source = source
    self.typCell = self.source.typCfg
    self.lvCell = self.source.lvCfg
end

function CityFurniturePlaceCityStateData:IsFurniture()
    return true
end

function CityFurniturePlaceCityStateData:RequestToBuild(x, y, direction)
    self.source.city.furnitureManager:RequestPlaceFurniture(self.lvCell:Id(), x, y, direction)
end

function CityFurniturePlaceCityStateData:GetName()
    return self.source:GetFurnitureName()
end

function CityFurniturePlaceCityStateData:ConfigId()
    return self.lvCell:Id()
end

function CityFurniturePlaceCityStateData:SizeX()
    return self.lvCell:SizeX()
end

function CityFurniturePlaceCityStateData:SizeY()
    return self.lvCell:SizeY()
end

function CityFurniturePlaceCityStateData:GetRecommendPos()
    return true, self.typCell:PositionX(), self.typCell:PositionY()
end

function CityFurniturePlaceCityStateData:Scale()
    local scale = ArtResourceUtils.GetItem(self.lvCell:Model(), 'ModelScale')
    if scale and scale ~= 0 then
        return scale
    end
    return 1
end

function CityFurniturePlaceCityStateData:PrefabName()
    return self.source:GetPrefabName()
end

return CityFurniturePlaceCityStateData