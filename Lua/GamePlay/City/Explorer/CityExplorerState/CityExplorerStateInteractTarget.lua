---@type CS.UnityEngine.Mathf
local Mathf = CS.UnityEngine.Mathf
local CityExplorerState = require("CityExplorerState")
local CityExplorerStateDefine = require("CityExplorerStateDefine")

---@class CityExplorerStateInteractTarget:CityExplorerState
---@field new fun(explorer:CityUnitExplorer):CityExplorerStateInteractTarget
---@field super CityExplorerState
local CityExplorerStateInteractTarget = class('CityExplorerStateInteractTarget', CityExplorerState)

function CityExplorerStateInteractTarget:Enter()
    CityExplorerState.Enter(self)
    self._explorer:SetIsRunning(false)
    --self._explorer:SetSelectedShow(true)
    self._timeoutTotal = self._explorer._config:InteractTargetTime()
    self._timeout = self._timeoutTotal 
    self._explorer:ChangeAnimatorState(CityExplorerStateDefine.AnimatorState.operate)
end

function CityExplorerStateInteractTarget:Tick(dt)
    CityExplorerState.Tick(self, dt)
    if self._timeout < 0 then
        self.stateMachine:ChangeState("CityExplorerStateIdle")
        return
    end
    self._timeout = self._timeout - dt
end

function CityExplorerStateInteractTarget:Exit()
    --self._explorer:SetSelectedShow(false)
    CityExplorerState.Exit(self)
end

return CityExplorerStateInteractTarget