local CityState = require("CityState")
---@class CityStateMovingLego:CityState
---@field new fun():CityStateMovingLego
local CityStateMovingLego = class("CityStateMovingLego", CityState)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityStateTileHandle = require("CityStateTileHandle")
local CityStateTileHandleLegoTileData = require("CityStateTileHandleLegoTileData")
local CityUtils = require("CityUtils")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CityGridLayerMask = require("CityGridLayerMask")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local I18N = require("I18N")
local CityConst = require("CityConst")
local CastleBuildingMoveParameter = require("CastleBuildingMoveParameter")

function CityStateMovingLego:ctor(city)
    CityState.ctor(self, city)
    self.tileHandle = CityStateTileHandle.new(self)
end

function CityStateMovingLego:Enter()
    ---@type CityLegoBuilding
    self.legoBuilding = self.stateMachine:ReadBlackboard("legoBuilding")
    self.legoTile = self.city.gridView.legoTiles[self.legoBuilding.id]
    self:BindingTiles()
    self.tileHandleDataWrap = CityStateTileHandleLegoTileData.new(self.legoTile)
    self.tileHandle:Initialize(self.tileHandleDataWrap)
    if not self.city:IsEditMode() then
        self.city:ShowMapGridView()
    end
    self.city.camera.enablePinch = false
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Delegate.GetOrCreate(self, self.OnLegoBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnElementBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_CHANGE_MOVING_LEGO_STATE, Delegate.GetOrCreate(self, self.OnMovingStateChange))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_REMOVE_PRE, Delegate.GetOrCreate(self, self.OnLegoDelete))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingMoveParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnMovingCallback))

    g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_SHOW_NAME, self.city)
end

function CityStateMovingLego:Exit()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Delegate.GetOrCreate(self, self.OnLegoBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnElementBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CHANGE_MOVING_LEGO_STATE, Delegate.GetOrCreate(self, self.OnMovingStateChange))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_REMOVE_PRE, Delegate.GetOrCreate(self, self.OnLegoDelete))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingMoveParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnMovingCallback))
    self.city.camera.enablePinch = true
    self.tileHandle:Release()
    self.tileHandleDataWrap = nil
    self:CancelMoving()
    if not self.city:IsEditMode() then
        self.city:HideMapGridView()
    end
    self:UnbindTiles()
    self.legoTile = nil
    self.legoBuilding = nil
end

function CityStateMovingLego:BindingTiles()
    ---@type CityFurnitureTile[]
    self.furnitureTiles = {}
    for i, furnitureId in ipairs(self.legoBuilding.payload.InnerFurnitureIds) do
        local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
        if furniture then
            local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
            if tile then
                tile:SetParent(self.legoBuilding.tileView.rotRoot.transform)
                self.furnitureTiles[furnitureId] = tile

                self.city.gridView:ForceShow(tile)
                tile:OnMoveBegin()
            end
        else
            g_Logger.ErrorChannel("CityLegoBuilding", "[buildingId:%d]服务器记录的InnerFurnitureIds与CastleFurniture不一致", self.legoBuilding.id)
        end
    end

    ---@type CityCellTile[]
    self.elementTiles = {}
    for i, elementId in ipairs(self.legoBuilding.payload.InnerResourceIds) do
        local element = self.city.elementManager:GetElementById(elementId)
        if element then
            local tile = self.city.gridView:GetCellTile(element.x, element.y)
            if tile then
                tile:SetParent(self.legoBuilding.tileView.rotRoot.transform)
                self.elementTiles[elementId] = tile

                self.city.gridView:ForceShow(tile)
                tile:OnMoveBegin()
            end
        else
            g_Logger.ErrorChannel("CityLegoBuilding", "[buildingId:%d]服务器记录的InnerResourcesIds与CastleElement不一致", self.legoBuilding.id)
        end
    end
end

function CityStateMovingLego:UnbindTiles()
    if self.furnitureTiles then
        for id, v in pairs(self.furnitureTiles) do
            v:ResetParent()
            self.city.gridView:CancelForceShow(v)
            v:OnMoveEnd()
        end
    end
    if self.elementTiles then
        for i, v in pairs(self.elementTiles) do
            v:ResetParent()
            self.city.gridView:CancelForceShow(v)
            v:OnMoveEnd()
        end
    end
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingLego:OnDragStart(gesture)
    self.tileHandle:OnDragStart(gesture, self.forceDragging)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingLego:OnDragUpdate(gesture)
    self.tileHandle:OnDragUpdate(gesture)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingLego:OnDragEnd(gesture)
    self.tileHandle:OnDragEnd(gesture)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
end

