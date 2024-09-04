local KingdomEntityDataWrapper = require("KingdomEntityDataWrapper")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local I18N = require("I18N")
local KingdomDataWrapperHelper = require("KingdomDataWrapperHelper")
local ObjectType = require("ObjectType")
local MapConfigCache = require("MapConfigCache")
local ConfigRefer = require("ConfigRefer")

local BUILDING_ICON_INDEX = 0
local BUILDING_LEVEL_TEXT_INDEX = 1
local BUILDING_LEVEL_BACKGROUND_INDEX = 2
local BUILDING_NAME_TEXT_INDEX = 3
local BUILDING_NAME_BACKGROUND_INDEX = 4
local BUILDING_LEVEL_SINGLE_TEXT_INDEX = 5
local BUILDING_LEVEL_SINGLE_BACKGROUND_INDEX = 6

---@class KingdomLandmarkDataWrapper : KingdomEntityDataWrapper
local KingdomLandmarkDataWrapper = class("KingdomLandmarkDataWrapper", KingdomEntityDataWrapper)

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetLodPrefab(brief, lod)
    local coord = self:GetCenterCoordinate(brief)
    local x, z = coord.X, coord.Y
    if not ModuleRefer.MapFogModule:IsFogUnlocked(x, z) then
        return string.Empty
    end

    if KingdomMapUtils.CheckIconLodByFixedConfig(brief.CfgId, lod) or (brief.IsAllianceCenter and ModuleRefer.PlayerModule:IsFriendlyById(brief.AllianceId, brief.PlayerId)) then
        return require("KingdomEntityDataWrapperFactory").GetPrefabName(brief.ObjectType)
    end
    return string.Empty
end

---@param refreshData KingdomRefreshData
---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:FeedData(refreshData, brief)
    local id = brief.ObjectId
    local icon = self:GetIcon(brief)
    local levelBase = self:GetLevelBase(brief)
    
    refreshData:SetSprite(id, BUILDING_ICON_INDEX, icon)
    refreshData:SetSprite(id, BUILDING_LEVEL_BACKGROUND_INDEX, levelBase)
    refreshData:SetSprite(id, BUILDING_LEVEL_SINGLE_BACKGROUND_INDEX, levelBase)
    refreshData:SetClick(id, BUILDING_ICON_INDEX)

    local level = self:GetLevel(brief)
    refreshData:SetText(id, BUILDING_LEVEL_TEXT_INDEX, level)
    refreshData:SetText(id, BUILDING_LEVEL_SINGLE_TEXT_INDEX, level)
    
    local name = self:GetName(brief)
    local color = self:GetColor(brief)
    refreshData:SetText(id, BUILDING_NAME_TEXT_INDEX, name)
    refreshData:SetColor(id, BUILDING_NAME_TEXT_INDEX, color)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomLandmarkDataWrapper:OnShowIcon(refreshData, delayInvoker, id, immediately)
    KingdomDataWrapperHelper.ShowSprite(refreshData, delayInvoker, id, BUILDING_ICON_INDEX, immediately)

end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomLandmarkDataWrapper:OnHideIcon(refreshData, delayInvoker, id, immediately)
    KingdomDataWrapperHelper.HideSprite(refreshData, delayInvoker, id, BUILDING_ICON_INDEX, immediately)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomLandmarkDataWrapper:OnShowName(refreshData, delayInvoker, id, immediately)
    KingdomDataWrapperHelper.ShowText(refreshData, delayInvoker, id, BUILDING_LEVEL_TEXT_INDEX, immediately)
    KingdomDataWrapperHelper.ShowSprite(refreshData, delayInvoker, id, BUILDING_LEVEL_BACKGROUND_INDEX, immediately)
    KingdomDataWrapperHelper.ShowText(refreshData, delayInvoker, id, BUILDING_NAME_TEXT_INDEX, immediately)
    KingdomDataWrapperHelper.ShowSprite(refreshData, delayInvoker, id, BUILDING_NAME_BACKGROUND_INDEX, immediately)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomLandmarkDataWrapper:OnHideName(refreshData, delayInvoker, id, immediately)
    KingdomDataWrapperHelper.HideText(refreshData, delayInvoker, id, BUILDING_LEVEL_TEXT_INDEX, immediately)
    KingdomDataWrapperHelper.HideSprite(refreshData, delayInvoker, id, BUILDING_LEVEL_BACKGROUND_INDEX, immediately)
    KingdomDataWrapperHelper.HideText(refreshData, delayInvoker, id, BUILDING_NAME_TEXT_INDEX, immediately)
    KingdomDataWrapperHelper.HideSprite(refreshData, delayInvoker, id, BUILDING_NAME_BACKGROUND_INDEX, immediately)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomLandmarkDataWrapper:OnShowLevel(refreshData, delayInvoker, id, immediately)
    KingdomDataWrapperHelper.ShowText(refreshData, delayInvoker, id, BUILDING_LEVEL_SINGLE_TEXT_INDEX, immediately)
    KingdomDataWrapperHelper.ShowSprite(refreshData, delayInvoker, id, BUILDING_LEVEL_SINGLE_BACKGROUND_INDEX, immediately)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomLandmarkDataWrapper:OnHideLevel(refreshData, delayInvoker, id, immediately)
    KingdomDataWrapperHelper.HideText(refreshData, delayInvoker, id, BUILDING_LEVEL_SINGLE_TEXT_INDEX, immediately)
    KingdomDataWrapperHelper.HideSprite(refreshData, delayInvoker, id, BUILDING_LEVEL_SINGLE_BACKGROUND_INDEX, immediately)
end

function KingdomLandmarkDataWrapper:GetCenterCoordinate(brief)
    return MapConfigCache.GetCenterCoordinate(brief.VID)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetCenterPosition(brief)
    return MapConfigCache.GetCenterPosition(brief.VID)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetIcon(brief)
    local isCreepInfected = KingdomMapUtils.IsMapEntityBriefCreepInfected(brief)
    return ModuleRefer.VillageModule:GetVillageIcon(brief.AllianceId, brief.PlayerId, brief.CfgId, brief.IsAllianceCenter, isCreepInfected)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetLevelBase(brief)
    return ModuleRefer.VillageModule:GetVillageLevelBaseSprite(brief.CfgId)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetName(brief)
    if brief.IsAllianceCenter then
        return I18N.Get("alliance_center_title")
    end
    return MapConfigCache.GetName(brief.VID)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetColor(brief)
    local isCreep = KingdomMapUtils.IsMapEntityBriefCreepInfected(brief)
    return ModuleRefer.MapBuildingTroopModule:GetColorByID(brief.PlayerId, brief.AllianceId, isCreep)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:GetLevel(brief)
    return MapConfigCache.GetLevel(brief.VID)
end

---@param brief wds.MapEntityBrief
function KingdomLandmarkDataWrapper:OnIconClick(brief)
    local coord = self:GetCenterCoordinate(brief)
    local name = self:GetName(brief)
    local level = self:GetLevel(brief)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(coord.X, coord.Y, name, level)
    ModuleRefer.KingdomTouchInfoModule:Hide()
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

return KingdomLandmarkDataWrapper