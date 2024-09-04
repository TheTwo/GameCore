---@class WorldTrendDefine
local WorldTrendDefine = {}

---@class WorldTrendDefine.TASK_TYPE
WorldTrendDefine.TASK_TYPE = {
    Personal = 1,
    Alliance = 2,
    Global = 3,
}

---@class WorldTrendDefine.TASK_STATE
WorldTrendDefine.TASK_STATE = {
    None = 0,
    Processing = 1,
    CanReward = 2,
    Rewarded = 3,
}

---@class WorldTrendDefine.BRANCH_STATE
WorldTrendDefine.BRANCH_STATE = {
    None = 0,
    Processing = 1,     --投票阶段
    CanReward = 2,  --投票结束，可领奖
    Rewarded = 3,   --已领奖（无奖励的分支就表示已结束）
}

---@class WorldTrendDefine.DOT_STATE
WorldTrendDefine.DOT_STATE = {
    None = 0,
    Lock_Normal = 1,     --普通未解锁节点
    Lock_WithCondition = 2,  --未解锁且存在解锁条件
    Open_Normal = 3,   --奖励未全部领取
    Open_CanReward = 4,   --有领奖可领取
    Open_AllRewarded = 5,   --所有奖励已领取
}

WorldTrendDefine.BRANCH_CELL_WIDTH = 1300
WorldTrendDefine.NO_BRANCH_CELL_WIDTH = 650

return WorldTrendDefine