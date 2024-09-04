---@class CityGridCell:CityCellBase
---@field new fun():CityGridCell
---@field children number[]
local CityGridCell = class("CityGridCell")
local CityGridCellDef = require("CityGridCellDef")
local CellType = CityGridCellDef.CellType
local ConfigType = CityGridCellDef.ConfigType

function CityGridCell:ctor(x, y)
    self.x = x
    self.y = y

    self:Reset()
end

function CityGridCell:Reset()
    self.sizeX = nil
    self.sizeY = nil

    self.tileId = 0
    self.configId = 0
    self.configType = ConfigType.INVALID
    self.children = nil
    self.cellType = CellType.INVALID
end

---@param node CityNode
function CityGridCell:FromCityNode(node)
    self:Reset()
    self.cellType = CellType.SQUARE_MAIN
    self.sizeX = node.sizeX
    self.sizeY = node.sizeY

    self.tileId = node.tileId
    self.configId = node.configId
    self.configType = node.configType

    self.children = {}
    for i = 0, self.sizeX - 1 do
        for j = 0, self.sizeY - 1 do
            if i == 0 and j == 0 then
                goto continue
            end

            table.insert(self.children, i)
            table.insert(self.children, j)
            ::continue::
        end
    end
end

---@param cell CityGridCell
function CityGridCell:Clone(cell)
    self:Reset()
    self.cellType = cell.cellType
    self.sizeX = cell.sizeX
    self.sizeY = cell.sizeY

    self.tileId = cell.tileId
    self.configId = cell.configId
    self.configType = cell.configType

    if self.cellType == CellType.SQUARE_MAIN or self.cellType == CellType.DISCRETE_MAIN then
        self.children = {}
        for _, child in ipairs(cell.children) do
            table.insert(self.children, child)
        end
    end
end

function CityGridCell:IsBuilding()
    return self.configType == ConfigType.BUILDING
end

function CityGridCell:IsResource()
    return self.configType == ConfigType.RESOURCE
end

function CityGridCell:IsNpc()
    return self.configType == ConfigType.NPC
end

function CityGridCell:IsCreepNode()
    return self.configType == ConfigType.CREEP_NODE
end

function CityGridCell:IsFurniture()
    return self.configType == ConfigType.FURNITURE
end

function CityGridCell:IsElement()
    return self:IsResource() or self:IsNpc() or self:IsCreepNode()
end

function CityGridCell:Besides(x, y)
    if x == self.x and y == self.y then
        return true
    end

    for i = 1, #self.children, 2 do
        if x == self.children[i] + self.x and y == self.children[i+1] + self.y then
            return true
        end
    end
    return false
end

function CityGridCell:UniqueId()
    return self.tileId
end

function CityGridCell:ConfigId()
    return self.configId
end

---@param temp boolean
function CityGridCell:ToCityNode(temp)
    if self.cellType == CellType.SQUARE_MAIN then
        local CityNode = require("CityNode")
        if temp then
            return CityNode.Temp(self.x, self.y, self.sizeX, self.sizeY, self.tileId, self.configId, self.configType)
        else
            return CityNode.new(self.x, self.y, self.sizeX, self.sizeY, self.tileId, self.configId, self.configType)
        end
    end
end

---@return CityZoneRecoverConfigCell
function CityGridCell:GetZoneRecoverCfg()
    local ConfigRefer = require("ConfigRefer")
    local zoneRecoverCfg = nil
    for i, v in ConfigRefer.CityZoneRecover:pairs() do
        if v:CityElement() == self.configId then
            zoneRecoverCfg = v
            break
        end
    end
    return zoneRecoverCfg
end

return CityGridCell
