local CityState = require("CityState")
local CityConst = require("CityConst")
---@class CityStateMovingBuilding : CityState
---@field new fun():CityStateMovingBuilding
---@field city City
---@field cellTile CityCellTile
---@field furnitureTiles CityFurnitureTile[]
local CityStateMovingBuilding = class("CityStateMovingBuilding", CityState)
local Delegate = require("Delegate")
local CastleBuildingMoveParameter = require("CastleBuildingMoveParameter")
local EventConst = require("EventConst")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CityUtils = require("CityUtils")
local CastleBuildingDelParameter = require("CastleBuildingDelParameter")
local CastleBuildingActivateParameter = require("CastleBuildingActivateParameter")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CityStateTileHandle = require("CityStateTileHandle")
local Utils = require("Utils")

---@param city City
function CityStateMovingBuilding:ctor(city)
    CityState.ctor(self, city)
    self.tileHandle = CityStateTileHandle.new(self)
end

function CityStateMovingBuilding:Enter()
    CityState.Enter(self)
    self.cellTile = self.stateMachine:ReadBlackboard("MovingCell")
    self.furnitureTiles = self.stateMachine:ReadBlackboard("RelativeFurniture")
    self.forceDragging = self.stateMachine:ReadBlackboard("DragImmediate")
    self._checkAutoCollectFurnitureIds = {}
    self:BindFurnitures()
    self:ForceShowTiles()

    if self.cellTile == nil then
        self:ExitToIdleState()
        return
    else
        local squareCheckFunc = Delegate.GetOrCreate(self.city, self.city.IsSquareValidForBuilding)
        local fixCoordFunc = Delegate.GetOrCreate(self.city, self.city.GetFixCoord)
        self.tileHandle:Initialize(self.cellTile, squareCheckFunc, fixCoordFunc)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_OPERATION_MOVING_START, self.cellTile:GetCell().tileId)
        if self.city:IsEditMode() then
            self.city:ShowMapGridView()
        end
    end
    self.cellTile:OnMoveBegin()
    if self.furnitureTiles then
        for _, v in pairs(self.furnitureTiles) do
            v:OnMoveBegin()
        end
    end
    self.rotRoot = self.cellTile:GetRotRoot()
    if Utils.IsNotNull(self.rotRoot) then
        self.city.flashMatController:StartFlash(self.rotRoot)
    end
    self:SwitchTransparentOutline(true)
    self.city.camera.enablePinch = false
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_CIRCLE_MENU_CLOSED, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingMoveParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingDelParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingActivateParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnCallback))
end

function CityStateMovingBuilding:Exit()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_OPERATION_MOVING_STOP)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_CONTINUE_PLACE)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CIRCLE_MENU_CLOSED, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingMoveParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingDelParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingActivateParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnCallback))
    if Utils.IsNotNull(self.rotRoot) then
        self.city.flashMatController:StopFlash(self.rotRoot)
    end
    self.rotRoot = nil
    self:SwitchTransparentOutline(false)
    if self.furnitureTiles then
        for _, v in pairs(self.furnitureTiles) do
            v:OnMoveEnd()
        end
    end
    self.cellTile:OnMoveEnd()
    self.tileHandle:Release()
    self:CancelMoving()
    self:CancelForceShow()
    self:ResetFurnitures()
    if not self.city:IsEditMode() then
        self.city:HideMapGridView()
    end
    self.city.camera.enablePinch = true
    self.cellTile = nil
    self.furnitureTiles = nil
    self.forceDragging = false
    CityState.Exit(self)
end

function CityStateMovingBuilding:ReEnter()
    self:Exit()
    self:Enter()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingBuilding:OnDragStart(gesture)
    self.tileHandle:OnDragStart(gesture, self.forceDragging)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingBuilding:OnDragUpdate(gesture)
    self.tileHandle:OnDragUpdate(gesture)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingBuilding:OnDragEnd(gesture)
    self.tileHandle:OnDragEnd(gesture)
    self.forceDragging = false
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
end

function CityStateMovingBuilding:OnCameraSizeChanged(oldValue, newValue)
    self:TryChangeToAirView(oldValue, newValue)
end

