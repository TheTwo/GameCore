local CityPetAssignHandle = require("CityPetAssignHandle")
---@class BuildMasterPetAssignHandle:CityPetAssignHandle
---@field new fun():BuildMasterPetAssignHandle
local BuildMasterPetAssignHandle = class("BuildMasterPetAssignHandle", CityPetAssignHandle)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityPetAssignPropertyData = require("CityPetAssignPropertyData")
local TimeFormatter = require("TimeFormatter")

---@param dataSrc BuildMasterDeployUIDataSrc
function BuildMasterPetAssignHandle:ctor(dataSrc, onPetClick)
    self.dataSrc = dataSrc
    CityPetAssignHandle.ctor(self, onPetClick)
end

function BuildMasterPetAssignHandle:NeedShowBuff()
    return true
end

---@return CityPetAssignPropertyData[]
function BuildMasterPetAssignHandle:GetRelativeAttrs(petId)
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    local time = 0
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        time = time + petWorkCfg:BuildingReduceTime() * self.dataSrc.city.petManager:GetLandFactor(petWorkCfg:Level())
    end
    return {CityPetAssignPropertyData.new(self, petId, "sp_city_icon_time_up", time, -1)}
end

---@param data CityPetAssignPropertyData
function BuildMasterPetAssignHandle:GetBuffValueText(data)
    return ("-%s"):format(TimeFormatter.TimerStringFormat(data.value, true))
end

function BuildMasterPetAssignHandle:NeedShowPosition()
    return true
end

return BuildMasterPetAssignHandle