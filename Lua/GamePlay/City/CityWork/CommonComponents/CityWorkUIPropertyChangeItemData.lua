---@class CityWorkUIPropertyChangeItemData
---@field new fun():CityWorkUIPropertyChangeItemData
local CityWorkUIPropertyChangeItemData = class("CityWorkUIPropertyChangeItemData")

function CityWorkUIPropertyChangeItemData:ctor(eleId, oldValue, newValue)
    self.eleId = eleId
    self.oldValue = oldValue
    self.newValue = newValue
end

return CityWorkUIPropertyChangeItemData