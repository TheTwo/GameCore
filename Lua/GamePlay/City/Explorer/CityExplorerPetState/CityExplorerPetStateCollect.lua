local StateMachine = require("StateMachine")
local CityInteractionPointType = require("CityInteractionPointType")
local CityExplorerPetSubStateGotoWork = require("CityExplorerPetSubStateGotoWork")
local CityExplorerPetSubStateDoWork = require("CityExplorerPetSubStateDoWork")
local CityExplorerPetSubStateNone = require("CityExplorerPetSubStateNone")
local CityWorkTargetType = require("CityWorkTargetType")
local ConfigRefer = require("ConfigRefer")

local CityExplorerPetState = require("CityExplorerPetState")

---@class CityExplorerPetStateCollect:CityExplorerPetState
---@field super CityExplorerPetState
local CityExplorerPetStateCollect = class("CityExplorerPetStateCollect", CityExplorerPetState)

function CityExplorerPetStateCollect:ctor(pet)
    CityExplorerPetStateCollect.super.ctor(self, pet)
    self._resourceTarget = nil
    ---@type CityInteractPoint_Impl
    self._resourceTargetPoint = nil
    ---@type CityInteractPointManager
    self._cityInteractPointManager = nil
    ---@type StateMachine
    self._subStatemachine = StateMachine.new()
    self._subStatemachine:AddState("CityExplorerPetSubStateGotoWork", CityExplorerPetSubStateGotoWork.new(pet, self))
    self._subStatemachine:AddState("CityExplorerPetSubStateDoWork", CityExplorerPetSubStateDoWork.new(pet, self))
    self._subStatemachine:AddState("CityExplorerPetSubStateNone", CityExplorerPetSubStateNone.new(pet, self))
    self._citySePetCollectMaxDistance = ConfigRefer.CityConfig:CitySePetCollectMaxDistance()
    self._citySePetCollectMaxDistance = self._citySePetCollectMaxDistance * self._citySePetCollectMaxDistance
end

function CityExplorerPetStateCollect:Enter()
    self._pet:MarkCollectActionCD()
    self._resourceTarget = self.stateMachine:ReadBlackboard("CollectResource")
    self._cityInteractPointManager = self._pet._seMgr.city.cityInteractPointManager
    ---@type CityCitizenTargetInfo
    local ownerInfo = {}
    ownerInfo.id = self._resourceTarget
    ownerInfo.type = CityWorkTargetType.Resource
    self._resourceTargetPoint = self._cityInteractPointManager:AcquireInteractPoint(CityInteractionPointType.Collect, ~0, ownerInfo)
    if self._resourceTargetPoint then
        self._subStatemachine:WriteBlackboard("ElementId", self._resourceTarget, true)
        self._subStatemachine:WriteBlackboard("CollectResource", self._resourceTargetPoint, true)
        self._subStatemachine:ChangeState("CityExplorerPetSubStateGotoWork")
    else
        self._subStatemachine:ChangeState("CityExplorerPetSubStateNone")
    end
    if self._pet._groupLogic then
        self._pet._groupLogic:UnitAssignWork(self._pet, self._resourceTarget)
    end
    CityExplorerPetStateCollect.super.Enter(self)
end

function CityExplorerPetStateCollect:Exit()
    CityExplorerPetStateCollect.super.Exit(self)
    if self._resourceTargetPoint then
        self._cityInteractPointManager:DismissInteractPoint(self._resourceTargetPoint)
        self._resourceTargetPoint = nil
    end
    self._cityInteractPointManager = nil
    if self._pet._groupLogic then
        self._pet._groupLogic:ClearUnitWork(self._pet)
    end
    self._subStatemachine:ChangeState("CityExplorerPetSubStateNone")
end

function CityExplorerPetStateCollect:CheckTransState()
    if self._pet._needInBattleHide or not self._resourceTargetPoint then
        self:ExitToNormal()
        return true
    end
    local petPos = self._pet._moveAgent._currentPosition
    if petPos then
        local team = self._pet._seMgr.city.cityExplorerManager:GetTeamByPresetIndex(self._pet._presetIndex)
        local teamPos = team and team:GetPosition()
        if teamPos then
            local distance = (petPos - teamPos).sqrMagnitude
            if distance > self._citySePetCollectMaxDistance then
                self:ExitToNormal()
                return true
            end
        end
    end
    return false
end

function CityExplorerPetStateCollect:Tick(dt)
    if self:CheckTransState() then
        return
    end
    self._subStatemachine:Tick(dt)
end

function CityExplorerPetStateCollect:ExitToNormal()
    self.stateMachine:ChangeState("CityExplorerPetStateEnter")
end

return CityExplorerPetStateCollect