local CityTileAssetFurniture = require("CityTileAssetFurniture")
---@class CityTileAssetFurnitureHatchEggFacility:CityTileAssetFurniture
---@field new fun():CityTileAssetFurnitureHatchEggFacility
local CityTileAssetFurnitureHatchEggFacility = class("CityTileAssetFurnitureHatchEggFacility", CityTileAssetFurniture)
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityTileAssetFurnitureHatchEggFacility:OnAssetLoaded(go, userdata, handle)
    CityTileAssetFurniture.OnAssetLoaded(self, go, userdata, handle)
    if Utils.IsNull(go) then return end

    ---@type CS.FXAttachPointHolder
    local attachPointHolder = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNotNull(attachPointHolder) then
        local glass = attachPointHolder:GetAttachPoint("holder_glass")
        if Utils.IsNotNull(glass) then
            self.glassGo = glass.gameObject
        end
    end

    self:UpdateGlass()
    if Utils.IsNotNull(self.glassGo) then
        g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    end
end

function CityTileAssetFurnitureHatchEggFacility:OnAssetUnload()
    CityTileAssetFurniture.OnAssetUnload(self)
    self.glassGo = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
end

function CityTileAssetFurnitureHatchEggFacility:OnFurnitureUpdate(city, batchEvt)
    if self:GetCity() ~= city then return end
    if not batchEvt.Change[self._furnitureId] then return end

    self:UpdateGlass()
end

function CityTileAssetFurnitureHatchEggFacility:UpdateGlass()
    if Utils.IsNull(self.glassGo) then return end
    local castleFurniture = self.tileView.tile:GetCastleFurniture()
    if castleFurniture and castleFurniture.ProcessInfo.ConfigId > 0 then
        self.glassGo:SetActive(false)
    else
        self.glassGo:SetActive(true)
    end
end

return CityTileAssetFurnitureHatchEggFacility