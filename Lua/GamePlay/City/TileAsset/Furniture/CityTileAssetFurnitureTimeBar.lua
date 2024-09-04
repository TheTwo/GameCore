---Obsolete
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local DBEntityPath = require("DBEntityPath")
local CityTilePriority = require("CityTilePriority")
local OnChangeHelper = require("OnChangeHelper")
local CityGridLayerMask = require("CityGridLayerMask")
local CityUtils = require("CityUtils")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local ConfigTimeUtility = require("ConfigTimeUtility")
local CityWorkTargetType = require("CityWorkTargetType")
local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetFurnitureTimeBar:CityTileAssetBubble
---@field new fun():CityTileAssetFurnitureTimeBar
---@field super CityTileAssetBubble
local CityTileAssetFurnitureTimeBar = class('CityTileAssetFurnitureTimeBar', CityTileAssetBubble)

function CityTileAssetFurnitureTimeBar:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
    self._furniture = nil
    self._isAutoCollect = false
    self._city = nil
    self._castle = nil
    self._uid = nil
    self._furnitureId = nil

    ---@type wds.CastleFurniture
    self._castleFurniture = nil
    self._ownerBuildingId = nil
    self._needTick = false
    self._eventsAdd = false
    ---@type City3DBubbleStandard
    self._timeBar = nil
    
    ---@type wds.CastleAutoProduceInfo|nil
    self._autoCollectInfo = nil
    ---@type wds.CastleProcess[]|nil
    self._processInfos = nil
    ---@type CityCitizenWorkData
    self._workData = nil
end

function CityTileAssetFurnitureTimeBar:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local tile = self.tileView.tile
    self._city = tile:GetCity()
    self._castle = self._city:GetCastle()
    self._uid = self._city.uid
    self._furnitureId = tile:GetCell():UniqueId()
    self._castleFurniture = tile:GetCastleFurniture()
    self._needTick = false
    self._ownerBuildingId = nil
    local mask = self._city.gridLayer:Get(tile.x, tile.y)
    if CityGridLayerMask.HasBuilding(mask) then
        local mainCell = self._city.grid:GetCell(tile.x, tile.y)
        if mainCell then
            self._ownerBuildingId = mainCell.tileId
        end
    end
    self:SetupEvents(true)
end

function CityTileAssetFurnitureTimeBar:OnTileViewRelease()
    self:SetupEvents(false)
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetFurnitureTimeBar:OnRoofStateChanged(roofHide)
    if not self.tileView then return end
    if not self.tileView.tile then return end
    if not self.tileView.tile:IsInner() then return end
    if not roofHide then
        self:Hide()
    else
        self:Show()
    end
end

function CityTileAssetFurnitureTimeBar:OnAssetLoaded(go, userdata)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    self._timeBar = nil
    self._needTick = false
    self._go = go
    if Utils.IsNull(go) then
        return
    end
    local behaviour = go:GetLuaBehaviour("City3DBubbleStandard")
    if Utils.IsNull(behaviour) then
        return
    end
    self._timeBar = behaviour.Instance
    if not self._timeBar then
        return
    end
    self:SetupTimeBar()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityTileAssetFurnitureTimeBar:OnAssetUnload(go, fade)
    if self._timeBar then
        self._timeBar:SetOnTrigger(nil, nil, false)
        self._timeBar:PlayOutAni()
    end
    self._timeBar = nil
    self._needTick = false
    self._go = nil
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityTileAssetFurnitureTimeBar:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_group)
end

