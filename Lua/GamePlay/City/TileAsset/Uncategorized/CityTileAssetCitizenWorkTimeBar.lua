local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityTileAssetBubble = require("CityTileAssetBubble")
local CityGridLayerMask = require("CityGridLayerMask")
local CityUtils = require("CityUtils")
local CityTilePriority = require("CityTilePriority")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkTargetType = require("CityWorkTargetType")

---@class CityTileAssetCitizenWorkTimeBar:CityTileAssetBubble
---@field new fun():CityTileAssetCitizenWorkTimeBar
---@field super CityTileAssetBubble
local CityTileAssetCitizenWorkTimeBar = class('CityTileAssetCitizenWorkTimeBar', CityTileAssetBubble)

function CityTileAssetCitizenWorkTimeBar:ctor()
    CityTileAssetBubble:ctor(self)
    self.isUI = true
    self.isAutoCollect = false
end

function CityTileAssetCitizenWorkTimeBar:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._cityCamera = city:GetCamera()
    self._uid = city.uid
    self._furnitureId = tile:GetCell().singleId
    ---@type wds.CastleProcess
    self._processInfo = nil
    ---@type wds.CastleAutoProduceInfo
    self._autoCollectInfo = nil
    local mask = city.gridLayer:Get(tile.x, tile.y)
    self._ownerBuildingId = nil
    if CityGridLayerMask.HasBuilding(mask) then
        local mainCell = city.grid:GetCell(tile.x, tile.y)
        if mainCell then
            self._ownerBuildingId = mainCell.tileId
        end
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
end

function CityTileAssetCitizenWorkTimeBar:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetCitizenWorkTimeBar:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_bubble_citizen_work_progress)
end

---@param go CS.UnityEngine.GameObject
---@param userData any
function CityTileAssetCitizenWorkTimeBar:OnAssetLoaded(go, userData)
    CityTileAssetBubble.OnAssetLoaded(self, go, userData)
    if Utils.IsNull(go) then
        return
    end
    ---@type CityCitizenWorkTimeBarData
    local data = {}
    data.targetType = CityWorkTargetType.Furniture
    data.targetId = self._furnitureId
    data.onclickTrigger = Delegate.GetOrCreate(self, self.OnClickTrigger)
    data.workData = self._citizenWorkData
    data.autoCollectInfo = self._autoCollectInfo
    data.processInfo = self._processInfo
    ---@type CityCitizenWorkTimeBar
    self.bubble = go:GetLuaBehaviour("CityCitizenWorkTimeBar").Instance
    self.bubble:Init(self.tileView, data)
end

function CityTileAssetCitizenWorkTimeBar:OnAssetUnload(go, fade)
    self.bubble:Release()
    self.bubble = nil
end

function CityTileAssetCitizenWorkTimeBar:ShouldShow()
    self.isAutoCollect = false
    ---@type CityCitizenWorkData
    self._citizenWorkData = nil
    self._processInfo = nil
    self._autoCollectInfo = nil
    local city = self:GetCity()
    if ModuleRefer.CityModule.myCity.uid ~= city.uid then
        return false
    end
    local castle = city:GetCastle()
    local furnitureData = castle.CastleFurniture[self._furnitureId]
    if not furnitureData then
        return false
    end
    if self.tileView.tile.inMoveState then
        return false
    end
    if furnitureData.AutoProduceInfo and #furnitureData.AutoProduceInfo > 0 then
        return self:ShouldAutoCollectShow(furnitureData, city, castle)
    end
    return self:ShouldWorkShow(furnitureData, city, castle)
end

---@param furnitureData wds.CastleFurniture
---@param city City
---@param castle wds.Castle
function CityTileAssetCitizenWorkTimeBar:ShouldWorkShow(furnitureData,city,castle)
    if not furnitureData.ProcessInfo then
        return false
    end
    self._processInfo = furnitureData.ProcessInfo[1]
    if not self._processInfo then
        return false
    end
    local citizenMgr = city.cityCitizenManager
    self._citizenWorkData = citizenMgr:GetWorkDataByTarget(self._furnitureId, CityWorkTargetType.Furniture)
    if self._ownerBuildingId then
        local building = castle.BuildingInfos[self._ownerBuildingId]
        if not building then
            return false
        end
        if not CityUtils.IsStatusReady(building.Status) then
            return false
        end
    end
    return true
end

