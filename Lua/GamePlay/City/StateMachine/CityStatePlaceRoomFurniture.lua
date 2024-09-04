local CityState = require("CityState")
---@class CityStatePlaceRoomFurniture:CityState
---@field new fun():CityStatePlaceRoomFurniture
---@field data CityConstructionUICellDataCustomRoom
local CityStatePlaceRoomFurniture = class("CityStatePlaceRoomFurniture", CityState)
local CastleAddFurnitureParameter = require("CastleAddFurnitureParameter")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local EventConst = require("EventConst")
local CityConst = require("CityConst")
local ArtResourceConsts = require("ArtResourceConsts")
local CityUtils = require("CityUtils")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CityFurniture = require("CityFurniture")
local ConfigRefer = require("ConfigRefer")

function CityStatePlaceRoomFurniture:Enter()
    CityState.Enter(self)
    self.minX = self.stateMachine:ReadBlackboard("minX")
    self.maxX = self.stateMachine:ReadBlackboard("maxX")
    self.minY = self.stateMachine:ReadBlackboard("minY")
    self.maxY = self.stateMachine:ReadBlackboard("maxY")
    self.data = self.stateMachine:ReadBlackboard("data")
    self.idx = self.stateMachine:ReadBlackboard("idx")
    self.cellTile = self.stateMachine:ReadBlackboard("cellTile")
    self.lvCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(self.data.cfg:RecommendFurnitures(self.idx))
    self.furnitureCategory = ConfigRefer.CityFurnitureTypes:Find(self.lvCell:Type()):Category()
    self:LoadPreviewModel()
    g_Game.ServiceManager:AddResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_ROOM_CANCEL_PLACE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
end

function CityStatePlaceRoomFurniture:Exit()
    self:HideCityCircleMenu()
    self:RecoverCamera()
    self:ReleaseHandles()
    self.screenPos = nil

    g_Game.ServiceManager:RemoveResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ROOM_CANCEL_PLACE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))

    self.data = nil
    self.cellTile = nil
    CityState.Exit(self)
end

function CityStatePlaceRoomFurniture:ReEnter()
    self:Exit()
    self:Enter()
end

function CityStatePlaceRoomFurniture:ReleaseHandles()
    if self.handler then
        if self.handler.Loaded and self.trans then
            self.city.flashMatController:StopFlash(self.trans.go)
        end
        self.city.createHelper:Delete(self.handler)
        self.handler = nil
    end
    if self.selectorHandler then
        self.city.createHelper:Delete(self.selectorHandler)
        self.selectorHandler = nil
    end
    self.trans = nil
end

function CityStatePlaceRoomFurniture:SquareCheckInRect(x, y, sizeX, sizeY)
    for i = x, x + sizeX - 1 do
        for j = y, y + sizeY - 1 do
            if not self:BesidesRect(i, j) or not self.city:IsLocationValidForFurniture(i, j, self.furnitureCategory) then
                return false
            end
        end
    end
    return true
end

function CityStatePlaceRoomFurniture:BesidesRect(x, y)
    return self.minX <= x and x <= self.maxX and self.minY <= y and y <= self.maxY
end

function CityStatePlaceRoomFurniture:FixCoordInRect(x, y, sizeX, sizeY)
    local fixX = math.clamp(x, self.minX, self.maxX - sizeX + 1)
    local fixY = math.clamp(y, self.minY, self.maxY - sizeY + 1)
    return fixX, fixY
end

function CityStatePlaceRoomFurniture:OnFurnitureAdd(isSuccess, reply, rpc)
    if isSuccess then
        self:TryTurnToNextStage()
    end
end

function CityStatePlaceRoomFurniture:IsXYExchange()
    return self.direction == 90 or self.direction == 270
end

function CityStatePlaceRoomFurniture:LoadPreviewModel()
    self.direction = 0
    self.sizeX = self:IsXYExchange() and self.lvCell:SizeY() or self.lvCell:SizeX()
    self.sizeY = self:IsXYExchange() and self.lvCell:SizeX() or self.lvCell:SizeY()
    self.curX, self.curY = self:GetRecommendCoord(self.sizeX, self.sizeY)
    self.lastX, self.lastY = self.curX, self.curY
    self.scale = self:GetScale()
    self.prefabName = self:GetPrefabName()
    self.handler = self.city.createHelper:Create(self.prefabName, self.city:GetRoot().transform, Delegate.GetOrCreate(self, self.OnPreviewModelLoaded), nil, 0, false)
    self.selectorHandler = self.city.createHelper:Create(self:GetSelectorPrefabName(), self.city:GetRoot().transform, Delegate.GetOrCreate(self, self.OnSelectorLoaded), nil, 0, false)
