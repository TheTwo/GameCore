local CityTileAssetLegoUnit = require("CityTileAssetLegoUnit")
---@class CityTileAssetLegoBuildingBlock:CityTileAssetLegoUnit
---@field new fun():CityTileAssetLegoBuildingBlock
local CityTileAssetLegoBuildingBlock = class("CityTileAssetLegoBuildingBlock", CityTileAssetLegoUnit)

---@param legoBuilding CityLegoBuilding
---@param legoBlock CityLegoBlock
function CityTileAssetLegoBuildingBlock:ctor(legoBuilding, legoBlock, indoor)
    CityTileAssetLegoUnit.ctor(self, legoBuilding, legoBlock:GetCfgId(), legoBlock:GetStyle(indoor), indoor)
    self.legoBuilding = legoBuilding
    self.legoBlock = legoBlock
end

function CityTileAssetLegoBuildingBlock:GetWorldPosition()
    return self.legoBlock:GetWorldPosition()
end

function CityTileAssetLegoBuildingBlock:GetWorldRotation()
    return self.legoBlock:GetWorldRotation()
end

function CityTileAssetLegoBuildingBlock:GetDecorations()
    return self.legoBlock:GetDecorations()
end

function CityTileAssetLegoBuildingBlock:GetInstanceId()
    return self.legoBlock.payload:Id()
end

function CityTileAssetLegoBuildingBlock:GetType()
    return "自由块"
end

return CityTileAssetLegoBuildingBlock