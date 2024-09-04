local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local SESceneRoot = require("SESceneRoot")
local ConfigRefer = require("ConfigRefer")
local Quaternion = CS.UnityEngine.Quaternion

local CityExplorerPetState = require("CityExplorerPetState")

---@class CityExplorerPetStateFollow:CityExplorerPetState
---@field new fun(pet:CityUnitExplorerPet):CityExplorerPetStateFollow
---@field super CityExplorerPetState
local CityExplorerPetStateFollow = class("CityExplorerPetStateFollow", CityExplorerPetState)

function CityExplorerPetStateFollow:Enter()
    self._pet:ChangeAnimatorState("run")
    self._posOffSetLimit = 0.01
    self._pet:StopMove()
    CityExplorerPetStateFollow.super.Enter(self)
end

function CityExplorerPetStateFollow:Exit()
    CityExplorerPetStateFollow.super.Exit(self)
    self._pet:StopMove()
end

function CityExplorerPetStateFollow:Tick(dt)
    if self:CheckTransState() then
        return
    end
    local env = self._pet._seMgr._seEnvironment
    if not env then return end
    local unitMgr = env:GetUnitManager()
    if not unitMgr then return end
    ---@type SEHero
    local hero = unitMgr:GetUnit(self._pet._linkHeroId)
    if not hero then
        return
    end
    local cityPathfinding = self._pet._seMgr.city.cityPathFinding
    local locomotion = hero:GetLocomotion()
    local heroMoving = locomotion:IsMoving()
    local selfAgent= self._pet._moveAgent
    local pos = selfAgent._currentPosition
    local forward = locomotion:GetForward()
    local dir = CS.UnityEngine.Quaternion.LookRotation(forward)
    ---hero go 异步创建 可能有一帧取不到位置 取不到就不计算
    local heroPos = hero:GetActor():GetPosition()
    if not heroPos then return end
    local targetPos = CityExplorerTeamDefine.CalculatePetFollowUnitPosition(heroPos, dir, ConfigRefer.CityConfig.CitySePetFollowDistance and ConfigRefer.CityConfig:CitySePetFollowDistance())
    targetPos = cityPathfinding:NearestWalkableOnGraph(targetPos, cityPathfinding.AreaMask.CityGround)
    local offset = targetPos - pos
    local distance = offset.magnitude
    local petSpeed = locomotion:GetMoveSpeed() * SESceneRoot.GetClientScale()
    local dtLength = petSpeed * dt
    local specialRunLimit = petSpeed * 5
    if distance > self._posOffSetLimit then
        local runDir = offset.normalized
        if distance < dtLength then
            if not heroMoving then
                selfAgent:ManualTickMove(targetPos, dir)
                self.stateMachine:ChangeState("CityExplorerPetStateEnter")
            else
                selfAgent:ManualTickMove(targetPos, Quaternion.LookRotation(runDir))
            end
            return
        else
            if distance > specialRunLimit then
                targetPos = dtLength * 2 * runDir + pos
            else
                targetPos = dtLength * runDir + pos
            end
        end
        selfAgent:ManualTickMove(targetPos, Quaternion.LookRotation(runDir))
    else
        if not heroMoving then
            selfAgent:ManualTickMove(targetPos, dir)
            self.stateMachine:ChangeState("CityExplorerPetStateEnter")
        end
    end
end

function CityExplorerPetStateFollow:CheckTransState()
    if self._pet._needInBattleHide then
        self.stateMachine:ChangeState("CityExplorerPetStateHideInBattle")
        return true
    end
    if not self._pet._needFollow then
        self.stateMachine:ChangeState("CityExplorerPetStateEnter")
        return true
    end
    return false
end

return CityExplorerPetStateFollow