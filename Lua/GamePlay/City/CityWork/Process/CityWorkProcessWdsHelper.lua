local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")
local CityWorkType = require("CityWorkType")
local CityProcessUtils = require("CityProcessUtils")
local CityWorkProcessWdsHelper = {}

---@param processes wds.CastleProcess[] | RepeatedField
---@return wds.CastleProcess, wds.CastleProcess[], wds.CastleProcess[]
function CityWorkProcessWdsHelper.GetWorking_InQueue_FinishedPart(processes)
    local finished = {}
    local inqueue = {}
    local workingProcess = nil
    for i, v in ipairs(processes) do
        if v.LeftNum == 0 and not v.Auto then
            table.insert(finished, v)
        else
            if workingProcess == nil then
                workingProcess = v
            else
                table.insert(inqueue, v)
            end
        end
    end
    return workingProcess, inqueue, finished
end

---@param city City
---@param castleFurniture wds.CastleFurniture
---@param process wds.CastleProcess
function CityWorkProcessWdsHelper.GetCityWorkProcessProgress(city, castleFurniture)
    if castleFurniture.ProcessInfo.LeftNum == 0 then return 1 end
    if castleFurniture.WorkType2Id[CityWorkType.Process] == nil
        and castleFurniture.WorkType2Id[CityWorkType.Incubate] == nil
        and castleFurniture.WorkType2Id[CityWorkType.MaterialProcess] == nil then
        return castleFurniture.ProcessInfo.CurProgress / castleFurniture.ProcessInfo.TargetProgress
    else
        local gap = city:GetWorkTimeSyncGap()
        local cur = castleFurniture.ProcessInfo.CurProgress + gap
        local total = castleFurniture.ProcessInfo.TargetProgress
        return math.clamp01(cur / total)
    end
end

---@param process wds.CastleProcess
---@param onceTime number
function CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(city, process)
    if process.LeftNum == 0 then return 0 end
    
    local gap = city:GetWorkTimeSyncGap()
    local now = process.CurProgress
    local target = process.TargetProgress
    local remain = target - now - gap
    return math.max(0, process.LeftNum - 1) * target + remain
end

---@param process wds.CastleProcess
function CityWorkProcessWdsHelper.GetOutputIcon(processCfg)
    local itemCfg = ConfigRefer.Item:Find(processCfg:Output())
    if itemCfg == nil then return string.Empty end

    if CityProcessUtils.IsFurnitureRecipe(processCfg) then
        local lvCfgId = checknumber(itemCfg:UseParam(1))
        local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
        local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
        return typeCfg:Image()
    else
        return itemCfg:Icon()
    end
end

return CityWorkProcessWdsHelper