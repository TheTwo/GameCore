local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityConst = require("CityConst")
local CityTilePriority = require("CityTilePriority")

local CityTileBase = require("CityTileBase")

---@class CitySafeAreaWallDoorTile:CityTileBase
---@field new fun():CitySafeAreaWallDoorTile
local CitySafeAreaWallDoorTile = class('CitySafeAreaWallDoorTile', CityTileBase)

---@return CitySafeAreaWallDoor
function CitySafeAreaWallDoorTile:GetCell()
    return self.gridView.safeAreaWallMgr:GetPlacedDoor(self.x, self.y)
end

function CitySafeAreaWallDoorTile:GetCameraSize()
    return CityConst.OTHER_MAX_VIEW_SIZE
end

function CitySafeAreaWallDoorTile:GetPriority()
    return CityTilePriority.SAFE_AREA_WALL_OR_DOOR
end

return CitySafeAreaWallDoorTile