---@param evt {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CityStateMovingLego:OnFurnitureBatchUpdate(city, evt)
    if self.city ~= city then return end
    if next(evt.Remove) == nil then return end

    for id, v in pairs(evt.Remove) do
        if self.furnitureTiles[id] then
            self.furnitureTiles[id]:OnMoveEnd()
            self.city.gridView:CancelForceShow(self.furnitureTiles[id])
            self.furnitureTiles[id] = nil
        end
    end
end

---@param evt {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CityStateMovingLego:OnLegoBatchUpdate(city, evt)
    if self.city ~= city then return end
    if not evt.Change[self.legoBuilding.id] == nil then return end

    for i, furnitureId in ipairs(self.legoBuilding.payload.InnerFurnitureIds) do
        if not self.furnitureTiles[furnitureId] then
            local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
            local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
            tile:SetParent(self.legoBuilding.tileView.rotRoot.transform)
            self.furnitureTiles[furnitureId] = tile
            self.city.gridView:ForceShow(tile)
            tile:OnMoveBegin()
        end
    end

    for i, elementId in ipairs(self.legoBuilding.payload.InnerResourceIds) do
        if not self.elementTiles[elementId] then
            local element = self.city.elementManager:GetElementById(elementId)
            local tile = self.city.gridView:GetCellTile(element.x, element.y)
            tile:SetParent(self.legoBuilding.tileView.rotRoot.transform)
            self.elementTiles[elementId] = tile
            self.city.gridView:ForceShow(tile)
            tile:OnMoveBegin()
        end
    end
end

---@param evt {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CityStateMovingLego:OnElementBatchUpdate(city, evt)
    if self.city ~= city then return end
    if next(evt.Remove) ~= nil then
        for id, v in pairs(evt.Remove) do
            if self.elementTiles[id] then
                self.elementTiles[id]:OnMoveEnd()
                self.city.gridView:CancelForceShow(self.elementTiles[id])
                self.elementTiles[id] = nil
            end
        end
    end
end

function CityStateMovingLego:GetCircleMenuUIParameter()
    local canBuild = self:CanBuild()
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        canBuild and self.tileHandle:SquareCheck(),
        Delegate.GetOrCreate(self, self.TryMove)
    )
    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.ExitToIdleState)
    )
    return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), I18N.Get(self.legoBuilding:GetNameI18N()), {confirm, cancel})
end

function CityStateMovingLego:WorldCenterPos()
    return self.city:GetWorldPositionFromCoord((2 * self.tileHandleDataWrap.x + self.tileHandleDataWrap.sizeX - 1) / 2, (2 * self.tileHandleDataWrap.y + self.tileHandleDataWrap.sizeY - 1) / 2)
end

function CityStateMovingLego:CanBuild()
    local curX, curY = self.tileHandleDataWrap.x, self.tileHandleDataWrap.y
    local sizeX, sizeY = self.legoBuilding.sizeX, self.legoBuilding.sizeZ
    for j = 0, sizeY - 1 do
        for i = 0, sizeX - 1 do
            local x, y = i + curX, j + curY
            if self.legoBuilding:Besides(x, y) then
                goto continue
            end

            local mask = self.city.gridLayer:Get(x, y)
            if CityGridLayerMask.IsPlaced(mask) then
                return false
            elseif not CityGridLayerMask.IsSafeArea(mask) then
                return false
            elseif not self.city.safeAreaWallMgr:IsValidSafeArea(x, y) then
                return false
            elseif self.city.creepManager:IsAffect(x, y) then
                return false
            end

            ::continue::
        end
    end

    return true
end

function CityStateMovingLego:TryMove()
    if self:CanBuild() and self.tileHandle:SquareCheck() then
        if self.tileHandle:NotChanged() then
            self:CancelMoving()
            self:ExitToIdleState()
        else
            self:RequestMove()
        end
    end
end

function CityStateMovingLego:RequestMove()
    local msg = CastleBuildingMoveParameter.new()
    msg.args.BuildingInstanceId = self.legoBuilding.id
    msg.args.NewPos = wds.Point2.New(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y)
    msg:SendWithFullScreenLock()
end

function CityStateMovingLego:OnMovingCallback(isSuccess, reply, abstractRpc)
    if not isSuccess then return end
    self.city.legoManager:PlayPutDownVfx(self.legoBuilding)
    self:ExitToIdleState()
end

function CityStateMovingLego:CancelMoving()
    self.legoTile:UpdatePosition(self.city:GetWorldPositionFromCoord(self.legoBuilding.x, self.legoBuilding.z))
end

function CityStateMovingLego:OnMovingStateChange(flag)
    if not flag then
        self:ExitToIdleState()
    end
end

function CityStateMovingLego:OnLegoDelete(city, legoBuilding)
    if self.city ~= city then return end
    if self.legoBuilding ~= legoBuilding then return end
    self:ExitToIdleState()
end

return CityStateMovingLego