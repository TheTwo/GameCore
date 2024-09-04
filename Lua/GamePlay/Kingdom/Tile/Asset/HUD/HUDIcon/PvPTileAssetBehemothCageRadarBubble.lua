local CommonTileAssetSlgBubble = require("CommonTileAssetSlgBubble")
local ModuleRefer = require("ModuleRefer")
local Utils = require('Utils')
local DBEntityType = require('DBEntityType')
local KingdomMapUtils = require('KingdomMapUtils')
local ArtResourceUtils = require('ArtResourceUtils')
local ObjectType = require('ObjectType')
local ConfigRefer = require('ConfigRefer')
local KingdomConstant = require('KingdomConstant')
local ManualResourceConst = require("ManualResourceConst")
local Delegate = require('Delegate')
local EventConst = require('EventConst')

---@class PvPTileAssetBehemothCageRadarBubble : CommonTileAssetSlgBubble
local PvPTileAssetBehemothCageRadarBubble = class("PvPTileAssetBehemothCageRadarBubble", CommonTileAssetSlgBubble)

---@return string
function PvPTileAssetBehemothCageRadarBubble:GetLodPrefabName(lod)
    if self:CheckLod(lod) then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

function PvPTileAssetBehemothCageRadarBubble:GetIcon()
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(entity.ID)
    local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
    if configInfo then
        return configInfo:RadarTaskIcon()
    end
    local conf = self:GetConfigData()
    if not conf then
        return string.Empty
    end
    if conf:MapInstanceId() > 0 then
        return "sp_comp_icon_radar_se"
    else
        return "sp_comp_icon_radar_collect"
    end
end

function PvPTileAssetBehemothCageRadarBubble:GetQuality()
    local entity = self:GetData()
    if not entity then
        return 0
    end
    return ModuleRefer.RadarModule:GetRadarTaskQuality(entity.ID)
end

function PvPTileAssetBehemothCageRadarBubble:CanShow()
    local entity = self:GetData()
    if not entity then
        return false
    end
    local isShow = ModuleRefer.RadarModule:IsRadarTaskEntity(entity.ID)
    if isShow then
        self:SetScout()
    end
    return isShow and not self.scoutHide
end

function PvPTileAssetBehemothCageRadarBubble:OnConstructionShutdown()
    PvPTileAssetBehemothCageRadarBubble.super.OnConstructionShutdown(self)
    g_Game.EventManager:RemoveListener(EventConst.RADAR_SCOUT_REFRESH, Delegate.GetOrCreate(self, self.ScoutComplete))
end

function PvPTileAssetBehemothCageRadarBubble:GetCustomData()
    local entity = self:GetData()
    local param = {isRadarTaskBubble = true, type = ObjectType.BehemothCage, X = entity.MapBasics.BuildingPos.X, Y = entity.MapBasics.BuildingPos.Y, entity = entity}
    return param
end

function PvPTileAssetBehemothCageRadarBubble:GetYOffset()
    return 300
end

function PvPTileAssetBehemothCageRadarBubble:SetScout()
    local entity = self:GetData()
    if self.setScout ~= entity.ID then
        self.setScout = entity.ID
        self.scoutHide = false
        ModuleRefer.RadarModule:SetScoutObject(entity, true)
        g_Game.EventManager:AddListener(EventConst.RADAR_SCOUT_REFRESH, Delegate.GetOrCreate(self, self.ScoutComplete))
    end
end

function PvPTileAssetBehemothCageRadarBubble:ScoutComplete(entityID)
    if entityID == self.setScout then
        self.scoutHide = true
        self.setScout = nil
        self:Hide()
        g_Game.EventManager:RemoveListener(EventConst.RADAR_SCOUT_REFRESH, Delegate.GetOrCreate(self, self.ScoutComplete))
    end
end

return PvPTileAssetBehemothCageRadarBubble
