local CityState = require("CityState")
local Utils = require("Utils")
---@class CityStateUpgradeBuildingPreview:CityState
---@field new fun():CityStateUpgradeBuildingPreview
---@field cellTile CityCellTile
---@field workerData CityCitizenData
local CityStateUpgradeBuildingPreview = class("CityStateUpgradeBuildingPreview", CityState)
local CircleMemuUIParam = require("CityCircleMenuUIMediator").UIParameter
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local CityUtils = require("CityUtils")
local CastleBuildingUpgradeParameter = require("CastleBuildingUpgradeParameter")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local ArtResourceUtils = require("ArtResourceUtils")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityConst = require("CityConst")
local Ease = CS.DG.Tweening.Ease

function CityStateUpgradeBuildingPreview:Enter()
    CityState.Enter(self)
    self.cellTile = self.stateMachine:ReadBlackboard("cellTile")
    self.furnitureTiles = self.stateMachine:ReadBlackboard("RelativeFurniture")
    self.workerData = self.stateMachine:ReadBlackboard("workerData")
    self.city.gridView:ForceHide(self.cellTile)
    self.city:ShowMapGridView()
    self.city:GetCamera():ZoomToMaxSize(0.5)
    self.city:GetCamera().enablePinch = false
    self:HideRelativeFurnitures()
    self:InitState()
    self:ShowCityCircleMenu()
    self:ChangeAndCacheHudRootAlpha(0.0, false)
    self:ShowToast()

    g_Game.ServiceManager:AddResponseCallback(CastleBuildingUpgradeParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnUpgradeCallback))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
end

function CityStateUpgradeBuildingPreview:Exit()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingUpgradeParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnUpgradeCallback))

    self:RecoverHudRootAlphaFromCache(false)
    self:RecoverCamera()
    self.city:HideMapGridView()
    self.city.gridView:CancelForceHide(self.cellTile)
    self.city:GetCamera().enablePinch = true
    self:ShowRelativeFurnitures()
    self:HideCityCircleMenu()
    self:ReleaseNodeAndRes()
    self.cellTile = nil
    self.workerData = nil
    CityState.Exit(self)
end

function CityStateUpgradeBuildingPreview:IgnoreInvervalTick()
    if self.screenPos and not self:TileInScreen(self.screenPos) then
        self:AdjustTileToInScreen(self.screenPos)
        self:OnDragUpdate({position = self.screenPos})
    end
end

function CityStateUpgradeBuildingPreview:InitState()
    self.curX, self.curY = self.cellTile.x, self.cellTile.y
    self.lastX, self.lastY = self.curX, self.curY

    local gridCell = self.cellTile:GetCell()
    local lvCell = ConfigRefer.BuildingLevel:Find(gridCell.configId)
    local nextLvCell = ConfigRefer.BuildingLevel:Find(lvCell:NextLevel())
    self.sizeX, self.sizeY = nextLvCell:SizeX(), nextLvCell:SizeY()
    self.prefabName = ArtResourceUtils.GetItem(nextLvCell:ModelArtRes())
    self.handler = self.city.createHelper:Create(self.prefabName, self.city:GetRoot().transform, Delegate.GetOrCreate(self, self.OnPreviewModelLoaded), nil, 0, false)
    self.selectorHandler = self.city.createHelper:Create(self.cellTile:GetSelectorPrefabName(), self.city:GetRoot().transform, Delegate.GetOrCreate(self, self.OnSelectorLoaded), nil, 0, false)
end

function CityStateUpgradeBuildingPreview:HideRelativeFurnitures()
    for i, v in ipairs(self.furnitureTiles) do
        self.city.gridView:ForceHide(v)
    end
end

function CityStateUpgradeBuildingPreview:ShowRelativeFurnitures()
    for i, v in ipairs(self.furnitureTiles) do
        self.city.gridView:CancelForceHide(v)
    end
end

---@param go CS.UnityEngine.GameObject
function CityStateUpgradeBuildingPreview:OnPreviewModelLoaded(go, userdata)
    if Utils.IsNull(go) then
        g_Logger.ErrorChannel("City", ("Load %s failed"):format(self.prefabName))
        return
    end
    go:SetLayerRecursively("City")
    local trans = go.transform
    trans.localScale = CS.UnityEngine.Vector3.one
    self.trans = trans
    self:UpdatePosition(true)
    self.lastX, self.lastY = self.curX, self.curY
    self.city.flashMatController:StartFlash(go)
end