function CityTileAssetCitizenWorkTimeBar:ShouldAutoCollectShow(furnitureData,city,castle)
    self._autoCollectInfo = furnitureData.AutoProduceInfo[1]
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if self._autoCollectInfo.FinishTime and self._autoCollectInfo.FinishTime.ServerSecond > nowTime then
        return true
    end
    return false
end

function CityTileAssetCitizenWorkTimeBar:OnClickTrigger(trigger)
    ---@type MyCity
    local city = self:GetCity()
    if not city or not city:IsMyCity() then
        return
    end
    local furnitureId = self._furnitureId
    local castle = city:GetCastle()
    local furniture = castle.CastleFurniture[furnitureId]
    if not furniture then
        return
    end
    if self.isAutoCollect then
        ---@type CityCitizenResourceAutoCollectMediatorParameter
        local uiParameter = {}
        uiParameter.furnitureId = furnitureId
        uiParameter.cityUid = city.uid
        uiParameter.buildingId = self._ownerBuildingId
        g_Game.UIManager:Open(UIMediatorNames.CityCitizenResourceAutoCollectMediator, uiParameter)
        return true
    elseif self._citizenWorkData and self._citizenWorkData._isInfinity then
        ---@type CityCitizenAutoProcessFurnitureMediatorParameter
        local uiParameter = {}
        uiParameter.furnitureId = furnitureId
        uiParameter.city = city
        uiParameter.buildingId = self._ownerBuildingId
        g_Game.UIManager:Open(UIMediatorNames.CityCitizenAutoProcessFurnitureMediator, uiParameter)
        return true
    else
        local process = furniture.ProcessInfo and furniture.ProcessInfo[1]
        if not process then
            return
        end
        if process.FinishNum > 0 then
            city.cityCitizenManager:GetProcessOutput(nil, furnitureId)
        end
        return true
    end
end

function CityTileAssetCitizenWorkTimeBar:Refresh()
    if self:ShouldShow() then
        if self.bubble then
            ---@type CityCitizenWorkTimeBarData
            local data = {}
            data.targetType = CityWorkTargetType.Furniture
            data.targetId = self._furnitureId
            data.onclickTrigger = Delegate.GetOrCreate(self, self.OnClickTrigger)
            data.workData = self._citizenWorkData
            data.autoCollectInfo = self._autoCollectInfo
            data.processInfo = self._processInfo
            self.bubble:RefreshData(data)
        elseif not self.handle then
            self:Show()
        end
    else
        self:Hide()
    end
end

---@param entity wds.CastleBrief
---@param changedData table
function CityTileAssetCitizenWorkTimeBar:OnFurnitureDataChanged(entity, changedData)
    if not self._uid or self._uid ~= entity.ID then
        return
    end
    if not self.tileView then
        return
    end
    if not self.tileView.tile then
        return
    end
    local city = self:GetCity()
    if not city then
        return
    end
    local castle = city:GetCastle()
    local furnitureData = castle.CastleFurniture[self._furnitureId]
    if  furnitureData then
        self:Refresh()
    end
end

---@param content CityCitizenWorkTargetPair
function CityTileAssetCitizenWorkTimeBar:OnWorkDataAdd(city, id, content)
    if not self._uid or city.uid ~= self._uid then
        return
    end
    if self.isAutoCollect then
        return
    end
    if content.targetType == CityWorkTargetType.Furniture and content.targetId == self._furnitureId then
        self:Refresh()
    end
end

function CityTileAssetCitizenWorkTimeBar:OnWorkDataChanged(city, id)
    if not self._uid or city.uid ~= self._uid then
        return
    end
    if self.isAutoCollect then
        return
    end
    if self._citizenWorkData and id == self._citizenWorkData._id then
        self:Refresh()
    end
end

function CityTileAssetCitizenWorkTimeBar:OnWorkDataDel(city, id)
    if not self._uid or city.uid ~= self._uid then
        return
    end
    if self.isAutoCollect then
        return
    end
    if self._citizenWorkData and id == self._citizenWorkData._id then
        self:Refresh()
    end
end

function CityTileAssetCitizenWorkTimeBar:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.BUILDING
end

function CityTileAssetCitizenWorkTimeBar:OnMoveBegin()
    self:Hide()
end

function CityTileAssetCitizenWorkTimeBar:OnMoveEnd()
    if self:ShouldShow() then
        self:Show()
    end
end

return CityTileAssetCitizenWorkTimeBar