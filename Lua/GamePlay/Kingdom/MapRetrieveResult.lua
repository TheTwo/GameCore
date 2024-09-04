---@class MapRetrieveResult
---@field new fun(x, y, decoList, entity, playerUnit, sizeX, sizeY)
---@field coord CS.DragonReborn.Vector2Short
---@field X number
---@field Z number
---@field entity wds.DefenceTower|wds.EnergyTower|wds.TransferTower|wds.Village|wds.ResourceField|wds.CastleBrief|wds.CommonMapBuilding
---@field playerUnit any|nil
---@field decoList any
local MapRetrieveResult = class("MapRetrieveResult")

function MapRetrieveResult:ctor(x, y, decoList, entity, playerUnit, sizeX, sizeY)
    self.X = x
    self.Z = y
    self.decoList = decoList
    self.entity = entity
    self.playerUnit = playerUnit
    self.sizeX = sizeX
    self.sizeY = sizeY
end

return MapRetrieveResult