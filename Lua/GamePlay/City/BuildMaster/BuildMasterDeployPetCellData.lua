local CityFurnitureDeployPetCellData = require("CityFurnitureDeployPetCellData")
---@class BuildMasterDeployPetCellData:CityFurnitureDeployPetCellData
---@field new fun(src, petData, isLocked):BuildMasterDeployPetCellData
local BuildMasterDeployPetCellData = class("BuildMasterDeployPetCellData", CityFurnitureDeployPetCellData)
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local ModuleRefer = require("ModuleRefer")

---@param src BuildMasterDeployUIDataSrc
---@param petData CommonPetIconBaseData
---@param isLocked boolean
---@param lockTaskId number|nil
function BuildMasterDeployPetCellData:ctor(src, petData, isLocked, lockTaskId)
    self.src = src
    self.petData = petData
    self.isLocked = isLocked
    self.lockTaskId = lockTaskId
end

function BuildMasterDeployPetCellData:GetStatus()
    if self.petData == nil then
        if self.isLocked then
            return 0
        else
            return 1
        end
    else
        return 2
    end
end

function BuildMasterDeployPetCellData:IsShowLockCondition()
    return self.isLocked
end

function BuildMasterDeployPetCellData:GetLockConditionStr()
    if self.lockTaskId and self.lockTaskId > 0 then
        return ModuleRefer.QuestModule:GetTaskDesc(self.lockTaskId)
    else
        return I18N.Get("#不知道几级才能解锁")
    end
end

function BuildMasterDeployPetCellData:GetPetName()
    if self.petData == nil then return string.Empty end

    local petCfg = ConfigRefer.Pet:Find(self.petData.cfgId)
    if petCfg == nil then return string.Empty end

    return I18N.Get(petCfg:Name())
end

function BuildMasterDeployPetCellData:GetDeployTimeStr()
    if self.petData == nil then return string.Empty end

    local time = self.src.city.petManager:GetDecreaseBuildTime(self.petData.id)
    return ("-%s"):format(TimeFormatter.SimpleFormatTimeWithDayHourSeconds2(time))
end

function BuildMasterDeployPetCellData:GetPetData()
    return self.petData
end

---@param cell CityFurnitureDeployUIPetCell
function BuildMasterDeployPetCellData:OnClick(cell)
    if self.isLocked then return end
    self.src:OpenAssignmentUI()
end

function BuildMasterDeployPetCellData:ShowDeleteButton()
    return true
end

---@param cell CityFurnitureDeployUIPetCell
function BuildMasterDeployPetCellData:OnClickDelete(cell)
    self.src:RequestDeletePet(self.petData.id, cell._p_btn_delete.transform)
end

return BuildMasterDeployPetCellData