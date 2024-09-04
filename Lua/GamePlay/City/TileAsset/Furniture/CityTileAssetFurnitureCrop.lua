local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetFurnitureCrop:CityTileAsset
---@field super CityTileAsset
local CityTileAssetFurnitureCrop = class("CityTileAssetFurnitureCrop", CityTileAsset)

function CityTileAssetFurnitureCrop:ctor()
    CityTileAssetFurnitureCrop.super.ctor(self)
    self.cityUid = nil
    self.furnitureId = nil
    ---@type CityFurnitureCropStatus
    self.cropStatus = nil
    self.isInMoving = false
end

function CityTileAssetFurnitureCrop:OnMainAssetLoaded(mainAsset, go)
    if self.cropStatus then return end
    if Utils.IsNull(go) then return end
    local be = go:GetLuaBehaviour("CityFurnitureCropStatus")
    if Utils.IsNull(be) then return end
    self.cropStatus = be.Instance
    if not self.cropStatus then return end
    if self.isInMoving then
        self.cropStatus:OnMoveBegin()
    end
end

function CityTileAssetFurnitureCrop:OnMainAssetUnloaded(mainAsset)
    if self.cropStatus then
        self.cropStatus:ClearAllCrop()
    end
    self.cropStatus = nil
end

function CityTileAssetFurnitureCrop:OnMoveBegin()
    self.isInMoving = true
    if not self.cropStatus then return end
    self.cropStatus:OnMoveBegin()
end

function CityTileAssetFurnitureCrop:OnMoveEnd()
    self.isInMoving = false
    if not self.cropStatus then return end
    self.cropStatus:OnMoveEnd()
end

return CityTileAssetFurnitureCrop
