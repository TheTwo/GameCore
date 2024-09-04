---@class MapAssetNames
local MapAssetNames = {}

function MapAssetNames.GetSettingsName(mapName)
    return ("map_settings_%s"):format(mapName)
end

function MapAssetNames.GetBasemapName(mapName)
    return ("mdl_%s_basemap"):format(mapName)
end

function MapAssetNames.GetSymbolAtlasName(mapName)
    return ("map_symbol_atlas_%s"):format(mapName)
end

function MapAssetNames.GetHighlandName(mapName)
    return ("mdl_highland_%s"):format(mapName)
end

function MapAssetNames.GetAtlasName(mapName)
    return ("%s_map_atlas"):format(mapName)
end

function MapAssetNames.CollectAll(mapName, assetNames)
    assetNames:Add(MapAssetNames.GetSettingsName(mapName))
    assetNames:Add(MapAssetNames.GetBasemapName(mapName))
    assetNames:Add(MapAssetNames.GetSymbolAtlasName(mapName))
    assetNames:Add(MapAssetNames.GetHighlandName(mapName))
    assetNames:Add(MapAssetNames.GetAtlasName(mapName))
end

return MapAssetNames