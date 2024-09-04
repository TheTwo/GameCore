---@class CityStoreroomUIGridFoodItemData
---@field new fun():CityStoreroomUIGridFoodItemData
local CityStoreroomUIGridFoodItemData = class("CityStoreroomUIGridFoodItemData")
local NumberFormatter = require("NumberFormatter")

function CityStoreroomUIGridFoodItemData:ctor(itemCfg, blood)
    self.itemCfg = itemCfg
    self.blood = blood
end

---@return ItemIconData
function CityStoreroomUIGridFoodItemData:GetItemIconData()
    return {configCell = self.itemCfg, showCount = false}
end

function CityStoreroomUIGridFoodItemData:ShowBlood()
    return true
end

---@return string
function CityStoreroomUIGridFoodItemData:GetBloodValue()
    return NumberFormatter.NumberAbbr(self.blood, true)
end

return CityStoreroomUIGridFoodItemData