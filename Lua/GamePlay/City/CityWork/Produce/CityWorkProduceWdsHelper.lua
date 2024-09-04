local ConfigRefer = require("ConfigRefer")
local CityWorkProduceWdsHelper = {}
local CityWorkType = require("CityWorkType")

---@param plan wds.CastleResourceGeneratePlan
function CityWorkProduceWdsHelper.GetproduceIcon(plan)
    local processCfg = ConfigRefer.CityProcess:Find(plan.ProcessId)
    local eleResCfg = ConfigRefer.CityElementResource:Find(processCfg:GenerateResType())
    return eleResCfg:Icon()
end

---@param castleFurniture wds.CastleFurniture
---@param city City
function CityWorkProduceWdsHelper.GetProduceProgress(castleFurniture, city)
    local gap = city:GetWorkTimeSyncGap()
    local produceInfo = castleFurniture.ResourceProduceInfo
    if produceInfo.StartTime.ServerSecond == 0 then return 0 end
    if produceInfo.Duration.ServerSecond == 0 then return 1 end

    local passTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + gap - produceInfo.StartTime.ServerSecond
    return math.clamp01(passTime / produceInfo.Duration.ServerSecond)
end

---@param castleFurniture wds.CastleFurniture
---@param city City
function CityWorkProduceWdsHelper.GetProduceSingleProgress(castleFurniture, city)
    local now = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    return math.clamp01((now % 5) / 5)
end

---@param castleFurniture wds.CastleFurniture
function CityWorkProduceWdsHelper.GetProduceRemainTime(castleFurniture)
    return math.max(0, castleFurniture.ResourceProduceInfo.StartTime.ServerSecond + castleFurniture.ResourceProduceInfo.Duration.ServerSecond - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
end

return CityWorkProduceWdsHelper