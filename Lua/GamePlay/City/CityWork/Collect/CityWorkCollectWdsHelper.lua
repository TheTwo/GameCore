local ItemGroupHelper = require("ItemGroupHelper")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local CityWorkCollectWdsHelper = {}

---@param collectingInfos wds.CastleFurnitureCollectInfo[] | RepeatedField
---@return wds.CastleFurnitureCollectInfo, wds.CastleFurnitureCollectInfo[], wds.CastleFurnitureCollectInfo[]
function CityWorkCollectWdsHelper.GetCollecting_InQueue_FinishedPart(collectingInfos)
    local finished = {}
    local inqueue = {}
    local collecting = nil
    for i, v in ipairs(collectingInfos) do
        if v.Finished then
            table.insert(finished, v)
        else
            if collecting == nil then
                collecting = v
            else
                table.insert(inqueue, v)
            end
        end
    end
    return collecting, inqueue, finished
end

---@param collectInfo wds.CastleFurnitureCollectInfo
function CityWorkCollectWdsHelper.GetOutputIcon(collectInfo)
    local workCfg = ConfigRefer.CityWork:Find(collectInfo.WorkCfgId)
    ---@type CityProcessConfigCell
    local processCfg = nil
    for i = 1, workCfg:CollectResListLength() do
        processCfg = ConfigRefer.CityProcess:Find(workCfg:CollectResList(i))
        if processCfg:CollectResType() == collectInfo.ResourceType then
            local outputIcon = processCfg:OutputIcon()
            if not string.IsNullOrEmpty(outputIcon) then
                return outputIcon
            end
        end
    end

    -- local eleResCfg = ConfigRefer.CityElementResource:Find(collectInfo.ResourceType)
    -- local itemGroup = ConfigRefer.ItemGroup:Find(eleResCfg:Reward())
    -- local _, icon = ItemGroupHelper.GetItemIcon(itemGroup)
    return string.Empty
end

---@param castleFurniture wds.CastleFurniture
---@param collectInfo wds.CastleFurnitureCollectInfo
function CityWorkCollectWdsHelper.GetResCollectProgress(castleFurniture, collectInfo)
    if collectInfo.Finished then return 1 end
    if collectInfo.Auto and collectInfo.CollectingResource == 0 then return 1 end

    if castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] == nil then
        return collectInfo.FinishedCount / collectInfo.TargetCount
    end

    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local startTime = collectInfo.StartTime.ServerSecond
    local endTime = collectInfo.FinishTime.ServerSecond
    local cur = curTime - startTime
    local total = endTime - startTime
    return math.clamp01(cur / total)
end

---@param collectInfo wds.CastleFurnitureCollectInfo
function CityWorkCollectWdsHelper:GetResCollectRemainTime(collectInfo)
    return math.max(0, collectInfo.FinishTime.ServerSecond - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
end

return CityWorkCollectWdsHelper