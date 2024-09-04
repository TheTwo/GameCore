local ModuleRefer = require("ModuleRefer")
---@class HeroListSorters
local HeroListSorters = {}

local SortType = {
    Default = 0,
    Level = 1,
    Quality = 2,
    StarLevel = 3,
    Id = 4,
}

HeroListSorters.SortType = SortType

---@param a HeroConfigCache
---@param b HeroConfigCache
function HeroListSorters.SortByLevel(a, b)
    if a:HasHero() and b:HasHero() then
        if a.dbData.Level ~= b.dbData.Level then
            return a.dbData.Level > b.dbData.Level
        elseif a.configCell:Quality() ~= b.configCell:Quality() then
            return a.configCell:Quality() > b.configCell:Quality()
        elseif a.dbData.StarLevel ~= b.dbData.StarLevel then
            return a.dbData.StarLevel > b.dbData.StarLevel
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    elseif a:HasHero() or b:HasHero() then
        return a:HasHero()
    else
        if a.configCell:Quality() ~= b.configCell:Quality() then
            return a.configCell:Quality() > b.configCell:Quality()
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    end
end

---@param a HeroConfigCache
---@param b HeroConfigCache
function HeroListSorters.SortByQuality(a, b)
    if a:HasHero() and b:HasHero() then
        if a.configCell:Quality() ~= b.configCell:Quality() then
            return a.configCell:Quality() > b.configCell:Quality()
        elseif a.dbData.Level ~= b.dbData.Level then
            return a.dbData.Level > b.dbData.Level
        elseif a.dbData.StarLevel ~= b.dbData.StarLevel then
            return a.dbData.StarLevel > b.dbData.StarLevel
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    elseif a:HasHero() or b:HasHero() then
        return a:HasHero()
    else
        if a.dbData.Level ~= b.dbData.Level then
            return a.dbData.Level > b.dbData.Level
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    end
end

---@param a HeroConfigCache
---@param b HeroConfigCache
function HeroListSorters.SortByStarLevel(a, b)
    if a:HasHero() and b:HasHero() then
        if a.dbData.StarLevel ~= b.dbData.StarLevel then
            return a.dbData.StarLevel > b.dbData.StarLevel
        elseif a.dbData.Level ~= b.dbData.Level then
            return a.dbData.Level > b.dbData.Level
        elseif a.configCell:Quality() ~= b.configCell:Quality() then
            return a.configCell:Quality() > b.configCell:Quality()
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    elseif a:HasHero() or b:HasHero() then
        return a:HasHero()
    else
        if a.dbData.Level ~= b.dbData.Level then
            return a.dbData.Level > b.dbData.Level
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    end
end

---@param a HeroConfigCache
---@param b HeroConfigCache
function HeroListSorters.HeroSortByPower(a, b)
    local powerA = ModuleRefer.HeroModule:CalcHeroPower(a.id)
    local powerB = ModuleRefer.HeroModule:CalcHeroPower(b.id)
    if a:HasHero() and b:HasHero() then
        if powerA ~= powerB then
            return powerA > powerB
        elseif a.dbData.Level ~= b.dbData.Level then
            return a.dbData.Level > b.dbData.Level
        elseif a.configCell:Quality() ~= b.configCell:Quality() then
            return a.configCell:Quality() > b.configCell:Quality()
        elseif a.dbData.StarLevel ~= b.dbData.StarLevel then
            return a.dbData.StarLevel > b.dbData.StarLevel
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    elseif a:HasHero() or b:HasHero() then
        return a:HasHero()
    else
        if powerA ~= powerB then
            return powerA > powerB
        elseif a.configCell:Quality() ~= b.configCell:Quality() then
            return a.configCell:Quality() > b.configCell:Quality()
        else
            return a.configCell:Id() < b.configCell:Id()
        end
    end
end

---@param sortType number
---@return nil | fun(a:HeroConfigCache, b:HeroConfigCache):boolean
function HeroListSorters.GetSorter(sortType)
    if sortType == SortType.Level then
        return HeroListSorters.SortByLevel
    elseif sortType == SortType.Quality then
        return HeroListSorters.SortByQuality
    elseif sortType == SortType.StarLevel then
        return HeroListSorters.SortByStarLevel
    else
        return nil
    end
end

return HeroListSorters