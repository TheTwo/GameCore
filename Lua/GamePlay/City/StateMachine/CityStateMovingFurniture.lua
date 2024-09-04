local CityState = require("CityState")
---@class CityStateMovingFurniture:CityState
local CityStateMovingFurniture = class("CityStateMovingFurniture", CityState)
local Delegate = require("Delegate")
local CastleMoveFurnitureParameter = require("CastleMoveFurnitureParameter")
local CastleDelFurnitureParameter = require("CastleDelFurnitureParameter")
local ModuleRefer = require('ModuleRefer')
local EventConst = require("EventConst")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CityUtils = require("CityUtils")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CityStateTileHandle = require("CityStateTileHandle")
local CityStateTileHandleFurnitureTileData = require("CityStateTileHandleFurnitureTileData")
local CityConstructionModeUIMediator = require("CityConstructionModeUIMediator")
local CityStateI18N = require("CityStateI18N")
local I18N = require("I18N")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local FurnitureBuildingIdMonitor = require("FurnitureBuildingIdMonitor")

---@param city City
function CityStateMovingFurniture:ctor(city)
    CityState.ctor(self, city)
    self.tileHandle = CityStateTileHandle.new(self)
end

function CityStateMovingFurniture:Enter()
    CityState.Enter(self)
    g_Game.ServiceManager:AddResponseCallback(CastleMoveFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuildingMove))
    g_Game.ServiceManager:AddResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureStore))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_CIRCLE_MENU_CLOSED, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:AddListener(EventConst.CITY_SELECTER_LEAVE_BUILDING, Delegate.GetOrCreate(self, self.OnLeaveBuilding))
    g_Game.EventManager:AddListener(EventConst.CITY_SELECTER_ENTER_BUILDING, Delegate.GetOrCreate(self, self.OnEnterBuilding))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_PREVIEW_POS, Delegate.GetOrCreate(self, self.OnUISyncDragPos))
    g_Game.EventManager:AddListener(EventConst.CITY_MOVING_UITILE_DRAG_RELEASE, Delegate.GetOrCreate(self, self.OnUIDragRelease))
    
    ---@type CityFurnitureTile
    self.furnitureTile = self.stateMachine:ReadBlackboard("MovingFurnitureCell")
    self.forceDragging = self.stateMachine:ReadBlackboard("DragImmediate")
    self.screenPos = self.stateMachine:ReadBlackboard("screenPos")
    self.tileHandleDataWrap = CityStateTileHandleFurnitureTileData.new(self.furnitureTile)
    if self.screenPos then
        local x, y = self:GetCoordFromScreenPos(self.screenPos, self.furnitureTile:SizeX(), self.furnitureTile:SizeY())
        self.tileHandleDataWrap:UpdatePosition(x, y)
    end

    self.tileHandle:Initialize(self.tileHandleDataWrap)
    self.tileMonitor = FurnitureBuildingIdMonitor.new(self.city, self.tileHandle, self.furnitureTile:SizeX(), self.furnitureTile:SizeY())
    self.tileMonitor:Initialize()
    self.tileAtBuildingIdMap = self.tileMonitor:GetCurrentBuildingIdMap()
    if self.city:IsEditMode() then
        self.city:ShowMapGridView()
    end
    self.furnitureTile:OnMoveBegin()
    self.rotRoot = self.furnitureTile:GetRotRoot()
    if Utils.IsNotNull(self.rotRoot) then
        self.city.flashMatController:StartFlash(self.rotRoot)
    end
    self:SwitchTransparentOutline(true)
    self.city.camera.enablePinch = false

    local buildingId = self.furnitureTile:GetCastleFurniture().BuildingId
    if buildingId > 0 and not self.tileAtBuildingIdMap[buildingId] then
        local furniture = self.furnitureTile:GetCell()
        local furnitureId = furniture.singleId
        g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_MOVING_PREVIEW_BUFF_CHANGE, buildingId, furnitureId)
        local lvCfgId = furniture.configId
        g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_PREVIEW_NEW, lvCfgId)
        self.exitShouldHideBubble = true
    end

    if self.screenPos then
        self:OnDragStart({position = self.screenPos})
    end

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE)
end

