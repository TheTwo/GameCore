local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetCarryingStateToEndPoint:CityUnitPetStateBase
local CityUnitPetCarryingStateToEndPoint = class("CityUnitPetCarryingStateToEndPoint", CityUnitPetStateBase)

function CityUnitPetCarryingStateToEndPoint:Enter()
    if not self.unit.petData:IsCurrentActionValid() then
        self.dirty = true
        return
    end

    self.checkMoving = true
    self.unit:PlayMove()
end

function CityUnitPetCarryingStateToEndPoint:Exit()
    self.dirty = false
    self.checkMoving = false
end

function CityUnitPetCarryingStateToEndPoint:Tick()
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

return CityUnitPetCarryingStateToEndPoint