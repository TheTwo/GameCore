local CityFurnitureDeployPetCellData = require("CityFurnitureDeployPetCellData")
---@class ShareLevelPetDeployPetCellData:CityFurnitureDeployPetCellData
---@field new fun():ShareLevelPetDeployPetCellData
local ShareLevelPetDeployPetCellData = class("ShareLevelPetDeployPetCellData", CityFurnitureDeployPetCellData)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local Delegate = require("Delegate")

function ShareLevelPetDeployPetCellData:ctor(petId, shareTarget)
    self.petId = petId
    self.petData = ModuleRefer.PetModule:GetPetByID(self.petId)
    self.petCfg = ConfigRefer.Pet:Find(self.petData.ConfigId)
    self.shareTarget = shareTarget
end

---@return number @0未解锁 1未驻派 2已驻派
function ShareLevelPetDeployPetCellData:GetStatus()
    return 2
end

---@return string
function ShareLevelPetDeployPetCellData:GetPetName()
    return I18N.Get(self.petCfg:Name())
end

---@return string
function ShareLevelPetDeployPetCellData:GetDeployTimeStr()
    return ("Lv.%d"):format(self.petData.Level)
end

---@return CommonPetIconBaseData
function ShareLevelPetDeployPetCellData:GetPetData()
    ---@type CommonPetIconBaseData
    local petData = {
        id = self.petId,
        cfgId = self.petData.ConfigId,
        level = self.petData.Level,
        rank = self.petData.RankLevel,
        onClick = Delegate.GetOrCreate(self, self.OnPetClick)
    }
    return petData
end

---@param cell CityFurnitureDeployUIPetCell
function ShareLevelPetDeployPetCellData:OnClick(cell)
    ---override this
end

---@param cell CityFurnitureDeployUIPetCell
function ShareLevelPetDeployPetCellData:OnClickDelete(cell)
    ---override this
end

function ShareLevelPetDeployPetCellData:IsShowShare()
    return self.shareTarget
end

return ShareLevelPetDeployPetCellData