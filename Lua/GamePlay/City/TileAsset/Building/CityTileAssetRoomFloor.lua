local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetRoomFloor:CityTileAsset
---@field new fun():CityTileAssetRoomFloor
local CityTileAssetRoomFloor = class("CityTileAssetRoomFloor", CityTileAsset)
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Offset = CS.UnityEngine.Vector3(0, 0.02, 0)

function CityTileAssetRoomFloor:GetPrefabName()
    if not self:ShouldShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_room_floors)
end

function CityTileAssetRoomFloor:ShouldShow()
    local gridCell = self.tileView.tile:GetCell()
    if gridCell == nil then return false end
    if not gridCell:IsBuilding() then return false end
    
    local lvCell = ConfigRefer.BuildingLevel:Find(gridCell.configId)
    if lvCell == nil then return false end
    if lvCell:InnerSizeX() == 0 or lvCell:InnerSizeY() == 0 then return false end

    return true
end

function CityTileAssetRoomFloor:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end
    local controller = go:GetComponent(typeof(CS.CityRoomFloorController))
    local city = self:GetCity()
    self.controller = controller
    self.controller.GlobalScale = city.scale
    self:LoadFloorTiles()
    if self.flash then
        self:GetCity().flashMatController:StartFlash(self.controller.gameObject)
    end
end

function CityTileAssetRoomFloor:OnAssetUnload()
    if Utils.IsNotNull(self.controller) then
        self.controller:UnloadAll()
    end

    if self.flash then
        self:GetCity().flashMatController:StopFlash(self.controller.gameObject)
    end
    self.controller = nil
end

function CityTileAssetRoomFloor:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_ROOM_FLOOR_UPDATE, Delegate.GetOrCreate(self, self.OnFloorUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_FLOOR_ASSET_FLASH, Delegate.GetOrCreate(self, self.OnFloorFlash))
end

function CityTileAssetRoomFloor:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ROOM_FLOOR_UPDATE, Delegate.GetOrCreate(self, self.OnFloorUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FLOOR_ASSET_FLASH, Delegate.GetOrCreate(self, self.OnFloorFlash))
end

function CityTileAssetRoomFloor:OnFloorUpdate(buildingId)
    local gridCell = self.tileView.tile:GetCell()
    if gridCell.tileId ~= buildingId then return end

    self:ForceRefresh()
end

function CityTileAssetRoomFloor:Refresh()
    if Utils.IsNotNull(self.controller) then
        self.controller:UnloadAll()
        self:LoadFloorTiles()
    end
end

function CityTileAssetRoomFloor:LoadFloorTiles()
    local city = self:GetCity()
    local gridCell = self.tileView.tile:GetCell()
    local building = city.buildingManager:GetBuilding(gridCell.tileId)
    local rootPos = city:GetWorldPositionFromCoord(building.x, building.y)
    self.controller.RelativePos = rootPos + CS.UnityEngine.Vector3.up * 0.015
    for id, room in pairs(building.rooms) do
        local floorCfg = ConfigRefer.BuildingRoomFloor:Find(room:GetFloorId())
        if floorCfg == nil then goto continue end

        local prefabName = ArtResourceUtils.GetItem(floorCfg:Model())
        if string.IsNullOrEmpty(prefabName) then goto continue end

        self.controller:Begin(prefabName)
        for x, y, _ in room.areas:pairs() do
            local position = city:GetCenterWorldPositionFromCoord(building.x + x, building.y + y, 1, 1) - rootPos
            self.controller:AddMatrix(x, y, position)
        end
        self.controller:End()
        ::continue::
    end
end

function CityTileAssetRoomFloor:UpdatePosition(pos)
    if Utils.IsNull(self.controller) then return end
    self.controller.RelativePos = pos + CS.UnityEngine.Vector3.up * 0.015
end

function CityTileAssetRoomFloor:OnFloorFlash(flag)
    self.flash = flag
    if Utils.IsNull(self.controller) then return end

    self:FloorFlashImp()
end

function CityTileAssetRoomFloor:FloorFlashImp()
    if self.flash then
        self:GetCity().flashMatController:StartFlash(self.controller.gameObject)
    else
        self:GetCity().flashMatController:StopFlash(self.controller.gameObject)
    end
end

return CityTileAssetRoomFloor