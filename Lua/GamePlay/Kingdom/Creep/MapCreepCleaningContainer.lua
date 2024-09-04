local Utils = require("Utils")

---@class MapCreepCleaningContainer
---@field idList table<number, table<number, table<number>>>
---@field hashTable table<number, table<number, number>>
local MapCreepCleaningContainer = class("MapCreepCleaningContainer")

function MapCreepCleaningContainer:ctor()
    self.idList = {}
    self.hashTable = {}
end

function MapCreepCleaningContainer:IsEmpty()
    for _, indexList in pairs(self.idList) do
        if not table.isNilOrZeroNums(indexList) then
            return false
        end
    end
    return true
end

---@return boolean
function MapCreepCleaningContainer:Contains(index, id, circleIndex)
    local hash = Utils.GetLongHashCode(index, circleIndex)
    local set = self.hashTable[id]
    return set and set[hash] ~= nil or false
end

function MapCreepCleaningContainer:Add(index, id, circleIndex)
    local set = table.getOrCreate(self.hashTable, id)
    local hash = Utils.GetLongHashCode(index, circleIndex)
    set[hash] = hash
    local indexList = table.getOrCreate(self.idList, id)
    local circleList = table.getOrCreate(indexList, circleIndex)
    circleList[index] = index
end

function MapCreepCleaningContainer:Clear()
    table.clear(self.idList)
    table.clear(self.hashTable)
end

return MapCreepCleaningContainer