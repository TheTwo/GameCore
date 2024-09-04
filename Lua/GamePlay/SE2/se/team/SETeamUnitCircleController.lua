---@class SETeamUnitCircleController
---@field new fun():SETeamUnitCircleController
local SETeamUnitCircleController = class("SETeamUnitCircleController")
local SESceneRoot = require("SESceneRoot")
local ConfigRefer = require("ConfigRefer")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local CityPathFinding = require("CityPathFinding")
local LayerMask = require("LayerMask")
local SEUnitStateType = require("SEUnitStateType")
local LookRotation = CS.UnityEngine.Quaternion.LookRotation
local RotateTowards = CS.UnityEngine.Quaternion.RotateTowards
local MoveTowards = CS.UnityEngine.Vector3.MoveTowards

---@param teamFormation SETeamFormation
function SETeamUnitCircleController:ctor(teamFormation)
    self._formation = teamFormation
    self._team = teamFormation._team
    ---@type CS.UnityEngine.Vector3
    self._direction = nil
    self._rotSpeed = ConfigRefer.ConstSe:CircleFormationCenterAngleSpeed()
    if self._rotSpeed == 0 then
        self._rotSpeed = 180
    end
    self._unitRotSpeed = ConfigRefer.ConstSe:CircleFormationUnitAngleSpeed()
    if self._unitRotSpeed == 0 then
        self._unitRotSpeed = 720
    end
    self._unitMoveSpeedMulti = ConfigRefer.ConstSe:CircleFormationUnitVelocityMulti()
    if self._unitMoveSpeedMulti == 0 then
        self._unitMoveSpeedMulti = 1.2
    end
    self._unitSmoothVelocity = {}
    self._unitDirection = {}
    self._unitDefaultDist = ConfigRefer.ConstSe:SEPetFormationDis() * SESceneRoot.GetClientScale()
    self._unitCanMove = {}
    if self._team._manager._env:GetEnvMode() == SEEnvironmentModeType.CityScene then
        self._rayCastAreaMask = CityPathFinding.AreaMask.CityAllWalkable
    else
        self._rayCastAreaMask = LayerMask.SEFloor
    end
end

function SETeamUnitCircleController:Move(centerTargetPos, moveDir, opCode, dt)
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        if self._unitDirection[entityId] == nil then
            self._unitDirection[entityId] = LookRotation(moveDir, CS.UnityEngine.Vector3.up)
        end 
    end

    if opCode == wrpc.MoveStickOpType.MoveStickOpType_StartMove then
        for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
            local unit = self._team:GetUnitMember(entityId)
            if unit and not unit:IsDead() then
                unit:GetController():StopMove()
                self._formation._team:GetEnvironment():GetSkillManager():ManualLocalCancelSkillToAttackerSelf(unit)
                self._unitCanMove[entityId] = self._formation:IsUnitCanMove(unit)
                if self._unitCanMove[entityId] then
                    self:DoUnitStatemachineMove(unit)
                end
            end
        end
    end
end

function SETeamUnitCircleController:DoTick(dt)
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            local unitCanMove = self._formation:IsUnitCanMove(unit)
            self._unitCanMove[entityId] = unitCanMove
            if unitCanMove then
                self:DoUnitStatemachineMove(unit)
            else
                self:DoUnitStatemachineStop(unit)
            end
            self:DoUnitTick(unit, dt)
        end
    end
end

---@param unit SEUnit
function SETeamUnitCircleController:DoUnitStatemachineMove(unit)
    local stateMachine = unit:GetStateMachine()
    if stateMachine and stateMachine:GetState() ~= SEUnitStateType.Move then
        stateMachine:OnMove()
    end
end

function SETeamUnitCircleController:DoUnitStatemachineStop(unit)
    local stateMachine = unit:GetStateMachine()
    if stateMachine and stateMachine:GetState() ~= SEUnitStateType.Idle then
        stateMachine:OnStop()
    end
end

