local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local MapResourceFieldType = require("MapResourceFieldType")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local MapResourceFieldDatum = require("MapResourceFieldDatum")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local GivingUpResourceParameter = require("GivingUpResourceParameter")
local UIHelper = require("UIHelper")
local OnChangeHelper = require("OnChangeHelper")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local OutputResourceType = require("OutputResourceType")
local DBEntityType = require("DBEntityType")

---@class MapResourceFieldModule:BaseModule
local MapResourceFieldModule = class('MapResourceFieldModule', BaseModule)

function MapResourceFieldModule:OnRegister()
    self.data = {}
    self.dirty = true
end

function MapResourceFieldModule:OnRemove()

    self.data = nil
    self.lod2IconMap = nil
end

---@param entity wds.ResourceField
function MapResourceFieldModule:IsCollecting(entity)
    return entity and entity.FieldInfo.State == wds.ResourceFieldState.ResourceStateOccupied
end

---@param entity wds.ResourceField
function MapResourceFieldModule:IsLockedByVillage(entity)
    if not entity or not entity.FieldInfo then
        return true
    end
    
    return false
end

---@param entity wds.ResourceField
function MapResourceFieldModule:IsLockedByLandform(entity)
    if not entity or not entity.FieldInfo then
        return true
    end
    
    local config = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    if not ModuleRefer.LandformModule:IsLandformUnlockByCfgId(config:LandId()) then
        return true
    end

    return false
end

function MapResourceFieldModule:GetUnlockLandformName(resourceConfigID)
    local config = ConfigRefer.FixedMapBuilding:Find(resourceConfigID)
    if config then
        local landConfig = ConfigRefer.Land:Find(config:LandId())
        local landName = I18N.Get(landConfig:Name())
        return landName
    end
    return nil
end

---@param entity wds.ResourceField
function MapResourceFieldModule:RequestCollectResourceField(entity)
    KingdomTouchInfoOperation.SendTroopToEntityQuickly(entity)
end

---@param entity wds.ResourceField
function MapResourceFieldModule:RequestRecallResourceField(entity)
    local content = I18N.Get("mining_info_collection_recall")
    local confirm = function()
        KingdomTouchInfoOperation.BackHomeFrom(entity)
    end
    UIHelper.ShowConfirm(content, nil, confirm)
end

---@param entity wds.ResourceField
function MapResourceFieldModule:GetCollectEndTime(entity)
    if not entity or not entity.FieldInfo then
        return 0
    end
    local fieldInfo = entity.FieldInfo
    if fieldInfo.InGather then
        return fieldInfo.EndGatherTime.Seconds
    end
    return 0
end

---@param entity wds.ResourceField
function MapResourceFieldModule:GetCollectLeftTime(entity)
    local endTime = self:GetCollectEndTime(entity)
    if endTime > 0 then
        local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        return math.max(endTime - serverTime, 0)
    end
    return 0
end

---@param entity wds.ResourceField
function MapResourceFieldModule:GetRemainResourceAmount(entity)
    if not entity or not entity.FieldInfo then
        return 0
    end
    local fieldInfo = entity.FieldInfo
    return math.max(fieldInfo.LeftResource, 0)
end

---@param fieldInfo wds.ResourceFieldInfo
function MapResourceFieldModule:GetCollectingSpeedAndInterval(fieldInfo)
    local speedRatio = fieldInfo.GatherSpeed > 0 and fieldInfo.GatherSpeed or 1
    local config = ConfigRefer.FixedMapBuilding:Find(fieldInfo.ConfID)
    local speed = math.floor(config:OutputResourceCount() * speedRatio)
    local interval = config:OutputResourceInterval()
    return speed, interval
end

---@param entity wds.ResourceField
function MapResourceFieldModule:GetTotalResourceAmount(entity)
    if not entity or not entity.FieldInfo then
        return 1
    end
    local fieldInfo = entity.FieldInfo
    local config = ConfigRefer.FixedMapBuilding:Find(fieldInfo.ConfID)
    return config:OutputResourceMax()
end

---@param troopInfo TroopInfo
---@param preset wds.TroopPreset
---@param fieldEntity wds.ResourceField
function MapResourceFieldModule:PrecalculateCollectInfo(troopInfo, preset, fieldEntity)
    if not fieldEntity then
        return 0, 0
    end
    
    local troopAvailableLoad = 0
    if troopInfo and troopInfo.entityData then
        ---@type wds.Troop
        local troop = troopInfo.entityData
        local maxLoad = troop.GatherInfo.MaxLoad
        local totalLoad = troop.GatherInfo.TotalLoad
        troopAvailableLoad = maxLoad - totalLoad
    else
        troopAvailableLoad = ModuleRefer.SlgModule:GetTroopCollectLoadByPreset(preset)
    end
    local loadScale = self:GetLoadScaleByEntity(fieldEntity)
    local amount = self:LoadToAmount(troopAvailableLoad, loadScale)
    amount = math.min(amount, fieldEntity.FieldInfo.LeftResource)
    
    local fieldConfig = ConfigRefer.FixedMapBuilding:Find(fieldEntity.FieldInfo.ConfID)
    local baseSpeed = fieldConfig:OutputResourceCount()
    local interval = fieldConfig:OutputResourceInterval()
    local speedRatio =  ModuleRefer.SlgModule:GetTroopCollectSpeedByPreset(preset) / 100.0
    local time = self:CalculateCollectTime(amount, baseSpeed * (1 + speedRatio), interval)
    return amount, time
