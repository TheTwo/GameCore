---@class CityWorkProcessUIParameter
---@field new fun(workCfg:CityWorkConfigCell, source:CityFurnitureTile):CityWorkProcessUIParameter
local CityWorkProcessUIParameter = class("CityWorkProcessUIParameter")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")

---@param a CityProcessConfigCell
---@param b CityProcessConfigCell
function CityWorkProcessUIParameter:OrderByIndex(a, b)
    local limitA = self.limitMap[a:Id()]
    local limitB = self.limitMap[b:Id()]

    if limitA ~= limitB then
        -- g_Logger.Error(("[%d - %d], reachVersion %s"):format(a:Id(), b:Id(), tostring(limitB)))
        return limitB
    end

    local effectiveA = self.effectiveMap[a:Id()]
    local effectiveB = self.effectiveMap[b:Id()]

    if effectiveA ~= effectiveB then
        -- g_Logger.Error(("[%d - %d], effective %s"):format(a:Id(), b:Id(), tostring(effectiveA)))
        return effectiveA
    end

    -- if effectiveA or effectiveB then
    --     local canBuildA, canBuildB = countA > 0, countB > 0
    --     if canBuildA ~= canBuildB then
    --         -- g_Logger.Error(("[%d - %d], canbuild %s"):format(a:Id(), b:Id(), tostring(canBuildA)))
    --         return canBuildA
    --     end
    -- end

    local priorityA = effectiveA and a:Index() or a:LockedIndex()
    local priorityB = effectiveB and b:Index() or b:LockedIndex()
    -- g_Logger.Error(("[%d - %d], priority %s"):format(a:Id(), b:Id(), tostring(priorityA > priorityB)))
    return priorityA > priorityB
end

---@param workCfg CityWorkConfigCell
---@param source CityFurnitureTile
function CityWorkProcessUIParameter:ctor(workCfg, source)
    self.workCfg = workCfg
    self.source = source
    self.city = source:GetCity()
    ---@type CityProcessConfigCell[]
    self.recipes = {}
    self.lvCfgId = source:GetCell().configId
    self.limitMap = {}
    self.effectiveMap = {}

    for i = 1, self.workCfg:ProcessListLength() do
        local processCfg = ConfigRefer.CityProcess:Find(self.workCfg:ProcessList(i))
        if processCfg then
            table.insert(self.recipes, processCfg)
            local lvCfg = self.city.cityWorkManager:GetProcessRecipeOutputFurnitureLvCfgId(processCfg)
            local count, limit, versionLimit = self.city.furnitureManager:GetFurnitureCanProcessCount(lvCfg)
            self.limitMap[processCfg:Id()] = limit
            self.effectiveMap[processCfg:Id()] = self.city.cityWorkManager:IsProcessEffective(processCfg)
        end
    end

    table.sort(self.recipes, Delegate.GetOrCreate(self, self.OrderByIndex))
end

function CityWorkProcessUIParameter:GetCity()
    return self.city
end

function CityWorkProcessUIParameter:GetWorkCfg()
    return self.workCfg
end

---@return CityProcessConfigCell[]
function CityWorkProcessUIParameter:GetRecipes()
    return self.recipes
end

return CityWorkProcessUIParameter