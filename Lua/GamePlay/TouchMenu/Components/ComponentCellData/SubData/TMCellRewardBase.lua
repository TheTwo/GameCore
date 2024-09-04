---@class TMCellRewardBase
---@field new fun():TMCellRewardBase
---@field data any
local TMCellRewardBase = class("TMCellRewardBase")

function TMCellRewardBase:GetPrefabIndex()
    return 0
end

return TMCellRewardBase