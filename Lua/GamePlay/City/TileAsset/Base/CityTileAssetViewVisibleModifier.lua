local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityGridCellDef = require("CityGridCellDef")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetViewVisibleModifier:CityTileAsset
---@field new fun():CityTileAssetViewVisibleModifier
---@field super CityTileAsset
local CityTileAssetViewVisibleModifier = class('CityTileAssetViewVisibleModifier', CityTileAsset)

function CityTileAssetViewVisibleModifier:ctor()
    CityTileAsset.ctor(self)
    ---@type MyCity
    self._city = nil
    ---@type number
    self._elementId = nil
end

function CityTileAssetViewVisibleModifier:OnTileViewInit()
    local city = self.tileView.tile:GetCity()
    if not city or not city:IsMyCity() then
        return
    end
    self._city = city
    local cell = self.tileView.tile:GetCell()
    self._elementId = cell.tileId
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_IN_TIMELINE_VISIBLE_CHANGED, Delegate.GetOrCreate(self, self.OnElementTempVisibleChanged))
    self.tileView:SetRootVisible(not city.elementManager:IsTempHiddenByTimeline(self._elementId))
end

function CityTileAssetViewVisibleModifier:OnTileViewRelease()
    if not self._elementId then
        return
    end
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_IN_TIMELINE_VISIBLE_CHANGED, Delegate.GetOrCreate(self, self.OnElementTempVisibleChanged))
    self._elementId = nil
    self._city = nil
end

function CityTileAssetViewVisibleModifier:OnElementTempVisibleChanged(city, elementId, visible)
    if not self._elementId or self._elementId ~= elementId or self._city ~= city then
        return
    end
    self.tileView:SetRootVisible(visible)
end

return CityTileAssetViewVisibleModifier