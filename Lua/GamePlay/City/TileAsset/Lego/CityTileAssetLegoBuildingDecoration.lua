local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetLegoBuildingDecoration:CityTileAsset
---@field new fun():CityTileAssetLegoBuildingDecoration
local CityTileAssetLegoBuildingDecoration = class("CityTileAssetLegoBuildingDecoration", CityTileAsset)

local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion

---@param legoBuilding CityLegoBuilding
---@param legoDecoration CityLegoFreeDecoration
function CityTileAssetLegoBuildingDecoration:ctor(legoBuilding, legoDecoration)
    CityTileAsset.ctor(self)
    self.legoBuilding = legoBuilding
    self.legoDecoration = legoDecoration
    self.decorationCfg = ConfigRefer.LegoDecoration:Find(legoDecoration:GetCfgId())

    local decoStyle = legoDecoration:GetStyle()
    local decoArtCfg = ConfigRefer.LegoDecorationArtMap:Find(decoStyle)
    local modelCfgId = 0
    if decoArtCfg then
        if self.legoDecoration:IsOutside() then
            modelCfgId = decoArtCfg:Model()
        else
            modelCfgId = decoArtCfg:ModelIndoor()
        end
    end

    self.modelPath, self.scale = ArtResourceUtils.GetItemAndScale(modelCfgId)
    if self.scale == 0 then
        self.scale = 1
    end
end

function CityTileAssetLegoBuildingDecoration:GetPrefabName()
    return self.modelPath or string.Empty
end

function CityTileAssetLegoBuildingDecoration:GetScale()
    return self.scale or 1
end

---@param go CS.UnityEngine.GameObject
---@param userdata any
---@param handle CS.DragonReborn.AssetTool.PooledGameObjectHandle
function CityTileAssetLegoBuildingDecoration:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    self.go.transform:SetPositionAndRotation(self.legoDecoration:GetWorldPosition(), Quaternion.identity)
    self.originName = self.go.name
    self.go.name = ("装饰物:%d"):format(self.decorationCfg:Id())
end

function CityTileAssetLegoBuildingDecoration:OnAssetUnload(go, fadeOut)
    if Utils.IsNotNull(self.go) then
        self.go.name = self.originName
    end
    self.go = nil
end

function CityTileAssetLegoBuildingDecoration:IndoorMaterial()
    local holder = self.go:GetComponent(typeof(CS.PrefabCustomInfoHolder))
    if Utils.IsNull(holder) then return end

    self.customInfoHolder = holder
    local roomLightColor = self.legoBuilding:GetRoomLightColor()
    local roomLightDir = self.legoBuilding:GetRoomLightDir()
    local roomGi = self.legoBuilding:GetRoomGi()
    self.customInfoHolder:EnterRoomMode(roomLightColor, roomLightDir, roomGi)
end

function CityTileAssetLegoBuildingDecoration:ClearIndoorMaterial()
    if Utils.IsNull(self.customInfoHolder) then return end

    self.customInfoHolder:ExitRoomMode()
    self.customInfoHolder = nil
end

function CityTileAssetLegoBuildingDecoration:GetScale()
    return self.scale
end

function CityTileAssetLegoBuildingDecoration:Refresh()
    if Utils.IsNull(self.go) then return end

    self.go.transform:SetPositionAndRotation(self.legoDecoration:GetWorldPosition(), Quaternion.identity)
end

return CityTileAssetLegoBuildingDecoration