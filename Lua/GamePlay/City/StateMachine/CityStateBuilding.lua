local CityState = require("CityState")
---@class CityStateBuilding:CityState
---@field new fun():CityStateBuilding
---@field data CityStateBuildingDataWrap
local CityStateBuilding = class("CityStateBuilding", CityState)
local Delegate = require("Delegate")
local Utils = require("Utils")
local EventConst = require("EventConst")
local CastleBuildingAddParameter = require("CastleBuildingAddParameter")
local CastleAddFurnitureParameter = require("CastleAddFurnitureParameter")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local CityFurniture = require("CityFurniture")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CityUtils = require("CityUtils")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CityConst = require("CityConst")
local CastleBuildingAddFromStorageParameter = require("CastleBuildingAddFromStorageParameter")
local FurnitureBuildingIdMonitor = require("FurnitureBuildingIdMonitor")
local ArtResourceConsts = require("ArtResourceConsts")
local Quaternion = CS.UnityEngine.Quaternion
local CityConstructionModeUIMediator = require("CityConstructionModeUIMediator")
local CityFurnitureType = require("CityFurnitureType")
local CityStateTileHandle = require("CityStateTileHandle")
local CityStateTileHandleCreateNewFurnitureData = require("CityStateTileHandleCreateNewFurnitureData")
local I18N = require("I18N")
local DragMoveCamera = {
    MinX = 0.18,
    MaxX = 0.92,
    MinY = 0.32,
    MaxY = 0.88,

    MaxSpeed = 20,
    MinSpeed = 5,
}

function CityStateBuilding:ctor(city)
    CityState.ctor(self, city)
    self.tileHandle = CityStateTileHandle.new(self)
end

function CityStateBuilding:Enter()
    CityState.Enter(self)
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_PREVIEW_POS, Delegate.GetOrCreate(self, self.OnUISyncDragPos))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_UICELL_DRAG_RELEASE, Delegate.GetOrCreate(self, self.OnUIDragRelease))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToBuildingState))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingAddParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuildingAdd))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingAddFromStorageParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuildingAddFromStorage))
    g_Game.ServiceManager:AddResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))

    self.data = self.stateMachine:ReadBlackboard("data")
    local screenPos = self.stateMachine:ReadBlackboard("screenPos")
    self.cellTile = self.stateMachine:ReadBlackboard("cellTile")
    local sizeX, sizeY = self.data:SizeX(), self.data:SizeY()
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(self.data:ConfigId())
    local furTypeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    local dirSet = nil
    if furTypeCfg:RotationControl() == 90 then
        dirSet = {0, 90}
    elseif furTypeCfg:RotationControl() == -90 then
        dirSet = {0, 270}
    else
        dirSet = {0, 90, 180, 270}
    end
    self.tileHandleDataWrap = CityStateTileHandleCreateNewFurnitureData.new(self.city, 0, 0, sizeX, sizeY, 0, self.data:ConfigId(), nil, dirSet)
    local x, y = self:GetInitPosition(self.data, screenPos)
    self.tileHandleDataWrap:UpdatePosition(x, y, false)
    self.tileHandle:Initialize(self.tileHandleDataWrap)
    self.tileMonitor = FurnitureBuildingIdMonitor.new(self.city, self.tileHandle, sizeX, sizeY)
    self.tileMonitor:Initialize()
    self.tileAtBuildingIdMap = self.tileMonitor:GetCurrentBuildingIdMap()

    self.city:ShowMapGridView()
    self.city.camera.enablePinch = false
    self._dragCamTimer = 0
    self.city:RefreshBorderParams()
    g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_PREVIEW_NEW, self.data:ConfigId())

    if screenPos then
        self:OnDragStart({position = screenPos})
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE)
end

function CityStateBuilding:Exit()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
    g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH)
    
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingAddParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuildingAdd))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingAddFromStorageParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuildingAddFromStorage))
    g_Game.ServiceManager:RemoveResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_UICELL_DRAG_RELEASE, Delegate.GetOrCreate(self, self.OnUIDragRelease))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_PREVIEW_POS, Delegate.GetOrCreate(self, self.OnUISyncDragPos))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_SELECTION, Delegate.GetOrCreate(self, self.OnSelectToBuildingState))
    
    self:HideSafeAreaHint()
    self.city:HideMapGridView()
    if self.city.camera then
        self.city.camera.enablePinch = true
    end
    self.tileHandle:Release()
    self.tileHandleDataWrap = nil
    self.tileMonitor:Release()
    self.tileMonitor = nil
    self.tileAtBuildingIdMap = nil
    self.screenPos = nil
    self.data = nil
    self.city:RefreshBorderParams()
    CityState.Exit(self)
end

function CityStateBuilding:ReEnter()
    self:Exit()
    self:Enter()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateBuilding:OnDragStart(gesture)
    self.tileHandle:OnDragStart(gesture, false)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateBuilding:OnDragUpdate(gesture)
    self.tileHandle:OnDragUpdate(gesture)
    self:ShowSafeAreaHintIfNeed()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateBuilding:OnDragEnd(gesture)
    self.tileHandle:OnDragEnd(gesture)
    self:ShowSafeAreaHintIfNeed()
