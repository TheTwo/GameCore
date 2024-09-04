local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local Utils = require("Utils")
local CityFarmlandCropBehaviour = require("CityFarmlandCropBehaviour")

local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetFurnitureFarmlandCrop:CityTileAsset
---@field new fun():CityTileAssetFurnitureFarmlandCrop
---@field super CityTileAsset
local CityTileAssetFurnitureFarmlandCrop = class('CityTileAssetFurnitureFarmlandCrop', CityTileAsset)

function CityTileAssetFurnitureFarmlandCrop:ctor()
    CityTileAsset.ctor(self)
    self.allowSelected = true
    ---@type CityFarmlandCropBehaviour
    self._crop = nil
    self._inDummyStatus = false
end

function CityTileAssetFurnitureFarmlandCrop:OnTileViewInit()
    self._castleBriefId = self.tileView.tile:GetCity().uid
    self._furnitureId = self.tileView.tile:GetCell():UniqueId()
    self._farmLandMgr = self.tileView.tile:GetCity().farmlandManager
    self._goCreator = self.tileView.tile:GetCity().createHelper
    self:LoadCropData()

    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, Delegate.GetOrCreate(self, self.OnFarmlandInfoChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_SEED, Delegate.GetOrCreate(self, self.DummySeed))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_HARVEST, Delegate.GetOrCreate(self, self.DummyHarvest))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickCropGrowing))
end

function CityTileAssetFurnitureFarmlandCrop:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, Delegate.GetOrCreate(self, self.OnFarmlandInfoChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_SEED, Delegate.GetOrCreate(self, self.DummySeed))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_HARVEST, Delegate.GetOrCreate(self, self.DummyHarvest))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickCropGrowing))
end

function CityTileAssetFurnitureFarmlandCrop:GetCropPrefabName()
    if self._cropConfig then
        return ArtResourceUtils.GetItem(ArtResourceConsts.mdl_city_crop_combine)
    end
    return string.Empty
end

function CityTileAssetFurnitureFarmlandCrop:GetPrefabName()
    return self:GetCropPrefabName()
end

function CityTileAssetFurnitureFarmlandCrop:LoadCropData()
    self._cropInfo = nil
    self._cropConfig = nil
    local furniture = self.tileView.tile:GetCastleFurniture()
    if not furniture then
        return
    end
    self._cropInfo = furniture.LandInfo
    if not self._cropInfo then
        return
    end
    self._cropConfig = ConfigRefer.Crop:Find(self._cropInfo.cropTid)
end

function CityTileAssetFurnitureFarmlandCrop:OnAssetLoaded(go, userdata)
    CityTileAsset.OnAssetLoaded(self, go, userdata)
    if Utils.IsNotNull(go) then
        local behavior = go:GetLuaBehaviour("CityFarmlandCropBehaviour")
        if behavior and behavior.Instance:is(CityFarmlandCropBehaviour) then
            self._crop = behavior.Instance
            self._crop:Init(self._goCreator)
            self:DoRefreshCrop()
        end
    end
end

function CityTileAssetFurnitureFarmlandCrop:OnAssetUnload()
    if self._crop then
        self._crop:ReleaseCrop()
    end
    self._crop = nil
    CityTileAsset.OnAssetUnload(self)
end

function CityTileAssetFurnitureFarmlandCrop:TickCropGrowing(_)
    if not self._crop or not self._cropInfo or self._cropInfo.state ~= wds.CastleLandState.CastleLandGrowing then
        return
    end
    self:DoSetGrowingProgress()
end

function CityTileAssetFurnitureFarmlandCrop:OnFarmlandInfoChanged(castleBriefId, changedId)
    if self._castleBriefId ~= castleBriefId then
        return
    end
    if not changedId[self._furnitureId] then
        return
    end
    self._inDummyStatus = false
    self:LoadCropData()
    self:RefreshCrop()
end

function CityTileAssetFurnitureFarmlandCrop:RefreshCrop()
    if not self._cropConfig then
        self:Hide()
    else
        if self.handle then
            self:DoRefreshCrop()
        else
            self:Hide()
            self:Show()
        end
    end
end

function CityTileAssetFurnitureFarmlandCrop:DoRefreshCrop()
    if not self._crop then
        return
    end
    self._crop:SetCropTid(self._cropConfig:Id(), self._cropConfig)
    self._crop:SetActive(true)
    self:DoSetGrowingProgress()
end

function CityTileAssetFurnitureFarmlandCrop:DoSetGrowingProgress()
    local progress
    if not self._cropInfo then
        progress = 0
    elseif self._cropInfo.state == wds.CastleLandState.CastleLandGrowing then
        local totalTime = self._cropConfig:RipeTime()
        if totalTime <= 0 then
            progress = 1
        else
            local leftTime = math.max(0, self._cropInfo.HarvestableTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
            progress = math.clamp01(1 - (leftTime * 1.0 / totalTime))
        end
    elseif self._cropInfo.state == wds.CastleLandState.CastleLandHarvestable then
        progress = 1
    end
        self._crop:SetCropGrowingProcess(progress)
    end

---@param castleBriefId number
---@param farmlandId number
---@param cropConfig CropConfigCell
function CityTileAssetFurnitureFarmlandCrop:DummySeed(castleBriefId, farmlandId, cropConfig)
    if self._castleBriefId ~= castleBriefId or self._furnitureId ~= farmlandId then
        return
    end
    self._inDummyStatus = true
    self._cropInfo = nil
    self._cropConfig = cropConfig
    self:RefreshCrop()
end

function CityTileAssetFurnitureFarmlandCrop:DummyHarvest(castleBriefId, farmlandId)
    if self._castleBriefId ~= castleBriefId or self._furnitureId ~= farmlandId then
        return
    end
    if not self._crop then
        return
    end
    self._crop:SetActive(false)
    self._inDummyStatus = true
end

return CityTileAssetFurnitureFarmlandCrop