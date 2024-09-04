local CityPetAssignHandle = require("CityPetAssignHandle")
---@class CityMobileUnitPetAssignHandle:CityPetAssignHandle
---@field new fun():CityMobileUnitPetAssignHandle
local CityMobileUnitPetAssignHandle = class("CityMobileUnitPetAssignHandle", CityPetAssignHandle)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")

---@param param CityMobileUnitUIParameter
function CityMobileUnitPetAssignHandle:ctor(param)
    self.param = param
    CityPetAssignHandle.ctor(self)
end

function CityMobileUnitPetAssignHandle:NeedShowPosition()
    return true
end

function CityMobileUnitPetAssignHandle:NeedShowExtraHint()
    return self.param:IsLackBasicNeed()
end

function CityMobileUnitPetAssignHandle:GetExtraHintText(fontSize)
    return self.param:GetLackBasicNeedText(fontSize)
end

function CityMobileUnitPetAssignHandle:NeedShowFeature()
    return true
end

function CityMobileUnitPetAssignHandle:GetPetWorkCfgs(petId)
    local ret = {}
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    if pet == nil then return ret end

    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    if petCfg == nil then return ret end

    local filterMap = self.param:NeedFeatureList(true)
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg and filterMap[petWorkCfg:Type()] then
            table.insert(ret, petWorkCfg)
        end
    end
    return ret
end

function CityMobileUnitPetAssignHandle:OnMultiSelectChange(...)
    if self.mediator then
        self.mediator:UpdateExtraHint()
    end
end

return CityMobileUnitPetAssignHandle