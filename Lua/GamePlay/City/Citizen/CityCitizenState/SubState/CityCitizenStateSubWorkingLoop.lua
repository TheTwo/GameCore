local StateMachine = require("StateMachine")
local CityCitizenStateSubSelectWorkTarget = require("CityCitizenStateSubSelectWorkTarget")
local CityCitizenStateSubGoToTarget = require("CityCitizenStateSubGoToTarget")
local CityCitizenStateSubInteractTarget = require("CityCitizenStateSubInteractTarget")
local CityCitizenDefine = require("CityCitizenDefine")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityCitizenStateHelper = require("CityCitizenStateHelper")
local CityWorkTargetType = require("CityWorkTargetType")

local CityCitizenState = require("CityCitizenState")

---@class CityCitizenStateSubWorkingLoop:CityCitizenState
---@field new fun(cityUnitCitizen:CityUnitCitizen):CityCitizenStateSubWorkingLoop
---@field super CityCitizenState
local CityCitizenStateSubWorkingLoop = class('CityCitizenStateSubWorkingLoop', CityCitizenState)

---@param cityUnitCitizen CityUnitCitizen
function CityCitizenStateSubWorkingLoop:ctor(cityUnitCitizen)
    CityCitizenState.ctor(self, cityUnitCitizen)
    self:SetSubStateMachine(StateMachine.new())
    self._subStateMachine:AddState("CityCitizenStateSubSelectWorkTarget", CityCitizenStateSubSelectWorkTarget.new(cityUnitCitizen))
    self._subStateMachine:AddState("CityCitizenStateSubGoToTarget", CityCitizenStateSubGoToTarget.new(cityUnitCitizen))
    self._subStateMachine:AddState("CityCitizenStateSubInteractTarget", CityCitizenStateSubInteractTarget.new(cityUnitCitizen))
    for _,v in pairs(self._subStateMachine.states) do
        v._parent = self
    end
    self._delayReSync = nil
    ---@type {id:number,type:number}
    self._subRegisterTargetInfo = nil
end

function CityCitizenStateSubWorkingLoop:Enter()
    self._delayReSync = nil
    if self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetRecovered) then
        local targetInfo = self.stateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo)
        self._subStateMachine:ReadBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo)
        self._subStateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetInfo, targetInfo)
        self._subStateMachine:ChangeState("CityCitizenStateSubInteractTarget")
    else
        self._subStateMachine:ChangeState("CityCitizenStateSubSelectWorkTarget")
    end
    self:SyncInfectionVfx()
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, Delegate.GetOrCreate(self, self.OnInProgressResourceRemove))
end

function CityCitizenStateSubWorkingLoop:Tick(dt)
    if self._delayReSync then
        self._delayReSync()
        self._delayReSync = nil
        return
    end
    if not self:HasWorkTask() then
        self.stateMachine:ChangeState("CityCitizenStateSubNotWorking")
        return
    end
    self._subStateMachine:Tick(dt)
end

---@param targetId number
---@param targetType CityWorkTargetType
function CityCitizenStateSubWorkingLoop:OnWorkTargetChanged(targetId, targetType)
    if not self:HasWorkTask() then
        return
    end
    local workData = self._citizen._data:GetWorkData()
    if not workData then
        return
    end
    local index = workData:GetCurrentTargetIndexGoToTimeLeftTime()
    if not index then
        return
    end
    local t,tt = workData:GetTarget()
    if t then
        ---@type CityCitizenTargetInfo
        local tInfo = {}
        tInfo.id = t
        tInfo.type = tt
        tInfo = CityCitizenStateHelper.ProcessFurnitureWorkTarget(tInfo, self._citizen._data)
        if targetId == tInfo.id and targetType == tInfo.type then
            self:ReSync(CityWorkTargetType.Resource == targetType)
        end
    end
end

function CityCitizenStateSubWorkingLoop:ReSync(needSendToServer)
    self._delayReSync = function()
        if self._parent and self._parent.stateMachine then
            self._parent.stateMachine:WriteBlackboard(CityCitizenDefine.StateMachineKey.TargetNeedReSync, needSendToServer)
            self._parent.stateMachine:ChangeState("CityCitizenStateSyncToServer")
        end
    end
end

function CityCitizenStateSubWorkingLoop:Exit()
    self._subRegisterTargetInfo = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_INPROGRESS_RESOURCE_REMOVED, Delegate.GetOrCreate(self, self.OnInProgressResourceRemove))
    self:SyncInfectionVfx()
    self._delayReSync = nil
    self._subStateMachine:ChangeState("")
end

function CityCitizenStateSubWorkingLoop:OnInProgressResourceRemove(cityId, elementId, progressInfo, workId)
    if not self._subRegisterTargetInfo or self._citizen._data._mgr.city.uid ~= cityId then
        return
    end
    if self._subRegisterTargetInfo.id ~= elementId then
        return
    end
    self._subStateMachine:ChangeState("CityCitizenStateSubSelectWorkTarget")
end

function CityCitizenStateSubWorkingLoop:SubSelectWorkTargetRegisterRedirectTarget(targetInfo)
    self._subRegisterTargetInfo = targetInfo
end

function CityCitizenStateSubWorkingLoop:OnUnitAssetLoaded()
    local subState = self._subStateMachine:GetCurrentState()
    if subState and subState.OnUnitAssetLoaded then
        subState:OnUnitAssetLoaded()
    end
end

return CityCitizenStateSubWorkingLoop

