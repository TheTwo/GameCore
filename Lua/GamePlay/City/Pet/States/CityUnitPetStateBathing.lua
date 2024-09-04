local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateBathing:CityUnitPetStateBase
local CityUnitPetStateBathing = class("CityUnitPetStateBathing", CityUnitPetStateBase)

function CityUnitPetStateBathing:Enter()
    local moveTime = self.unit.petData:GetCurrentActionMovingTime()
    if moveTime > 0 then
        self.checkMoving = true
        self.unit:PlayMove()
    else
        self:PlayBathingAnimation()
    end
end

function CityUnitPetStateBathing:Exit()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
end

function CityUnitPetStateBathing:Tick()
    if self.checkMoving then
        if self.unit._moveAgent._isMoving or self.unit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self:PlayBathingAnimation()
    end
end

function CityUnitPetStateBathing:PlayBathingAnimation()
    self.unit:SyncAnimatorSpeed()
    self.unit:PlayLoopState(CityPetAnimStateDefine.Bath)
end

return CityUnitPetStateBathing