end

---@param center CS.UnityEngine.Vector3
function CityStateBuilding:GetXYFromCenterPoint(center, sizeX, sizeY)
    local x, y = self.city:GetCoordFromPosition(center)
    if sizeX % 2 == 0 then
        x = x - sizeX / 2
    else
        x = x - (sizeX - 1) / 2
    end

    if sizeY % 2 == 0 then
        y = y - sizeY / 2
    else
        y = y - (sizeY - 1) / 2
    end
    return x, y
end

function CityStateBuilding:IsAllTileValid(x, y)
    if self.data:IsFurniture() then
        local furnitureType = ModuleRefer.CityConstructionModule:GetFurnitureTypeById(self.data:ConfigId())
        local node = CityFurniture.new(self.city.furnitureManager, self.data:ConfigId(), 0, self.tileHandleDataWrap.direction)
        return self.city.furnitureManager:CanPlaceFurniture(x, y, node, furnitureType)
    else
        return self:IsAllSpace(x, y)
    end
end

function CityStateBuilding:IsAllSpace(x, y)
    for i = x, x + self.tileHandleDataWrap.sizeX - 1 do
        for j = y, y + self.tileHandleDataWrap.sizeY - 1 do
            if not self.city:IsLocationEmpty(i, j) then
                return false
            end
        end
    end
    return true
end

---@param data CityConstructionUICellDataFurniture
---@param screenPos CS.UnityEngine.Vector3|nil
function CityStateBuilding:GetInitPosition(data, screenPos)
    local sizeX = data:SizeX()
    local sizeY = data:SizeY()
    local retX, retY
    self.screenPos = screenPos
    if screenPos then
        retX, retY = self:GetCoordFromScreenPos(screenPos, sizeX, sizeY)
    else
        local hasRecommend, x, y = data:GetRecommendPos()
        if hasRecommend then
            if self.city:IsSquareValidForFurniture(x, y, sizeX, sizeY) and self:IsAllTileValid(x, y) then
                retX, retY = x, y
            else
                retX, retY = self:GetRecommendCoord(sizeX, sizeY, x, y)
            end
        else
            retX, retY = self:GetRecommendCoord(sizeX, sizeY)
        end

        self.city:GetCamera():LookAt(self.city:GetWorldPositionFromCoord(retX + sizeX / 2, retY + sizeY / 2), 0.1)
    end
    return retX, retY
end

---旋转模型
function CityStateBuilding:Rotate(anticlockwise)
    self.tileHandle:Rotate(anticlockwise)
end

function CityStateBuilding:GetCoordFromScreenPos(screenPos, sizeX, sizeY)
    local worldPos = self.city:GetCamera():GetHitPoint(screenPos)
    local x, y = self:GetXYFromCenterPoint(worldPos, sizeX, sizeY)
    if self.city:IsSquareValidForFurniture(x, y, sizeX, sizeY) then
        return x, y
    else
        return self.city:GetFixCoord(x, y, sizeX, sizeY)
    end
end

function CityStateBuilding:GetRecommendCoordIndoor(sizeX, sizeY, cfgRx, cfgRy)
    local x, y = cfgRx, cfgRy
    if not x and not y then
        local pos = self.city:GetCamera():GetLookAtPosition()
        x, y = self:GetXYFromCenterPoint(pos, sizeX, sizeY)
    end
    local rx, ry = self.city.emptyGraph:GetInnerSpaceEnoughPos(sizeX, sizeY, x, y, self.city.editBuilding)
    if rx then
        return rx, ry, true
    end
    g_Logger.Trace("找不到足够大的空间")
    local pos = self.city:GetCamera():GetLookAtPosition()
    x, y = self:GetXYFromCenterPoint(pos, sizeX, sizeY)
    if self.city:IsSquareValidForFurniture(x, y, sizeX, sizeY) then
        return x, y, false
    else
        x, y = self.city:GetFixCoord(x, y, sizeX, sizeY)
        return x, y, false
    end
end

function CityStateBuilding:GetRecommendCoordOutdoor(sizeX, sizeY, cfgRx, cfgRy)
    local x, y = cfgRx, cfgRy
    if not x and not y then
        local pos = self.city:GetCamera():GetLookAtPosition()
        x, y = self:GetXYFromCenterPoint(pos, sizeX, sizeY)
    end
    local rx, ry = self.city.emptyGraph:GetSpaceEnoughPos(sizeX, sizeY, x, y)
    if rx then
        return rx, ry, true
    end

    g_Logger.Trace("找不到足够大的空间")
    local pos = self.city:GetCamera():GetLookAtPosition()
    x, y = self:GetXYFromCenterPoint(pos, sizeX, sizeY)
    if self.city:IsSquareValidForFurniture(x, y, sizeX, sizeY) then
        return x, y, false
    else
        x, y = self.city:GetFixCoord(x, y, sizeX, sizeY)
        return x, y, false
    end