function CityStateMovingFurniture:Exit()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_CONTINUE_PLACE)
    if self.exitShouldHideBubble then
        self.exitShouldHideBubble = nil
    end
    g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_MOVING_PREVIEW_END)
    g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH)

    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_EXIT_EDIT_MODE, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CIRCLE_MENU_CLOSED, Delegate.GetOrCreate(self, self.ExitToIdleState))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SELECTER_LEAVE_BUILDING, Delegate.GetOrCreate(self, self.OnLeaveBuilding))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SELECTER_ENTER_BUILDING, Delegate.GetOrCreate(self, self.OnEnterBuilding))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_PREVIEW_POS, Delegate.GetOrCreate(self, self.OnUISyncDragPos))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MOVING_UITILE_DRAG_RELEASE, Delegate.GetOrCreate(self, self.OnUIDragRelease))

    g_Game.ServiceManager:RemoveResponseCallback(CastleMoveFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuildingMove))
    g_Game.ServiceManager:RemoveResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureStore))
    
    if Utils.IsNotNull(self.rotRoot) then
        self.city.flashMatController:StopFlash(self.rotRoot)
    end
    self:SwitchTransparentOutline(false)
    self.furnitureTile:OnMoveEnd()
    self.tileHandle:Release()
    self.tileHandleDataWrap = nil
    self.tileMonitor:Release()
    self.tileMonitor = nil
    self.tileAtBuildingIdMap = nil
    self:CancelMoving()
    if self.city:IsEditMode() then
        self.city:HideMapGridView()
    end
    self.furnitureTile = nil
    if self.city.camera then
        self.city.camera.enablePinch = true
    end
    self.forceDragging = nil
    self:HideSafeAreaHint()
    CityState.Exit(self)
end

function CityStateMovingFurniture:ReEnter()
    self:Exit()
    self:Enter()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingFurniture:OnDragStart(gesture)
    self.tileHandle:OnDragStart(gesture, self.forceDragging)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingFurniture:OnDragUpdate(gesture)
    self.tileHandle:OnDragUpdate(gesture)
    self:ShowSafeAreaHintIfNeed()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateMovingFurniture:OnDragEnd(gesture)
    self.tileHandle:OnDragEnd(gesture)
    self:ShowSafeAreaHintIfNeed()
    self.forceDragging = false
end

function CityStateMovingFurniture:OnCameraSizeChanged(oldValue, newValue)
    self:TryChangeToAirView(oldValue, newValue)
end

function CityStateMovingFurniture:TryMove()
    local furniture = self.furnitureTile:GetCell()
    local furnitureType = ModuleRefer.CityConstructionModule:GetFurnitureTypeById(furniture.configId)
    local copy = furniture:Clone()
    copy.x = self.tileHandleDataWrap.x
    copy.y = self.tileHandleDataWrap.y
    copy.sizeX = self.tileHandleDataWrap.sizeX
    copy.sizeY = self.tileHandleDataWrap.sizeY
    copy.direction = self.tileHandleDataWrap.direction
    local canBuild = self.city.furnitureManager:CanPlaceFurniture(copy.x, copy.y, copy, furnitureType, true)
    if canBuild and self.tileHandle:SquareCheck() then
        if self.tileHandle:NotChanged() then
            self:CancelMoving()
            self:ExitToIdleState()
        else
            self:TryRequestMove()
        end
    end
end

function CityStateMovingFurniture:Rotate()
    self.tileHandle:Rotate()
end

function CityStateMovingFurniture:CancelMoving()
    if self.furnitureTile and self.furnitureTile.x and self.furnitureTile.y then
        local furniture = self.furnitureTile:GetCell()
        self.furnitureTile:SetPositionCenterAndRotation(self.city:GetWorldPositionFromCoord(furniture.x, furniture.y), self.city:GetCenterWorldPositionFromCoord(furniture.x, furniture.y, furniture.sizeX, furniture.sizeY), CS.UnityEngine.Quaternion.Euler(0, furniture.direction, 0))
        self.city.furnitureManager:PlayPutDownVfx(furniture)
    end
end

function CityStateMovingFurniture:TryRequestMove()
    local castleFurniture = self.furnitureTile:GetCastleFurniture()
    if castleFurniture.BuildingId > 0 then
        local legoBuilding = self.city.legoManager:GetLegoBuildingAt(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y)
        local newBuildingId = legoBuilding and legoBuilding.id or 0
        if newBuildingId ~= castleFurniture.BuildingId then
            local oldLegoBuilding = self.city.legoManager:GetLegoBuilding(castleFurniture.BuildingId)
            local flag, willExpireBuffCfgs = oldLegoBuilding:IsBuffExpireDueToFurnitureRemove(self.furnitureTile:GetCell().singleId)
            if flag then
                ---@type CommonConfirmPopupMediatorParameter
                local param = {}
                param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
                param.title = I18N.Get(CityStateI18N.UIHint_FurnitureMovingExpireBuffTitle)
                param.content = I18N.GetWithParams("toast_move_room_tip", self.furnitureTile:GetName())
                param.onConfirm = function()
                    self:RequestMove()
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
                return
            end
        end
    end
    self:RequestMove()
