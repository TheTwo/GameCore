local DramaStateDefine = require("DramaStateDefine")

local MineDramaState = require("MineDramaState")

---@class MineDramaStateStorage:MineDramaState
---@field super MineDramaState
local MineDramaStateStorage = class("MineDramaStateStorage", MineDramaState)

function MineDramaStateStorage:Enter()
    self.handle:CountClear()
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

return MineDramaStateStorage