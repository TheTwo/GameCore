local ConfigRefer = require("ConfigRefer")

local CityExplorerPetStateBase = require("CityExplorerPetStateBase")

---@class CityExplorerPetSubStateGotoWork:CityExplorerPetStateBase
---@field new fun(pet:CityUnitExplorerPet, host:CityExplorerPetStateCollect):CityExplorerPetSubStateGotoWork
---@field super CityExplorerPetStateBase
local CityExplorerPetSubStateGotoWork = class("CityExplorerPetSubStateGotoWork", CityExplorerPetStateBase)

function CityExplorerPetSubStateGotoWork:ctor(pet, host)
    CityExplorerPetSubStateGotoWork.super.ctor(self, pet)
    self._host = host
    self._speedMutli = ConfigRefer.CityConfig:CitySePetCollectSpeedMutli()
end

function CityExplorerPetSubStateGotoWork:Enter()
    self._elementId = self.stateMachine:ReadBlackboard("ElementId")
    ---@type CityInteractPoint_Impl
    self._targetInfo = self.stateMachine:ReadBlackboard("CollectResource")
    local pet = self._pet
    pet:StopMove()
    local targetPos = self._targetInfo:GetWorldPos()
    if pet._moveAgent._currentPosition then
        local targetDistance = (targetPos - pet._moveAgent._currentPosition).sqrMagnitude
        if targetDistance <= pet._moveAgent.MoveEpsilon then
            return
        end
    end
    pet:SetTempSpeedMutli(self._speedMutli)
    pet:SetIsRunning(true)
    pet:MoveToTargetPos(targetPos)
end

function CityExplorerPetSubStateGotoWork:Tick(dt)
    if not self._pet._hasTargetPos then
        self.stateMachine:WriteBlackboard("ElementId", self._elementId)
        self.stateMachine:WriteBlackboard("CollectResource", self._targetInfo)
        self.stateMachine:ChangeState("CityExplorerPetSubStateDoWork")
    end
end

function CityExplorerPetSubStateGotoWork:Exit()
    self._pet:SetTempSpeedMutli()
    self._pet:StopMove()
    if self._targetInfo and self._targetInfo.worldRotation then
        self._pet._moveAgent:StopMoveTurnToRotation(CS.UnityEngine.Quaternion.LookRotation(self._targetInfo.worldRotation))
    end
end

return CityExplorerPetSubStateGotoWork