end

function CityStateMovingFurniture:RequestMove()
    local msg = CastleMoveFurnitureParameter.new()
    local cell = self.furnitureTile:GetCell()
    msg.args.Id = cell.singleId
    msg.args.X = self.tileHandleDataWrap.x
    msg.args.Y = self.tileHandleDataWrap.y
    msg.args.Dir = self.tileHandleDataWrap.direction
    local legoBuilding = self.city.legoManager:GetLegoBuildingAt(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y)
    msg.args.BuildingId = legoBuilding and legoBuilding.id or 0
    msg:SendWithFullScreenLock()
end

function CityStateMovingFurniture:TryStorage()
    local castleFurniture = self.furnitureTile:GetCastleFurniture()
    if castleFurniture.BuildingId > 0 then
        local oldLegoBuilding = self.city.legoManager:GetLegoBuilding(castleFurniture.BuildingId)
        local flag, willExpireBuffCfgs = oldLegoBuilding:IsBuffExpireDueToFurnitureRemove(self.furnitureTile:GetCell().singleId)
        if flag then
            ---@type CommonConfirmPopupMediatorParameter
            local param = {}
            param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            param.title = I18N.Get(CityStateI18N.UIHint_FurnitureMovingExpireBuffTitle)
            param.content = I18N.GetWithParams("toast_takeback_room_tip", self.furnitureTile:GetName())
            param.onConfirm = function()
                self:RequestStorage()
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
            return
        end
    end
    self:RequestStorage()
end

function CityStateMovingFurniture:RequestStorage()
    self.city:StorageFurniture(self.furnitureTile:GetCell())
end

function CityStateMovingFurniture:FailedStorage()
    local toast = self.furnitureTile:CantStorageReason()
    if not string.IsNullOrEmpty(toast) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(toast))
    end
end

function CityStateMovingFurniture:OnBuildingMove(isSuccess, rsp)
    if isSuccess then
        self:ExitToIdleState()
    end
end

function CityStateMovingFurniture:OnFurnitureStore(isSuccess, rsp)
    if isSuccess then
        self:ExitToIdleState()
    end
end

function CityStateMovingFurniture:WorldCenterPos()
    return self.city:GetWorldPositionFromCoord((2 * self.tileHandleDataWrap.x + self.tileHandleDataWrap.sizeX - 1) / 2, (2 * self.tileHandleDataWrap.y + self.tileHandleDataWrap.sizeY - 1) / 2)
end

function CityStateMovingFurniture:GetCircleMenuUIParameter()
    local furniture = self.furnitureTile:GetCell():Clone():SetDirection(self.tileHandleDataWrap.direction)
    local furnitureType = ModuleRefer.CityConstructionModule:GetFurnitureTypeById(furniture.configId)
    local canBuild = self.city.furnitureManager:CanPlaceFurniture(self.tileHandleDataWrap.x, self.tileHandleDataWrap.y, furniture, furnitureType, true)
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        canBuild and self.tileHandle:SquareCheck(),
        Delegate.GetOrCreate(self, self.TryMove)
    )
    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackSec,
        true,
        Delegate.GetOrCreate(self, self.ExitToIdleState)
    )

    local rotate = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconRotate,
        CircleMenuButtonConfig.ButtonBacks.BackNormal,
        true,
        Delegate.GetOrCreate(self, self.Rotate)
    )
    
    local functionSwitch = ConfigRefer.CityConfig:StorageSystemSwitch()
    local packDisabled = not ModuleRefer.CityModule:CanDoBuild() or (functionSwitch > 0 and not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(functionSwitch))
    local furnitureConfig = ConfigRefer.CityFurnitureLevel:Find(furniture.configId)
    if not packDisabled and furnitureConfig then
        local fType = furnitureConfig:Type()
        local typeConfig = ConfigRefer.CityFurnitureTypes:Find(fType)
        packDisabled = typeConfig and typeConfig:PackDisabled()
        -- if not packDisabled then
        --     packDisabled = self.city.furnitureManager:IsSpecialFurnitureWorkingNotMovable(gridCell:UniqueId(), fType)
        -- end
    end

    if packDisabled then
        return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), self.furnitureTile:GetName(), {confirm, cancel, rotate})
    else
        local store = CityUtils.CircleMenuSimpleButtonData(
                CircleMenuButtonConfig.ButtonIcons.IconStorage,
                CircleMenuButtonConfig.ButtonBacks.BackGray,
                self.furnitureTile:CanStorage(),
                Delegate.GetOrCreate(self, self.TryStorage),
                Delegate.GetOrCreate(self, self.FailedStorage)
        )
        return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), self.furnitureTile:GetName(), {confirm, cancel, rotate, store})
    end
