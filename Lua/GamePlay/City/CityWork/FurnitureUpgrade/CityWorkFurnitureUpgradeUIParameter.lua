local CityCommonRightPopupUIParameter = require("CityCommonRightPopupUIParameter")
---@class CityWorkFurnitureUpgradeUIParameter:CityCommonRightPopupUIParameter
---@field new fun():CityWorkFurnitureUpgradeUIParameter
local CityWorkFurnitureUpgradeUIParameter = class("CityWorkFurnitureUpgradeUIParameter", CityCommonRightPopupUIParameter)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")

---@param workCfg CityWorkConfigCell
---@param source CityFurnitureTile
function CityWorkFurnitureUpgradeUIParameter:ctor(workCfg, source)
    CityCommonRightPopupUIParameter.ctor(self, source)
    self.workCfg = workCfg
    self.source = source
    self.city = source:GetCity()

    self.lvCell = self.source:GetCell().furnitureCell
    local typ = self.lvCell:Type()
    self.typCell = ConfigRefer.CityFurnitureTypes:Find(typ)
    self.nextLvCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(typ, self.lvCell:Level() + 1)
end

function CityWorkFurnitureUpgradeUIParameter:UpdateDataByFurnitureTile()
    local furniture = self.source:GetCell()
    local workCfgId = furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp)
    if workCfgId == 0 then
        return true
    end

    self.workCfg = ConfigRefer.CityWork:Find(workCfgId)
    self.lvCell = furniture.furnitureCell
    local typ = self.lvCell:Type()
    self.typCell = ConfigRefer.CityFurnitureTypes:Find(typ)
    self.nextLvCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(typ, self.lvCell:Level() + 1)

    if self.nextLvCell == nil then
        return true
    end

    -- if self.lvCell:WorkListLength() ~= self.lvCell:WorkListLength() then
    --     return true
    -- end

    -- local oldWorkMap = {}
    -- for i = 1, self.lvCell:WorkListLength() do
    --     local work = self.lvCell:WorkList(i)
    --     oldWorkMap[work] = true
    -- end

    -- local workMap = {}
    -- for i = 1, self.nextLvCell:WorkListLength() do
    --     local work = self.nextLvCell:WorkList(i)
    --     workMap[work] = true
    -- end

    -- for work, _ in pairs(oldWorkMap) do
    --     if workMap[work] == nil then
    --         return true
    --     end
    -- end

    -- for work, _ in pairs(workMap) do
    --     if oldWorkMap[work] == nil then
    --         return true
    --     end
    -- end
    
    return false
end

function CityWorkFurnitureUpgradeUIParameter:GetWorkCfg()
    return self.workCfg
end

function CityWorkFurnitureUpgradeUIParameter:GetCity()
    return self.city
end

function CityWorkFurnitureUpgradeUIParameter:GetLvCell()
    return self.lvCell
end

function CityWorkFurnitureUpgradeUIParameter:GetNextLvCell()
    return self.nextLvCell
end

function CityWorkFurnitureUpgradeUIParameter:GetTypeCell()
    return self.typCell
end

return CityWorkFurnitureUpgradeUIParameter