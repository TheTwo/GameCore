local MapBuildingProvider = require("MapBuildingProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")

---@class MapBuildingProviderCastle : MapBuildingProvider
local MapBuildingProviderCastle = class("MapBuildingProviderCastle", MapBuildingProvider)

local IconMine = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_1)
local IconAlliance = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_3)
local IconHostile = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_2)
local IconNeutral = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_4)
local IconAllianceDot = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_dot_2)
local IconAllianceLeaderDot = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_dot_2_leader)
local CastleDotIconLod = ConfigRefer.ConstBigWorld:CastleDotIconLod()

---@param entity wds.CastleBrief
function MapBuildingProviderCastle.GetName(entity)
    return ModuleRefer.PlayerModule.FullNameOwner(entity.Owner, true)
end

---@param entity wds.CastleBrief
function MapBuildingProviderCastle.GetLevel(entity)
    return ModuleRefer.MapBuildingTroopModule:GetStrongholdLevel(entity)
end

---@param entity wds.CastleBrief
function MapBuildingProviderCastle.GetBuildingImage(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    return config and config:Image() or string.Empty
end

---@param entity wds.CastleBrief
function MapBuildingProviderCastle.GetIcon(entity, lod)
    local icon
    if ModuleRefer.PlayerModule:IsMine(entity.Owner) then
        icon = IconMine
    elseif ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
        if lod >= CastleDotIconLod then
            if ModuleRefer.AllianceModule:IsInAlliance() and ModuleRefer.AllianceModule:GetAllianceLeaderInfo().PlayerID == entity.Owner.PlayerID then
                icon = IconAllianceLeaderDot
            else
                icon = IconAllianceDot
            end
        else
            icon = IconAlliance
        end
    elseif ModuleRefer.PlayerModule:IsHostile(entity.Owner) then
        icon = IconHostile
    else
        icon = IconNeutral
    end
    return icon
end

return MapBuildingProviderCastle