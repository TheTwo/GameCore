local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Utils = require("Utils")

local CityTileAssetFurniture = require("CityTileAssetFurniture")

---@class CityTileAssetFurnitureFarmland:CityTileAssetFurniture
---@field new fun():CityTileAssetFurnitureFarmland
---@field super CityTileAssetFurniture
local CityTileAssetFurnitureFarmland = class('CityTileAssetFurnitureFarmland', CityTileAssetFurniture)

function CityTileAssetFurnitureFarmland:ctor()
    CityTileAssetFurniture.ctor(self)
    self._isAssetReady = false
    ---@type CityFarmlandFieldBehaviour
    self._field = nil
end

function CityTileAssetFurnitureFarmland:OnTileViewInit()
    CityTileAssetFurniture.OnTileViewInit(self)
    self._castleBriefId = self.tileView.tile:GetCity().uid
    self._furnitureId =self.tileView.tile:GetCell():UniqueId()
    self._farmLandMgr = self.tileView.tile:GetCity().farmlandManager
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_SELECT, Delegate.GetOrCreate(self, self.DummySelect))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_CANCEL, Delegate.GetOrCreate(self, self.DummyCancel))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, Delegate.GetOrCreate(self, self.OnFarmlandInfoChanged))
end

function CityTileAssetFurnitureFarmland:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_SELECT, Delegate.GetOrCreate(self, self.DummySelect))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_CANCEL, Delegate.GetOrCreate(self, self.DummyCancel))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, Delegate.GetOrCreate(self, self.OnFarmlandInfoChanged))
    CityTileAssetFurniture.OnTileViewRelease(self)
end

function CityTileAssetFurnitureFarmland:SkipForSLGAsset()
    return false
end

function CityTileAssetFurnitureFarmland:OnAssetLoaded(go, userdata)
    CityTileAssetFurniture.OnAssetLoaded(self, go, userdata)
    if Utils.IsNotNull(go) then
        self._isAssetReady = true
        self._field = go:GetLuaBehaviour("CityFarmlandFieldBehaviour").Instance
        self._field:RefreshFieldModel(self.tileView.tile:GetCastleFurniture().LandInfo)
    end
end

function CityTileAssetFurnitureFarmland:OnAssetUnload()
    if self._field then
        self._field:RefreshFieldModel(nil)
    end
    self._field = nil
    self._isAssetReady = false
    CityTileAssetFurniture.OnAssetUnload(self)
end

function CityTileAssetFurnitureFarmland:DummySelect(castleBriefId, farmlandId)
    if self._castleBriefId ~= castleBriefId or self._furnitureId ~= farmlandId then
        return
    end
    if not self._isAssetReady then
        return
    end
    self.tileView:SetSelected(true)
end

function CityTileAssetFurnitureFarmland:DummyCancel(castleBriefId)
    if self._castleBriefId ~= castleBriefId then
        return
    end
    if not self._isAssetReady then
        return
    end
    self.tileView:SetSelected(false)
end

function CityTileAssetFurnitureFarmland:OnFarmlandInfoChanged(castleBriefId, changedId)
    if self._castleBriefId ~= castleBriefId then
        return
    end
    if not changedId[self._furnitureId] then
        return
    end
    if self._field then
        self._field:RefreshFieldModel(self.tileView.tile:GetCastleFurniture().LandInfo)
    end
end

return CityTileAssetFurnitureFarmland