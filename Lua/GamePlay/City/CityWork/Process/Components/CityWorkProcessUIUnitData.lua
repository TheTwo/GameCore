---@class CityWorkProcessUIUnitData
---@field new fun():CityWorkProcessUIUnitData
local CityWorkProcessUIUnitData = class("CityWorkProcessUIUnitData")
local CityWorkProcessUIUnitStatus = require("CityWorkProcessUIUnitStatus")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")

---@param furniture CityFurniture
function CityWorkProcessUIUnitData:ctor(furniture, uiMediator)
    self.furniture = furniture
    self.uiMediator = uiMediator
    self.status = CityWorkProcessUIUnitStatus.Free
end

function CityWorkProcessUIUnitData:SetFree()
    self.status = CityWorkProcessUIUnitStatus.Free
    self.process = nil
end

---@param process wds.CastleProcess
function CityWorkProcessUIUnitData:SetInQueue(process)
    self.status = CityWorkProcessUIUnitStatus.InQueue
    self.process = process
end

function CityWorkProcessUIUnitData:SetWorking(process)
    self.status = CityWorkProcessUIUnitStatus.Working
    self.process = process
end

---@param process wds.CastleProcess
function CityWorkProcessUIUnitData:SetFinished(process, needVx)
    self.status = CityWorkProcessUIUnitStatus.Collect
    self.process = process
    self.needVx = needVx
end

function CityWorkProcessUIUnitData:SetForbid()
    self.status = CityWorkProcessUIUnitStatus.Forbid
    self.process = nil
end

function CityWorkProcessUIUnitData:GetIcon()
    if self.status == CityWorkProcessUIUnitStatus.Free then
        return string.Empty
    end

    local processCfg = ConfigRefer.CityWorkProcess:Find(self.process.ConfigId)
    return CityWorkProcessWdsHelper.GetOutputIcon(processCfg)
end

function CityWorkProcessUIUnitData:IsAuto()
    return self.process ~= nil and self.process.Auto
end

return CityWorkProcessUIUnitData