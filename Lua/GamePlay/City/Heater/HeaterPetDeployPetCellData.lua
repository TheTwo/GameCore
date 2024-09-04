local CityFurnitureDeployPetCellData = require("CityFurnitureDeployPetCellData")
---@class HeaterPetDeployPetCellData:CityFurnitureDeployPetCellData
---@field new fun(src, petData):HeaterPetDeployPetCellData
local HeaterPetDeployPetCellData = class("HeaterPetDeployPetCellData", CityFurnitureDeployPetCellData)
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

---@param src HeaterPetDeployUIDataSrc
---@param petData CommonPetIconBaseData
function HeaterPetDeployPetCellData:ctor(src, petData)
    self.src = src
    self.petData = petData
end

function HeaterPetDeployPetCellData:GetStatus()
    return self.petData == nil and 1 or 2
end

function HeaterPetDeployPetCellData:GetPetName()
    if self.petData == nil then return string.Empty end

    local petCfg = ConfigRefer.Pet:Find(self.petData.cfgId)
    if petCfg == nil then return string.Empty end

    return I18N.Get(petCfg:Name())
end

function HeaterPetDeployPetCellData:GetDeployTimeStr()
    return string.Empty
end

function HeaterPetDeployPetCellData:GetPetData()
    return self.petData
end

---@param cell CityFurnitureDeployUIPetCell
function HeaterPetDeployPetCellData:OnClick(cell)
    self.src:OpenAssignmentUI()
end

function HeaterPetDeployPetCellData:ShowDeleteButton()
    return true
end

---@param cell CityFurnitureDeployUIPetCell
function HeaterPetDeployPetCellData:OnClickDelete(cell)
    self.src:RequestDeletePet(self.petData.id, cell._p_btn_delete.transform)
end

function HeaterPetDeployPetCellData:IsLandNotFit()
    return self.src:IsLandNotFit(self)
end

return HeaterPetDeployPetCellData