local CityFurnitureDeployUIDataSrc = require("CityFurnitureDeployUIDataSrc")
---@class ShareLevelHeroDeployUIDataSrc:CityFurnitureDeployUIDataSrc
---@field new fun():ShareLevelHeroDeployUIDataSrc
local ShareLevelHeroDeployUIDataSrc = class("ShareLevelHeroDeployUIDataSrc", CityFurnitureDeployUIDataSrc)
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local ShareLevelHeroDeployHeroCellData = require("ShareLevelHeroDeployHeroCellData")

---@param cellTile CityFurnitureTile
function ShareLevelHeroDeployUIDataSrc:ctor(cellTile)
    self.cellTile = cellTile
    CityFurnitureDeployUIDataSrc.ctor(self, self.cellTile:GetName())
end

function ShareLevelHeroDeployUIDataSrc:GetMainHint()
    local ret = {}
    for i, id in ipairs(self.heroes) do
        local data = ShareLevelHeroDeployHeroCellData.new(id, i == #self.heroes)
        table.insert(ret, data)
    end

    table.sort(ret, function(l, r)
        if l.heroCfgCache.dbData.Level ~= r.heroCfgCache.dbData.Level then
            return l.heroCfgCache.dbData.Level < r.heroCfgCache.dbData.Level
        end
        return l.heroCfgCache.dbData.ID < r.heroCfgCache.dbData.ID
    end)

    if #ret > 0 then
        return I18N.GetWithParams("animal_work_fur_desc_02", ret[1].heroCfgCache.dbData.Level, I18N.Get(ret[1].heroCfgCache.configCell:Name()))
    else
        return I18N.GetWithParams("animal_work_fur_desc_02", 0, "unknown")
    end
end

---@return string
function ShareLevelHeroDeployUIDataSrc:GetLeftTitle()
    return string.Empty
end

---@return CityFurnitureDeployCellData[]
function ShareLevelHeroDeployUIDataSrc:GetTableViewCellData()
    local ret = {}
    for i, v in ipairs(self.heroes) do
        local data = ShareLevelHeroDeployHeroCellData.new(v)
        table.insert(ret, data)
    end

    table.sort(ret, function(l, r)
        if l.heroCfgCache.dbData.Level ~= r.heroCfgCache.dbData.Level then
            return l.heroCfgCache.dbData.Level > r.heroCfgCache.dbData.Level
        end
        return l.heroCfgCache.dbData.ID > r.heroCfgCache.dbData.ID
    end)

    if #ret > 0 then
        ret[#ret].shareTarget = true
    end

    return ret
end

---@param mediator CityFurnitureDeployUIMediator
function ShareLevelHeroDeployUIDataSrc:OnMediatorOpened(mediator)
    self.mediator = mediator
    self.heroes = ModuleRefer.PlayerModule:GetPlayer().Hero.SystemLevelHero
end

---@param mediator CityFurnitureDeployUIMediator
function ShareLevelHeroDeployUIDataSrc:OnMediatorClosed(mediator)
    self.mediator = nil
    self.heroes = nil
end

return ShareLevelHeroDeployUIDataSrc