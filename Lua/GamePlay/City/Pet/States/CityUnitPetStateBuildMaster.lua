local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateBuildMaster:CityUnitPetStateBase
local CityUnitPetStateBuildMaster = class("CityUnitPetStateBuildMaster", CityUnitPetStateBase)

function CityUnitPetStateBuildMaster:Enter()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()

    self.buildMasterInfo = self.unit:GetBelongsToBuildMasterInfo()
    if self.buildMasterInfo == nil then
        return
    end

    self.buildMasterInfo:UpdateTargetInfo()
    if self.buildMasterInfo:NeedMove(self.unit) then
        self.unit:PlayMove()
        self.checkMoving = true
    else
        self.buildMasterInfo:TryRegisterBuildMasterReady(self.unit)
    end
end

function CityUnitPetStateBuildMaster:Exit()
    self.unit:DetachFromPrevPetAnchor()
    self.unit:StopMove()
    self.unit:SyncAnimatorSpeed()
    self.checkMoving = nil
end

function CityUnitPetStateBuildMaster:Tick()
    if self.buildMasterInfo == nil then
        self.unit:SyncFromServer()
        return
    end

    if self.checkMoving then
        if self.unit._moveAgent._isMoving or self.unit:IsFindingPath() then
            return
        end

        self.checkMoving = nil
        self.buildMasterInfo:RegisterPetPerformanceReady(self.unit)
    end
end

function CityUnitPetStateBuildMaster:OnModelReady()
    if self.buildMasterInfo then
        self.buildMasterInfo:TryRegisterBuildMasterReady(self.unit)
    end
end

function CityUnitPetStateBuildMaster:ReEnter()
    self:Exit()
    self:Enter()
end

return CityUnitPetStateBuildMaster