---@return boolean
function CityTileAssetFurnitureTimeBar:ShouldShow()
    if ModuleRefer.CityModule.myCity.uid ~= self._uid then
        return false
    end
    if not self._castleFurniture then
        return false
    end
    if self.tileView.tile.inMoveState then
        return false
    end
    if self.tileView.tile:IsInner() and not self:GetCity().roofHide then
        return false
    end
    if self._castleFurniture.AutoProduceInfo and #self._castleFurniture.AutoProduceInfo > 0 then
        local autoProduceInfo = self._castleFurniture.AutoProduceInfo[1]
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        return autoProduceInfo.FinishTime and autoProduceInfo.FinishTime.ServerSecond > nowTime
    end
    if not self._castleFurniture.ProcessInfo or #self._castleFurniture.ProcessInfo <= 0 then
        return false
    end
    if self._ownerBuildingId then
        local building = self._castle.BuildingInfos[self._ownerBuildingId]
        if not building then
            return false
        end
        if not CityUtils.IsStatusReady(building.Status) then
            return false
        end
    end
    return true
end

function CityTileAssetFurnitureTimeBar:SetupEvents(add)
    if add and not self._eventsAdd then
        self._eventsAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
    elseif not add and self._eventsAdd then
        self._eventsAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
    end
end

---@param entity wds.CastleBrief
---@param changedData table
function CityTileAssetFurnitureTimeBar:OnFurnitureDataChanged(entity, changedData)
    if not self._uid or self._uid ~= entity.ID then
        return
    end
    local _,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if change and change[self._furnitureId] then
        self._castleFurniture = change[self._furnitureId][2]
        self:CheckAndSetup()
    end
    if remove and remove[self._furnitureId] then
        self:Hide()
    end
end

---@param city City
---@param id number
---@param content CityCitizenWorkTargetPair
function CityTileAssetFurnitureTimeBar:OnWorkDataAdd(city, id, content)
    if not self._uid or self._uid ~= city.uid then
        return
    end
    if self._isAutoCollect then
        return
    end

    if content.targetType == CityWorkTargetType.Furniture and content.targetId == self._furnitureId then
        self:CheckAndSetup()
    end
end

function CityTileAssetFurnitureTimeBar:OnWorkDataChanged(city, id)
    if not self._uid or self._uid ~= city.uid then
        return
    end
    if self._isAutoCollect then
        return
    end
    if not self._workData or self._workData._id ~= id then
        return
    end
    self:CheckAndSetup()
end

---@param city City
function CityTileAssetFurnitureTimeBar:OnWorkDataDel(city, id)
    if not self._uid or self._uid ~= city.uid then
        return
    end
    if self._isAutoCollect then
        return
    end
    if not self._workData or self._workData._id ~= id then
        return
    end
    self:CheckAndSetup()
end

function CityTileAssetFurnitureTimeBar:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.BUILDING
end

function CityTileAssetFurnitureTimeBar:OnMoveBegin()
    self:Hide()
end

function CityTileAssetFurnitureTimeBar:OnMoveEnd()
    if self:ShouldShow() then
        self:Show()
    end
end

function CityTileAssetFurnitureTimeBar:CheckAndSetup()
    if self:ShouldShow() then
        if self._timeBar then
            self:SetupTimeBar()
        elseif not self.handle then
            self:Show()
        end
    else
        self:Hide()
    end
end

---@return boolean
function CityTileAssetFurnitureTimeBar:SetupTimeBar()
    self._needTick = false
    if not self._timeBar then
        return false
    end
    self._isAutoCollect = false
    self._autoCollectInfo = nil
    self._workData = nil
    self._timeBar:Reset()
    if not self:TrySetPosToMainAssetAnchor(self._timeBar.transform) then
        self:SetPosToTileWorldCenter(self._go)
    end
    self._timeBar:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickCollect), self.tileView.tile)
    self._timeBar:EnableTrigger(false)
    local isInfection = self._city.cityCitizenManager:IsTargetInfection(self._furnitureId, CityWorkTargetType.Furniture)
    local autoCollect = self._castleFurniture.AutoProduceInfo and self._castleFurniture.AutoProduceInfo[1]
    if autoCollect then
        return self:SetupAutoCollect(autoCollect, isInfection)
    end
    local processInfo = self._castleFurniture.ProcessInfo
    local workData = self._city.cityCitizenManager:GetWorkDataByTarget(self._furnitureId, CityWorkTargetType.Furniture)
    return self:SetupNormalProduce(processInfo, (workData and workData._isInfinity) and workData or nil, isInfection)
