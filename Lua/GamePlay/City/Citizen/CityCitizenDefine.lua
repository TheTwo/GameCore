local FurnitureCategory = require("FurnitureCategory")
local ArtResourceUtils = require("ArtResourceUtils")
local CityDefenseType = require("CityDefenseType")
local ConfigRefer = require("ConfigRefer")

---@class CityCitizenTargetInfo
---@field id number
---@field type number @CityWorkTargetType

---@class CityCitizenDefine
local CityCitizenDefine = {}

---@class CityCitizenDefine.TaskType
CityCitizenDefine.TaskType = {
    NotAssigned = 0,
    AssignedIdle = 1,
    Building = 2,
    Logging = 3,
    Farming = 4,
    Mining = 5,
    Crafting = 6,
}

---@class CityCitizenDefine.TaskPhase
CityCitizenDefine.TaskPhase = {
    None = 0,
    GoingToWork = 1,
    WorkLoop = 2,
}

---@class CityCitizenDefine.StateMachineKey
CityCitizenDefine.StateMachineKey = {
    TargetPos = "TargetPos",
    TargetInteract = "TargetInteract",
    TargetInfo = "TargetInfo",
    TargetRecovered = "TargetRecovered",
    TargetNeedReSync = "TargetNeedReSync",
    TargetIsFromExitWork = "TargetIsFromExitWork",
    TargetIsAssignHouse = "TargetIsAssignHouse",
    TargetNeedForceRun = "TargetNeedForceRun",
    FaintingFromSync = "FaintingFromSync",
    WaitSyncDelayTime = "WaitSyncDelayTime",
}

---@class CityCitizenDefine.AniClip
CityCitizenDefine.AniClip = {
    Idle = "idle",
    Walking = "walk",
    Running = "run",
    Building = "jiagong",
    Logging = "pickup",
    Farming = "pickup",
    Mining = "pickup",
    Crafting = "pickup",
    Resting = "pickup",
    Sweeping = "pickup",
    Fainting = "death",
}

CityCitizenDefine.WorkTargetToIconNone = "sp_city_icon_free_resident"
CityCitizenDefine.WorkTargetToIconHomeless = "sp_city_icon_free_refugee"
CityCitizenDefine.WorkTargetToIconWorking = "sp_city_icon_hammer"

---@class CityCitizenDefine.HealthStatus
CityCitizenDefine.HealthStatus = {
    Health = 0,
    UnHealth = 1,
    Fainting = 2,
    FaintingReadyWakeUp = 3,
}

---@class CityCitizenDefine.HealthStatusSortOrder
CityCitizenDefine.HealthStatusSortOrder = {
    [CityCitizenDefine.HealthStatus.FaintingReadyWakeUp] = 0,
    [CityCitizenDefine.HealthStatus.Health] = 1,
    [CityCitizenDefine.HealthStatus.UnHealth] = 2,
    [CityCitizenDefine.HealthStatus.Fainting] = 3,
}

---@param config CityFurnitureLevelConfigCell
function CityCitizenDefine.GetFurnitureBedCount(config)
    if not config then
        return 0
    end
    return config:CitizenCapInc()
end

CityCitizenDefine.CityNormalProcessId = 4

CityCitizenDefine.CityFurnitureBedTypeIds = {
    [28] = 28
}

CityCitizenDefine.CityFurnitureExplorerTeamTypeIds = {
    [9] = 9
}
CityCitizenDefine.CityFurnitureRadarTypeIds = {
    [3] = 3
}
CityCitizenDefine.CityCollectBoxTypeIds = {
    [13] = 13
}
CityCitizenDefine.CitizenRecruitmentAgency = {
    [14] = 14
}
CityCitizenDefine.CityFurnitureProduceBoxTypeIds = {
    [24] = 24
}
CityCitizenDefine.CityFurnitureFarmlandTypeIds = {
    [15] = 15
}

CityCitizenDefine.CityFurnitureTrainSoldiers = {
    [1013] = 1013
}

