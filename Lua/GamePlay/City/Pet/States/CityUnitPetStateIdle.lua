local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateIdle:CityUnitPetStateBase
local CityUnitPetStateIdle = class("CityUnitPetStateIdle", CityUnitPetStateBase)

function CityUnitPetStateIdle:Enter()
    if self.unit.isCarring then
        self.unit:ChangeAnimatorState(CityPetAnimStateDefine.TransportIdle)
    else
        self.unit:ChangeAnimatorState(CityPetAnimStateDefine.Idle)
    end
end

function CityUnitPetStateIdle:ReEnter()
    self:Enter()
end

return CityUnitPetStateIdle