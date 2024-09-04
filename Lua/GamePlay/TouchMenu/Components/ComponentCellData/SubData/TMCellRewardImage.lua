local TMCellRewardBase = require("TMCellRewardBase")
---@class TMCellRewardImage:TMCellRewardBase
---@field new fun(image):TMCellRewardImage
local TMCellRewardImage = class("TMCellRewardImage", TMCellRewardBase)

---@param image string
function TMCellRewardImage:ctor(image)
    self.data = image
end

function TMCellRewardImage:GetPrefabIndex()
    return 2
end

return TMCellRewardImage