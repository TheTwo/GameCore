local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateWalking:CityUnitPetStateBase
local CityUnitPetStateWalking = class("CityUnitPetStateWalking", CityUnitPetStateBase)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local SyncToServerDelay = 2

function CityUnitPetStateWalking:Enter()
    self.unit:PickRandomTargetPosForWalk()
    self.unit:PlayMove()

    self.nextSyncCountdown = SyncToServerDelay
end

function CityUnitPetStateWalking:Exit()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
    self.nextRandomMoveDelay = nil
end

function CityUnitPetStateWalking:Tick(delta)
    if self.nextRandomMoveDelay == nil then
        if not self.unit._moveAgent._isMoving and self.unit.pathFindingHandle == nil then
            self.unit:ChangeAnimatorState(CityPetAnimStateDefine.Idle)
            self.nextRandomMoveDelay = math.random(5, 10)
            return
        end
    else
        self.nextRandomMoveDelay = self.nextRandomMoveDelay - delta
        if self.nextRandomMoveDelay <= 0 then
            self.nextRandomMoveDelay = nil
            self.unit:PickRandomTargetPosForWalk()
            self.unit:PlayMove()
        end
    end

    self.nextSyncCountdown = self.nextSyncCountdown - delta
    if self.nextSyncCountdown <= 0 then
        self.unit:PushCurrentPositionToServer()
        self.nextSyncCountdown = SyncToServerDelay
    end
end

return CityUnitPetStateWalking