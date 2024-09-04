---@class CityWorkProduceUIUnitData
---@field new fun(furniture:CityFurniture):CityWorkProduceUIUnitData
---@field plan wds.CastleResourceGeneratePlan
---@field icon string|nil
local CityWorkProduceUIUnitData = class("CityWorkProduceUIUnitData")
local ConfigRefer = require("ConfigRefer")
local CityWorkProduceUIUnitStatus = require("CityWorkProduceUIUnitStatus")

---@param furniture CityFurniture
function CityWorkProduceUIUnitData:ctor(furniture, uiMediator)
    self.furniture = furniture
    self.uiMediator = uiMediator
    self.status = CityWorkProduceUIUnitStatus.None
end

function CityWorkProduceUIUnitData:SetInQueue(plan)
    self.status = CityWorkProduceUIUnitStatus.InQueue
    self.plan = plan
    local processCfg = ConfigRefer.CityProcess:Find(self.plan.ProcessId)
    local eleRefCfg = ConfigRefer.CityElementResource:Find(processCfg:GenerateResType())
    self.icon = eleRefCfg:Icon()
end

function CityWorkProduceUIUnitData:SetWorking(plan)
    self.status = CityWorkProduceUIUnitStatus.Working
    self.plan = plan
    local processCfg = ConfigRefer.CityProcess:Find(self.plan.ProcessId)
    local eleRefCfg = ConfigRefer.CityElementResource:Find(processCfg:GenerateResType())
    self.icon = eleRefCfg:Icon()
end

function CityWorkProduceUIUnitData:SetForbid()
    self.status = CityWorkProduceUIUnitStatus.Forbid
    self.plan = nil
    self.icon = nil
end

function CityWorkProduceUIUnitData:SetFree()
    self.status = CityWorkProduceUIUnitStatus.Free
    self.plan = nil
    self.icon = nil
end

function CityWorkProduceUIUnitData:IsAuto()
    return self.plan ~= nil and self.plan.Auto
end

function CityWorkProduceUIUnitData:GetInQueueImage()
    return self.icon
end

return CityWorkProduceUIUnitData