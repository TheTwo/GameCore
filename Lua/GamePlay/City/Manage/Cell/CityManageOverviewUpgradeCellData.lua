---@class CityManageOverviewUpgradeCellData
---@field new fun():CityManageOverviewUpgradeCellData
local CityManageOverviewUpgradeCellData = class("CityManageOverviewUpgradeCellData")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")

---@param param CityManageCenterUIParameter
---@param furnitureId number
---@param isFree boolean
function CityManageOverviewUpgradeCellData:ctor(param, furnitureId, isFree)
    self.param = param
    self.furnitureId = furnitureId
    self.isFree = isFree
end

function CityManageOverviewUpgradeCellData:GetStatus()
    if self.furnitureId then
        return 1
    end

    if self.isFree then
        return 0
    else
        return 2
    end
end

function CityManageOverviewUpgradeCellData:GetFurnitureIcon()
    if not self.furnitureId then return string.Empty end

    local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(castleFurniture.ConfigId)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    return typCfg:Image()
end

function CityManageOverviewUpgradeCellData:GetFurnitureUpgradeProgress()
    if not self.furnitureId then return 0 end

    local gap = self.param.city:GetWorkTimeSyncGap()
    local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    return math.clamp01((castleFurniture.LevelUpInfo.CurProgress + gap) / castleFurniture.LevelUpInfo.TargetProgress)
end

function CityManageOverviewUpgradeCellData:GetFurnitureUpgradeRemainTime()
    if not self.furnitureId then return string.Empty end

    local gap = self.param.city:GetWorkTimeSyncGap()
    local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    return math.max(0, castleFurniture.LevelUpInfo.TargetProgress - castleFurniture.LevelUpInfo.CurProgress - gap)
end

return CityManageOverviewUpgradeCellData