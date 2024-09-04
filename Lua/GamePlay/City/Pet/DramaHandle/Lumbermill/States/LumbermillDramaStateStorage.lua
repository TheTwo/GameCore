local DramaStateDefine = require("DramaStateDefine")

local LumbermillDramaState = require("LumbermillDramaState")
---@class LumbermillDramaStateStorage:LumbermillDramaState
local LumbermillDramaStateStorage = class("LumbermillDramaStateStorage", LumbermillDramaState)

function LumbermillDramaStateStorage:Enter()
    self.handle:CountClear()
    self.stateMachine:ChangeState(DramaStateDefine.State.route)
end

return LumbermillDramaStateStorage