local CityTileAssetGroupMember = require("CityTileAssetGroupMember")
---@class CityTileAssetDoor:CityTileAssetGroupMember
---@field new fun():CityTileAssetDoor
local CityTileAssetDoor = class("CityTileAssetDoor", CityTileAssetGroupMember)
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param id number
---@param door CityDoor
function CityTileAssetDoor:ctor(group, id, door)
    CityTileAssetGroupMember.ctor(self, group)
    self.id = id
    self.door = door
end

function CityTileAssetDoor:GetCustomNameInGroup()
    return string.format("door%s_%d_%d", self.door.isHorizontal and "H" or "V", self.door.idx, self.door.number)
end

function CityTileAssetDoor:GetPrefabName()
    local cfg = ConfigRefer.BuildingRoomDoor:Find(self.door.cfgId)
    if cfg == nil then return string.Empty end

    return ArtResourceUtils.GetItem(cfg:Model())
end

function CityTileAssetDoor:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    self:OnWallHideChangedImp(self:GetCity().wallHide, go)
    go.transform:SetPositionAndRotation(self.door:GetWorldCenter(), self.door:GetWorldRotation())
    self.door.Asset = self
end

function CityTileAssetDoor:OnAssetUnload()
    self.door.Asset = nil
end

function CityTileAssetDoor:OnWallHideChanged(flag)
    if self.handle and self.handle.Asset then
        self:OnWallHideChangedImp(flag, self.handle.Asset)
    end
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetDoor:OnWallHideChangedImp(flag, go)
    local comps = go:GetComponentsInChildren(typeof(CS.CityHideableWall), true)
    for i = 0, comps.Length - 1 do
        comps[i]:EditStateChange(flag)
    end
end

return CityTileAssetDoor