CityCitizenDefine.CityFurnitureGacha = {
    [1002601] = 1002601
}

CityCitizenDefine.HetchPet = {
    [1002801] = 1002801
}


---@class CityCitizenDefine.WorkTargetReason
CityCitizenDefine.WorkTargetReason = {
    Base = 1,
    Operate = 2,
}

---@class CityCitizenDefine.CitizenCameraLodLevel
CityCitizenDefine.CitizenCameraLodLevel = {
    Low = 0,
    Mid = 1,
    High = 2,
    Off = 3,
}


function CityCitizenDefine.IsNormalWorkFurniture(type)
    local typeConfig = require("ConfigRefer").CityFurnitureTypes:Find(type)
    if not typeConfig then
        return false
    end
    return typeConfig:Category() == FurnitureCategory.Economy
end

function CityCitizenDefine.IsSpecialFunctionFurniture(type)
    local typeConfig = require("ConfigRefer").CityFurnitureTypes:Find(type)
    if not typeConfig then
        return false
    end
    return typeConfig:Category() == FurnitureCategory.System
end

function CityCitizenDefine.IsMilitaryFurniture(type)
    local typeConfig = require("ConfigRefer").CityFurnitureTypes:Find(type)
    if not typeConfig then
        return false
    end
    return typeConfig:Category() == FurnitureCategory.Military
end

function CityCitizenDefine.IsDecorationFurniture(type)
    local typeConfig = require("ConfigRefer").CityFurnitureTypes:Find(type)
    if not typeConfig then
        return false
    end
    return typeConfig:Category() == FurnitureCategory.Decoration
end

function CityCitizenDefine.IsFurnitureWallOrDoor(type)
    local typeConfig = require("ConfigRefer").CityFurnitureTypes:Find(type)
    if not typeConfig then
        return false
    end
    local dt = typeConfig:DefenseType()
    return dt == CityDefenseType.Door or dt == CityDefenseType.Wall
end

function CityCitizenDefine.IsFarmlandFurniture(typeId)
    return CityCitizenDefine.CityFurnitureFarmlandTypeIds[typeId] ~= nil
end

function CityCitizenDefine.IsTrainSoldier(typeId)
    return CityCitizenDefine.CityFurnitureTrainSoldiers[typeId] ~= nil
end

function CityCitizenDefine.IsGachaDogHouse(typeId)
    return CityCitizenDefine.CityFurnitureGacha[typeId] ~= nil
end

function CityCitizenDefine.IsHetchPet(typeId)
    return CityCitizenDefine.HetchPet[typeId] ~= nil
end

---@param citizenConfig CitizenConfigCell
function CityCitizenDefine.GetCitizenModelByDeviceLv(citizenConfig)
    local level = g_Game.PerformanceLevelManager:GetDeviceLevel()
    local selectedAsset
    if level ==  CS.DragonReborn.Performance.DeviceLevel.Low then
        selectedAsset = ArtResourceUtils.GetItem(citizenConfig:ModelLow())
    end
    if string.IsNullOrEmpty(selectedAsset) then
        selectedAsset = ArtResourceUtils.GetItem(citizenConfig:Model())
    end
    return selectedAsset
end

---@param citizenConfig CitizenConfigCell
---@return string,number
function CityCitizenDefine.GetCitizenModelAndScaleByDeviceLv(citizenConfig)
    local level = g_Game.PerformanceLevelManager:GetDeviceLevel()
    local selectedAsset,scale
    if level ==  CS.DragonReborn.Performance.DeviceLevel.Low then
        selectedAsset,scale = ArtResourceUtils.GetItemAndScale(citizenConfig:ModelLow())
    end
    if string.IsNullOrEmpty(selectedAsset) then
        selectedAsset,scale = ArtResourceUtils.GetItemAndScale(citizenConfig:Model())
    end
    return selectedAsset,scale
end

return CityCitizenDefine

