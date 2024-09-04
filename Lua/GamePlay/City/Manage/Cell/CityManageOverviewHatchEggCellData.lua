---@class CityManageOverviewHatchEggCellData
---@field new fun():CityManageOverviewHatchEggCellData
local CityManageOverviewHatchEggCellData = class("CityManageOverviewHatchEggCellData")
local ConfigRefer = require("ConfigRefer")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
local TimeFormatter = require("TimeFormatter")

---@param param CityManageCenterUIParameter
---@param furnitureId number
---@param castleFurniture wds.CastleFurniture
function CityManageOverviewHatchEggCellData:ctor(param, furnitureId)
    self.param = param
    self.furnitureId = furnitureId
end

function CityManageOverviewHatchEggCellData:GetStatus()
    if self.furnitureId == nil then
        return 3
    else
        local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
        if castleFurniture.ProcessInfo.ConfigId > 0 then
            return 1
        else
            return 0
        end
    end
end

function CityManageOverviewHatchEggCellData:GetEggImage()
    local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    local processCfg = ConfigRefer.CityWorkProcess:Find(castleFurniture.ProcessInfo.ConfigId)
    return CityWorkProcessWdsHelper.GetOutputIcon(processCfg)
end

function CityManageOverviewHatchEggCellData:GetWorkingProgress()
    local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    return CityWorkProcessWdsHelper.GetCityWorkProcessProgress(self.param.city, castleFurniture)
end

function CityManageOverviewHatchEggCellData:GetWorkingTime()
    local castleFurniture = self.param.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.param.city, castleFurniture.ProcessInfo)
    return TimeFormatter.SimpleFormatTime(remainTime)
end

function CityManageOverviewHatchEggCellData:OnClickEmpty()
    return self.param:GotoHatchEgg(self.furnitureId)
end

return CityManageOverviewHatchEggCellData