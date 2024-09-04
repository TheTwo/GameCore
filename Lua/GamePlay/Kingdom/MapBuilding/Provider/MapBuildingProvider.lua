---@class MapBuildingProvider
local MapBuildingProvider = class("MapBuildingProvider")

function MapBuildingProvider.GetName(entity)
    return string.Empty
end

function MapBuildingProvider.GetLevel(entity)
    return 0
end

function MapBuildingProvider.GetBuildingImage(entity)
    return string.Empty
end

function MapBuildingProvider.GetIcon(entity, lod)
end

return MapBuildingProvider