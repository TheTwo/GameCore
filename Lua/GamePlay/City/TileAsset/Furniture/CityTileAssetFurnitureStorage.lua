local CityWorkProduceWdsHelper = require("CityWorkProduceWdsHelper")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Utils = require("Utils")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetFurnitureStorage:CityTileAsset
---@field super CityTileAsset
local CityTileAssetFurnitureStorage = class("CityTileAssetFurnitureStorage", CityTileAsset)

function CityTileAssetFurnitureStorage:ctor()
    CityTileAssetFurnitureStorage.super.ctor(self)
    ---@type CityFurnitureStorageStatus
    self.storageStatus = nil
    self.nextSyncTime = nil
    self.cityUid = nil
    self.furnitureId = nil

    self.secTickAdd = false
end

function CityTileAssetFurnitureStorage:OnTileViewInit()
    self.cityUid = self:GetCity().uid
    self.furnitureId = self.tileView.tile:GetCell():UniqueId()
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
end

function CityTileAssetFurnitureStorage:OnTileViewRelease()
    self.storageStatus = nil
    self.nextSyncTime = nil
    self.cityUid = nil
    self.furnitureId = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
end

---@param city City
function CityTileAssetFurnitureStorage:OnCastleFurnitureChanged(city, batchEvt)
    if not self.cityUid or self.cityUid ~= city.uid then return end
    if not batchEvt or not batchEvt.Change then return end
    if not batchEvt.Change[self.furnitureId] then return end
    self:SyncStorageStatus()
end

function CityTileAssetFurnitureStorage:OnMainAssetLoaded(mainAsset, go)
    if self.storageStatus then return end
    if Utils.IsNull(go) then return end
    local be = go:GetLuaBehaviour("CityFurnitureStorageStatus")
    if Utils.IsNull(be) then return end
    self.storageStatus = be.Instance
    if not self.storageStatus then return end
    if not self.secTickAdd then
        self.secTickAdd = true
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
    end
    self:SyncStorageStatus()
end

function CityTileAssetFurnitureStorage:OnMainAssetUnloaded(mainAsset)
    if self.secTickAdd then
        self.secTickAdd = false
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
    end
    self.storageStatus = nil
end

function CityTileAssetFurnitureStorage:SecTick(dt)
    if not self.nextSyncTime or self.nextSyncTime < g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then return end
    self:SyncStorageStatus()
end

function CityTileAssetFurnitureStorage:SyncStorageStatus()
    self.nextSyncTime = nil
    if not self.storageStatus then return end
    ---@type CityFurniture
    local cell = self.tileView.tile:GetCell()
    local furniture = self:GetCity().furnitureManager:GetCastleFurniture(cell.singleId)
    local duration = furniture and furniture.ResourceProduceInfo and furniture.ResourceProduceInfo.Duration and furniture.ResourceProduceInfo.Duration.ServerSecond or 0
    local hasCount = furniture and furniture.ResourceProduceInfo.CurCount or 0
    if duration <= 0 or hasCount < 1 then
        self.storageStatus:SetStorageProgress(0)
        return
    end
    local remainTime = CityWorkProduceWdsHelper.GetProduceRemainTime(furniture)
    local progress = 1 - math.inverseLerp(0, duration, remainTime)
    self.storageStatus:SetStorageProgress(progress)
    self.nextSyncTime = duration * 0.1 + g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

return CityTileAssetFurnitureStorage