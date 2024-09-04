local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetSubStateMoving:CityUnitPetStateBase
local CityUnitPetSubStateMoving = class("CityUnitPetSubStateMoving", CityUnitPetStateBase)
local Delegate = require("Delegate")

function CityUnitPetSubStateMoving:Enter()
    local targetPos = self.unit.targetPos
    local targetRotation = self.unit.targetRotation
    self.unit:MoveToTargetPos(targetPos, targetRotation, Delegate.GetOrCreate(self, self.OnMoveStart))
    self.targetPos = targetPos
    self.targetRotation = targetRotation
end

function CityUnitPetSubStateMoving:OnMoveStart()
    self.unit:SyncAnimatorSpeed()
    if self.unit.isCarring then
        self.unit:ChangeAnimatorState(CityPetAnimStateDefine.Transport)
    elseif self.unit.isRun then
        self.unit:ChangeAnimatorState(CityPetAnimStateDefine.Run)
    else
        self.unit:ChangeAnimatorState(CityPetAnimStateDefine.Walk)
    end
end

function CityUnitPetSubStateMoving:Exit()
    if CS.UnityEngine.Vector3.Distance(self.unit._moveAgent._currentPosition, self.targetPos) < 0.5 then
        self.unit:StopMove(self.targetPos, self.targetRotation)
    else
        self.unit:StopMove()
    end
    self.unit:SyncAnimatorSpeed()
    self.targetPos = nil
    self.targetRotation = nil
end

function CityUnitPetSubStateMoving:ReEnter()
    self:Exit()
    self:Enter()
end

return CityUnitPetSubStateMoving