end

function CityStatePlaceRoomFurniture:OnPreviewModelLoaded(go, userdata)
    if Utils.IsNull(go) then
        g_Logger.ErrorChannel("City", ("Load %s failed"):format(self.prefabName))
        self:ExitToIdleState()
        return
    end

    self.city.flashMatController:StartFlash(go)
    go:SetLayerRecursively("City")
    self.trans = go.transform
    if self.scale ~= 1 then
        self.trans.localScale = CS.UnityEngine.Vector3.one * self.scale
    else
        self.trans.localScale = CS.UnityEngine.Vector3.one
    end
    self.lastX, self.lastY = self.curX, self.curY
    self:OnModelLoadedPositionAndRotation()
end

---旋转模型
function CityStatePlaceRoomFurniture:Rotate(anticlockwise)
    if anticlockwise then
        self.direction = (self.direction - 90) % 360
    else
        self.direction = (self.direction + 90) % 360
    end
    
    ---长宽不等时需要调整 curX, curY, sizeX, sizeY
    if self.sizeX ~= self.sizeY then
        self.lastX, self.lastY = self.curX, self.curY

        local offsetX = self.sizeX / 2 - self.sizeY / 2
        local offsetY = self.sizeY / 2 - self.sizeX / 2
        self.curX = math.floor(math.abs(offsetX)) * math.sign(offsetX) + self.curX
        self.curY = math.floor(math.abs(offsetY)) * math.sign(offsetY) + self.curY

        self.sizeX, self.sizeY = self.sizeY, self.sizeX
        self:OnSelectorRotate()
    end

    if Utils.IsNotNull(self.trans) then
        self:OnModelLoadedPositionAndRotation()
    end
end

function CityStatePlaceRoomFurniture:OnSelectorLoaded(go, userdata)
    if Utils.IsNull(go) then
        return
    end

    if not self.data then
        if self.selectorHandler then
            self.city.createHelper:Delete(self.selectorHandler)
            self.selectorHandler = nil
        end
        return
    end

    local behaviourName = self:GetSelectorBehaviourName()
    if behaviourName == "CityBuildingSelector" then
        ---@type CityBuildingSelector
        self.selector = go:GetLuaBehaviour(behaviourName).Instance
        self.selector:InitPreview(self.city, self.curX, self.curY, self.sizeX, self.sizeY, true, self.lvCell:Id())
    elseif behaviourName == "CityAutoCollectBoxFurnitureSelector" then
        ---@type CityAutoCollectBoxFurnitureSelector
        self.selector = go:GetLuaBehaviour(behaviourName).Instance
        self.selector:InitPreview(self.city, self.curX, self.curY, self.sizeX, self.sizeY, true, self.lvCell:Id())
    elseif behaviourName == "CityCreepSweeperFurnitureSelector" then
        ---@type CityCreepSweeperFurnitureSelector
        local selector = go:GetLuaBehaviour(behaviourName).Instance
        local lvCellId = self.lvCell:Id()
        local sweeperConfig = ModuleRefer.CityCreepModule:GetSweeperConfigByFurnitureLevelId(lvCellId)
        local sweepSizeX = self:IsXYExchange() and sweeperConfig:SweepSizeY() or sweeperConfig:SweepSizeX()
        local sweepSizeY = self:IsXYExchange() and sweeperConfig:SweepSizeX() or sweeperConfig:SweepSizeY()
        selector:InitPreview(self.city, self.curX, self.curY, self.sizeX, self.sizeY, sweepSizeX, sweepSizeY, lvCellId)
        self.selector = selector
    end

    if not self.screenPos then
        self:ShowCityCircleMenu()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
    end
end

