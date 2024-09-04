local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateSleeping:CityUnitPetStateBase
local CityUnitPetStateSleeping = class("CityUnitPetStateSleeping", CityUnitPetStateBase)

function CityUnitPetStateSleeping:Enter()
    local moveTime = self.unit.petData:GetCurrentActionMovingTime()
    if moveTime > 0 then
        self.checkMoving = true
        self.unit:PlayMove()
    else
        self:PlaySleepingAnimation()
        self.unit:LoadZZZEffect()
    end
end

function CityUnitPetStateSleeping:Exit()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
    self.unit:UnloadZZZEffect()
end

function CityUnitPetStateSleeping:Tick()
    if self.checkMoving then
        if self.unit._moveAgent._isMoving or self.unit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self:PlaySleepingAnimation()
    end
end

function CityUnitPetStateSleeping:PlaySleepingAnimation()
    self.unit:SyncAnimatorSpeed()
    self.unit:PlayLoopState(CityPetAnimStateDefine.Idle)
end

function CityUnitPetStateSleeping:OnModelReady()
    self.unit:LoadZZZEffect()
end

return CityUnitPetStateSleeping