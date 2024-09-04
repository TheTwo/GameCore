local MapBuildingProvider = require("MapBuildingProvider")
local ConfigRefer = require("ConfigRefer")
local PlayerModule = require("PlayerModule")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")

---@class MapBuildingProviderVillage : MapBuildingProvider
local MapBuildingProviderVillage = class("MapBuildingProviderVillage", MapBuildingProvider)

---@param entity wds.Village
function MapBuildingProviderVillage.GetName(entity)
    local isCenter = ModuleRefer.VillageModule:IsAllianceCenter(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    if entity.Owner.AllianceID > 0 then
        local name = I18N.Get(config:Name())
        if isCenter then
            name = I18N.Get("alliance_center_title")
        end
        return PlayerModule.FullName(entity.Owner.AllianceAbbr.String, name)
    end
    if isCenter then
        return I18N.Get("alliance_center_title")
    end
    return I18N.Get(config:Name())
end

---@param entity wds.Village
function MapBuildingProviderVillage.GetLevel(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    return config:Level()
end

function MapBuildingProviderVillage.GetBuildingImage(entity)
    if not entity or not entity.MapBasics then
        return 'sp_icon_missing'
    end
    local config = ConfigRefer.FixedMapBuilding:Find(entity.MapBasics.ConfID)
    local icon = config and config:Image()
    if string.IsNullOrEmpty(icon) then
        icon = 'sp_icon_missing'
    end
    return icon
end

return MapBuildingProviderVillage