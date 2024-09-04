---@class CityWorkCollectUIParameter
---@field new fun():CityWorkCollectUIParameter
---@field recipes CityProcessConfigCell[]
local CityWorkCollectUIParameter = class("CityWorkCollectUIParameter")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")

---@param a CityProcessConfigCell
---@param b CityProcessConfigCell
function CityWorkCollectUIParameter:OrderByIndex(a, b)
    local effectiveA = self.city.cityWorkManager:IsProcessEffective(a)
    local effectiveB = self.city.cityWorkManager:IsProcessEffective(b)
    local priorityA = effectiveA and a:Index() or a:LockedIndex()
    local priorityB = effectiveB and b:Index() or b:LockedIndex()
    return priorityA > priorityB
end

---@param workCfg CityWorkConfigCell
---@param source CityFurnitureTile
function CityWorkCollectUIParameter:ctor(workCfg, source)
    self.workCfg = workCfg
    self.source = source
    self.city = source:GetCity()
    self.recipes = {}
    self.lvCfgId = source:GetCell().configId

    for i = 1, self.workCfg:CollectResListLength() do
        local recipeId = self.workCfg:CollectResList(i)
        local recipe = ConfigRefer.CityProcess:Find(recipeId)
        table.insert(self.recipes, recipe)
    end
    table.sort(self.recipes, Delegate.GetOrCreate(self, self.OrderByIndex))
end

function CityWorkCollectUIParameter:GetRecipes()
    return self.recipes
end

return CityWorkCollectUIParameter