local CityCitizenDefine = require("CityCitizenDefine")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSubRandomTarget:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubRandomTarget
---@field super CityCitizenState
local CityCitizenStateSubRandomTarget = class('CityCitizenStateSubRandomTarget', CityCitizenState)

function CityCitizenStateSubRandomTarget:Enter()
    local targetPos
    if not self:IsAssigned() then
        targetPos = self._citizen._pathFinder:RandomPositionInExploredZoneWithInSafeArea(self._citizen._pathFinder.AreaMask.CityGround)
    else
        local x,z,sX,sZ,areaMask = self:GetAssignedArea()
        if x and z and sX and sZ and areaMask then
            targetPos = self._citizen._pathFinder:RandomPositionInRange(x,z,sX, sZ, areaMask)
        else
            targetPos = self._citizen._pathFinder:RandomPositionInExploredZoneWithInSafeArea(self._citizen._pathFinder.AreaMask.CityGround)
        end
    end
    self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetPos, targetPos)
    self.stateMachine:ChangeState("CityCitizenStateSubGoToTarget")
end

return CityCitizenStateSubRandomTarget

