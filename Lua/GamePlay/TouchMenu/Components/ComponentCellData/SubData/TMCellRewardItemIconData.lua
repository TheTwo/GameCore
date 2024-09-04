local TMCellRewardBase = require("TMCellRewardBase")
---@class TMCellRewardItemIconData:TMCellRewardBase
---@field new fun(data):TMCellRewardItemIconData
local TMCellRewardItemIconData = class("TMCellRewardItemIconData", TMCellRewardBase)

---@param data ItemIconData
function TMCellRewardItemIconData:ctor(data)
    self.data = data
end

function TMCellRewardItemIconData:GetPrefabIndex()
    return 0
end

return TMCellRewardItemIconData