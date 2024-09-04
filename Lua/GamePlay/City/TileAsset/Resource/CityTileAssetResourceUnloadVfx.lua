local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetResourceUnloadVfx:CityTileAsset
---@field new fun():CityTileAssetResourceUnloadVfx
local CityTileAssetResourceUnloadVfx = class("CityTileAssetResourceUnloadVfx", CityTileAsset)
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityTileAssetResourceUnloadVfx:ctor()
    CityTileAsset.ctor(self)
    self._x, self._y = -1, -1
    self._sx, self._sy = -1, -1
end

function CityTileAssetResourceUnloadVfx:OnTileViewInit()
    self.city = self:GetCity()
    self._x = self.tileView.tile.x
    self._y = self.tileView.tile.y
    self._unloadVfx = nil
    local cell = self.tileView.tile:GetCell()
    self._sx = cell.sizeX
    self._sy = cell.sizeY
    local element = self.city.elementManager:GetElementById(cell.tileId)
    if element and element:IsResource() then
        self._unloadVfx = element.resourceConfigCell:UnloadVfx()
    end
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_PRE_REMOVE, Delegate.GetOrCreate(self, self.OnElementPreRemove))
end

function CityTileAssetResourceUnloadVfx:OnTileViewRelease()
    self._unloadVfx = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_PRE_REMOVE, Delegate.GetOrCreate(self, self.OnElementPreRemove))
end

---@param city City
function CityTileAssetResourceUnloadVfx:OnElementPreRemove(city, x, y)
    if self.city ~= city or self._x ~= x or self._y ~= y then
        return
    end
    if self._unloadVfx and self._unloadVfx > 0 then
        city.elementManager:SpawnElementUnloadVfx(x, y, self._sx, self._sy , self._unloadVfx)
        self._unloadVfx = nil
    end
end

return CityTileAssetResourceUnloadVfx