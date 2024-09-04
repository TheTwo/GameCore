local CityTileVoidAsset = require("CityTileVoidAsset")
---@class CityTileAssetBuildingSLGUnitLifeBar:CityTileVoidAsset
---@field new fun():CityTileAssetBuildingSLGUnitLifeBar
local CityTileAssetBuildingSLGUnitLifeBar = class("CityTileAssetBuildingSLGUnitLifeBar", CityTileVoidAsset)

function CityTileAssetBuildingSLGUnitLifeBar:ctor()
    CityTileVoidAsset.ctor(self)
    self.isUI = true
end

function CityTileAssetBuildingSLGUnitLifeBar:OnTileViewInit()
    self.building = self:GetCity().buildingManager:GetBuilding(self.tileView.tile:GetCell().tileId)
end

function CityTileAssetBuildingSLGUnitLifeBar:OnTileViewRelease()
    self.building = nil
end

function CityTileAssetBuildingSLGUnitLifeBar:Show()
    self.building:RegisterLifeBar()
end

function CityTileAssetBuildingSLGUnitLifeBar:Hide()
    self.building:UnregisterLifeBar()
end

return CityTileAssetBuildingSLGUnitLifeBar