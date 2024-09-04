local SelectorDataWrap = require("SelectorDataWrap")
---@class FurnitureTileSelectorDataWrap:SelectorDataWrap
---@field new fun(furnitureTile):FurnitureTileSelectorDataWrap
local FurnitureTileSelectorDataWrap = class("FurnitureTileSelectorDataWrap", SelectorDataWrap)
local FurnitureCategory = require("FurnitureCategory")
local CityFurnitureType = require("CityFurnitureType")

---@param furnitureTile CityFurnitureTile
---@param legoBuilding CityLegoBuilding
function FurnitureTileSelectorDataWrap:ctor(furnitureTile, legoBuilding)
    self.furnitureTile = furnitureTile
    SelectorDataWrap.ctor(self, furnitureTile:GetCity(), furnitureTile.x, furnitureTile.y, furnitureTile:SizeX(), furnitureTile:SizeY(), furnitureTile:GetCell().direction, legoBuilding, furnitureTile:GetDirSet())
end

---@return boolean
function FurnitureTileSelectorDataWrap:Besides(x, y)
    return self.furnitureTile:GetCell():Besides(x, y)
end

---@return boolean
function FurnitureTileSelectorDataWrap:IsMilitary()
    return self.furnitureTile:GetFurnitureTypesCell():Category() == FurnitureCategory.Military
end

---@return boolean, boolean @是否可以放室内，是否可以放室外
function FurnitureTileSelectorDataWrap:GetFurniturePlaceType()
    local typCfg = self.furnitureTile:GetFurnitureTypesCell()
    if typCfg == nil then return SelectorDataWrap.GetFurniturePlaceType(self) end

    local placeType = typCfg:Type()
    local canInLego = placeType == CityFurnitureType.InDoor or placeType == CityFurnitureType.Both
    local canOutLego = placeType == CityFurnitureType.OutDoor or placeType == CityFurnitureType.Both
    return canInLego, canOutLego
end

function FurnitureTileSelectorDataWrap:GetFurnitureTypeCfgId()
    return self.furnitureTile:GetFurnitureType()
end

return FurnitureTileSelectorDataWrap