end

function CityStateMovingFurniture:ShowSafeAreaHintIfNeed()
    for x = self.tileHandle.curX, self.tileHandle.curX + self.tileHandle.dataSource.sizeX - 1 do
        for y = self.tileHandle.curY, self.tileHandle.curY + self.tileHandle.dataSource.sizeY - 1 do
            if not self.city.safeAreaWallMgr:IsValidSafeArea(x, y) and not self.city:IsInnerBuildingMask(x, y) then
                return g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW_HINT, CityConstructionModeUIMediator.TIPS_ALERT, I18N.Get("city_city_set_room_tips_7"))
            end
        end
    end
    self:HideSafeAreaHint()
end

function CityStateMovingFurniture:HideSafeAreaHint()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE_HINT)
end

function CityStateMovingFurniture:SwitchTransparentOutline(flag)
    if Utils.IsNotNull(self.city.flashMatController) and self.city.camera and Utils.IsNotNull(self.city.camera.mainCamera) then
        self.city.flashMatController:SwitchTransparentOutline(flag, self.city.camera.mainCamera)
    end
end

function CityStateMovingFurniture:OnLeaveBuilding(city, buildingId)
    if self.city ~= city then return end
    if self.tileAtBuildingIdMap == nil then return end
    
    if self.tileAtBuildingIdMap[buildingId] then
        self.tileAtBuildingIdMap[buildingId] = nil
        
        local castleFurniture = self.furnitureTile:GetCastleFurniture()
        if castleFurniture and castleFurniture.BuildingId == buildingId then
            --- 离开了当前家具所在的建筑，通知显示Buff丢失的气泡
            local furnitureId = self.furnitureTile:GetCell().singleId
            g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_MOVING_PREVIEW_BUFF_CHANGE, buildingId, furnitureId)
            --- 同时也意味着这个家具可能被挪入任何一个家具中，所以通知显示所有家具可能产生新Buff的气泡
            local lvCfgId = self.furnitureTile:GetCell().configId
            g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_PREVIEW_NEW, lvCfgId)
            self.exitShouldHideBubble = true
        end
    end
end

function CityStateMovingFurniture:OnEnterBuilding(city, buildingId)
    if self.city ~= city then return end
    if self.tileAtBuildingIdMap == nil then return end

    if not self.tileAtBuildingIdMap[buildingId] then
        self.tileAtBuildingIdMap[buildingId] = true

        local castleFurniture = self.furnitureTile:GetCastleFurniture()
        if castleFurniture and castleFurniture.BuildingId == buildingId then
            --- 如果移回来了那么这个气泡就不用显示了
            g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_MOVING_PREVIEW_END)
            --- 其他家具也不需要再显示可能产生新Buff的气泡了
            g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH)
            self.exitShouldHideBubble = false
        end
    end
end


function CityStateMovingFurniture:GetCoordFromScreenPos(screenPos, sizeX, sizeY)
    local worldPos = self.city:GetCamera():GetHitPoint(screenPos)
    local x, y = self:GetXYFromCenterPoint(worldPos, sizeX, sizeY)
    if self.city:IsSquareValidForFurniture(x, y, sizeX, sizeY) then
        return x, y
    else
        return self.city:GetFixCoord(x, y, sizeX, sizeY)
    end
end

function CityStateMovingFurniture:GetXYFromCenterPoint(center, sizeX, sizeY)
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

function CityStateMovingFurniture:OnUISyncDragPos(screenPos)
    if self.screenPos == nil then
        self:OnDragStart({position = screenPos})
    else
        self:OnDragUpdate({position = screenPos})
    end
end

function CityStateMovingFurniture:OnUIDragRelease()
    self:OnDragEnd({position = self.screenPos})
end

return CityStateMovingFurniture