end

function CityStateBuilding:GetRecommendCoord(sizeX, sizeY, x, y)
    local rx, ry = x, y
    if rx == 0 and ry == 0 then
        rx, ry = nil, nil
    end
    if self.data:IsFurniture() then
        local typ = self.data.typCell:Type()
        if typ == CityFurnitureType.InDoor then
            return self:GetRecommendCoordIndoor(sizeX, sizeY, rx, ry)
        elseif typ == CityFurnitureType.OutDoor then
            return self:GetRecommendCoordOutdoor(sizeX, sizeY, rx, ry)
        else
            local x, y, flag = self:GetRecommendCoordIndoor(sizeX, sizeY, rx, ry)
            if flag then
                return x, y
            end
            return self:GetRecommendCoordOutdoor(sizeX, sizeY, rx, ry)
        end
    else
        return self:GetRecommendCoordOutdoor(sizeX, sizeY, rx, ry)
    end
end

---@param screenPos CS.UnityEngine.Vector2
function CityStateBuilding:OnUISyncDragPos(screenPos)
    if self.screenPos == nil then
        self:OnDragStart({position = screenPos})
    else
        self:OnDragUpdate({position = screenPos})
    end
end

function CityStateBuilding:OnUIDragRelease()
    self:OnDragEnd({position = self.screenPos})
end

function CityStateBuilding:OnConfirmToBuild()
    self.canBuild = self.tileHandle:SquareCheck() and self:IsAllTileValid(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y)
    if self.canBuild then
        self.data:RequestToBuild(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y, self.tileHandleDataWrap.direction)
    end
end

function CityStateBuilding:OnBuildingAdd(isSuccess, rsp)
    if isSuccess then
        -- g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_EXIT_EDIT_MODE)
        local x, y = self.tileHandleDataWrap.x, self.tileHandleDataWrap.y
        self:ExitToIdleState()
        self.city.mediator:SimClickCoord(x + 0.5, y + 0.5)
    else
        g_Logger.Error("放置失败")
    end
end

function CityStateBuilding:OnBuildingAddFromStorage(isSuccess, rsp)
    if isSuccess then
        -- g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_EXIT_EDIT_MODE)
        self:ExitToIdleState()
    else
        g_Logger.Error("放置失败")
    end
end

function CityStateBuilding:OnFurnitureAdd(isSuccess, rsp)
    if isSuccess then
        if self.cellTile then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_CONTINUE_PLACE)
        else
            -- g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_EXIT_EDIT_MODE)
        end
        self:ExitToIdleState()
    else
        g_Logger.Error("放置失败")
    end
end

function CityStateBuilding:WorldCenterPos()
    return self.city:GetWorldPositionFromCoord((2 * self.tileHandleDataWrap.x + self.tileHandleDataWrap.sizeX - 1) / 2, (2 * self.tileHandleDataWrap.y + self.tileHandleDataWrap.sizeY - 1) / 2)
end

function CityStateBuilding:CancelPutting()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_CONTINUE_PLACE)
    self:ExitToIdleState()
end

function CityStateBuilding:GetCircleMenuUIParameter()
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        self.tileHandle:SquareCheck() and self:IsAllTileValid(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y),
        Delegate.GetOrCreate(self, self.OnConfirmToBuild)
    )

    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackSec,
        true,
        Delegate.GetOrCreate(self, self.CancelPutting)
    )

    local rotate = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconRotate,
        CircleMenuButtonConfig.ButtonBacks.BackNormal,
        true,
        Delegate.GetOrCreate(self, self.Rotate)
    )
    return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), self.data:GetName(), {confirm, cancel, rotate})
end

function CityStateBuilding:OnSelectToBuildingState(data, pos)
    if self.city and self.city:IsMyCity() and self.city:IsEditMode() then
        self.stateMachine:WriteBlackboard("data", data)
        self.stateMachine:WriteBlackboard("screenPos", pos)
        self.stateMachine:ChangeState(CityConst.STATE_BUILDING)
    end
end

function CityStateBuilding:ShowSafeAreaHintIfNeed()
    if not self.data:IsFurniture() then return end

    for x = self.tileHandleDataWrap.x, self.tileHandleDataWrap.x + self.tileHandleDataWrap.sizeX - 1 do
        for y = self.tileHandleDataWrap.y, self.tileHandleDataWrap.y + self.tileHandleDataWrap.sizeY - 1 do
            if not self.city.safeAreaWallMgr:IsValidSafeArea(x, y) and not self.city:IsInnerBuildingMask(x, y) then
                return g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW_HINT, CityConstructionModeUIMediator.TIPS_ALERT, I18N.Get("city_city_set_room_tips_7"))
            end
        end
    end
    self:HideSafeAreaHint()
end

function CityStateBuilding:HideSafeAreaHint()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE_HINT)
end

return CityStateBuilding