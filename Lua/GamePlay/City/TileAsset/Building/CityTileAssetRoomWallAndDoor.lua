local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetRoomWallAndDoor:CityTileAsset
---@field new fun():CityTileAssetRoomWallAndDoor
local CityTileAssetRoomWallAndDoor = class("CityTileAssetRoomWallAndDoor", CityTileAsset)
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityTileAssetRoomWallAndDoor:GetPrefabName()
    if not self:ShouldShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_room_wall_and_door)
end

function CityTileAssetRoomWallAndDoor:ShouldShow()
    local gridCell = self.tileView.tile:GetCell()
    if gridCell == nil then return false end
    if not gridCell:IsBuilding() then return false end
    
    local lvCell = ConfigRefer.BuildingLevel:Find(gridCell.configId)
    if lvCell == nil then return false end
    if lvCell:InnerSizeX() == 0 or lvCell:InnerSizeY() == 0 then return false end

    return true
end

function CityTileAssetRoomWallAndDoor:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end
    local controller = go:GetComponent(typeof(CS.CityRoomWallAndDoorController))
    local city = self:GetCity()
    self.controller = controller
    self.controller.GlobalScale = city.scale
    self.walls = self:LoadWallAndDoors()
end

function CityTileAssetRoomWallAndDoor:OnAssetUnload()
    if Utils.IsNotNull(self.controller) then
        self.controller:UnloadAll()
    end
    self.controller = nil

    for _, v in ipairs(self.walls) do
        v.Asset = nil
    end
    self.walls = nil
end

function CityTileAssetRoomWallAndDoor:LoadWallAndDoors()
    local city = self:GetCity()
    local gridCell = self.tileView.tile:GetCell()
    local building = city.buildingManager:GetBuilding(gridCell.tileId)
    local rootPos = city:GetWorldPositionFromCoord(building.x, building.y)
    self.controller.RelativePos = rootPos

    local wallRoomInfo = building:GetRoomInfo()
    if wallRoomInfo == nil then return {} end

    local ret = {}
    for idx = wallRoomInfo.Y + 1, wallRoomInfo.Y + wallRoomInfo.Height - 1 do
        for number = wallRoomInfo.X, wallRoomInfo.X + wallRoomInfo.Width - 1 do
            local h = building:GetInnerHWallOrDoor(idx, number)
            if h ~= nil and h:IsWall() then
                local position = h:GetWorldCenter() - rootPos
                local rotation = h:GetWorldRotation()
                local prefabName = h:GetPrefabName()
                self.controller:AddDatum(prefabName, position, rotation, h:LocalX(), h:LocalY(), h.isHorizontal)
                h.Asset = self
                table.insert(ret, h)
            end
        end
    end

    for idx = wallRoomInfo.X + 1, wallRoomInfo.X + wallRoomInfo.Width - 1 do
        for number = wallRoomInfo.Y, wallRoomInfo.Y + wallRoomInfo.Height - 1 do
            local v = building:GetInnerVWallOrDoor(idx, number)
            if v ~= nil and v:IsWall() then
                local position = v:GetWorldCenter() - rootPos
                local rotation = v:GetWorldRotation()
                local prefabName = v:GetPrefabName()
                self.controller:AddDatum(prefabName, position, rotation, v:LocalX(), v:LocalY(), v.isHorizontal)
                v.Asset = self
                table.insert(ret, v)
            end
        end
    end

    return ret
end

function CityTileAssetRoomWallAndDoor:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, Delegate.GetOrCreate(self, self.OnWallUpdate))
end

function CityTileAssetRoomWallAndDoor:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_ROOM_WALL_UPDATE, Delegate.GetOrCreate(self, self.OnWallUpdate))
end

function CityTileAssetRoomWallAndDoor:UpdatePosition(pos)
    if Utils.IsNull(self.controller) then return end
    self.controller.RelativePos = pos
end

function CityTileAssetRoomWallAndDoor:OnWallUpdate(buildingId)
    local myBuildingId = self.tileView.tile:GetCell().tileId
    if buildingId ~= myBuildingId then return end

    self:ForceRefresh()
end

function CityTileAssetRoomWallAndDoor:Refresh()
    if Utils.IsNull(self.controller) then
        return
    end

    self.controller:UnloadAll()
    self.controller.GlobalScale = self:GetCity().scale
    self.walls = self:LoadWallAndDoors()
end

return CityTileAssetRoomWallAndDoor