local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local PlayerModule = require("PlayerModule")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")

local MapBuildingProvider = require("MapBuildingProvider")

---@class MapBuildingProviderDefenseTower : MapBuildingProvider
local MapBuildingProviderDefenseTower = class("MapBuildingProviderDefenseTower", MapBuildingProvider)

---@param entity wds.DefenceTower
function MapBuildingProviderDefenseTower.GetName(entity)
    if not entity then return string.Empty end
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    local name = config and I18N.Get(config:Name()) or string.Empty
    if entity.Owner.AllianceID > 0 then
        return PlayerModule.FullName(entity.Owner.AllianceAbbr.String, name)
    end
    return name
end

---@param entity wds.DefenceTower
function MapBuildingProviderDefenseTower.GetLevel(entity)
    if not entity then return 0 end
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    return config and config:Level() or 0
end

---@param entity wds.DefenceTower
function MapBuildingProviderDefenseTower.GetBuildingImage(entity)
    if not entity then return 0 end
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    return config and config:Image() or string.Empty
end

---@param entity wds.DefenceTower
function MapBuildingProviderDefenseTower.GetIcon(entity, lod)
    local icon
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    if ModuleRefer.PlayerModule:IsFriendly(entity.Owner) then
        icon = ArtResourceUtils.GetUIItem(config:LodIconOwn())
    else
        icon = ArtResourceUtils.GetUIItem(config:LodIconOther())
    end
    return icon
end

return MapBuildingProviderDefenseTower