---@param go CS.UnityEngine.GameObject
function CityStateUpgradeBuildingPreview:OnSelectorLoaded(go, userdata)
    if go == nil then
        g_Logger.Error("Load city_map_building_selector failed!")
        return
    end

    local cell = self.cellTile:GetCell()
    ---@type CityBuildingSelector
    self.selector = go:GetLuaBehaviour(self.cellTile:GetSelectorBehaviourName()).Instance
    self.selector:Init(self.city, self.curX, self.curY, self.sizeX, self.sizeY, cell, true)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateUpgradeBuildingPreview:OnDragStart(gesture)
    local point = self.city:GetCamera():GetHitPoint(gesture.lastPosition)
    local x, y = self.city:GetCoordFromPosition(point)
    self.screenPos = gesture.position

    if self:IsDragEmpty(x, y) then
        self.dragPlane = true;
        self:ChangeAndCacheCameraSmoothing(0)
        self:AnchorLookAtPosition()
        self:RecoverCamera()
    else
        self:AnchorGesturePoint(gesture)
        self:BlockCamera()
    end
    self:HideCityCircleMenu()
end

---@return boolean
function CityStateUpgradeBuildingPreview:IsDragEmpty(x, y)
    return not (x >= self.curX and x < self.curX + self.sizeX and y >= self.curY and y < self.curY + self.sizeY)
end

function CityStateUpgradeBuildingPreview:AnchorLookAtPosition()
    local point = self.city:GetCamera():GetLookAtPosition()
    self.lastX, self.lastY = self.city:GetCoordFromPosition(point)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateUpgradeBuildingPreview:AnchorGesturePoint(gesture)
    local screenPos = gesture.position
    local point = self.city:GetCamera():GetHitPoint(screenPos)
    self.lastX, self.lastY = self.city:GetCoordFromPosition(point)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateUpgradeBuildingPreview:OnDragUpdate(gesture)
    self.screenPos = gesture.position
    if self.dragPlane then
        -- self:OnDragPlaneForMoving(gesture)
    else
        self:OnDragTileForMoving(gesture)
    end
    self:HideCityCircleMenu()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateUpgradeBuildingPreview:OnDragPlaneForMoving(gesture)
    local point = self.city:GetCamera():GetLookAtPosition()
    local x, y = self.city:GetCoordFromPosition(point)
    if x ~= self.lastX or y ~= self.lastY then
        local offsetX, offsetY = x - self.lastX, y - self.lastY
        if not self.city:IsSquareValidForBuilding(self.curX + offsetX, self.curY + offsetY, self.sizeX, self.sizeY) then
            local fixX, fixY = self.city:GetFixCoord(self.curX + offsetX, self.curY + offsetY, self.sizeX, self.sizeY)
            if fixX == self.curX and fixY == self.curY then
                return
            else
                offsetX = fixX - self.curX
                offsetY = fixY - self.curY
                x = offsetX + self.lastX
                y = offsetY + self.lastY
            end
        end

        self.lastX, self.lastY = x, y
        self.curX, self.curY = self.curX + offsetX, self.curY + offsetY
        self:UpdatePosition()
    end
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateUpgradeBuildingPreview:OnDragTileForMoving(gesture)
    local point = self.city:GetCamera():GetHitPoint(gesture.position)
    local x, y = self.city:GetCoordFromPosition(point)
    if x ~= self.lastX or y ~= self.lastY then
        local offsetX, offsetY = x - self.lastX, y - self.lastY
        if not self.city:IsSquareValidForBuilding(self.curX + offsetX, self.curY + offsetY, self.sizeX, self.sizeY) then
            local fixX, fixY = self.city:GetFixCoord(self.curX + offsetX, self.curY + offsetY, self.sizeX, self.sizeY)
            if fixX == self.curX and fixY == self.curY then
                return
            else
                offsetX = fixX - self.curX
                offsetY = fixY - self.curY
                x = offsetX + self.lastX
                y = offsetY + self.lastY
            end
        end

        self.lastX, self.lastY = x, y
        self.curX, self.curY = self.curX + offsetX, self.curY + offsetY
        self:UpdatePosition()
    end
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateUpgradeBuildingPreview:OnDragEnd(gesture)
    if self.dragPlane then
        self:BlockCamera()
        self:RecoverCameraSmoothingFromCache()
        self.dragPlane = false
    else
        self:RecoverCamera();
    end
    self:ShowCityCircleMenu()
end

function CityStateUpgradeBuildingPreview:UpdatePosition(easeYAxis)
    if self.trans then
        if easeYAxis then
            self.trans.position = self.city:GetCenterWorldPositionFromCoord(self.curX, self.curY, self.sizeX, self.sizeY)
            local originScale = self.trans.localScale
            self.trans:DOScale(originScale * 0.8, 0.1):SetEase(Ease.OutQuad):OnComplete(function()
                self.trans:DOBlendableMoveBy(CityConst.RiseOffset, 0.15, false):SetEase(Ease.OutQuad)
                self.trans:DOScale(originScale, 0.1):SetEase(Ease.InQuad)
            end)
        else
            self.trans.position = self.city:GetCenterWorldPositionFromCoord(self.curX, self.curY, self.sizeX, self.sizeY) + CityConst.RiseOffset
        end
    end

    if self.selector then
        self.selector:UpdatePosition(self.curX, self.curY)
    end
end

