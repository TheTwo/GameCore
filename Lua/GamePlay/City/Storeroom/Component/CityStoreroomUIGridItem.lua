local BaseUIComponent = require ('BaseUIComponent')

---@class CityStoreroomUIGridItem:BaseUIComponent
local CityStoreroomUIGridItem = class('CityStoreroomUIGridItem', BaseUIComponent)

function CityStoreroomUIGridItem:OnCreate()
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
end

---@param data CityStoreroomUIGridItemData|CityStoreroomUIGridFoodItemData
function CityStoreroomUIGridItem:OnFeedData(data)
    self._child_item_standard_s:FeedData(data:GetItemIconData())
end

return CityStoreroomUIGridItem