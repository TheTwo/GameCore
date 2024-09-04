local CityTileAssetGroup = require("CityTileAssetGroup")
---@class CityTileAssetDoorGroup:CityTileAssetGroup
---@field new fun():CityTileAssetDoorGroup
local CityTileAssetDoorGroup = class("CityTileAssetDoorGroup", CityTileAssetGroup)
local CityTileAssetDoor = require("CityTileAssetDoor")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityTileAssetDoorGroup:GetCurrentMembers()
    local buildingId = self.tileView.tile:GetCell().tileId
    local building = self:GetCity().buildingManager:GetBuilding(buildingId)
    if building == nil then
        return nil
    end
    
    local members = {}
    for k, v in pairs(building.doors) do
        table.insert(members, CityTileAssetDoor.new(self, k, v))
    end
    return members
end

function CityTileAssetDoorGroup:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_ROOM_DOOR_UPDATE, Delegate.GetOrCreate(self, self.OnDoorUpdate))
end

function CityTileAssetDoorGroup:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_ROOM_DOOR_UPDATE, Delegate.GetOrCreate(self, self.OnDoorUpdate))
end

function CityTileAssetDoorGroup:OnDoorUpdate(buildingId)
    local myBuildingId = self.tileView.tile:GetCell().tileId
    if buildingId ~= myBuildingId then return end

    self:ForceRefresh()
end

return CityTileAssetDoorGroup