end

---@param autoCollect wds.CastleAutoProduceInfo
function CityTileAssetFurnitureTimeBar:SetupAutoCollect(autoCollect, isInfection)
    self._isAutoCollect = true
    local config = ConfigRefer.CityResourceCheck:Find(autoCollect.ConfigId)
    if config then
        local outPutItem = ConfigRefer.Item:Find(config:OutputItem())
        self._timeBar:ShowProgress(0, outPutItem:Icon(), isInfection, isInfection)
        self._needTick = true
        self._autoCollectInfo = autoCollect
        return true
    end
    return false
end

---@param processInfos wds.CastleProcess[]
---@param workData CityCitizenWorkData
function CityTileAssetFurnitureTimeBar:SetupNormalProduce(processInfos, workData, isInfection)
    if not processInfos or not processInfos[1] then
        return false
    end
    self._processInfos = processInfos
    local showQueue = {}
    for _, v in ipairs(processInfos) do
        if v.FinishNum > 0 then
            local firstShowItem = showQueue[1]
            local config = ConfigRefer.CityProcess:Find(v.ConfigId)
            local item = config:Output(1)
            local itemConfig = ConfigRefer.Item:Find(item:ItemId())
            table.insert(showQueue, {itemConfig:Icon(), v.FinishNum * item:Count(), item:ItemId()})
            if firstShowItem and firstShowItem[3] == item:ItemId() then
                firstShowItem[2] = firstShowItem[2] + v.FinishNum * item:Count()
            end
        end
    end
    if #showQueue > 0 then
        self._timeBar:EnableTrigger(true)
        local first = showQueue[1]
        self._timeBar:ShowBubble(first[1], false, string.format("x%s",first[2]), false, isInfection)
        self._timeBar:PlayLoopAni()
        --local extras = {}
        --for i = 2, #showQueue do
        --    local icon = showQueue[i][1]
        --    if icon and icon ~= first[1] then
        --        table.insert(extras, icon)
        --    end
        --end
        --if #extras > 0 then
        --    self._timeBar:ShowExtraIcon(table.unpack(extras))
        --end
    else
        local mainIcon = string.Empty
        local tickProcess = processInfos[1]
        local processCfg = ConfigRefer.CityProcess:Find(tickProcess.ConfigId)
        if processCfg and processCfg:OutputLength() > 0 then
            local outPutItem = ConfigRefer.Item:Find(processCfg:Output(1):ItemId())
            if outPutItem then
                mainIcon = outPutItem:Icon()
            end
        end
        self._timeBar:ShowProgress(0, mainIcon, false, string.Empty, isInfection)
        self._workData = workData
        if workData then
            if not workData._isInfinity then
                self._needTick = true
            else
                self._timeBar:EnableTrigger(true)
            end
        else
            local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
            if tickProcess.FinishTime and tickProcess.FinishTime.ServerSecond > nowTime then
                self._needTick = true
            end
        end
        if self._needTick then
            self:TickNormalProduce()
        end
    end
    return true
end

function CityTileAssetFurnitureTimeBar:Tick(dt)
    if not self._needTick then
        return
    end
    if self._autoCollectInfo then
        self:TickAutoCollect()
        return
    end
    if self._processInfos then
        self:TickNormalProduce()
        return
    end
end

function CityTileAssetFurnitureTimeBar:TickAutoCollect()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local leftTime = self._autoCollectInfo.FinishTime.ServerSecond - nowTime
    self._timeBar:ShowTimeText(leftTime > 0 and TimeFormatter.SimpleFormatTimeWithoutZero(leftTime) or "--:--")
