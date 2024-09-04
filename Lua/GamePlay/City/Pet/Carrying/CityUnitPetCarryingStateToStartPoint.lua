local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetCarryingStateToStartPoint:CityUnitPetStateBase
local CityUnitPetCarryingStateToStartPoint = class("CityUnitPetCarryingStateToStartPoint", CityUnitPetStateBase)

function CityUnitPetCarryingStateToStartPoint:Enter()
    if not self.unit.petData:IsMovingToStartPoint() then
        self.dirty = true
        return
    end
       
    self.checkMoving = true
    self.unit:PlayMove()
end

function CityUnitPetCarryingStateToStartPoint:Exit()
    self.dirty = false
    self.checkMoving = false
end

function CityUnitPetCarryingStateToStartPoint:Tick()
    if self.dirty then
        self.stateMachine:ChangeState("route")
        return
    end

    if self.checkMoving then
        if self.unit._moveAgent._isMoving or self.unit:IsFindingPath() then
            return
        end

        self.checkMoving = false
        self.stateMachine:ChangeState("route")
    end
end

return CityUnitPetCarryingStateToStartPoint