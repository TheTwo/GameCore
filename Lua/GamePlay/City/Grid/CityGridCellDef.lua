local CellType = {
    INVALID = -1,
    SQUARE_MAIN = 0,
    DISCRETE_MAIN = 1,
}

local ConfigType = {
    INVALID = -1,
    BUILDING = 1,
    FURNITURE = 2,
    RESOURCE = 3,       --资源点
    NPC = 4,            --任务据点
    CREEP_NODE = 5,     --菌毯节点或核心
    ZONE_RECOVER = 6,   --区域收复建筑
}

---@class CityGridCellDef
local m = { CellType = CellType, ConfigType = ConfigType}
return m