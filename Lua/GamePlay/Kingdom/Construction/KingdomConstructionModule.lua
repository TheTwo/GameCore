local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local KingdomConstructionCantPlaceReason = require("KingdomConstructionCantPlaceReason")
local MapBuildingType = require("MapBuildingType")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local DBEntityType = require("DBEntityType")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local AreaShape = require('AreaShape')
local I18N= require("I18N")
local AllianceAttr = require("AllianceAttr")

---@class FlexibleMapBuildingUIData
---@field Config FlexibleMapBuildingConfigCell
---@field Count number

---@class KingdomConstructionModule : BaseModule
---@field fixedConfigsByType table<number, table<number>>
local KingdomConstructionModule = class("KingdomConstructionModule", BaseModule)

function KingdomConstructionModule:OnRegister()
    --init by type cache
    self.fixedConfigsByType = {}
    for i, config in ConfigRefer.FixedMapBuilding:ipairs() do
        local type = config:Type()
        local list = self.fixedConfigsByType[type]
        if not list then
            list = {}
            self.fixedConfigsByType[type] = list
        end
        table.insert(list, config:Id())
    end
end

function KingdomConstructionModule:OnRemove()
    table.clear(self.fixedConfigsByType)
end

---@param filterType number
---@return FlexibleMapBuildingUIData[]
function KingdomConstructionModule:GetSortedBuildingList(filterType, mapBuildingType)
    ---@type FlexibleMapBuildingUIData[]
    local result = {}
    for _, cell in ConfigRefer.FlexibleMapBuilding:ipairs() do
        if filterType == cell:FilterType() and mapBuildingType == cell:Type() then
            local count = self:GetBuildingCountByConfig(cell)
            ---@type FlexibleMapBuildingUIData
            local data = {}
            data.Config = cell
            data.Count = count
            table.insert(result, data)
        end
    end
    local techModule = ModuleRefer.AllianceTechModule
    table.sort(result, function(a, b) 
        local unlockA = techModule:IsBuildingTechSatisfy(a.Config)
        local unlockB = techModule:IsBuildingTechSatisfy(b.Config)
        if unlockA and not unlockB then
            return true
        elseif unlockB == unlockA then
            return a.Config:Id() < b.Config:Id()
        end
        return false
    end)
    return result
end

---@param buildingConfigCell FlexibleMapBuildingConfigCell
---@return number
function KingdomConstructionModule.CanPlace(buildingConfigCell)
    if not ModuleRefer.KingdomConstructionModule:CheckBuildingResourceRequirement(buildingConfigCell) then
        return KingdomConstructionCantPlaceReason.ResourceLimit
    elseif not ModuleRefer.KingdomConstructionModule:CheckBuildingCountLimit(buildingConfigCell) then
        return KingdomConstructionCantPlaceReason.CountLimit
    elseif not ModuleRefer.AllianceModule:IsInAlliance() then
        return KingdomConstructionCantPlaceReason.AllianceLimit
    elseif not ModuleRefer.KingdomConstructionModule:CheckBuildingAuthority(buildingConfigCell:Type()) then
        return KingdomConstructionCantPlaceReason.AuthorityLimit
    elseif not ModuleRefer.KingdomConstructionModule:CheckBuildingTechRequire(buildingConfigCell) then
        return KingdomConstructionCantPlaceReason.TechRequire
    elseif not ModuleRefer.KingdomConstructionModule:CheckBuildingSystemEntryUnlocked(buildingConfigCell) then
        return KingdomConstructionCantPlaceReason.SystemEntryLock
    end 
    return KingdomConstructionCantPlaceReason.OK
end

---@param reason number
---@param buildingConfig FlexibleMapBuildingConfigCell
function KingdomConstructionModule.CantPlaceToast(reason, buildingConfig)
    if reason == KingdomConstructionCantPlaceReason.ResourceLimit then
        return "world_build_ziyuanbuzu"
    elseif reason == KingdomConstructionCantPlaceReason.CountLimit then
        return "world_build_shangxian"
    elseif reason == KingdomConstructionCantPlaceReason.AuthorityLimit then
        return "world_build_quanxian"
    elseif reason == KingdomConstructionCantPlaceReason.TechRequire then
        return "alliance_jz_lingdichakan"
    elseif reason == KingdomConstructionCantPlaceReason.SystemEntryLock then
        local tip = string.Empty
        if buildingConfig and buildingConfig:BuildSystemSwitch() ~= 0 then
            tip = ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(buildingConfig:BuildSystemSwitch())
        end
        if string.IsNullOrEmpty(tip) then
            tip = "build_unknown"
        end
        return tip
    end
    return "world_build_weizhi"
