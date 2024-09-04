local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetConstructionTimeBar:CityTileAssetBubble
---@field new fun():CityTileAssetConstructionTimeBar
local CityTileAssetConstructionTimeBar = class("CityTileAssetConstructionTimeBar", CityTileAssetBubble)
local CastleBuildingStatus = wds.enum.CastleBuildingStatus
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityUtils = require("CityUtils")
local UIMediatorNames = require("UIMediatorNames")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local TimeFormatter = require("TimeFormatter")
local CityTilePriority = require("CityTilePriority")
local CityWorkTargetType = require("CityWorkTargetType")

function CityTileAssetConstructionTimeBar:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
end

function CityTileAssetConstructionTimeBar:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._cityCamera = city:GetCamera()
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_UPDATE, Delegate.GetOrCreate(self, self.OnCellUpdate))
end

function CityTileAssetConstructionTimeBar:OnTileViewRelease()
    self.bubble = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_UPDATE, Delegate.GetOrCreate(self, self.OnCellUpdate))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetConstructionTimeBar:Show()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    return CityTileAssetBubble.Show(self)
end

function CityTileAssetConstructionTimeBar:Hide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    return CityTileAssetBubble.Hide(self)
end

function CityTileAssetConstructionTimeBar:Refresh()
    if self.bubble then
        self:UpdateBar()
    end
end

function CityTileAssetConstructionTimeBar:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if self:ShouldShow() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_group)
    end
    return string.Empty
end

function CityTileAssetConstructionTimeBar:ShouldShow()
    if not self:GetCity():IsMyCity() then
        return false
    end

    local buildingInfo = self.tileView.tile:GetCastleBuildingInfo()
    if buildingInfo == nil then
        return false
    end
    if self.tileView.tile.inMoveState then
        return false
    end

    return buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_Created or
        buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_Constructing or
        buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend or
        buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_UpgradeReady or
        buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_Upgrading or
        buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
end

function CityTileAssetConstructionTimeBar:OnAssetLoaded(go, userData)
    CityTileAssetConstructionTimeBar.super.OnAssetLoaded(self, go, userData)
    if Utils.IsNull(go) then
        return
    end

    local luaBehaviour = go:AddMissingLuaBehaviour("City3DBubbleStandard", "City3DBubbleStandardSchema")
    ---@type City3DBubbleStandard
    local bubble = luaBehaviour.Instance
    self.bubble = bubble
    self.bubble:Reset()
    self.bubble:ShowProgress()
    if not self:TrySetPosToMainAssetAnchor(self.bubble.transform) then
        self:SetPosToTileWorldCenter(go)
    end
    self:UpdateBar()
end

function CityTileAssetConstructionTimeBar:OnAssetUnload(go, fade)
    if self.bubble then
        self.bubble:SetOnTrigger(nil, nil, false)
    end
    self.bubble = nil
end

function CityTileAssetConstructionTimeBar:UpdateBar()
    self.cellTile = self.tileView.tile
    local houseId = self.cellTile:GetCell().tileId
    local city = self.cellTile:GetCity()
    self.workData = city.cityCitizenManager:GetWorkDataByTarget(houseId, CityWorkTargetType.Building)

    local buildingInfo = self.cellTile:GetCastleBuildingInfo()
    local isCreate = buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_Constructing
        or buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend
        or buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_Created
    local level = isCreate and buildingInfo.Level or buildingInfo.Level + 1
    local typeCfg = ConfigRefer.BuildingTypes:Find(buildingInfo.BuildingType)
    self.duration = ModuleRefer.CityConstructionModule:GetBuildingCostTime(typeCfg, level)

    local isPause = buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
        or buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend
    self.bubble:ShowRedProgress(isPause):ShowDangerImg(isPause)

    if self.workData == nil then
        self.tick = false
        self:UpdateStaticProgress()
    else
        self.tick = true
        self:OnTick()
    end

    self.bubble:EnableTrigger(not isCreate)
    if not isCreate then
        self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickTrigger), self.tileView.tile, true)
    end
end

function CityTileAssetConstructionTimeBar:UpdateStaticProgress()
    local buildingInfo = self.cellTile:GetCastleBuildingInfo()
    self.bubble:UpdateProgress(buildingInfo.Progress / self.duration)
    self.bubble:ShowTimeText(nil)
end

function CityTileAssetConstructionTimeBar:OnTick()
    if not self.tick or not self.bubble then
        return
    end

    local progress, leftTime = self.workData:GetMakeProgress(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
    local index, goTime, _ = self.workData:GetCurrentTargetIndexGoToTimeLeftTime()
    local isGoing = index == 2 and goTime ~= nil
    self.bubble:ShowRoot(not isGoing)
    self.bubble:UpdateProgress(progress)
    self.bubble:ShowTimeText(TimeFormatter.SimpleFormatTimeWithoutZero(leftTime))
end

---@param content table @{targetId=targetId,targetType=targetType}
function CityTileAssetConstructionTimeBar:OnWorkDataAdd(city, id, content)
    local tile = self.tileView.tile
    if city ~= tile:GetCity() then
        return
    end

    if self.bubble == nil then return end
    if content.targetType == CityWorkTargetType.Building and content.targetId == tile:GetCell().tileId then
        self:ForceRefresh()

        local buildingInfo = tile:GetCastleBuildingInfo()
        local isPause = buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_UpgradeSuspend
            or buildingInfo.Status == CastleBuildingStatus.CastleBuildingStatus_ConstructSuspend
        self.bubble:ShowRedProgress(isPause)
    end
end

---@param city City
function CityTileAssetConstructionTimeBar:OnWorkDataChanged(city, id)
    local tile = self.tileView.tile
    if city ~= tile:GetCity() then
        return
    end

    if not self.workData then
        return
    end

    if self.bubble and self.workData._id == id then
        self:Refresh()
    end
end

---@param city City
function CityTileAssetConstructionTimeBar:OnWorkDataDel(city, id)
    local tile = self.tileView.tile
    if city ~= tile:GetCity() then
        return
    end

    if not self.workData then
        return
    end

    if self.bubble and self.workData._id == id then
        self:ForceRefresh()
    end
end

---@param city City
function CityTileAssetConstructionTimeBar:OnCellUpdate(city, x, y)
    local tile = self.tileView.tile
    if city ~= tile:GetCity() then
        return
    end

    local cell = city.grid:GetCell(x, y)
    if tile:GetCell() ~= cell then
        return
    end

    self:ForceRefresh()
end

function CityTileAssetConstructionTimeBar:OnClickTrigger(_)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    if not city:IsMyCity() then return false end

    local buildingInfo = tile:GetCastleBuildingInfo()
    if CityUtils.IsStatusUpgrade(buildingInfo.Status) then
        city.stateMachine:ChangeState(city:GetSuitableIdleState(city.cameraSize))
        g_Game.UIManager:Open(UIMediatorNames.CityBuildUpgradeUIMediator, {cellTile = tile})
        return true
    elseif CityUtils.IsStatusCreateWaitWorker(buildingInfo.Status) then
        city:TryFindFreeWorkerToBuild(tile:GetCell().tileId)
        return true
    end
    return false
end

function CityTileAssetConstructionTimeBar:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.BUILDING
end

function CityTileAssetConstructionTimeBar:OnMoveBegin()
    self:Hide()
end

function CityTileAssetConstructionTimeBar:OnMoveEnd()
    if self:ShouldShow() then
        self:Show()
    end
end

return CityTileAssetConstructionTimeBar