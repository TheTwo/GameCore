local CityExplorerStateDefine = require("CityExplorerStateDefine")
local CityExplorerState = require("CityExplorerState")

---@class CityExplorerStateIdle:CityExplorerState
---@field new fun(explorer:CityUnitExplorer):CityExplorerStateIdle
---@field super CityExplorerState
local CityExplorerStateIdle = class('CityExplorerStateIdle', CityExplorerState)

function CityExplorerStateIdle:Enter()
    self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetPos, true)
    self._explorer:SetIsRunning(false)
    --self._explorer:SetSelectedShow(false)
    self._explorer:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.idle)
end

return CityExplorerStateIdle