local SESceneRoot = require("SESceneRoot")
local DBEntityType = require("DBEntityType")

local SETeamSubUnitState = require("SETeamSubUnitState")

---@class SETeamSubStateRoute:SETeamSubUnitState
---@field new fun():SETeamSubStateRoute
---@field super SETeamSubUnitState
local SETeamSubStateRoute = class('SETeamSubStateRoute', SETeamSubUnitState)

function SETeamSubStateRoute:Tick()
    local status = self.logic._currentStatus
    if status.isInteract and not string.IsNullOrEmpty(status.uniqueName) then
        ---@type wds.SeInteractor
        local entity = g_Game.DatabaseManager:GetEntity(status.interactId, DBEntityType.SeInteractor)
        if not entity then return end
        local targetPos = self._team:GetEnvironment():ServerPos2Client(CS.UnityEngine.Vector3(entity.MapBasics.Position.X, entity.MapBasics.Position.Y, entity.MapBasics.Position.Z))
        local currentPos = self.seUnit:GetActor():GetPosition()
        local radius = status.config:Distance() * SESceneRoot.GetClientScale()
        if self:IsCloseEnough(targetPos, currentPos, radius) then
            self.stateMachine:ChangeState("SETeamSubStateCollect")
            return
        end
        self.stateMachine:WriteBlackboard("TargetPos", targetPos, true)
        self.stateMachine:WriteBlackboard("TargetRadius", radius, true)
        self.stateMachine:ChangeState("SETeamSubStateMove")
        return
    end
    self.stateMachine:ChangeState("SETeamSubStateIdle")
end

return SETeamSubStateRoute