function CityStatePlaceRoomFurniture:OnSelectorRotate()
    if not self.selector then return end
    if not self.data then return end

    local behaviourName = self:GetSelectorBehaviourName()
    if behaviourName == "CityBuildingSelector" then
        ---@type CityBuildingSelector
        self.selector:InitPreview(self.city, self.curX, self.curY, self.sizeX, self.sizeY, true, self.lvCell:Id())
    elseif behaviourName == "CityAutoCollectBoxFurnitureSelector" then
        ---@type CityAutoCollectBoxFurnitureSelector
        self.selector:InitPreview(self.city, self.curX, self.curY, self.sizeX, self.sizeY, true, self.lvCell:Id())
    elseif behaviourName == "CityCreepSweeperFurnitureSelector" then
        ---@type CityCreepSweeperFurnitureSelector
        local lvCellId = self.lvCell:Id()
        local sweeperConfig = ModuleRefer.CityCreepModule:GetSweeperConfigByFurnitureLevelId(lvCellId)
        local sweepSizeX = self:IsXYExchange() and sweeperConfig:SweepSizeY() or sweeperConfig:SweepSizeX()
        local sweepSizeY = self:IsXYExchange() and sweeperConfig:SweepSizeX() or sweeperConfig:SweepSizeY()
        self.selector:InitPreview(self.city, self.curX, self.curY, self.sizeX, self.sizeY, sweepSizeX, sweepSizeY, lvCellId)
    end
end

function CityStatePlaceRoomFurniture:GetRecommendCoord(sizeX, sizeY)
    local pos = self.city:GetCamera():GetLookAtPosition()
    local x, y = self:GetXYFromCenterPoint(pos, sizeX, sizeY)
    local rx, ry = self.city.emptyGraph:GetRectSpaceEnoughPos(self.minX, self.minY, self.maxX, self.maxY, sizeX, sizeY, x, y)
    if rx then
        return rx, ry
    end
    if self:SquareCheckInRect(x, y, sizeX, sizeY) then
        return x, y
    end
    return self:FixCoordInRect(x, y, sizeX, sizeY)
end

---@param center CS.UnityEngine.Vector3
function CityStatePlaceRoomFurniture:GetXYFromCenterPoint(center, sizeX, sizeY)
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

function CityStatePlaceRoomFurniture:GetScale()
    local scale = ArtResourceUtils.GetItem(self.lvCell:Model(), 'ModelScale') or 1
    return scale <= 0 and 1 or scale
end

function CityStatePlaceRoomFurniture:GetPrefabName()
    return ArtResourceUtils.GetItem(self.lvCell:Model())
end

function CityStatePlaceRoomFurniture:GetSelectorPrefabName()
    if self:IsSweeperFurniture() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.city_map_creep_sweeper_selector)
    else
        return ArtResourceUtils.GetItem(ArtResourceConsts.city_map_building_selector)
    end
end

function CityStatePlaceRoomFurniture:GetSelectorBehaviourName()
    if self:IsSweeperFurniture() then
        return "CityCreepSweeperFurnitureSelector"
    else
        return "CityBuildingSelector"
    end
end

function CityStatePlaceRoomFurniture:IsSweeperFurniture()
    return ModuleRefer.CityCreepModule:GetSweeperConfigByFurnitureLevelId(self.lvCell:Id())
end

function CityStatePlaceRoomFurniture:OnModelLoadedPositionAndRotation()
    if Utils.IsNotNull(self.trans) then
        self.trans:SetPositionAndRotation(self.city:GetCenterWorldPositionFromCoord(self.curX, self.curY, self.sizeX, self.sizeY), CityConst.Quaternion[self.direction])
    end
end

---@param gesture CS.DragonReborn.DragGesture
function CityStatePlaceRoomFurniture:OnDragStart(gesture)
    if Utils.IsNull(self.trans) then
        return
    end

    self.screenPos = gesture.position
    local point = self.city:GetCamera():GetHitPoint(gesture.lastPosition)
    local x, y = self.city:GetCoordFromPosition(point)
    self.movingBuilding = self:IsPointAtModel(x, y)
    if self.movingBuilding then
        self.lastX, self.lastY = x, y
        self:BlockCamera()
    else
        self:RecoverCamera()
    end
    self:HideCityCircleMenu()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStatePlaceRoomFurniture:OnDragUpdate(gesture)
    self.screenPos = gesture.position
    if self.movingBuilding then
        self:OnDragTileForMoving(self.screenPos)
    end
    self:HideCityCircleMenu()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStatePlaceRoomFurniture:OnDragEnd(gestrue)
    if Utils.IsNull(self.trans) then
        return
    end
    self.screenPos = nil

    if self.movingBuilding then
        self:RecoverCamera()
        self.movingBuilding = false
    end

    self:ShowCityCircleMenu()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
end

