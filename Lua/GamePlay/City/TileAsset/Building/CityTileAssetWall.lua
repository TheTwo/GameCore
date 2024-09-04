local CityTileAssetGroupMember = require("CityTileAssetGroupMember")
---@class CityTileAssetWall:CityTileAssetGroupMember
---@field parent CityTileAssetWallGroup
---@field new fun():CityTileAssetWall
local CityTileAssetWall = class("CityTileAssetWall", CityTileAssetGroupMember)
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

---@param wall CityWall
function CityTileAssetWall:ctor(group, wall)
    CityTileAssetGroupMember.ctor(self, group)
    self.wall = wall
end

function CityTileAssetWall:GetCustomNameInGroup()
    return string.format("wall%s_%d_%d", self.wall.isHorizontal and "H" or "V", self.wall.idx, self.wall.number)
end

function CityTileAssetWall:GetPrefabName()
    local cfg = ConfigRefer.BuildingRoomWall:Find(self.wall.cfgId)
    if cfg == nil then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(cfg:Model())
end

function CityTileAssetWall:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    go.transform:SetPositionAndRotation(self.wall:GetWorldCenter(), self.wall:GetWorldRotation())
    self.wall.Asset = self
end

function CityTileAssetWall:OnAssetUnload()
    self.wall.Asset = nil
end

return CityTileAssetWall