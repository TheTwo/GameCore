local State = require("State")
local CityCitizenStateHelper = require("CityCitizenStateHelper")

---@class CityCitizenState:State
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenState
---@field super State
local CityCitizenState = class('CityCitizenState', State)

---@param cityUnitCitizen CityUnitCitizen
function CityCitizenState:ctor(cityUnitCitizen)
    ---@type CityUnitCitizen
    self._citizen = cityUnitCitizen
    ---@type CityCitizenState
    self._parent = nil
end

---@param stateMachine StateMachine
function CityCitizenState:SetSubStateMachine(stateMachine)
    self._subStateMachine = stateMachine
end

function CityCitizenState:IsAssigned()
    return self._citizen._data:IsAssignedHouse()
end

---@return number,number,number,number,number @x,z,sX,sZ,areaMask
function CityCitizenState:GetAssignedArea()
    return self._citizen._data:GetAssignedArea()
end

function CityCitizenState:HasWorkTask()
    return self._citizen._data._workId ~= 0
end

function CityCitizenState:IsFainting()
    return self._citizen._data:IsFainting()
end

function CityCitizenState:IsCurrentWorkValid()
    return CityCitizenStateHelper.IsCurrentWorkValid(self._citizen._data)
end

---@return CityCitizenTargetInfo
function CityCitizenState:GetTargetInfo()
    local workData = self._citizen._data:GetWorkData()
    if workData then
        local targetId, targetType = workData:GetTarget()
        ---@type CityCitizenTargetInfo
        local ret = {}
        ret.id = targetId
        ret.type = targetType
        return ret
    end
    return nil
end

---@param gridRange CityPathFindingGridRange
function CityCitizenState:OnWalkableChangedCheck(gridRange)
    if not self._subStateMachine then
        return
    end
    ---@type CityCitizenState
    local state = self._subStateMachine.currentState
    if state then
        state:OnWalkableChangedCheck(gridRange)
    end
end

---@param targetId number
---@param targetType number
---@see CityWorkTargetType
function CityCitizenState:OnWorkTargetChanged(targetId, targetType)
    if not self._subStateMachine then
        return
    end
    ---@type CityCitizenState
    local state = self._subStateMachine:GetCurrentState()
    if state then
        state:OnWorkTargetChanged(targetId, targetType)
    end
end

function CityCitizenState:OnDrawGizmos()
    if not self._subStateMachine then
        return
    end
    ---@type CityCitizenState
    local state = self._subStateMachine:GetCurrentState()
    if state then
        state:OnDrawGizmos()
    end
end

function CityCitizenState:SyncInfectionVfx()
    self._citizen:SyncInfectionVfx()
end

function CityCitizenState:OnUnitAssetLoaded()
    
end

return CityCitizenState