function CityStateMovingBuilding:TryMove()
    if self.city:IsSquareValidForBuilding(self.tileHandle.curX, self.tileHandle.curY, self.tileHandle.sizeX, self.tileHandle.sizeY) and self:IsAllSpaceBesidesSelf() then
        if self.cellTile.x == self.tileHandle.curX and self.cellTile.y == self.tileHandle.curY then
            self:CancelMoving()
            self:ExitToIdleState()
        else
            self:BuildingMove()
        end
    end
end

function CityStateMovingBuilding:IsAllSpaceBesidesSelf()
    local ret = true
    local gridCell = self.cellTile:GetCell()
    for x = self.tileHandle.curX, self.tileHandle.curX + self.tileHandle.sizeX - 1 do
        for y = self.tileHandle.curY, self.tileHandle.curY + self.tileHandle.sizeY - 1 do
            if self.city:IsLocationEmpty(x, y) then
                goto continue
            end

            if gridCell:Besides(x, y) then
                goto continue
            end

            ret = false
            break

            ::continue::
        end
    end
    return ret
end

function CityStateMovingBuilding:CancelMoving()
    if self.cellTile and self.cellTile.x and self.cellTile.y then
        local cell = self.cellTile:GetCell()
        self.cellTile:UpdatePosition(self.city:GetWorldPositionFromCoord(cell.x, cell.y))
    end
end

function CityStateMovingBuilding:BuildingMove()
    local msg = CastleBuildingMoveParameter.new()
    msg.args.BuildingInstanceId = self.cellTile:GetCell().tileId
    msg.args.NewPos = wds.Point2.New(self.tileHandle.curX, self.tileHandle.curY)
    msg:SendWithFullScreenLock()
end

function CityStateMovingBuilding:Storage()
    if self.cellTile then
        local msg = CastleBuildingDelParameter.new()
        msg.args.BuildingInstanceId = self.cellTile:GetCell().tileId
        msg:SendWithFullScreenLock()
    end
end

function CityStateMovingBuilding:RibbonCut()
    local cell = self.cellTile:GetCell()
    self.city:RibbonCut(cell.tileId)
end

function CityStateMovingBuilding:OnCallback(isSuccess, rsp)
    if isSuccess then
        self:ExitToIdleState()
    end
end

function CityStateMovingBuilding:BindFurnitures()
    table.clear(self._checkAutoCollectFurnitureIds)
    for i, v in ipairs(self.furnitureTiles) do
        v:SetParent(self.cellTile:GetRoot().transform)
        self._checkAutoCollectFurnitureIds[v:GetCell():UniqueId()] = true
    end
end

function CityStateMovingBuilding:ResetFurnitures()
    for i, v in ipairs(self.furnitureTiles) do
        v:ResetParent()
    end
end

function CityStateMovingBuilding:ForceShowTiles()
    for i, v in ipairs(self.furnitureTiles) do
        self.city.gridView:ForceShow(v)
    end
end

function CityStateMovingBuilding:CancelForceShow()
    if self.furnitureTiles then
        for i, v in ipairs(self.furnitureTiles) do
            self.city.gridView:CancelForceShow(v)
        end
    end
end

function CityStateMovingBuilding:WorldCenterPos()
    return self.city:GetWorldPositionFromCoord((2 * self.tileHandle.curX + self.tileHandle.sizeX - 1) / 2, (2 * self.tileHandle.curY + self.tileHandle.sizeY - 1) / 2)
end

function CityStateMovingBuilding:GetCircleMenuUIParameter()
    local buttons = {}
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        self.city:IsSquareValidForBuilding(self.tileHandle.curX, self.tileHandle.curY, self.tileHandle.sizeX, self.tileHandle.sizeY) and self:IsAllSpaceBesidesSelf(),
        Delegate.GetOrCreate(self, self.TryMove)
    )
    table.insert(buttons, confirm)
    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.ExitToIdleState)
    )
    table.insert(buttons, cancel)
    return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), self.cellTile:GetBuildingName(), buttons)
end

function CityStateMovingBuilding:SwitchTransparentOutline(flag)
    if Utils.IsNotNull(self.city.flashMatController) then
        self.city.flashMatController:SwitchTransparentOutline(flag, self.city.camera.mainCamera)
    end
end

return CityStateMovingBuilding