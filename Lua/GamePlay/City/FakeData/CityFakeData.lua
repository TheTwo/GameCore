---@class CityFakeData
---@field new fun():CityFakeData
---@field buildings CityFakeBuilding[]
local CityFakeData = class("CityFakeData")
local CityFakeBuilding = require("CityFakeBuilding")

function CityFakeData:ctor()
    self:GenerateFakeBuildings()
end

function CityFakeData:GenerateFakeBuildings()
    self.buildings = {}
    for i = 1, 9 do
        table.insert(self.buildings, CityFakeBuilding.new(i))
    end
end

return CityFakeData