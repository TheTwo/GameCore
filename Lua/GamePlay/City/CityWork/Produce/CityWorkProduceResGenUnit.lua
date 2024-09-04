---@class CityWorkProduceResGenUnit
---@field new fun():CityWorkProduceResGenUnit
---@field eleId number @CityElement的id
---@field index number @种植点索引，基于配置
---@field x number @种植点x坐标
---@field y number @种植点y坐标
---@field sizeX number @种植点宽度
---@field sizeY number @种植点高度
---@field resCfgId number @资源配置id
---@field status number @种植点状态 [-1:无效, 0:生成中, 1:已完成]
local CityWorkProduceResGenUnit = class("CityWorkProduceResGenUnit")
local CityWorkProduceResGenUnitStatus = require("CityWorkProduceResGenUnitStatus")
local ConfigRefer = require("ConfigRefer")

---@param agent CityWorkProduceResGenGridAgent
function CityWorkProduceResGenUnit:ctor(agent)
    self.agent = agent
    self:Clear()
end

function CityWorkProduceResGenUnit:Clear()
    self.plan = nil
    self.eleId = -1
    self.index = -1
    self.x = -1
    self.y = -1
    self.sizeX = 0
    self.sizeY = 0
    self.resCfgId = -1
    self.status = CityWorkProduceResGenUnitStatus.None
end

---@param plan wds.CastleResourceGeneratePlan
function CityWorkProduceResGenUnit:FillDataByGeneratePlan(plan)
    if not plan.Auto and plan.FinishedCount == plan.TargetCount then
        self:Clear()
        return
    end

    local processCfg = ConfigRefer.CityProcess:Find(plan.ProcessId)
    local eleResCfg = ConfigRefer.CityElementResource:Find(processCfg:GenerateResType())
    self.plan = plan
    self.resCfgId = eleResCfg:Id()
    self.x = plan.GeneratingPos.X
    self.y = plan.GeneratingPos.Y
    self.sizeX = eleResCfg:SizeX()
    self.sizeY = eleResCfg:SizeY()
    self.eleId = -1
    self.index = plan.GeneratingPosIdx + 1
    self.status = self.index > 0
        and CityWorkProduceResGenUnitStatus.Generating
        or CityWorkProduceResGenUnitStatus.None
end

function CityWorkProduceResGenUnit:IsGenerating()
    return self.status == CityWorkProduceResGenUnitStatus.Generating
end

---@param inst CityWorkProduceResGenUnit
function CityWorkProduceResGenUnit:Equals(inst)
    if inst == nil then return false end

    return self.index == inst.index
        and self.eleId == inst.eleId
        and self.x == inst.x
        and self.y == inst.y
        and self.sizeX == inst.sizeX
        and self.sizeY == inst.sizeY
        and self.resCfgId == inst.resCfgId
        and self.status == inst.status
end

---@param inst CityWorkProduceResGenUnit
function CityWorkProduceResGenUnit:Exchange(inst)
    if inst == nil then return end
    if not inst:is(CityWorkProduceResGenUnit) then return end

    self.index, inst.index = inst.index, self.index
    self.eleId, inst.eleId = inst.eleId, self.eleId
    self.x, inst.x = inst.x, self.x
    self.y, inst.y = inst.y, self.y
    self.sizeX, inst.sizeX = inst.sizeX, self.sizeX
    self.sizeY, inst.sizeY = inst.sizeY, self.sizeY
    self.resCfgId, inst.resCfgId = inst.resCfgId, self.resCfgId
    self.status, inst.status = inst.status, self.status
    self.plan, inst.plan = inst.plan, self.plan
    return self
end

return CityWorkProduceResGenUnit