local CityLegoBuffProvider_FurnitureCfg = require("CityLegoBuffProvider_FurnitureCfg")
---@class CityLegoBuffProvider_Furniture:CityLegoBuffProvider_FurnitureCfg
---@field new fun():CityLegoBuffProvider_Furniture
local CityLegoBuffProvider_Furniture = class("CityLegoBuffProvider_Furniture", CityLegoBuffProvider_FurnitureCfg)
local ConfigRefer = require("ConfigRefer")

---@param furnitureId number
---@param calculator CityLegoBuffCalculatorWds
function CityLegoBuffProvider_Furniture:ctor(furnitureId, calculator)
    self.funitureId = furnitureId
    self.calculator = calculator

    local castleFurniture = self.calculator.city:GetCastle().CastleFurniture[self.funitureId]
    local furnitureCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    CityLegoBuffProvider_FurnitureCfg.ctor(self, furnitureCfg, castleFurniture.Locked)
end

function CityLegoBuffProvider_Furniture:UpdateTagMap()
    local castleFurniture = self.calculator.city:GetCastle().CastleFurniture[self.funitureId]
    local furnitureCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    self.lvCfg = furnitureCfg
    CityLegoBuffProvider_FurnitureCfg.UpdateTagMap(self, castleFurniture.Locked)
end

function CityLegoBuffProvider_Furniture:GetTagCount(tagId)
    return self.tagMap[tagId] or 0
end

function CityLegoBuffProvider_Furniture:GetImage()
    local furniture = self.calculator.city.furnitureManager:GetFurnitureById(self.funitureId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
    return typCfg:Image()
end

return CityLegoBuffProvider_Furniture