local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateEating:CityUnitPetStateBase
local CityUnitPetStateEating = class("CityUnitPetStateEating", CityUnitPetStateBase)
local Utils = require("Utils")

function CityUnitPetStateEating:Enter()
    self:PlayEatingAnimation()
    local eatingTime = 2
    if Utils.IsNotNull(self.unit._animator) then
        local state = self.unit._animator:GetCurrentAnimatorStateInfo(0)
        eatingTime = state.length
    end

    self.exitTime = g_Game.RealTime.time + eatingTime
    self.startTime = g_Game.RealTime.time
    if self.unit.statusHandle then
        self.unit.statusHandle:ShowEatting(0)
    end
end

function CityUnitPetStateEating:Tick()
    local progress = (g_Game.RealTime.time - self.startTime) / (self.exitTime - self.startTime)
    if self.unit.statusHandle then
        self.unit.statusHandle:ShowEatting(progress)
    end

    if g_Game.RealTime.time > self.exitTime then
        self.unit:SyncFromServer()
    end
end

function CityUnitPetStateEating:Exit()
    if self.unit.statusHandle then
        self.unit.statusHandle:HideEatting()
    end
end

function CityUnitPetStateEating:PlayEatingAnimation()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
    self.unit:PlayNormalAnimState(CityPetAnimStateDefine.Eat)
end

return CityUnitPetStateEating