local SelectorDataWrap = require("SelectorDataWrap")
---@class FurnitureBuildSelectorDataWrap:SelectorDataWrap
---@field new fun(x, y, sizeX, sizeY, rotation, lvCfgId):FurnitureBuildSelectorDataWrap
local FurnitureBuildSelectorDataWrap = class("FurnitureBuildSelectorDataWrap", SelectorDataWrap)
local ConfigRefer = require("ConfigRefer")
local FurnitureCategory = require("FurnitureCategory")
local CityFurnitureType = require("CityFurnitureType")

---@param legoBuilding CityLegoBuilding
function FurnitureBuildSelectorDataWrap:ctor(city, x, y, sizeX, sizeY, rotation, lvCfgId, legoBuilding, dirSet)
    SelectorDataWrap.ctor(self, city, x, y, sizeX, sizeY, rotation, legoBuilding, dirSet)
    self.lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    self.typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCfg:Type())
end

function FurnitureBuildSelectorDataWrap:IsMilitary()
    return self.typCfg:Category() == FurnitureCategory.Military
end

---@return boolean, boolean @是否可以放室内，是否可以放室外
function FurnitureBuildSelectorDataWrap:GetFurniturePlaceType()
    if self.typCfg == nil then return SelectorDataWrap.GetFurniturePlaceType(self) end
    local placeType = self.typCfg:Type()
    local canInLego = placeType == CityFurnitureType.InDoor or placeType == CityFurnitureType.Both
    local canOutLego = placeType == CityFurnitureType.OutDoor or placeType == CityFurnitureType.Both
    return canInLego, canOutLego
end

function FurnitureBuildSelectorDataWrap:GetFurnitureTypeCfgId()
    return self.typCfg:Id()
end

return FurnitureBuildSelectorDataWrap