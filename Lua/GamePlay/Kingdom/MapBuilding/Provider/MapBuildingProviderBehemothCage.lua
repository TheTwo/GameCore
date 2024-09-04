local ConfigRefer = require("ConfigRefer")
local PlayerModule = require("PlayerModule")
local I18N = require("I18N")

local MapBuildingProvider = require("MapBuildingProvider")

---@class MapBuildingProviderBehemothCage:MapBuildingProvider
---@field new fun():MapBuildingProviderBehemothCage
---@field super MapBuildingProvider
local MapBuildingProviderBehemothCage = class('MapBuildingProviderBehemothCage', MapBuildingProvider)

---@param entity wds.BehemothCage
function MapBuildingProviderBehemothCage.GetName(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.BehemothCage.ConfigId)
    if entity.Owner.AllianceID > 0 then
        local name = I18N.Get(config:Name())
        return PlayerModule.FullName(entity.Owner.AllianceAbbr.String, name)
    end
    return I18N.Get(config:Name())
end

---@param entity wds.BehemothCage
function MapBuildingProviderBehemothCage.GetBuildingImage(entity)
    if not entity or not entity.MapBasics then
        return 'sp_icon_missing'
    end
    local config = ConfigRefer.FixedMapBuilding:Find(entity.BehemothCage.ConfigId)
    local icon = config and config:Image()
    if string.IsNullOrEmpty(icon) then
        icon = 'sp_icon_missing'
    end
    return icon
end

---@param entity wds.BehemothCage
function MapBuildingProviderBehemothCage.GetLevel(entity)
    local config = ConfigRefer.FixedMapBuilding:Find(entity.BehemothCage.ConfigId)
    return config:Level()
end

return MapBuildingProviderBehemothCage