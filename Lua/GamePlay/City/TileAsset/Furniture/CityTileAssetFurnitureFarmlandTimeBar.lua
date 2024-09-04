local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local Utils = require("Utils")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")

local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetFurnitureFarmlandTimeBar:CityTileAssetBubble
---@field new fun():CityTileAssetFurnitureFarmlandTimeBar
---@field super CityTileAsset
local CityTileAssetFurnitureFarmlandTimeBar = class('CityTileAssetFurnitureFarmlandTimeBar', CityTileAssetBubble)

function CityTileAssetFurnitureFarmlandTimeBar:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
end

function CityTileAssetFurnitureFarmlandTimeBar:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    self._city = self.tileView.tile:GetCity()
    self._farmlandMgr = self._city.farmlandManager
    self._castleBriefId = self._city .uid
    self._furnitureId =self.tileView.tile:GetCell():UniqueId()
    self._shouldShow = false
    self:ShouldShow()
    self._timeBar = nil
    self._leftTime = nil
    self._totalTime = nil
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, Delegate.GetOrCreate(self, self.OnFarmlandInfoChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_GROWING_SELECT, Delegate.GetOrCreate(self, self.OnGrowingSelect))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_FARMLAND_GROWING_UNSELECT, Delegate.GetOrCreate(self, self.OnGrowingUnselect))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityTileAssetFurnitureFarmlandTimeBar:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, Delegate.GetOrCreate(self, self.OnFarmlandInfoChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_GROWING_SELECT, Delegate.GetOrCreate(self, self.OnGrowingSelect))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_FARMLAND_GROWING_UNSELECT, Delegate.GetOrCreate(self, self.OnGrowingUnselect))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetFurnitureFarmlandTimeBar:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self._shouldShow then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_progress)
end

function CityTileAssetFurnitureFarmlandTimeBar:OnAssetLoaded(go, userdata)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    local progressBar = go:GetLuaBehaviour("CityProgressBar")
    if not progressBar or not progressBar.Instance then
        return
    end
    local landInfo = self._city:GetCastle().CastleFurniture[self._furnitureId].LandInfo
    local cropConfig = ConfigRefer.Crop:Find(landInfo.cropTid)
    local item = ConfigRefer.Item:Find(cropConfig:ItemId())
    self._cropConfig = cropConfig

    self._totalTime = cropConfig:RipeTime()
    self._leftTime = landInfo.HarvestableTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    ---@type CityProgressBar
    self._timeBar = progressBar.Instance

    if self:TrySetPosToMainAssetAnchor(self._timeBar.root) then
        self._timeBar:UpdatePosition(0)
    else
        self:SetPosToTileWorldCenter(go)
        local cell = self.tileView.tile:GetCell()
        local offset = math.max(cell.sizeX, cell.sizeY)
        self._timeBar:UpdatePosition(offset * 0.5)
    end
    
    self._timeBar:UpdateIcon(item:Icon())
    self._timeBar:ShowProgress(true)
    if landInfo.state == wds.CastleLandState.CastleLandGrowing then
        local costGold = ConfigRefer.Item:Find(ConfigRefer.ConstMain:CropSpeedUpConsumeItemId())
        self._timeBar:SetupPayButton(costGold:Icon(), "", CS.UnityEngine.Color.white, Delegate.GetOrCreate(self, self.OnClickSpeedUp), self.tileView.tile)
    else
        self._timeBar:HidePayButton()
    end
    self._timeBar.time:SetVisible(true)
    self:Tick(0)
end

function CityTileAssetFurnitureFarmlandTimeBar:OnAssetUnload(go, fade)
    self._leftTime = nil
    if self._timeBar then
        self._timeBar:ResetToNormal()
    end
    self._timeBar = nil
end

function CityTileAssetFurnitureFarmlandTimeBar:TickPayCount()
    if self._leftTime and self._leftTime > 0 and self._cropConfig then
        local costCount = math.ceil(self._leftTime * self._cropConfig:SpeedUpConsume())
        local color = ModuleRefer.InventoryModule:GetAmountByConfigId(ConfigRefer.ConstMain:CropSpeedUpConsumeItemId()) < costCount and CS.UnityEngine.Color.red or CS.UnityEngine.Color.white
        self._timeBar:UpdatePayCount(tostring(costCount), color)
    else
        self._timeBar:HidePayButton()
    end
end

function CityTileAssetFurnitureFarmlandTimeBar:Tick(dt)
    if not self._timeBar or not self._leftTime or not self._totalTime or self._totalTime <= 0 then
        return
    end
    self._leftTime = self._leftTime - dt
    self:TickPayCount()
    if self._leftTime <= 0 then
        self._timeBar:UpdateTime("")
        self._leftTime = nil
        self._totalTime = nil
        self._timeBar:UpdateProgress(1)
        self._timeBar.time:SetVisible(false)
    else
        self._timeBar:UpdateTime(TimeFormatter.SimpleFormatTimeWithoutZero(self._leftTime))
        local p = math.clamp01((self._totalTime - self._leftTime) / self._totalTime)
        self._timeBar:UpdateProgress(p)
    end
end

function CityTileAssetFurnitureFarmlandTimeBar:OnFarmlandInfoChanged(castleBriefId, changedId)
    if self._castleBriefId ~= castleBriefId then
        return
    end
    if not changedId[self._furnitureId] then
        return
    end
    local changed = self:ShouldShow()
    if not changed then
        return
    end
    self:Hide()
    self:Show()
end

function CityTileAssetFurnitureFarmlandTimeBar:OnGrowingSelect(castleBriefId, landId)
    if self._castleBriefId ~= castleBriefId or landId ~= self._furnitureId then
        return
    end
    local changed = self:ShouldShow()
    if changed then
        self:Hide()
        self:Show()
    end
end

function CityTileAssetFurnitureFarmlandTimeBar:OnGrowingUnselect(castleBriefId, landId)
    if self._castleBriefId ~= castleBriefId or landId ~= self._furnitureId then
        return
    end
    local changed = self:ShouldShow()
    if changed then
        self:Hide()
        self:Show()
    end
end

---@return boolean changed
function CityTileAssetFurnitureFarmlandTimeBar:ShouldShow()
    local landInfo = self._city:GetCastle().CastleFurniture[self._furnitureId].LandInfo
    local shouldShow = false
    if landInfo and landInfo.state == wds.CastleLandState.CastleLandGrowing and self._farmlandMgr:IsSelectedGrowingFarmland(self._furnitureId) then
        shouldShow = true
    end
    if shouldShow ~= self._shouldShow then
        self._shouldShow = shouldShow
        return true
    end
    return false
end

function CityTileAssetFurnitureFarmlandTimeBar:OnClickSpeedUp()
    self._farmlandMgr:GrowSpeed(self._furnitureId)
    return true
end

return CityTileAssetFurnitureFarmlandTimeBar