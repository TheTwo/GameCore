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
---@class PvPTileAssetSlgInteractorRadarBubble : CommonTileAssetSlgBubble
local PvPTileAssetSlgInteractorRadarBubble = class("PvPTileAssetSlgInteractorRadarBubble", CommonTileAssetSlgBubble)

---@return string
function PvPTileAssetSlgInteractorRadarBubble:GetLodPrefabName(lod)
    if self:CheckLod(lod) then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

function PvPTileAssetSlgInteractorRadarBubble:GetIcon()
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

function PvPTileAssetSlgInteractorRadarBubble:GetQuality()
    local entity = self:GetData()
    if not entity then
        return 0
    end
    return ModuleRefer.RadarModule:GetRadarTaskQuality(entity.ID)
end

function PvPTileAssetSlgInteractorRadarBubble:GetConfigData()
    local entity = self:GetData()
    if not entity or not entity.Interactor then
        return nil
    end
    return ConfigRefer.Mine:Find(entity.Interactor.ConfigID)
end

function PvPTileAssetSlgInteractorRadarBubble:CanShow()
    local entity = self:GetData()
    if not entity then
        return false
    end
    return ModuleRefer.RadarModule:IsRadarTaskEntity(entity.ID)
end

function PvPTileAssetSlgInteractorRadarBubble:GetCustomData()
    local entity = self:GetData()
    local param = {isRadarTaskBubble = true, type = ObjectType.SlgInteractor,
    X = entity.MapBasics.BuildingPos.X, Y = entity.MapBasics.BuildingPos.Y}
    return param
end

function PvPTileAssetSlgInteractorRadarBubble:GetYOffset()
    local conf = self:GetConfigData()
    if conf and conf:MapInstanceId() > 0 then
        return 150
    else
        return 200
    end
end

return PvPTileAssetSlgInteractorRadarBubble