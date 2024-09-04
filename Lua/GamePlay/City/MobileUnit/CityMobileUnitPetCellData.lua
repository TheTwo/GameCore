---@class CityMobileUnitPetCellData
---@field new fun():CityMobileUnitPetCellData
local CityMobileUnitPetCellData = class("CityMobileUnitPetCellData")

---@param petData CommonPetIconBaseData
---@param param CityMobileUnitUIParameter
function CityMobileUnitPetCellData:ctor(petData, param, isLock, lockTaskId)
    self.petData = petData
    self.param = param
    self.isLock = isLock
    self.lockTaskId = lockTaskId
end

function CityMobileUnitPetCellData:GetStatus()
    if self.petData ~= nil then
        return 2
    elseif self.isLock then
        return 0
    else
        return 1
    end
end

return CityMobileUnitPetCellData