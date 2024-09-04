---@class CityStoreroomUIGridData
---@field new fun():CityStoreroomUIGridData
local CityStoreroomUIGridData = class("CityStoreroomUIGridData")

function CityStoreroomUIGridData:ctor()
    self.cellData = {}
end

function CityStoreroomUIGridData:AddCell(cell)
    table.insert(self.cellData, cell)
end

---@return CityStoreroomUIGridItemData[]
function CityStoreroomUIGridData:GetData()
    return self.cellData
end

return CityStoreroomUIGridData