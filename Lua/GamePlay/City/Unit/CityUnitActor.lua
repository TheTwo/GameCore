local Utils = require("Utils")
local UnitActor = require("UnitActor")

---@class CityUnitActor:UnitActor
---@field new fun(id:number, type:UnitActorType):CityUnitActor
---@field super UnitActor
local CityUnitActor = class('CityUnitActor', UnitActor)

function CityUnitActor:ctor(id, type)
    UnitActor.ctor(self, id, type)
    ---@type string
    self._state = nil
end

---@param asset string
---@param creator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param moveAgent UnitMoveAgent
---@param config UnitActorConfigWrapper
---@param pathFinder CityPathFinding
---@param pathHeightFixer fun(pos:CS.UnityEngine.Vector3):CS.UnityEngine.Vector3
function CityUnitActor:Init(asset, creator, moveAgent, config, pathFinder, pathHeightFixer)
    UnitActor.Init(self, asset, creator)
    self._config = config
    self._moveAgent = moveAgent
    self._pathFinder = pathFinder
    self._pathHeightFixer = pathHeightFixer
end

function CityUnitActor:Tick(detla)
    UnitActor.Tick(self, detla)
    local agent = self._moveAgent
    if not agent.Dirty then
        return
    end
    if not self.model or not self.model:IsReady() then
        return
    end
    agent.Dirty = false
    local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
    self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)
end

function CityUnitActor:SyncMoveAgentPosToModel()
    if not self.model or not self.model:IsReady() then
        return
    end
    local agent = self._moveAgent
    local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
    self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)
end

---@param state string
function CityUnitActor:ChangeAnimatorState(state)
    if self._state == state then
        return
    end
    self._state = state
    if self._animatorCount <= 1 then
        if Utils.IsNotNull(self._animator) and self._animator.isActiveAndEnabled then
            self._animator:CrossFadeInFixedTime(self._state, self._config:StateCrossfadeTime())
        end
    else
        for i, animator in ipairs(self._animators) do
            if Utils.IsNotNull(animator) and animator.isActiveAndEnabled then
                animator:CrossFadeInFixedTime(self._state, self._config:StateCrossfadeTime())
            end
        end
    end
end

function CityUnitActor:GetCurrentAnimationNormalizedTime()
    if self._state and Utils.IsNotNull(self._animator) and self._animator.isActiveAndEnabled then
        local info = self._animator:GetCurrentAnimatorStateInfo(0)
        if info then
            return info.normalizedTime, info.loop
        end
    end
    return 0
end

function CityUnitActor:RestartCurrentAnimation()
    if self._animatorCount <= 1 then
        if self._state and Utils.IsNotNull(self._animator) and self._animator.isActiveAndEnabled then
            self._animator:Play(self._state, 0, 0)
        end
    else
        for i, animator in ipairs(self._animators) do
            if Utils.IsNotNull(animator) and animator.isActiveAndEnabled then
                animator:Play(self._state, 0, 0)
            end
        end
    end
end

function CityUnitActor:PlaySound(audioResId)
    if not self.model or not self.model:IsReady() then
        return
    end
    return g_Game.SoundManager:PlayAudio(audioResId, self.model._go)
end

function CityUnitActor:SetIsHide(isHide)
    local lastStatus = self._isHide
    UnitActor.SetIsHide(self, isHide)
    if lastStatus and not isHide then
        if self._animatorCount <= 1 then
            if Utils.IsNotNull(self._animator) then
                self._animator:CrossFadeInFixedTime(self._state, 0)
            end
        else
            for i, animator in ipairs(self._animators) do
                if Utils.IsNotNull(animator) then
                    animator:CrossFadeInFixedTime(self._state, 0)
                end
            end
        end
    end
end

return CityUnitActor