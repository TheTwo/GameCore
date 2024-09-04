local CityPetAssignHandle = require("CityPetAssignHandle")
---@class CityPetAssignHandleCollectV2:CityPetAssignHandle
---@field new fun(param, onPetClick):CityPetAssignHandleCollectV2
local CityPetAssignHandleCollectV2 = class("CityPetAssignHandleCollectV2", CityPetAssignHandle)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityAttrType = require("CityAttrType")
local CityPetAssignPropertyData = require("CityPetAssignPropertyData")
local NumberFormatter = require("NumberFormatter")
local ArtResourceUtils = require("ArtResourceUtils")

---@param param CityCollectV2UIParameter
function CityPetAssignHandleCollectV2:ctor(param, onPetClick)
    self.param = param
    CityPetAssignHandle.ctor(self, onPetClick)
end

function CityPetAssignHandleCollectV2:NeedShowBuff()
    return true
end

---@return CityPetAssignPropertyData[]
function CityPetAssignHandleCollectV2:GetRelativeAttrs(petId)
    local param1 = self.param.workCfg:CustomParam1()
    local param2 = self.param.workCfg:CustomParam2()
    local produceCfg = ConfigRefer.CityWorkProduceResource:Find(self.param.workCfg:ResProduceCfg())
    local output = ConfigRefer.Item:Find(produceCfg:ResType())

    local workSpeed = ModuleRefer.CastleAttrModule:GetValueWithPet(CityAttrType.PetWorkSpeed, petId)
    local needFeature = self.param.workCfg:RequireWorkerType()
    local workLevel = self.param.city.petManager:GetWorkLevel(petId, needFeature)
    local levelFactor = self.param.city.petManager:GetLandFactor(workLevel)

    local castleBrief = self.param.city:GetCastleBrief()
    local hp = castleBrief.TroopPresets.PetHp[petId] or 1
    local hungry = hp == 1 and ConfigRefer.CityConfig:HungryWorkSpeedFactor() or 1
    local value = (param1 + workSpeed) / param2 * levelFactor * hungry
    local outputSpeedAttr = ModuleRefer.CastleAttrModule:GetValueWithFurniture(produceCfg:OutputSpeedAttr(), self.param.cellTile:GetCell().singleId)
    return {CityPetAssignPropertyData.new(self, petId, output:Icon(), outputSpeedAttr * value, CityAttrType.PetWorkSpeed)}
end

function CityPetAssignHandleCollectV2:NeedShowPosition()
    return true
end

---@param data CityPetAssignPropertyData
function CityPetAssignHandleCollectV2:GetBuffValueText(data)
    return NumberFormatter.WithSign(data.value) .. "/h"
end

---@param data CityPetAssignmentUICellData
function CityPetAssignHandleCollectV2:IsLandNotFit(data)
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
function CityPetAssignHandleCollectV2:GetLandFactorPercent(data)
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
function CityPetAssignHandleCollectV2:GetSuitableLandName(data)
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

return CityPetAssignHandleCollectV2