end

---@param typeHash number
function KingdomConstructionModule:GetBuildingCount(typeHash, flexibleMapBuildingType)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return 0
    end
    
    local buildingBriefs = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    if not buildingBriefs then
        return 0
    end
    local count = 0
    for _, buildingBrief in pairs(buildingBriefs) do
        if buildingBrief.EntityTypeHash == typeHash then
            if typeHash == DBEntityType.CommonMapBuilding then
                local config = ConfigRefer.FlexibleMapBuilding:Find(buildingBrief.ConfigId)
                if config and config:Type() == flexibleMapBuildingType then
                    count = count + 1
                end
            else
                count = count + 1
            end
        end
    end
    return count
end

---@param buildingConfigCell FlexibleMapBuildingConfigCell
function KingdomConstructionModule:CheckBuildingResourceRequirement(buildingConfigCell)
    local currency = buildingConfigCell:CostAllianceCurrency()
    local currencyCount = buildingConfigCell:CostAllianceCurrencyCount()
    if currency ~= 0 and currencyCount > 0 then
        return ModuleRefer.AllianceModule:GetAllianceCurrencyById(currency) >= currencyCount
    end
    return true
end

---@param buildingConfigCell FlexibleMapBuildingConfigCell
function KingdomConstructionModule:CheckBuildingCountLimit(buildingConfigCell)
    local buildingType = buildingConfigCell:Type()
    if buildingType == FlexibleMapBuildingType.EnergyTower 
            or buildingType == FlexibleMapBuildingType.DefenseTower 
            or buildingType == FlexibleMapBuildingType.BehemothDevice 
            or buildingType == FlexibleMapBuildingType.BehemothSummoner then
        local lvLimit = self:GetBuildingLimitCount(buildingConfigCell)
        local lvCount = self:GetBuildingCountByConfig(buildingConfigCell)
        return lvCount < lvLimit
    else
        local typeHash = KingdomConstructionModule.ConfigTypeToEntityType(buildingConfigCell:Type())
        local count = self:GetBuildingCount(typeHash, buildingConfigCell:Type())
        return count < buildingConfigCell:BuildCountMax()
    end
end

---@param buildingType number FlexibleMapBuildingType
function KingdomConstructionModule:CheckBuildingAuthority(buildingType)
    local authorityItem = KingdomConstructionModule.ConfigTypeToAuthorityItem(buildingType)
    return ModuleRefer.AllianceModule:CheckHasAuthority(authorityItem)
end

---@param buildingType number FlexibleMapBuildingType
function KingdomConstructionModule:CheckSupportBuildingAuthority(buildingType)
    return true
end

---@param buildingConfigCell FlexibleMapBuildingConfigCell
function KingdomConstructionModule:CheckBuildingTechRequire(buildingConfigCell)
    return ModuleRefer.AllianceTechModule:IsBuildingTechSatisfy(buildingConfigCell)
end

---@param buildingConfigCell FlexibleMapBuildingConfigCell
function KingdomConstructionModule:CheckBuildingSystemEntryUnlocked(buildingConfigCell)
    local entryLock = buildingConfigCell:BuildSystemSwitch()
    if entryLock == 0 then return true end
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(entryLock)
end

function KingdomConstructionModule:GetNameByBuildingType(buildingType)
    if buildingType == FlexibleMapBuildingType.EnergyTower then
        return I18N.Get("alliance_territory_10")
    elseif buildingType == FlexibleMapBuildingType.DefenseTower then
        return I18N.Get("alliance_territory_9")
    elseif buildingType == FlexibleMapBuildingType.BehemothDevice then
        return I18N.Get("alliance_behemothActivity_title_device")
    elseif buildingType == FlexibleMapBuildingType.BehemothSummoner then
        return I18N.Get("alliance_behemothActivity_title_summon") 
    end
    return I18N.Get("*UNKNOWN")
end

function KingdomConstructionModule:GetNameAndCountByBuildingType(buildingType, has, max)
    if buildingType == FlexibleMapBuildingType.EnergyTower then
        return I18N.GetWithParams("alliance_territory_13", tostring(has), tostring(max))
    elseif buildingType == FlexibleMapBuildingType.DefenseTower then
        return I18N.GetWithParams("alliance_territory_12", tostring(has), tostring(max))
    elseif buildingType == FlexibleMapBuildingType.BehemothDevice then
        return I18N.Get("alliance_behemothActivity_title_device") .. (" (%s/%s)"):format(tostring(has), tostring(max))
    elseif buildingType == FlexibleMapBuildingType.BehemothSummoner then
        return I18N.Get("alliance_behemothActivity_title_summon") .. (" (%s/%s)"):format(tostring(has), tostring(max))
    end
    return I18N.Get("*UNKNOWN")
