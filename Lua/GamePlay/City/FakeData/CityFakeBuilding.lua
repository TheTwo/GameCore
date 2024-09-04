---@class CityFakeBuilding
---@field new fun():CityFakeBuilding
local CityFakeBuilding = class("CityFakeBuilding")

function CityFakeBuilding:ctor(index)
    self.index = index
    self.x = math.floor((self.index - 1) / 3) * 20
    self.y = (self.index % 3) * 20
    self.configId = self.index % 2 + 1
    self.size = self.configId == 1 and 12 or 9
end

return CityFakeBuilding