local Delegate = require("Delegate")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateWorking:CityUnitPetStateBase
local CityUnitPetStateWorking = class("CityUnitPetStateWorking", CityUnitPetStateBase)
local Vector3 = CS.UnityEngine.Vector3

function CityUnitPetStateWorking:Enter()
    local moveTime = self.unit.petData:GetCurrentActionMovingTime()
    if moveTime > 0 then
        self.checkMoving = true
        self.unit:PlayMove()
    else
        self:BlinkToTargetPos()
        self:PlayWorkAnimation()
    end
end

function CityUnitPetStateWorking:Exit()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
    self.unit:ReleaseCustomDrama()
end

function CityUnitPetStateWorking:Tick(dt)
    if self.checkMoving then
        if self.unit._moveAgent._isMoving or self.unit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self:PlayWorkAnimation()
    end
end

function CityUnitPetStateWorking:PlayWorkAnimation()
    self.unit:SyncAnimatorSpeed()
    local manager = self.unit:GetManager()
    local dramaHandle = manager:GetCustomDramaHandle(self.unit)
    if dramaHandle == nil then
        local animName = self.unit:GetWorkAnimName()
        self.unit:PlayLoopState(animName)
    else
        self.unit:SetupCustomDrama(dramaHandle)
    end
end

function CityUnitPetStateWorking:BlinkToTargetPos()
    self.unit:StopMove(self.unit.petData:GetWorkTargetPos())
end

function CityUnitPetStateWorking:GetCurrentActionMovingTime()
    return self.unit.petData:GetCurrentActionMovingTime()
end

function CityUnitPetStateWorking:ReEnter()
    self:Exit()
    self:Enter()
end

return CityUnitPetStateWorking