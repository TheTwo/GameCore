---@class CityPetAssignPropertyData
---@field new fun(handle, petId, icon, value, attrType):CityPetAssignPropertyData
local CityPetAssignPropertyData = class("CityPetAssignPropertyData")

---@param handle CityPetAssignHandle
---@param petId number
---@param icon number
function CityPetAssignPropertyData:ctor(handle, petId, icon, value, attrType)
    self.handle = handle
    self.petId = petId
    self.icon = icon
    self.value = value
    self.attrType = attrType
end

function CityPetAssignPropertyData:GetIcon()
    return self.icon
end

function CityPetAssignPropertyData:GetWorkRelativeBuffValue()
    return self.handle:GetBuffValueText(self)
end

function CityPetAssignPropertyData:IsBetterThanCurrentPet()
    return self.handle:IsBetterThanCurrentPet(self)
end

function CityPetAssignPropertyData:IsWorseThanCurrentPet()
    return self.handle:IsWorseThanCurrentPet(self)
end

return CityPetAssignPropertyData