local CityTileAssetGroup = require("CityTileAssetGroup")
---@class CityTileAssetWallGroup:CityTileAssetGroup
---@field new fun():CityTileAssetWallGroup
local CityTileAssetWallGroup = class("CityTileAssetWallGroup", CityTileAssetGroup)
local CityTileAssetWall = require("CityTileAssetWall")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityTileAssetWallGroup:GetCurrentMembers()
    local buildingId = self.tileView.tile:GetCell().tileId
    local building = self:GetCity().buildingManager:GetBuilding(buildingId)
    if building == nil then
        return nil
    end

    local wallRoomInfo = building:GetRoomInfo()
    if wallRoomInfo == nil then
        return nil
    end

    local members = {}
    for idx = wallRoomInfo.Y + 1, wallRoomInfo.Y + wallRoomInfo.Height - 1 do
        for number = wallRoomInfo.X, wallRoomInfo.X + wallRoomInfo.Width - 1 do
            local h = building:GetInnerHWallOrDoor(idx, number)
            if h ~= nil and h:IsWall() then
                table.insert(members, CityTileAssetWall.new(self, h))
            end
        end
    end

    for idx = wallRoomInfo.X + 1, wallRoomInfo.X + wallRoomInfo.Width - 1 do
        for number = wallRoomInfo.Y, wallRoomInfo.Y + wallRoomInfo.Height - 1 do
            local v = building:GetInnerVWallOrDoor(idx, number)
            if v ~= nil and v:IsWall() then
                table.insert(members, CityTileAssetWall.new(self, v))
            end
        end
    end
    
    return members
end

function CityTileAssetWallGroup:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, Delegate.GetOrCreate(self, self.OnWallUpdate))
end

function CityTileAssetWallGroup:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, Delegate.GetOrCreate(self, self.OnWallUpdate))
end

function CityTileAssetWallGroup:OnWallUpdate(buildingId)
    local myBuildingId = self.tileView.tile:GetCell().tileId
    if buildingId ~= myBuildingId then return end

    self:ForceRefresh()
end

return CityTileAssetWallGroup