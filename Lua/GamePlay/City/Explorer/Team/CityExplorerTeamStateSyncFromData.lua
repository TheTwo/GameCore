local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")

local CityExplorerTeamState = require("CityExplorerTeamState")

---@class CityExplorerTeamStateSyncFromData:CityExplorerTeamState
---@field new fun(team:CityExplorerTeam):CityExplorerTeamStateSyncFromData
---@field super CityExplorerTeamState
local CityExplorerTeamStateSyncFromData = class('CityExplorerTeamStateSyncFromData', CityExplorerTeamState)

function CityExplorerTeamStateSyncFromData:Fire()
    if self._team._teamData:HasTarget() and self._team._teamData:IsInMoving() then
        self.stateMachine:ChangeState("CityExplorerTeamStateGoToTarget")
        return
    end
    if self._team._teamData:HasTarget() then
        self.stateMachine:ChangeState("CityExplorerTeamStateInteractTarget")
    else
        self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
    end
end

function CityExplorerTeamStateSyncFromData:Enter()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.MapStates.Moving.MsgPath, Delegate.GetOrCreate(self, self.OnEntityMoveStatusChanged))
end

function CityExplorerTeamStateSyncFromData:Exit()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.MapStates.Moving.MsgPath, Delegate.GetOrCreate(self, self.OnEntityMoveStatusChanged))
end

---@param entity wds.Hero
function CityExplorerTeamStateSyncFromData:OnEntityMoveStatusChanged(entity, _)
    local currentFocusOnHero = self._team._teamData:GetEntity()
    if not currentFocusOnHero or currentFocusOnHero.ID ~= entity.ID  then return end
    self:Fire()
end

return CityExplorerTeamStateSyncFromData

