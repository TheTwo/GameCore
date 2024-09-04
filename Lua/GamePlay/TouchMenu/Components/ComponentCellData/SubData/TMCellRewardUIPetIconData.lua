local TMCellRewardBase = require("TMCellRewardBase")
---@class TMCellRewardUIPetIconData:TMCellRewardBase
---@field new fun():TMCellRewardUIPetIconData
local TMCellRewardUIPetIconData = class("TMCellRewardUIPetIconData", TMCellRewardBase)

---@param data UIPetIconData
function TMCellRewardUIPetIconData:ctor(data)
    self.data = data
end

function TMCellRewardUIPetIconData:GetPrefabIndex()
    return 1
end

return TMCellRewardUIPetIconData