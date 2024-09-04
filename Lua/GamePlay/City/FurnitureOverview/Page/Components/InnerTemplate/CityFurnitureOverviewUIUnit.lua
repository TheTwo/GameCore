local BaseUIComponent = require ('BaseUIComponent')

---@class CityFurnitureOverviewUIUnit:BaseUIComponent
local CityFurnitureOverviewUIUnit = class('CityFurnitureOverviewUIUnit', BaseUIComponent)

---@param data CityFurnitureOverviewUnitDataBase
function CityFurnitureOverviewUIUnit:OnFeedData(data)
    if self.data ~= nil then
        self.data:OnClose(self)
    end

    self.data = data
    if self.data then
        self.data:FeedCell(self)
    end
end

function CityFurnitureOverviewUIUnit:OnClose()
    if self.data then
        self.data:OnClose(self)
    end
end

function CityFurnitureOverviewUIUnit:OnHide()
    if self.data then
        self.data:OnHide(self)
    end
end

return CityFurnitureOverviewUIUnit