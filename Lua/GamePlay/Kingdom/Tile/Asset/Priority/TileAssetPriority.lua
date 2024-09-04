---@class TileAssetPriority
local TileAssetPriority = class("TileAssetPriority")

local Priority =
{
    ["MapTileAssetUnit"] = 100,
    ["PvPTileAssetHUDIcon"] = 200,
    ["PvPTileAssetBridge"] = 1000,
    ["PvPTileAssetSlope"] = 1000,
    ["PvPTileAssetGate"] = 1000,
}

function TileAssetPriority.Get(className)
    return Priority[className] or 0
end

return TileAssetPriority