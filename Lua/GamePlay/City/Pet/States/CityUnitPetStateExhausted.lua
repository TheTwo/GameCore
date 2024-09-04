local CityPetAnimStateDefine = require("CityPetAnimStateDefine")
local CityUnitPetStateBase = require("CityUnitPetStateBase")
---@class CityUnitPetStateExhausted:CityUnitPetStateBase
local CityUnitPetStateExhausted = class("CityUnitPetStateExhausted", CityUnitPetStateBase)

function CityUnitPetStateExhausted:Enter()
    self.unit:PlayLoopState(CityPetAnimStateDefine.Exhausted)
end

return CityUnitPetStateExhausted