function CityStateUpgradeBuildingPreview:IsAllSpaceBesidesSelf()
    local ret = true
    local gridCell = self.cellTile:GetCell()
    for x = self.curX, self.curX + self.sizeX - 1 do
        for y = self.curY, self.curY + self.sizeY - 1 do
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

function CityStateUpgradeBuildingPreview:WorldCenterPos()
    return self.city:GetWorldPositionFromCoord((2 * self.curX + self.sizeX - 1) / 2, (2 * self.curY + self.sizeY - 1) / 2)
end

function CityStateUpgradeBuildingPreview:GetCircleMenuUIParameter()
    local confirm = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconTick,
        CircleMenuButtonConfig.ButtonBacks.BackConfirm,
        self.city:IsSquareValidForBuilding(self.curX, self.curY, self.sizeX, self.sizeY) and self:IsAllSpaceBesidesSelf(),
        Delegate.GetOrCreate(self, self.Confirm)
    )
    local cancel = CityUtils.CircleMenuSimpleButtonData(
        CircleMenuButtonConfig.ButtonIcons.IconCancel,
        CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        true,
        Delegate.GetOrCreate(self, self.Cancel)
    )
    return CircleMemuUIParam.new(self.city:GetCamera(), self:WorldCenterPos(), self.cellTile:GetBuildingName(), {confirm, cancel})
end

function CityStateUpgradeBuildingPreview:Confirm()
    self.city:UpgradeBuilding(self.cellTile:GetCell().tileId, self.curX, self.curY, self.workerData)
end

function CityStateUpgradeBuildingPreview:Cancel()
    self:RecoverCamera()
    g_Game.UIManager:Open(UIMediatorNames.CityBuildUpgradeUIMediator, {cellTile = self.cellTile, workerData = self.workerData}, Delegate.GetOrCreate(self, self.ExitToIdleState))
end

local horizontal = 0.08
local vertical = 0.12
local intencity = 3

---@param screenPos CS.UnityEngine.Vector3
function CityStateUpgradeBuildingPreview:AdjustTileToInScreen(screenPos)
    local x, y = screenPos.x, screenPos.y
    local camera = self.city:GetCamera()
    local width, height = camera:ScreenWidth(), camera:ScreenHeight()
    local offset = CS.UnityEngine.Vector3.zero
    if x < width * horizontal then
        offset = offset - camera.right
    elseif x > width * (1- horizontal) then
        offset = offset + camera.right
    end

    if y < height * vertical then
        offset = offset - camera.up
    elseif y > height * (1 - vertical) then
        offset = offset + camera.up
    end

    camera:MoveCameraOffset(offset * intencity * g_Game.RealTime.deltaTime)
end

function CityStateUpgradeBuildingPreview:TileInScreen(screenPos)
    local x, y = screenPos.x, screenPos.y
    local camera = self.city:GetCamera()
    local width, height = camera:ScreenWidth(), camera:ScreenHeight()
    local ep1, ep2
    if x < width * horizontal then
        ep1 = self.city:GetWorldPositionFromCoord(self.curX, self.curY + self.sizeY)
    elseif x > width * (1- horizontal) then
        ep1 = self.city:GetWorldPositionFromCoord(self.curX + self.sizeX, self.curY)
    end

    if y < height * vertical then
        ep2 = self.city:GetWorldPositionFromCoord(self.curX, self.curY)
    elseif y > height * (1 - vertical) then
        ep2 = self.city:GetWorldPositionFromCoord(self.curX + self.sizeX, self.curY + self.sizeY)
    end

    if ep1 then
        local viewPort = camera.mainCamera:WorldToScreenPoint(ep1)
        local vx, vy = viewPort.x, viewPort.y
        if vx < width * horizontal or vx > width * (1- horizontal) or vy < height * vertical or vy > height * (1 - vertical) then
            return false
        end
    end

    if ep2 then
        local viewPort = camera.mainCamera:WorldToScreenPoint(ep2)
        local vx, vy = viewPort.x, viewPort.y
        if vx < width * horizontal or vx > width * (1- horizontal) or vy < height * vertical or vy > height * (1 - vertical) then
            return false
        end
    end
    return true
end

function CityStateUpgradeBuildingPreview:ReleaseNodeAndRes()
    if self.trans then
        self.city.flashMatController:StopFlash(self.trans.gameObject)
    end

    if self.handler then
        self.city.createHelper:Delete(self.handler)
        self.handler = nil
    end
    if self.selectorHandler then
        self.city.createHelper:Delete(self.selectorHandler)
        self.selectorHandler = nil
    end
    self.prefabName = nil
    self.trans = nil
    self.selector = nil
end

function CityStateUpgradeBuildingPreview:ShowToast()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_set_room_tips_6"))
end

---@param isSuccess boolean
---@param rsp wrpc.CastleBuildingUpgradeReply
function CityStateUpgradeBuildingPreview:OnUpgradeCallback(isSuccess, rsp)
    if isSuccess then
        self:ExitToIdleState()
    end
end

return CityStateUpgradeBuildingPreview