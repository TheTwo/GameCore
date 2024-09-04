---@class CityStoreroomUIGridItemData
---@field new fun():CityStoreroomUIGridItemData
local CityStoreroomUIGridItemData = class("CityStoreroomUIGridItemData")

function CityStoreroomUIGridItemData:ctor(itemCfg, count)
    self.itemCfg = itemCfg
    self.count = count
end

---@return ItemIconData
function CityStoreroomUIGridItemData:GetItemIconData()
    return {configCell = self.itemCfg, count = self.count}
end

function CityStoreroomUIGridItemData:ShowBlood()
    return false
end

---@return string
function CityStoreroomUIGridItemData:GetBloodValue()
    return string.Empty
end

return CityStoreroomUIGridItemData