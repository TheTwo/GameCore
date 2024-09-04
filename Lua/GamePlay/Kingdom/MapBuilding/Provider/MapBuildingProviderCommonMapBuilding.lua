local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local PlayerModule = require("PlayerModule")

local MapBuildingProvider = require("MapBuildingProvider")

---@class MapBuildingProviderCommonMapBuilding:MapBuildingProvider
---@field new fun():MapBuildingProviderCommonMapBuilding
---@field super MapBuildingProvider
local MapBuildingProviderCommonMapBuilding = class('MapBuildingProviderCommonMapBuilding', MapBuildingProvider)

---@param entity wds.CommonMapBuilding
function MapBuildingProviderCommonMapBuilding.GetName(entity)
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    if entity.Owner.AllianceID > 0 then
        local name = I18N.Get(config:Name())
        return PlayerModule.FullName(entity.Owner.AllianceAbbr.String, name)
    end
    return I18N.Get(config:Name())
end

---@param entity wds.CommonMapBuilding
function MapBuildingProviderCommonMapBuilding.GetBuildingImage(entity)
    if not entity or not entity.MapBasics then
        return 'sp_icon_missing'
    end
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    local icon = config and config:Image()
    if string.IsNullOrEmpty(icon) then
        icon = 'sp_icon_missing'
    end
    return icon
end

---@param entity wds.CommonMapBuilding
function MapBuildingProviderCommonMapBuilding.GetLevel(entity)
    local config = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    return config:Level()
end

return MapBuildingProviderCommonMapBuilding