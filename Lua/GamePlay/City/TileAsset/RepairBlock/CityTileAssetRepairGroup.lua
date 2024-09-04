local CityTileAssetGroup = require("CityTileAssetGroup")
---@class CityTileAssetRepairGroup:CityTileAssetGroup
---@field new fun():CityTileAssetRepairGroup
local CityTileAssetRepairGroup = class("CityTileAssetRepairGroup", CityTileAssetGroup)
local CityTileAssetRepairBlockGroup = require("CityTileAssetRepairBlockGroup")

function CityTileAssetRepairGroup:GetCurrentMembers()
    local city = self:GetCity()
    local building = city.buildingManager:GetBuilding(self.tileView.tile:GetCell().tileId)
    local ret = {}
    for id, v in pairs(building.repairBlocks) do
        table.insert(ret, CityTileAssetRepairBlockGroup.new(id, v))
    end
    return ret
end

return CityTileAssetRepairGroup