end

---@param buildingConfig FlexibleMapBuildingConfigCell
---@return number
function KingdomConstructionModule:GetBuildingCountByConfig(buildingConfig)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return 0
    end
    local configId = buildingConfig:Id()
    local buildingType = buildingConfig:Type()
    local typeHash = KingdomConstructionModule.ConfigTypeToEntityType(buildingType)
    if typeHash then
        local buildingBriefs = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
        if not buildingBriefs then
            return 0
        end
        local count = 0
        for _, v in pairs(buildingBriefs) do
            if v.EntityTypeHash == typeHash and configId == v.ConfigId then
                count = count + 1
            end
        end
        return count
    end
    return 0
end

---@param buildingConfig FlexibleMapBuildingConfigCell
---@return number
function KingdomConstructionModule:GetBuildingLimitCount(buildingConfig)
    local buildingType = buildingConfig:Type()
    if buildingType == FlexibleMapBuildingType.EnergyTower then
        local lv = math.clamp(buildingConfig:Level(), 1, 5)
        local attr = AllianceAttr[("EnergyTower_Lv_%d_Count_Limit"):format(lv)]
        return ModuleRefer.AllianceTechModule:GetTechAttrDisplayValue(attr, 0)
    elseif buildingType == FlexibleMapBuildingType.DefenseTower  then
        local lv = math.clamp(buildingConfig:Level(), 1, 5)
        local attr = AllianceAttr[("DefenceTower_Lv_%d_Count_Limit"):format(lv)]
        return ModuleRefer.AllianceTechModule:GetTechAttrDisplayValue(attr, 0)
    else
        return buildingConfig:BuildCountMax()
    end
end

---@param buildingType number @FlexibleMapBuildingType
---@return number, number
function KingdomConstructionModule:GetBuildingTypeCountAndLimitCount(buildingType)
    local typeHash = KingdomConstructionModule.ConfigTypeToEntityType(buildingType)
    if typeHash then
        local limitCount = 0
        if buildingType == FlexibleMapBuildingType.EnergyTower then
            for id = AllianceAttr.EnergyTower_Lv_1_Count_Limit, AllianceAttr.EnergyTower_Lv_5_Count_Limit do
                limitCount = limitCount + ModuleRefer.AllianceTechModule:GetTechAttrDisplayValue(id, 0)
            end
        elseif buildingType == FlexibleMapBuildingType.DefenseTower then
            for id = AllianceAttr.DefenceTower_Lv_1_Count_Limit, AllianceAttr.DefenceTower_Lv_5_Count_Limit do
                limitCount = limitCount + ModuleRefer.AllianceTechModule:GetTechAttrDisplayValue(id, 0)
            end
        elseif buildingType == FlexibleMapBuildingType.BehemothDevice or buildingType == FlexibleMapBuildingType.BehemothSummoner then
            for _, v in ConfigRefer.FlexibleMapBuilding:ipairs() do
                if buildingType == v:Type() then
                    limitCount = limitCount + v:BuildCountMax()
                end
            end
        end
        return self:GetBuildingCount(typeHash, buildingType), limitCount
    end
    return 0, 0
end

---@param mapBuildingType number
---@return number[]
function KingdomConstructionModule:GetFixedBuildingConfigsByType(mapBuildingType)
    local list = self.fixedConfigsByType[mapBuildingType]
    return list
end

function KingdomConstructionModule:CanBreak(entity)
    if self:IsMyBuilding(entity.Owner) then
        return true
    end
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    return self:IsBuildingSameAlliance(entity.Owner) and self:CheckBuildingAuthority(buildingConfig:Type())
end

function KingdomConstructionModule:CanSupportBuild(entity)
    if self:IsMyBuilding(entity.Owner) then
        return true
    end
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    return self:IsBuildingSameAlliance(entity.Owner) and self:CheckSupportBuildingAuthority(buildingConfig:Type())
end

