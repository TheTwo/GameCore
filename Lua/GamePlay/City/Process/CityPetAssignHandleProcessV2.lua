local CityPetAssignHandle = require("CityPetAssignHandle")
---@class CityPetAssignHandleProcessV2:CityPetAssignHandle
---@field new fun():CityPetAssignHandleProcessV2
local CityPetAssignHandleProcessV2 = class("CityPetAssignHandleProcessV2", CityPetAssignHandle)
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local ConfigRefer = require("ConfigRefer")
local CityPetAssignPropertyData = require("CityPetAssignPropertyData")
local NumberFormatter = require("NumberFormatter")
local TimeFormatter = require("TimeFormatter")

---@param param CityProcessV2UIParameter
function CityPetAssignHandleProcessV2:ctor(param, onPetClick)
    self.param = param
    CityPetAssignHandle.ctor(self, onPetClick)
end

function CityPetAssignHandleProcessV2:NeedShowBuff()
    return true
end

---@return CityPetAssignPropertyData[]
function CityPetAssignHandleProcessV2:GetRelativeAttrs(petId)
    local param1 = self.param.workCfg:CustomParam1()
    local param2 = self.param.workCfg:CustomParam2()

    local workSpeed = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, petId)
    local needFeature = self.param.workCfg:RequireWorkerType()
    local workLevel = self.param.city.petManager:GetWorkLevel(petId, needFeature)
    local levelFactor = self.param.city.petManager:GetLandFactor(workLevel)

    local castleBrief = self.param.city:GetCastleBrief()
    local hp = castleBrief.TroopPresets.PetHp[petId] or 1
    local hungry = hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
    local value = (workSpeed + param1) / param2 * levelFactor * hungry
    value = math.min(0.9, value)

    local originTime = self.param:GetOriginalCostTime()
    return {CityPetAssignPropertyData.new(self, petId, "sp_city_icon_time_up", value * originTime, CityAttrType.PetWorkSpeed)}
end

function CityPetAssignHandleProcessV2:NeedShowPosition()
    return true
end

---@param data CityPetAssignPropertyData
function CityPetAssignHandleProcessV2:GetBuffValueText(data)
    return ("-%s"):format(TimeFormatter.SimpleFormatTimeWithDayHourSeconds2(data.value))
end

---@param data CityPetAssignPropertyData
function CityPetAssignHandleProcessV2:IsLandNotFit(data)
    local needFeature = self.param.workCfg:RequireWorkerType()
    local petCfg = ConfigRefer.Pet:Find(data.petData.cfgId)
    local workLevel = 0
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg:Type() == needFeature then
            workLevel = petWorkCfg:Level()
            break
        end
    end
    return self.param.city.petManager:IsLandNotFit(workLevel)
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandleProcessV2:GetLandFactorPercent(data)
    local needFeature = self.param.workCfg:RequireWorkerType()
    local petCfg = ConfigRefer.Pet:Find(data.petData.cfgId)
    local workLevel = 0
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg:Type() == needFeature then
            workLevel = petWorkCfg:Level()
            break
        end
    end
    local percent = self.param.city.petManager:GetLandFactor(workLevel) / self.param.city.petManager:GetMaxLandFactor(workLevel)
    return NumberFormatter.Percent(percent)
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandleProcessV2:GetSuitableLandName(data)
    local needFeature = self.param.workCfg:RequireWorkerType()
    local petCfg = ConfigRefer.Pet:Find(data.petData.cfgId)
    local workLevel = 0
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        if petWorkCfg:Type() == needFeature then
            workLevel = petWorkCfg:Level()
            break
        end
    end

    return self.param.city.petManager:GetBestLandName(workLevel)
end

return CityPetAssignHandleProcessV2