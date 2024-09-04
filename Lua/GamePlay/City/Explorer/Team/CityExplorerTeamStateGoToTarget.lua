local CityExplorerStateDefine = require("CityExplorerStateDefine")
local EventConst = require("EventConst")

local CityExplorerTeamState = require("CityExplorerTeamState")

---@class CityExplorerTeamStateGoToTarget:CityExplorerTeamState
---@field new fun(team:CityExplorerTeam):CityExplorerTeamStateGoToTarget
---@field super CityExplorerTeamState
local CityExplorerTeamStateGoToTarget = class('CityExplorerTeamStateGoToTarget', CityExplorerTeamState)

function CityExplorerTeamStateGoToTarget:Enter()
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_LEAVE_EVENT_TRIGGER,nil, true, self._team._teamPresetIdx + 1)
end

function CityExplorerTeamStateGoToTarget:Tick(dt)
    if not self._team._teamData:IsInMoving() then
        if self._team._teamData:IsTargetGround() then
            self._team._teamData:ResetTarget()
            self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
        elseif self._team._teamData:HasTarget() then
            local targetId = self._team._teamData:GetTargetIdAndReset()
            self.stateMachine:WriteBlackboard(CityExplorerStateDefine.BlackboardKey.TargetId, targetId)
            self.stateMachine:ChangeState("CityExplorerTeamStateInteractTarget")
        end
    end
end

return CityExplorerTeamStateGoToTarget