end

function CityTileAssetFurnitureTimeBar:TickNormalProduce()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if self._workData then
        if not self._workData._isInfinity then
            local v, leftTime = self._workData:GetMakeProgress(nowTime)
            self._timeBar:UpdateProgress(v)
            self._timeBar:ShowTimeText(TimeFormatter.SimpleFormatTimeWithoutZero(leftTime))
        end
    elseif self._processInfos then
        local needTick = false
        local tickProcess = self._processInfos[1]
        if tickProcess.LeftNum > 0 and tickProcess.FinishTime and tickProcess.FinishTime.ServerSecond > nowTime then
            local processConfig = ConfigRefer.CityProcess:Find(tickProcess.ConfigId)
            local oneLoopTime = ConfigTimeUtility.NsToSeconds(processConfig:Time())
            local lastUpdateTime = self._castle.LastWorkUpdateTime.ServerSecond
            local beginTime = lastUpdateTime - (oneLoopTime * tickProcess.FinishNum + tickProcess.CurProgress)
            local endTime = tickProcess.FinishTime.ServerSecond
            for i = 2, #self._processInfos do
                local p = self._processInfos[i]
                processConfig = ConfigRefer.CityProcess:Find(p.ConfigId)
                oneLoopTime = ConfigTimeUtility.NsToSeconds(processConfig:Time())
                endTime = endTime + oneLoopTime * p.LeftNum
            end
            local g = math.inverseLerp(beginTime, endTime, nowTime)
            self._timeBar:UpdateProgress(g)
            local leftTime = endTime - nowTime
            self._timeBar:ShowTimeText(TimeFormatter.SimpleFormatTimeWithoutZero(leftTime))
            needTick = true
        end
        if not needTick then
            self._needTick = false
        end
    else
        self._needTick = false
    end
end

---@param trigger CityTrigger
---@return boolean
function CityTileAssetFurnitureTimeBar:OnClickCollect(trigger)
    if self._isAutoCollect then
        ---@type CityCitizenResourceAutoCollectMediatorParameter
        local uiParameter = {}
        uiParameter.furnitureId = self._furnitureId
        uiParameter.cityUid = self._uid
        uiParameter.buildingId = self._ownerBuildingId
        g_Game.UIManager:Open(UIMediatorNames.CityCitizenResourceAutoCollectMediator, uiParameter)
        return true
    elseif self._workData and self._workData._isInfinity then
        ---@type CityCitizenAutoProcessFurnitureMediatorParameter
        local uiParameter = {}
        uiParameter.furnitureId = self._furnitureId
        uiParameter.city = self._city
        uiParameter.buildingId = self._ownerBuildingId
        g_Game.UIManager:Open(UIMediatorNames.CityCitizenAutoProcessFurnitureMediator, uiParameter)
    else
        if self._processInfos and self._processInfos[1] and self._processInfos[1].FinishNum > 0 then
            local processOutPut = ConfigRefer.CityProcess:Find(self._processInfos[1].ConfigId)
            local itemId = processOutPut:Output(1):ItemId()
            local needGet = {}
            table.insert(needGet, 0)
            for i = 2, #self._processInfos do
                local processInfo = self._processInfos[i]
                if processInfo.FinishNum > 0 then
                    local outItem = ConfigRefer.CityProcess:Find(processInfo.ConfigId):Output(1):ItemId()
                    if outItem == itemId then
                        table.insert(needGet, i - 1)
                    end
                end
            end
            self._city.cityCitizenManager:GetProcessOutput(nil, self._furnitureId, nil, needGet)
            return true
        end
    end
    return false
end

function CityTileAssetFurnitureTimeBar:GetFadeOutDuration()
    return self._timeBar and self._timeBar:GetFadeOutDuration() or CityTileAssetBubble.GetFadeOutDuration(self)
end

return CityTileAssetFurnitureTimeBar