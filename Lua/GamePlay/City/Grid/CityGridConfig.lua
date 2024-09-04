---@class CityGridConfig
---@field new fun():CityGridConfig
---@field minX number
---@field minY number
---@field cellsX number
---@field cellsY number
---@field unitsPerCellX number
---@field unitsPerCellY number
local CityGridConfig = class("CityGridConfig")
local CITY_GRID_SIZE = 512

function CityGridConfig:ctor(minX, minY, cellsX, cellsY, unitsPerCellX, unitsPerCellY)
    self.minX = minX
    self.minY = minY
    self.cellsX = cellsX
    self.cellsY = cellsY
    self.unitsPerCellX = unitsPerCellX
    self.unitsPerCellY = unitsPerCellY
end

function CityGridConfig:IsLocationValid(x, y)
    local ox = x - self.minX
    local oy = y - self.minY
    return 0 <= ox and ox < self.cellsX and 0 <= oy and oy < self.cellsY
end

function CityGridConfig:GetLocalPosition(x, y)
    local wx = (x - self.minX) * self.unitsPerCellX
    local wy = (y - self.minY) * self.unitsPerCellY
    return CS.UnityEngine.Vector3(wx, 0, wy)
end

CityGridConfig.Instance = CityGridConfig.new(0, 0, CITY_GRID_SIZE, CITY_GRID_SIZE, 1, 1)

return CityGridConfig