---@param unit SEUnit
function SETeamUnitCircleController:DoUnitTick(unit, dt)
    local localOffset = self._formation._unitClientOffsetMap[unit._id]
    local offsetLength = localOffset.magnitude
    local angleSpeedMulti = 1
    if offsetLength > 0 then
        angleSpeedMulti = math.min(1, self._unitDefaultDist / localOffset.magnitude)
    end
    
    local toRot = LookRotation(self._formation._dir, CS.UnityEngine.Vector3.up)
    if self._unitDirection[unit._id] ~= nil then
        local curRot = RotateTowards(self._unitDirection[unit._id], toRot, self._rotSpeed * angleSpeedMulti * dt)
        self._unitDirection[unit._id] = curRot
    else
        self._unitDirection[unit._id] = toRot
    end

    local worldOffset = self._unitDirection[unit._id] * localOffset
    local formationPos = self._formation._clientPos + worldOffset
    local isHit, navmeshHit = CS.UnityEngine.AI.NavMesh.Raycast(self._formation._clientPos, formationPos, self._rayCastAreaMask)
    if isHit then
        local hitPos = navmeshHit.position
        local hitDir = hitPos - self._formation._clientPos
        local hitDirNormalized = hitDir.normalized
        local hitDistance = navmeshHit.distance
        formationPos = hitPos - hitDirNormalized * math.min(hitDistance, 0.1)
    end

    local unitCurWorldPos = unit:GetActor():GetPosition()
    local endPos = MoveTowards(unitCurWorldPos, formationPos, self._team:GetCenterMoveSpeed() * self._unitMoveSpeedMulti * SESceneRoot.GetClientScale() * dt)
    local fixedEndPos = self:FixPos(endPos)
    local forward = (fixedEndPos - unitCurWorldPos)
    forward.y = 0
    local forward = forward.normalized
    local curForward = unit:GetActor():GetForward()
    local from = LookRotation(curForward, CS.UnityEngine.Vector3.up)
    local to
    if forward.sqrMagnitude == 0 then
        to = from
    else
        to = LookRotation(forward, CS.UnityEngine.Vector3.up)
    end
    self._unitSmoothVelocity[unit._id] = self._unitSmoothVelocity[unit._id] or 0
    local yValue, newVelocity = CS.UnityEngine.Mathf.SmoothDampAngle(from.eulerAngles.y, to.eulerAngles.y, self._unitSmoothVelocity[unit._id], 0.1, self._unitRotSpeed, dt)
    self._unitSmoothVelocity[unit._id] = newVelocity
    local rot = CS.UnityEngine.Quaternion.Euler(0, yValue, 0)
    local newForward = rot * CS.UnityEngine.Vector3.forward
    self._formation._unitClientTargetPosMap[unit._id] = fixedEndPos

    if self._unitCanMove[unit._id] then
        unit:GetActor():SetMoveForward(newForward)
        unit:GetActor():SetForward(newForward)
        unit:GetActor():SetPosition(fixedEndPos)
        unit:GetActor():SetServerPosition(fixedEndPos)
    end
end

function SETeamUnitCircleController:StopMove()
    for entityId, _ in pairs(self._formation._unitClientOffsetMap) do
        local unit = self._team:GetUnitMember(entityId)
        if unit and not unit:IsDead() then
            unit:GetActor():SetMoveForward(nil)
            if self._unitCanMove[entityId] then
                unit:GetStateMachine():OnStop()
            end
        end
    end
    self._direction = self._formation._dir
    for entityId, _ in pairs(self._unitSmoothVelocity) do
        self._unitSmoothVelocity[entityId] = 0
    end
end

function SETeamUnitCircleController:FixPos(origin)
    local sample, result = CS.UnityEngine.AI.NavMesh.SamplePosition(origin, 1, CS.UnityEngine.AI.NavMesh.AllAreas)
    if sample then
        return result.position
    end
    return origin
end

return SETeamUnitCircleController