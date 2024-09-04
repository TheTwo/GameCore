local FurOverviewProcessState = require("FurOverviewProcessState")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local CityWorkFormula = require("CityWorkFormula")

---@class FurOverviewProcessStateFinished:FurOverviewProcessState
---@field new fun():FurOverviewProcessStateFinished
local FurOverviewProcessStateFinished = class("FurOverviewProcessStateFinished", FurOverviewProcessState)

function FurOverviewProcessStateFinished:Enter()
    self.data.cell._statusRecord:ApplyStatusRecord(3)
    local castleFurniture = self.data.city.furnitureManager:GetCastleFurniture(self.data.furnitureId)
    local info = castleFurniture.ProcessInfo[1]

    local cur = info.FinishNum
    local thisWorkCfg = ConfigRefer.CityWork:Find(info.WorkCfgId)
    local workId = castleFurniture.WorkType2Id[CityWorkType.Process]
    local citizenId = nil
    if workId ~= nil and workId > 0 then
        local workData = self.data.city.cityWorkManager:GetWorkData(workId)
        if workData ~= nil and workData.CitizenId > 0 then
            citizenId = workData.CitizenId
        end
    end
    local max = CityWorkFormula.GetAutoProcessMaxCount(thisWorkCfg, nil, self.data.furnitureId, citizenId)
    self.data.cell._p_progress_process.value = math.clamp01(cur / max)
    self.data.cell._p_text_time_process.text = ("%d/%d"):format(cur, max)
end

function FurOverviewProcessStateFinished:Exit()
    
end

return FurOverviewProcessStateFinished