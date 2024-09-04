---@class CityWorkProduceUIParameter
---@field new fun():CityWorkProduceUIParameter
local CityWorkProduceUIParameter = class("CityWorkProduceUIParameter")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")

---@param a CityProcessConfigCell
---@param b CityProcessConfigCell
function CityWorkProduceUIParameter:OrderByIndex(a, b)
    local effectiveA = self.city.cityWorkManager:IsProcessEffective(a)
    local effectiveB = self.city.cityWorkManager:IsProcessEffective(b)
    local priorityA = effectiveA and a:Index() or a:LockedIndex()
    local priorityB = effectiveB and b:Index() or b:LockedIndex()
    return priorityA > priorityB
end

---@param workCfg CityWorkConfigCell
---@param cellTile CityFurnitureTile
function CityWorkProduceUIParameter:ctor(workCfg, cellTile)
    self.workCfg = workCfg
    self.cellTile = cellTile
    self.city = cellTile:GetCity()
    self.recipes = {}
    self.lvCfgId = cellTile:GetCell().configId
    for i = 1, self.workCfg:GenerateResListLength() do
        local processCfgId = self.workCfg:GenerateResList(i)
        table.insert(self.recipes, ConfigRefer.CityProcess:Find(processCfgId))
    end
    table.sort(self.recipes, Delegate.GetOrCreate(self, self.OrderByIndex))
end

---@return CityProcessConfigCell[]
function CityWorkProduceUIParameter:GetRecipes()
    return self.recipes
end

return CityWorkProduceUIParameter