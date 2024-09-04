---@obsolete 目前选用SETeamUnitCircleController
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local CityPathFinding = require("CityPathFinding")
local LayerMask = require("LayerMask")

---@class SETeamUnitSEController
---@field new fun():SETeamUnitSEController
local SETeamUnitSEController = class("SETeamUnitSEController")
local MOVE_MODE = {
    DONT_KEEP_FORMATION_ON_MOVE = 1,
    KEEP_FORMATION_ON_MOVE = 2,
}
local INFLECTION_DISTANCE = 1
local SESceneRoot = require("SESceneRoot")
local SEFormationHelper = require("SEFormationHelper")

---@param teamFormation SETeamFormation
function SETeamUnitSEController:ctor(teamFormation)
    self._formation = teamFormation
    self._team = self._formation._team
    self._moveMode = MOVE_MODE.KEEP_FORMATION_ON_MOVE
    self._rayCastAreaMask = CS.UnityEngine.AI.NavMesh.AllAreas
    if self._team._manager._env:GetEnvMode() == SEEnvironmentModeType.CityScene then
        self._rayCastAreaMask = CityPathFinding.AreaMask.CityAllWalkable
    else
        self._rayCastAreaMask = LayerMask.SEFloor
    end
end

function SETeamUnitSEController:Move(centerTargetPos, moveDir, opCode, dt)
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
function SETeamUnitSEController:DoUnitMove(unit, targetPos, centerRot)
    local centerSpeed = self._team:GetCenterMoveSpeed()
    local unitCurWorldPos = unit:GetActor():GetPosition()
    local path = {targetPos}
    if self._moveMode == MOVE_MODE.KEEP_FORMATION_ON_MOVE then
        local localOffset = self._formation._unitClientOffsetMap[unit._id]
        local worldOffset = centerRot * localOffset
        local nowFormationPos = self._formation._clientPos + worldOffset
        local isHit, navmeshHit = CS.UnityEngine.AI.NavMesh.Raycast(self._formation._clientPos, nowFormationPos, self._rayCastAreaMask)
        if isHit then
            local hitPos = navmeshHit.position
            local hitDir = hitPos - self._formation._clientPos
            local hitDirNormalized = hitDir.normalized
            local hitDistance = navmeshHit.distance
            nowFormationPos = hitPos - hitDirNormalized * math.min(hitDistance, 0.1)
        end

        local dirUnit2Target = (targetPos - unitCurWorldPos).normalized
        local dirUnit2Formation = (nowFormationPos - unitCurWorldPos).normalized
        local toNowFormationVec = unitCurWorldPos - nowFormationPos

        if toNowFormationVec.magnitude > INFLECTION_DISTANCE * SESceneRoot.GetClientScale()
            or CS.UnityEngine.Vector3.Dot(dirUnit2Target, dirUnit2Formation) < 0.866 then
            path = {targetPos, nowFormationPos}
        end
    end

    unit:GetLocomotion():SetMoveSpeed(centerSpeed)
    unit:GetController():SetTargetPath(path)
end

function SETeamUnitSEController:DoTick(dt)
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            self:DoUnitTick(unit, dt)
        end
    end
end

---@private
---@param unit SEUnit
function SETeamUnitSEController:DoUnitTick(unit, dt)
    if self._moveMode == MOVE_MODE.KEEP_FORMATION_ON_MOVE then
        local lookRotation = CS.UnityEngine.Quaternion.LookRotation(self._formation._dir, CS.UnityEngine.Vector3.up)
        local localOffset = self._formation._unitClientOffsetMap[unit._id]
        local worldOffset = lookRotation * localOffset
        local formationPos = self._formation._clientPos + worldOffset
        local unitCurWorldPos = unit:GetActor():GetPosition()
        if CS.UnityEngine.Vector3.Distance(unitCurWorldPos, formationPos) <= INFLECTION_DISTANCE * 0.2 * SESceneRoot.GetClientScale() then
            local targetPos = self._formation._unitClientTargetPosMap[unit._id]
            if targetPos then
                unit:GetController():SetTargetPath({self:FixedPos(targetPos)})
            end
        else
            local targetPos = self._formation._unitClientTargetPosMap[unit._id]
            if targetPos then
                unit:GetController():SetTargetPath({self:FixedPos(targetPos), self:FixedPos(formationPos)})
            end
        end
    elseif self._moveMode == MOVE_MODE.DONT_KEEP_FORMATION_ON_MOVE then
        local lookRotation = CS.UnityEngine.Quaternion.LookRotation(self._formation._dir, CS.UnityEngine.Vector3.up)
        local localOffset = self._formation._unitClientOffsetMap[unit._id]
        local worldOffset = lookRotation * localOffset
        local formationPos = self._formation._clientPos + worldOffset
        local dir2Form = (formationPos - unit:GetActor():GetPosition()).normalized
        local dir2Target = (self._formation._unitClientTargetPosMap[unit._id] - unit:GetActor():GetPosition()).normalized
        local basicSpeed = self._team:GetCenterMoveSpeed()
        local dot = CS.UnityEngine.Vector3.Dot(dir2Form, dir2Target)
        if dot < 0 then
            basicSpeed = (1 + dot) * basicSpeed
        end
        unit:GetLocomotion():SetMoveSpeed(basicSpeed)
    end
end

function SETeamUnitSEController:StopMove()
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            unit:GetLocomotion():Stop()
        end
    end
end

function SETeamUnitSEController:FixedPos(origin)
    local sample, result = CS.UnityEngine.AI.NavMesh.SamplePosition(origin, 1, CS.UnityEngine.AI.NavMesh.AllAreas)
    if sample then
        return result.position
    end
    return origin
end

return SETeamUnitSEController