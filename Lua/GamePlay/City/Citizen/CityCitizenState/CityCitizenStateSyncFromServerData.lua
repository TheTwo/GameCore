local CityCitizenDefine = require("CityCitizenDefine")
local ConfigRefer = require("ConfigRefer")
local CityWorkTargetType = require("CityWorkTargetType")
local CityCitizenState = require("CityCitizenState")
local CityWorkHelper = require("CityWorkHelper")

---@class CityCitizenStateSyncFromServerData:CityCitizenState
---@field new fun():CityCitizenStateSyncFromServerData
---@field super CityCitizenState
local CityCitizenStateSyncFromServerData = class('CityCitizenStateSyncFromServerData', CityCitizenState)

---@param cityUnitCitizen CityUnitCitizen
function CityCitizenStateSyncFromServerData:ctor(cityUnitCitizen)
    CityCitizenState.ctor(self, cityUnitCitizen)
    ---@type CS.UnityEngine.Vector3[]
    self._targetPath = nil
    ---@type CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
    self._pathFindingHandle = nil
    self._pathFindingStart = 0
    self._pathTime = 0
end

function CityCitizenStateSyncFromServerData:Enter()
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    self._targetPath = nil
    self._pathFindingHandle = nil
    self._pathFindingStart = 0
    self._pathTime = 0
    if self:IsFainting() then
        self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.FaintingFromSync, true, true)
        self.stateMachine:ChangeState("CityCitizenStateFainting")
    elseif self:HasWorkTask() then
        self:OnRecoverFromData()
    elseif self:IsAssigned() then
        self.stateMachine:ChangeState("CityCitizenStateAssigned")
    else
        self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
    end
end

function CityCitizenStateSyncFromServerData:OnRecoverFromData()
    self._citizen:StopMove()
    local citizenData = self._citizen._data
    local workData = citizenData:GetWorkData()
    if workData then
        local index,goTime,workTime = workData:GetCurrentTargetIndexGoToTimeLeftTime()
        if not index then
            self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime)
            self.stateMachine:ChangeState("CityCitizenStateWaitSync")
        else
            if goTime then
                self._citizen:StopMove()
                if not self:PreCalculateTargetPath(goTime) then
                    self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime)
                    self.stateMachine:ChangeState("CityCitizenStateWaitSync")
                end
            elseif workTime and workTime > 0 then
                local target, targetType = workData:GetTarget()
                local addTargetRecoveredFlag = true
                self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered, true)
                if targetType == CityWorkTargetType.Furniture then
                    local furniture = self._citizen._data._mgr.city.furnitureManager:GetCastleFurniture(target)
                    if furniture then
                        local furnitureConfig = ConfigRefer.CityFurnitureLevel:Find(furniture.ConfigId)
                        if furnitureConfig and CityCitizenDefine.IsNormalWorkFurniture(furnitureConfig:Type()) then
                            if self:IsAssigned() then
                                self.stateMachine:ChangeState("CityCitizenStateAssigned")
                            else
                                self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
                            end
                            return
                        end
                    end
                end

                local position = citizenData:GetPositionById(target, targetType)
                if not position then
                    self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime, 5, true)
                    self.stateMachine:ChangeState("CityCitizenStateWaitSync")
                    return
                end
                
                local pathFinding = citizenData._mgr.city.cityPathFinding
                position = pathFinding:NearestWalkableOnGraph(position, pathFinding.AreaMask.CityAllWalkable)
                self._citizen:OffsetMoveAndWayPoints(position)
                if addTargetRecoveredFlag then
                    self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered, true)
                end
                if self:IsAssigned() then
                    self.stateMachine:ChangeState("CityCitizenStateAssigned")
                else
                    self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
                end
            else
                self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime)
                self.stateMachine:ChangeState("CityCitizenStateWaitSync")
            end
        end
    else
        if self:IsAssigned() then
            self.stateMachine:ChangeState("CityCitizenStateAssigned")
        else
            self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
        end
    end
end

function CityCitizenStateSyncFromServerData:Tick(dt)
    if self._pathFindingStart == 0 then
        return
    end
    if self._pathFindingHandle then
        return
    end
    self._pathFindingStart = 0
    local speed = self._citizen._config:RunSpeed()
    local goLength = speed * self._pathTime
    local count = #self._targetPath
    for i = count, 2, -1 do
        local last = self._targetPath[i - 1]
        local current = self._targetPath[i]
        local pointTo = last - current
        local length = pointTo.magnitude
        if goLength > length then
            goLength = goLength - length
        else
            local dir = pointTo.normalized
            local pos = current + dir * goLength
            self._citizen:OffsetMoveAndWayPoints(pos)
            if self:IsAssigned() then
                self.stateMachine:ChangeState("CityCitizenStateAssigned")
            else
                self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
            end
            return
        end
    end
    if self._targetPath and #self._targetPath > 0 then
        self._citizen:OffsetMoveAndWayPoints(self._targetPath[1])
    end
    if self:IsAssigned() then
        self.stateMachine:ChangeState("CityCitizenStateAssigned")
    else
        self.stateMachine:ChangeState("CityCitizenStateNotAssigned")
    end
end

function CityCitizenStateSyncFromServerData:PreCalculateTargetPath(goTime)
    local data = self._citizen._data
    local pathFinding = data._mgr.city.cityPathFinding
    local workData = data:GetWorkData()
    local lastPos = self._citizen._moveAgent._currentPosition    
    local targetPos = data:GetPositionById(workData._target, CityWorkHelper.GetWorkTargetTypeByCfg(workData._config))
    if targetPos == nil then
        return false
    end
    local handle = pathFinding:FindPath(lastPos, targetPos, pathFinding.AreaMask.CityAllWalkable, function(waypoints)
        self._targetPath = waypoints
        self._pathFindingHandle = nil
    end)
    self._pathFindingHandle = handle
    self._pathFindingStart = 1
    self._pathTime = goTime
    return true
end

function CityCitizenStateSyncFromServerData:Exit()
    self._pathFindingStart = 0
    if self._pathFindingHandle then
        self._pathFindingHandle:Release()
    end
    self._pathFindingHandle = nil
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = nil
    end
end

return CityCitizenStateSyncFromServerData