---@param entity wds.EnergyTower
function KingdomConstructionModule:IsBuildingConstructing(entity)
    if entity.TypeHash == DBEntityType.Village then
        ---@type wds.Village
        local village = entity
        return village.VillageTransformInfo.Status == wds.VillageTransformStatus.VillageTransformStatusProcessing
    end
    return entity.Construction and entity.Construction.Status == wds.BuildingConstructionStatus.BuildingConstructionStatusProcessing
end

---@param entity wds.EnergyTower|wds.Village
function KingdomConstructionModule:IsBuildingBroken(entity)
    local underConstruction = self:IsBuildingConstructing(entity)
    local fullDurability = entity.Battle and entity.Battle.Durability >= entity.Battle.MaxDurability
    local villageInBattle = entity.Village and entity.Village.InBattle
    return (villageInBattle or not underConstruction) and not fullDurability 
end

---@param owner wds.Owner
function KingdomConstructionModule:IsMyBuilding(owner)
    return owner and owner.PlayerID == ModuleRefer.PlayerModule:GetPlayer().ID
end

---@param owner wds.Owner
function KingdomConstructionModule:IsBuildingSameAlliance(owner)
    return ModuleRefer.AllianceModule:IsInAlliance() and owner and owner.AllianceID == ModuleRefer.AllianceModule:GetAllianceId()
end

function KingdomConstructionModule:GetBuildingAffectedRange(entity)
    local mapBasics = entity.MapBasics
    local positionX = mapBasics.Position.X
    local positionY = mapBasics.Position.Y
    local buildingX = mapBasics.BuildingPos.X
    local buildingY = mapBasics.BuildingPos.Y
    if entity.TypeHash == DBEntityType.Expedition then
        local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
        local ra = eventCfg:RadiusA()
        if eventCfg:Shape() == AreaShape.Ellipse then
            local rb = eventCfg:RadiusB()
            -- local rot = math.radian2angle(instanceCfg:Rot())
            local rot = 0
            local rectX = math.sqrt(ra * ra * math.cos(rot) * math.cos(rot) + rb * rb * math.sin(rot) * math.sin(rot))
            local sizeA = math.ceil(rectX * 2)
            local rectY = math.sqrt(rb * rb * math.cos(rot) * math.cos(rot) + ra * ra * math.sin(rot) * math.sin(rot))
            local sizeB = math.ceil(rectY * 2)
            return math.floor(buildingX - rectX), math.floor(buildingY - rectY), sizeA, sizeB
        else
            return math.floor(buildingX - ra), math.floor(buildingY - ra), math.ceil(ra * 2), math.ceil(ra * 2)
        end
    elseif entity.TypeHash == DBEntityType.EnergyTower
        or entity.TypeHash == DBEntityType.DefenceTower then
        local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
        local size = buildingConfig:EffectRaid()
        return math.floor(positionX - size),
                math.floor(positionY - size),
                math.ceil(positionX + size),
                math.ceil(positionY + size)
    else
        local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(mapBasics.LayoutCfgId)
        return buildingX, buildingY, layout.SizeX, layout.SizeY
    end
end

---@param configType number
function KingdomConstructionModule.ConfigTypeToEntityType(configType)
    if configType == FlexibleMapBuildingType.EnergyTower then
        return DBEntityType.EnergyTower
    elseif configType == FlexibleMapBuildingType.MobileFortress then
        return DBEntityType.MobileFortress
    elseif configType == FlexibleMapBuildingType.TransferTower then
        return DBEntityType.TransferTower
    elseif configType == FlexibleMapBuildingType.DefenseTower then
        return DBEntityType.DefenceTower
    elseif configType == FlexibleMapBuildingType.BehemothDevice then
        return DBEntityType.CommonMapBuilding
    elseif configType == FlexibleMapBuildingType.BehemothSummoner then
        return DBEntityType.CommonMapBuilding
    end
    return nil
end

---@param configType number
function KingdomConstructionModule.ConfigTypeToAuthorityItem(configType)
    if configType == FlexibleMapBuildingType.EnergyTower then
        return AllianceAuthorityItem.BuildEnergyTower
    elseif configType == FlexibleMapBuildingType.MobileFortress then
        return AllianceAuthorityItem.BuildMobileFortress
    elseif configType == FlexibleMapBuildingType.DefenseTower then
        return AllianceAuthorityItem.BuildDefenceTower
    elseif configType == FlexibleMapBuildingType.BehemothDevice then
        return AllianceAuthorityItem.BuildBehemothDevice
    elseif configType == FlexibleMapBuildingType.BehemothSummoner then
        return AllianceAuthorityItem.BuildBehemothSummoner
    end
    return nil
end

return KingdomConstructionModule
