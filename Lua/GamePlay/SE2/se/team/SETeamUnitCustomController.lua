---@obsolete 目前选用SETeamUnitCircleController
---@class SETeamUnitCustomController
---@field new fun(teamFormation):SETeamUnitCustomController
local SETeamUnitCustomController = class("SETeamUnitCustomController")
local SESceneRoot = require("SESceneRoot")
local ORCA_Agent = require("ORCA_Agent")
local ORCA_Simulator = require("ORCA_Simulator")
local Delegate = require("Delegate")
local DebugDrawGizmos = false
local SEFormationHelper = require("SEFormationHelper")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local CityPathFinding = require("CityPathFinding")
local LayerMask = require("LayerMask")
local LAYER_MASK_SE_FLOOR = 1 << 20

---@param teamFormation SETeamFormation
function SETeamUnitCustomController:ctor(teamFormation)
    self._formation = teamFormation
    self._team = self._formation._team
    self._radius = teamFormation:GetUnitRadius()
    self._simulator = ORCA_Simulator.new(self._team:GetCenterMoveSpeed(), 0.15)
    ---@type table<number, CS.UnityEngine.Vector3>
    self._unitTargetPos = {}
    ---@type table<number, CS.UnityEngine.Vector3>
    self._unitVelocity = {}
    ---@type table<number, ORCA_Agent>
    self._orcaAgents = {}
    ---@type ORCA_Agent[]
    self._aliveAgents = {}
    if self._team._manager._env:GetEnvMode() == SEEnvironmentModeType.CityScene then
        self._rayCastAreaMask = CityPathFinding.AreaMask.CityAllWalkable
    else
        self._rayCastAreaMask = LayerMask.SEFloor
    end
end

function SETeamUnitCustomController:Move(centerTargetPos, moveDir, opCode, dt)
    local centerRot = CS.UnityEngine.Quaternion.LookRotation(moveDir, CS.UnityEngine.Vector3.up)    
    table.clear(self._formation._unitClientTargetPosMap)
    for entityId, localOffset in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._formation._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            local worldOffset = centerRot * localOffset
            local targetPos = centerTargetPos + worldOffset
            local isHit, navmeshHit = CS.UnityEngine.AI.NavMesh.Raycast(centerTargetPos, targetPos, self._rayCastAreaMask)
            if isHit then
                local hitPos = navmeshHit.position
                local hitDir = hitPos - centerTargetPos
                local hitDirNormalized = hitDir.normalized
                local hitDistance = navmeshHit.distance
                targetPos = hitPos - hitDirNormalized * math.min(hitDistance, 0.1)
            end
            
            local unitIsHit, unitNavmeshHit = unit:GetLocomotion():HasObstacleBetween(targetPos)
            if unitIsHit then
                local hitPos = unitNavmeshHit.position
                local normal = unitNavmeshHit.normal
                local hitPos2D = CS.UnityEngine.Vector2(hitPos.x, hitPos.z)
                local tangent2D = CS.UnityEngine.Vector2(-normal.z, normal.x)
                local center2D = CS.UnityEngine.Vector2(self._formation._clientPos.x, self._formation._clientPos.z)
                local dir2D = CS.UnityEngine.Vector2(moveDir.x, moveDir.z)

                local intersect, point2D = SEFormationHelper.IsRaysIntersecting(center2D, dir2D, hitPos2D, tangent2D)
                if not intersect then
                    intersect, point2D = SEFormationHelper.IsRaysIntersecting(center2D, dir2D, hitPos2D, -tangent2D)
                end

                if intersect then
                    targetPos = CS.UnityEngine.Vector3(point2D.x, targetPos.y, point2D.y)

                    local ray = CS.UnityEngine.Ray(CS.UnityEngine.Vector3(point2D.x, 5000, point2D.y), CS.UnityEngine.Vector3.down)
                    local result, point = CS.RaycastHelper.PhysicsRaycastRayHitWithMask(ray, 9999, self._rayCastAreaMask)
                    if result then
                        targetPos = point
                        local sample, sampleNavmeshHit = CS.UnityEngine.AI.NavMesh.SamplePosition(targetPos, 1, CS.UnityEngine.AI.NavMesh.AllAreas)
                        if sample then
                            targetPos = sampleNavmeshHit.position
                        end
                    end
                end
            end

            self._formation._unitClientTargetPosMap[entityId] = targetPos
            self:DoUnitMove(unit, targetPos, centerRot)
        end
    end