function CityStatePlaceRoomFurniture:OnDragTileForMoving(screenPos)
    if Utils.IsNull(self.trans) then
        return
    end

    local point = self.city:GetCamera():GetHitPoint(screenPos)
    local x, y = self.city:GetCoordFromPosition(point)
    if x ~= self.lastX or y ~= self.lastY then
        local offsetX, offsetY = x - self.lastX, y - self.lastY
        if not self:SquareCheckInRect(self.curX + offsetX, self.curY + offsetY, self.sizeX, self.sizeY) then
            local fixX, fixY = self:FixCoordInRect(self.curX + offsetX, self.curY + offsetY, self.sizeX, self.sizeY)
            if fixX == self.curX and fixY == self.curY then
                return
            else
                offsetX = fixX - self.curX
                offsetY = fixY - self.curY
            end
        end
        self.lastX, self.lastY = x, y
        self.curX, self.curY = self.curX + offsetX, self.curY + offsetY
        self:UpdatePosition()
    end
end

function CityStatePlaceRoomFurniture:IsPointAtModel(x, y)
    return x >= self.curX and x < self.curX + self.sizeX and y >= self.curY and y < self.curY + self.sizeY
end

function CityStatePlaceRoomFurniture:UpdatePosition()
    if Utils.IsNotNull(self.trans) then
        self.trans.position = self.city:GetCenterWorldPositionFromCoord(self.curX, self.curY, self.sizeX, self.sizeY)
    end

    if self.selector then
        local furnitureType = ModuleRefer.CityConstructionModule:GetFurnitureTypeById(self.lvCell:Id())
        local furnitureCategory = ModuleRefer.CityConstructionModule:GetFurnitureCategory(self.lvCell:Id())
        self.selector:UpdateFurniturePosition(self.curX, self.curY, furnitureType, furnitureCategory)
    end
end

function CityStatePlaceRoomFurniture:GetCircleMenuUIParameter()
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        self:SquareCheckInRect(self.curX, self.curY, self.sizeX, self.sizeY) and self:IsAllTileValid(),
        Delegate.GetOrCreate(self, self.OnConfirmToBuild)
    )

    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.CancelPutting)
    )

    local rotate = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconStrength,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.Rotate)
    )
    return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), self.data:GetName(), {confirm, cancel, rotate})
end

function CityStatePlaceRoomFurniture:IsAllTileValid()
    local furnitureType = ModuleRefer.CityConstructionModule:GetFurnitureTypeById(self.lvCell:Id())
    local node = CityFurniture.new(self.city.furnitureManager, self.lvCell:Id(), 0, self.direction)
    return self.city.furnitureManager:CanPlaceFurniture(self.curX, self.curY, node, furnitureType)
end

function CityStatePlaceRoomFurniture:OnConfirmToBuild()
    local msg = CastleAddFurnitureParameter.new()
    msg.args.ConfigId = self.lvCell:Id()
    msg.args.X = self.curX
    msg.args.Y = self.curY
    msg.args.Dir = self.direction
    local mainCell = ModuleRefer.CityModule.myCity:GetBuilding(self.curX, self.curY)
    msg.args.BuildingId = mainCell and mainCell.tileId or 0
    msg:SendWithFullScreenLock()
end

function CityStatePlaceRoomFurniture:CancelPutting()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_EXIT_ROOM_SUBPAGE)
end

function CityStatePlaceRoomFurniture:WorldCenterPos()
    return self.city:GetWorldPositionFromCoord((2 * self.curX + self.sizeX - 1) / 2, (2 * self.curY + self.sizeY - 1) / 2)
end

function CityStatePlaceRoomFurniture:TryTurnToNextStage()
    local length = self.data.cfg:RecommendFurnituresLength()
    if self.idx >= length then
        self:CancelPutting()
    else
        self:TurnToNextStage()
    end
end

function CityStatePlaceRoomFurniture:TurnToNextStage()
    self.stateMachine:WriteBlackboard("minX", self.minX, true)
    self.stateMachine:WriteBlackboard("minY", self.minY, true)
    self.stateMachine:WriteBlackboard("maxX", self.maxX, true)
    self.stateMachine:WriteBlackboard("maxY", self.maxY, true)
    self.stateMachine:WriteBlackboard("data", self.data, true)
    self.stateMachine:WriteBlackboard("cellTile", self.cellTile, true)
    self.stateMachine:WriteBlackboard("idx", self.idx + 1)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_ROOM_MOVE_STEP)
    self.stateMachine:ChangeState(CityConst.STATE_PLACE_ROOM_FURNITURE)
end

return CityStatePlaceRoomFurniture