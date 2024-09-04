local CityCitizenDefine = require("CityCitizenDefine")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateFainting:CityCitizenState
---@field new fun():CityCitizenStateFainting
---@field super CityCitizenState
local CityCitizenStateFainting = class('CityCitizenStateFainting', CityCitizenState)

function CityCitizenStateFainting:Enter()
    self._bubbleCreated = false
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    self._citizen:StopMove()
    local isFromServerPos = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.FaintingFromSync, true)
    if isFromServerPos and self._citizen._data._workPos then
        local position = self._citizen._data._mgr.city:GetWorldPositionFromCoord(self._citizen._data._workPos.X, self._citizen._data._workPos.Y)
        position = self._citizen._pathFinder:NearestWalkableOnGraph(position, self._citizen._pathFinder.AreaMask.CityAllWalkable)
        self._citizen:OffsetMoveAndWayPoints(position)
    end
    self._citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Fainting)
    self:SyncInfectionVfx()
end

function CityCitizenStateFainting:Tick(dt)
    if self:IsFainting() then
        if not self._bubbleCreated then
            if self._citizen._data:IsReadyForWeakUp() then
                self._bubbleCreated = true
                self._citizen._data._mgr:CreateCitizenRecoverBubble(self._citizen._data._id)
            end
        end
        return
    end
    self.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.WaitSyncDelayTime, 5)
    self.stateMachine:ChangeState("CityCitizenStateWaitSync")
end

function CityCitizenStateFainting:Exit()
    if self._bubbleCreated then
        self._citizen._data._mgr:RemoveCitizenRecoverBubble(self._citizen._data._id)
    end
    self._bubbleCreated = false
    self._subStateMachine:ChangeState("")
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = nil
    end
end

function CityCitizenStateFainting:OnUnitAssetLoaded()
    local subState = self._subStateMachine:GetCurrentState()
    if subState and subState.OnUnitAssetLoaded then
        subState:OnUnitAssetLoaded()
    end
end

return CityCitizenStateFainting