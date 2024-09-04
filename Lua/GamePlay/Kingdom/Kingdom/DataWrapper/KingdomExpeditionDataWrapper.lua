local KingdomEntityDataWrapper = require("KingdomEntityDataWrapper")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local ObjectType = require("ObjectType")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")

local MapUtils = CS.Grid.MapUtils

local EVENT_ICON_INDEX = 0
local EVENT_FRAME_INDEX = 1

local QualitySprite =
{
    "sp_world_base_1",
    "sp_world_base_2",
    "sp_world_base_3",
    "sp_world_base_4",
}

---@class KingdomExpeditionDataWrapper : KingdomEntityDataWrapper
local KingdomExpeditionDataWrapper = class("KingdomExpeditionDataWrapper", KingdomEntityDataWrapper)

---@param brief wds.MapEntityBrief
function KingdomExpeditionDataWrapper:GetLodPrefab(brief, lod)
    return require("KingdomEntityDataWrapperFactory").GetPrefabName(brief.ObjectType)
end


---@param refreshData KingdomRefreshData
---@param brief wds.MapEntityBrief
function KingdomExpeditionDataWrapper:FeedData(refreshData, brief, showLevel)
    local id = brief.ObjectId
    refreshData:SetSprite(id, EVENT_ICON_INDEX, self:GetIcon(brief))
    refreshData:SetSprite(id, EVENT_FRAME_INDEX, self:GetFrame(brief))
    refreshData:SetClick(id, EVENT_ICON_INDEX)
end
---@param brief wds.MapEntityBrief
function KingdomExpeditionDataWrapper:GetCoordinate(brief)
    local config = ConfigRefer.WorldExpeditionTemplateInstance:Find(brief.CfgId)
    if not config then
        g_Logger.Error("can't find expedition config! id=%s", brief.CfgId)
        return 0, 0
    end
    local pos = config:Pos()
    return KingdomMapUtils.ParseCoordinate(pos:X(), pos:Y())
end

---@param brief wds.MapEntityBrief
function KingdomExpeditionDataWrapper:GetIcon(brief)
    local expeditionConfig = ConfigRefer.WorldExpeditionTemplate:Find(brief.CfgId)
    local sovereignConfig = ConfigRefer.Sovereign:Find(expeditionConfig:SovereignConfig())
    if sovereignConfig then
        return sovereignConfig:Icon()
    else
        return "sp_comp_icon_worldevent"
    end
end

---@param brief wds.MapEntityBrief
function KingdomExpeditionDataWrapper:GetFrame(brief)
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local quality = (radarInfo.ExpeditionQuality[brief.ObjectId] or {}).QualityType
    if quality and quality >= 0 then
        local qualityIndex = math.clamp(quality + 1, 1, #QualitySprite)
        return QualitySprite[qualityIndex]
    else
        return QualitySprite[1]
    end
end

function KingdomExpeditionDataWrapper:GetName(brief)
    return string.Empty
end

---@param brief wds.MapEntityBrief
---@return string
function KingdomExpeditionDataWrapper:GetLevel(brief)
    return string.Empty
end

---@param brief wds.MapEntityBrief
function KingdomExpeditionDataWrapper:OnIconClick(brief)
    local x, z = self:GetCoordinate(brief)
    local position = MapUtils.CalculateCoordToTerrainPosition(x, z, KingdomMapUtils.GetMapSystem())
    local touchData = KingdomTouchInfoFactory.CreateExpedition(brief.CfgId, position)
    ModuleRefer.KingdomTouchInfoModule:Hide()
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

return KingdomExpeditionDataWrapper