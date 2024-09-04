---@class MapFogDefine
local MapFogDefine = {}

---@class MapFogDefine.MistLockedReason
MapFogDefine.MistLockedReason = {
    RadarLevelLimit = 1,        --雷达等级不满足
    FogCellLimit = 2,           --迷雾格子不合法
    NotNeighborhood = 3,        --不是基地附近迷雾
    MistUnlockTasksLimit = 4,   --迷雾任务未完成
}

return MapFogDefine