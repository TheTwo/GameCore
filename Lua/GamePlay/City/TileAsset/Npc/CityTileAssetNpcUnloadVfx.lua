local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetNpcUnloadVfx:CityTileAsset
---@field new fun():CityTileAssetNpcUnloadVfx
---@field super CityTileAsset
local CityTileAssetNpcUnloadVfx = class('CityTileAssetNpcUnloadVfx', CityTileAsset)

function CityTileAssetNpcUnloadVfx:ctor()
    CityTileAsset.ctor(self)
    ---@type number
    self._cityUid = 0
    ---@type number
    self._x = 0
    ---@type number
    self._y = 0
    ---@type number
    self._sx = 1
    ---@type number
    self._sy = 1
    ---@type number
    self._unloadVfx = nil
    self._unloadLang = string.Empty
end

function CityTileAssetNpcUnloadVfx:OnTileViewInit()
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._cityUid = city.uid
    self._x = tile.x
    self._y = tile.y
    self._unloadVfx = nil
    local cell = tile:GetCell()
    self._sx = cell.sizeX
    self._sy = cell.sizeY
    local elementConfigId = cell:ConfigId()
    local eleCfg = ConfigRefer.CityElementData:Find(elementConfigId)
    if eleCfg then
        local npcConfig = ConfigRefer.CityElementNpc:Find(eleCfg:ElementId())
        if npcConfig then
            self._unloadVfx = npcConfig:UnloadVFX()
            self._unloadLang = npcConfig:UnloadVFXWithI18N()
        end
    end
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_PRE_REMOVE, Delegate.GetOrCreate(self, self.OnElementPreRemove))
end

function CityTileAssetNpcUnloadVfx:OnTileViewRelease()
    self._unloadLang = string.Empty
    self._unloadVfx = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_PRE_REMOVE, Delegate.GetOrCreate(self, self.OnElementPreRemove))
end

---@param city City
function CityTileAssetNpcUnloadVfx:OnElementPreRemove(city, x, y)
    if self._cityUid ~= city.uid or self._x ~= x or self._y ~= y then
        return
    end
    if self._unloadVfx and self._unloadVfx > 0 then
        city.elementManager:SpawnElementUnloadVfx(x, y, self._sx, self._sy , self._unloadVfx)
        self._unloadVfx = nil
    end
    if not string.IsNullOrEmpty(self._unloadLang) then
        local _,pos = self:TryGetAnchorPos()
        city.elementManager:SpawnElementUnloadVfxI18N(x, y, self._sx, self._sy , self._unloadLang, pos)
        self._unloadLang = string.Empty
    end
end

return CityTileAssetNpcUnloadVfx