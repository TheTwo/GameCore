local CityTileAssetLegoUnit = require("CityTileAssetLegoUnit")
---@class CityTileAssetLegoBuildingFloor:CityTileAssetLegoUnit
---@field new fun():CityTileAssetLegoBuildingFloor
local CityTileAssetLegoBuildingFloor = class("CityTileAssetLegoBuildingFloor", CityTileAssetLegoUnit)

---@param legoBuilding CityLegoBuilding
---@param legoFloor CityLegoFloor
function CityTileAssetLegoBuildingFloor:ctor(legoBuilding, legoFloor, indoor)
    CityTileAssetLegoUnit.ctor(self, legoBuilding, legoFloor:GetCfgId(), legoFloor:GetStyle(indoor), indoor)
    self.legoBuilding = legoBuilding
    self.legoFloor = legoFloor
end

function CityTileAssetLegoBuildingFloor:GetWorldPosition()
    return self.legoFloor:GetWorldPosition()
end

function CityTileAssetLegoBuildingFloor:GetDecorations(indoor)
    return self.legoFloor:GetDecorations(indoor)
end

function CityTileAssetLegoBuildingFloor:GetInstanceId()
    return self.legoFloor.payload:Id()
end

function CityTileAssetLegoBuildingFloor:GetType()
    return "地板"
end

return CityTileAssetLegoBuildingFloor