end

function MapResourceFieldModule:CalculateCollectTime(amount, speed, interval)
    local leftTime = math.ceil(amount / speed) * interval
    return leftTime
end

---@param fieldEntity wds.ResourceField
function MapResourceFieldModule:GetLoadScaleByEntity(fieldEntity)
    if fieldEntity then
        local config = ConfigRefer.FixedMapBuilding:Find(fieldEntity.FieldInfo.ConfID)
        local loadScale = self:GetLoadScaleByType(config:OutputType())
        return loadScale
    end
    return 1
end

---@param troop wds.Troop
function MapResourceFieldModule:IsTroopLoadFull(troop)
    return troop and troop.GatherInfo and troop.GatherInfo.TotalLoad >= troop.GatherInfo.MaxLoad
end

function MapResourceFieldModule:GetLoadScaleByType(outputType)
    if outputType == OutputResourceType.LoggingCamp then
        return ConfigRefer.ResourceFieldConsts:Log2LoadScale()
    elseif outputType == OutputResourceType.Farm then
        return ConfigRefer.ResourceFieldConsts:Farm2LoadScale()
    elseif outputType == OutputResourceType.StoneCamp then
        return ConfigRefer.ResourceFieldConsts:Stone2LoadScale()
    elseif outputType == OutputResourceType.LuoLing then
        return ConfigRefer.ResourceFieldConsts:LuoLing2LoadScale()
    elseif outputType == OutputResourceType.PetEgg then
        return ConfigRefer.ResourceFieldConsts:PetEgg2LoadScale()
    end
    return 1
end

---@param heroIDList number[]
---@param petIDList number[]
function MapResourceFieldModule:CalculateTroopMaxLoad(heroIDList, petIDList)
    local totalLoad = 0
    if heroIDList then
        for _, heroId in ipairs(heroIDList) do
            local load = ModuleRefer.TroopModule:GetTroopHeroCollectLoad(heroId)
            totalLoad = totalLoad + load
        end
    end
    if petIDList then
        for _, petID in ipairs(petIDList) do
            local load = ModuleRefer.TroopModule:GetTroopPetCollectLoad(petID)
            totalLoad = totalLoad + load
        end
    end
    return totalLoad
end

function MapResourceFieldModule:CheckCollectTimes()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player then
        return false
    end

    local currentTimes = player.PlayerWrapper3.PlayerGather.CurGatherTimes
    local maxTimes = ConfigRefer.ConstMain:GatherTimesPerDay()
    return currentTimes < maxTimes
end

---@param resourceFieldConfig FixedMapBuildingConfigCell
---@return PetConfigCell[]
function MapResourceFieldModule:GetMayHatchPetConfigs(resourceFieldConfig)
    local dropID = resourceFieldConfig:OutputResourcePetDrop()
    local dropItemGroupInfos = ModuleRefer.InventoryModule:GetDropItems(dropID)
    local petConfigs = {}
    for _, itemGroupInfo in ipairs(dropItemGroupInfos) do
        local itemID = itemGroupInfo:Items()
        local itemConfig = ConfigRefer.Item:Find(itemID)
    end
    return petConfigs
end

function MapResourceFieldModule:LoadToAmount(load, scale)
    return load // scale
end

---@return ResourceFieldIconWrap|nil
function MapResourceFieldModule:GetLod2IconGroup(typ)
    if self.lod2IconMap == nil then
        self:InitIconGroupCache()
    end
    return self.lod2IconMap[typ]
end

function MapResourceFieldModule:InitIconGroupCache()
    self.lod2IconMap = {}
    self:InsertLod2IconByConfig(ConfigRefer.ConstMain:ResourceFieldLod2IconFood())
    self:InsertLod2IconByConfig(ConfigRefer.ConstMain:ResourceFieldLod2IconWood())
    self:InsertLod2IconByConfig(ConfigRefer.ConstMain:ResourceFieldLod2IconStone())
    self:InsertLod2IconByConfig(ConfigRefer.ConstMain:ResourceFieldLod2IconRolin())
    self:InsertLod2IconByConfig(ConfigRefer.ConstMain:ResourceFieldLod2IconPetEgg())
end

---@param wrap ResourceFieldIconWrap
function MapResourceFieldModule:InsertLod2IconByConfig(wrap)
    self.lod2IconMap[wrap:Type()] = wrap
end

return MapResourceFieldModule