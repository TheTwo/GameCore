local CityFurnitureDeployHeroCellData = require("CityFurnitureDeployHeroCellData")
---@class ShareLevelHeroDeployHeroCellData:CityFurnitureDeployHeroCellData
---@field new fun():ShareLevelHeroDeployHeroCellData
local ShareLevelHeroDeployHeroCellData = class("ShareLevelHeroDeployHeroCellData", CityFurnitureDeployHeroCellData)
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")

---@param heroCfgCache HeroConfigCache
function ShareLevelHeroDeployHeroCellData:ctor(heroId, shareTarget)
    self.heroId = heroId
    self.heroCfgCache = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
    self.shareTarget = shareTarget
end

---@return HeroConfigCache
function ShareLevelHeroDeployHeroCellData:GetHeroData()
    return self.heroCfgCache
end

---@return string
function ShareLevelHeroDeployHeroCellData:GetHeroName()
    return I18N.Get(self.heroCfgCache.configCell:Name())
end

---@return string
function ShareLevelHeroDeployHeroCellData:GetHeroLv()
    return self.heroCfgCache
end

function ShareLevelHeroDeployHeroCellData:IsShareTarget()
    return self.shareTarget
end

return ShareLevelHeroDeployHeroCellData