end

---@param unit SEUnit
---@param targetPos CS.UnityEngine.Vector3
---@param centerRot CS.UnityEngine.Quaternion
function SETeamUnitCustomController:DoUnitMove(unit, targetPos, centerRot)
    self._unitTargetPos[unit._id] = targetPos
    unit:GetController():StopMove()
    unit:GetStateMachine():OnMove()

    if DebugDrawGizmos and UNITY_EDITOR then
        g_Game:AddOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    end
end

---@param unit SEUnit
function SETeamUnitCustomController:DoTick(dt)
    table.clear(self._unitVelocity)
    table.clear(self._aliveAgents)
    local centerSpeed = self._team:GetCenterMoveSpeed()
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            local unitCurWorldPos = unit:GetActor():GetPosition()
            local targetPos = self._unitTargetPos[entityId]
            if CS.UnityEngine.Vector3.Distance(unitCurWorldPos, targetPos) <= SESceneRoot.GetClientScale() then
                self._unitVelocity[entityId] = CS.UnityEngine.Vector3.zero
            else
                local dist = targetPos - unitCurWorldPos
                local maxSpeed = dist.magnitude * SESceneRoot.GetClientScale() / dt
                self._unitVelocity[entityId] = dist.normalized * math.min(centerSpeed, maxSpeed)
            end

            local agent = self._orcaAgents[entityId]
            if not agent then
                agent = ORCA_Agent.new(entityId, self._radius, CS.UnityEngine.Vector2(unitCurWorldPos.x, unitCurWorldPos.z), CS.UnityEngine.Vector2(self._unitVelocity[entityId].x, self._unitVelocity[entityId].z))
                self._orcaAgents[entityId] = agent
            else
                self._orcaAgents[entityId]:UpdatePosition(CS.UnityEngine.Vector2(unitCurWorldPos.x, unitCurWorldPos.z))
                self._orcaAgents[entityId]:UpdatePrefVelocity(CS.UnityEngine.Vector2(self._unitVelocity[entityId].x, self._unitVelocity[entityId].z))
            end

            table.insert(self._aliveAgents, agent)
        end
    end

    self._simulator._timeHorizon = dt
    self._simulator:CalculateNewVelocity(self._aliveAgents, dt, Delegate.GetOrCreate(self, self.SkipPetToHero))

    for _, agent in ipairs(self._aliveAgents) do
        local newVelocity = CS.UnityEngine.Vector3(agent._newVelocity.x, 0, agent._newVelocity.y)
        local unit = self._team:GetUnitMember(agent._id)
        local lastRot = unit:GetActor():GetForward()
        local newForward = CS.UnityEngine.Vector3.Slerp(lastRot, newVelocity.normalized, 20 * dt)
        unit:GetActor():SetForward(newForward, 0)
        local oldPos = unit:GetActor():GetPosition()
        local newPos = oldPos + newVelocity * (SESceneRoot.GetClientScale() * dt)
        unit:GetActor():SetServerPosition(newPos)
        unit:GetActor():SetPosition(newPos)
        
        if UNITY_EDITOR then
            CS.UnityEngine.Debug.DrawLine(oldPos, oldPos + (newVelocity * SESceneRoot.GetClientScale()), CS.UnityEngine.Color.green, 0.02)
            CS.UnityEngine.Debug.DrawLine(oldPos, newPos, CS.UnityEngine.Color.red, 0.15)
        end
    end
end

function SETeamUnitCustomController:StopMove()
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            unit:GetActor():SetMoveForward(nil)
            unit:GetStateMachine():OnIdle()
        end
    end

    if DebugDrawGizmos and UNITY_EDITOR then
        g_Game:RemoveOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    end
end

function SETeamUnitCustomController:OnDrawGizmos()
    local radius = self._formation:GetUnitRadius()
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            CS.UnityEngine.Gizmos.color = CS.UnityEngine.Color.green
            CS.UnityEngine.Gizmos.DrawSphere(unit:GetActor():GetPosition(), radius)
        end
    end
end

function SETeamUnitCustomController:SkipPetToHero(heroId, petId)
    local hero = self._team:GetUnitMember(heroId)
    local pet = self._team:GetUnitMember(petId)
    return hero:IsHero() and not pet:IsHero()
end

return SETeamUnitCustomController