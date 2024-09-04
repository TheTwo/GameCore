---@class CityFurnitureOverviewUnitDataBase
---@field new fun():CityFurnitureOverviewUnitDataBase
local CityFurnitureOverviewUnitDataBase = class("CityFurnitureOverviewUnitDataBase")
local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")

---@param city City
function CityFurnitureOverviewUnitDataBase:ctor(city)
    self.city = city
end

function CityFurnitureOverviewUnitDataBase:GetPrefabIndex()
    ---override this
    return string.Empty
end

function CityFurnitureOverviewUnitDataBase:GetFurnitureId()
    return -1
end

function CityFurnitureOverviewUnitDataBase:GetWorkType()
    return 0
end

---@param cell CityFurnitureOverviewUIUnit
function CityFurnitureOverviewUnitDataBase:FeedCell(cell)
    ---override this
end

function CityFurnitureOverviewUnitDataBase:OnClose(cell)
    cell:StopTimer(self.timer)
end

function CityFurnitureOverviewUnitDataBase:OnHide(cell)
    cell:StopTimer(self.timer)
end

return CityFurnitureOverviewUnitDataBase