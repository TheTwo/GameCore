local CityCitizenDefine = require("CityCitizenDefine")
local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSyncToServer:CityCitizenState
---@field new fun():CityCitizenStateSyncToServer
---@field super CityCitizenState
local CityCitizenStateSyncToServer = class('CityCitizenStateSyncToServer', CityCitizenState)

function CityCitizenStateSyncToServer:Enter()
    self._pathfinding = nil
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    local needSync = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetNeedReSync)
    local workData = self._citizen._data:GetWorkData()
    if needSync and workData then
        self._target = workData._target
        self._targetsPathTime = workData._targetsPathTime
        self._needSync = needSync
        self._result = 0
        self:ReCalculateTime()
    else
        self.stateMachine:ChangeState("CityCitizenStateSyncFromServerData")
    end
end

function CityCitizenStateSyncToServer:Tick(dt)
    if self._pathfinding then
        return
    end
    if not self._needSync then
        return
    end
    if self._result > 0 then
        self._targetsPathTime = self._result
    end
    self._needSync = nil
    self:SendUpdate()
end

function CityCitizenStateSyncToServer:ReCalculateTime()
    local data = self._citizen._data
    local workData = data:GetWorkData()
    local from = self._citizen._moveAgent._currentPosition
    local id, targetType = workData:GetTarget()
    local to = self._citizen._data:GetPositionById(id, targetType)
    local speed = data:RunSpeed()
    local p = data._mgr.city.cityPathFinding
    self._pathfinding = p:FindPath(from, to, p.AreaMask.CityAllWalkable, function(waypoints)
        local last = waypoints[1]
        for i = 2, #waypoints do
            local current = waypoints[i]
            self._result = self._result + (current - last).magnitude / speed
            last = current
        end
        if self._pathfinding then
            self._pathfinding:Release()
        end
        self._pathfinding = nil
    end)
end

function CityCitizenStateSyncToServer:SendUpdate()
    local array = {self._targetsPathTime * 1000}
    self._citizen._data._mgr:UpdateWork(self._citizen._data._workId, array)
    self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime, 5, true)
    self.stateMachine:ChangeState("CityCitizenStateWaitSync")
end

function CityCitizenStateSyncToServer:Exit()
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = nil
    end
    if self._pathfinding then
        self._pathfinding:Release()
    end
    self._pathfinding = nil
    self._target = nil
    self._targetsPathTime = nil
    self._needSync = nil
end

return CityCitizenStateSyncToServer

