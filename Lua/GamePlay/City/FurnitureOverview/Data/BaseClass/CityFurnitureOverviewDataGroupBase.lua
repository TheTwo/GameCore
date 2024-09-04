---@class CityFurnitureOverviewDataGroupBase
---@field new fun():CityFurnitureOverviewDataGroupBase
local CityFurnitureOverviewDataGroupBase = class("CityFurnitureOverviewDataGroupBase")

---@param city City
function CityFurnitureOverviewDataGroupBase:ctor(city)
    self.city = city
end

---@return CityFurnitureOverviewUnitDataBase[]
function CityFurnitureOverviewDataGroupBase:GetOneLineOverviewData()
    ---override this
    return {}
end

---@return string|nil
function CityFurnitureOverviewDataGroupBase:GetOneLineTitle()
    return string.Empty
end

function CityFurnitureOverviewDataGroupBase:ShowUpgradeBase()
    return false
end

return CityFurnitureOverviewDataGroupBase