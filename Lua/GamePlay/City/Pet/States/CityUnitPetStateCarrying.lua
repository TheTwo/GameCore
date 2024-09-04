local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateCarrying:CityUnitPetStateBase
local CityUnitPetStateCarrying = class("CityUnitPetStateCarrying", CityUnitPetStateBase)
local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local StateMachine = require("StateMachine")
local CityUnitPetCarryingStateToStartPoint = require("CityUnitPetCarryingStateToStartPoint")
local CityUnitPetCarryingStateToEndPoint = require("CityUnitPetCarryingStateToEndPoint")
local CityUnitPetCarryingStateRoute = require("CityUnitPetCarryingStateRoute")
local CityUnitPetCarryingStateNone = require("CityUnitPetCarryingStateNone")

function CityUnitPetStateCarrying:ctor(petUnit)
    CityUnitPetStateBase.ctor(self, petUnit)
    self.subStateMachine = StateMachine.new()
    self.subStateMachine:AddState("tostart", CityUnitPetCarryingStateToStartPoint.new(petUnit))
    self.subStateMachine:AddState("toend", CityUnitPetCarryingStateToEndPoint.new(petUnit))
    self.subStateMachine:AddState("route", CityUnitPetCarryingStateRoute.new(petUnit))
    self.subStateMachine:AddState("none", CityUnitPetCarryingStateNone.new(petUnit))
end

function CityUnitPetStateCarrying:Enter()
    self.unit:EnterCarryingState()
    self.unit:SetupCarryItemGo()
    self.subStateMachine:ChangeState("route")
    self.stopTime = self.unit.petData.nextFreeTime
end

function CityUnitPetStateCarrying:Exit()
    self.subStateMachine:ChangeState("none")
    self.unit:ExitCarryingState()
    self.unit:DestroyCarryItemGo()
end

function CityUnitPetStateCarrying:Tick(dt)
    self.subStateMachine:Tick(dt)
    if g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() >= self.stopTime then
        self.unit:SyncFromServer()
    end
end

function CityUnitPetStateCarrying:OnModelReady()
    self.unit:SetupCarryItemGo()
end

return CityUnitPetStateCarrying