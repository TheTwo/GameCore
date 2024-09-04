---@class CityStateTileHandle
---@field new fun():CityStateTileHandle
local CityStateTileHandle = class("CityStateTileHandle")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CloseCircleMenuUIParam = require("CityCircleMenuUIMediator").CloseUIParameter
local dontExitState = CloseCircleMenuUIParam.new(true)
local UIMediatorNames = require("UIMediatorNames")
local DragMoveCamera = {
    MinX = 0.06,
    MaxX = 0.94,
    MinY = 0.05,
    MaxY = 0.95,

    MaxSpeed = 20,
    MinSpeed = 5,
}

---@param state CityState
function CityStateTileHandle:ctor(state)
    self.cityState = state
    self.city = state.city
    self._dragCamTimer = 0
end

---@param dataSource CityStateTileHandleDataWrap
function CityStateTileHandle:Initialize(dataSource)
    if self.inited then return end

    self.dataSource = dataSource
    self.dataSource:OnHandleInitialize(self)
    self.selectorDataWrap = dataSource:GetSelectorDataWrap()
    self.inited = true

    self:BlockCamera()
    self:RecordOriginState()
    self:UpdatePosition(self.dataSource.x, self.dataSource.y, true, false)
    self:ShowCityCircleMenu()
    self:ForceShowTiles()
    self:CreateSelector()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATE_TILE_HANDLE_INITIALIZE, self)
end

function CityStateTileHandle:Release()
    if not self.inited then return end
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    self:HideCityCircleMenu(dontExitState)
    self:DeleteSelector()
    self:RecoverCamera()
    self:RecoverCameraSmoothingFromCache()
    self.alpha = 1
    self:RecoverHudRootAlphaFromCache(false)
    self:CancelForceShow()
    
    self.dataSource:OnHandleRelease(self)
    self.dataSource = nil
    self.selectorDataWrap = nil
    self.inited = nil
    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATE_TILE_HANDLE_RELEASE, self)
end

function CityStateTileHandle:RecordOriginState()
    self.curX, self.curY = self.dataSource.x, self.dataSource.y
    self.lastX, self.lastY = self.curX, self.curY
end

function CityStateTileHandle:UpdatePosition(x, y, easeYAxis, fireEvt)
    self.dataSource:UpdatePosition(x, y, easeYAxis)
    self.selectorDataWrap:UpdatePosition(x, y)
    if fireEvt then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_STATE_TILE_HANDLE_MOVING, self)
    end
end

function CityStateTileHandle:cornerPairs()
    self.cornerIdx = 0
    return Delegate.GetOrCreate(self, self.cornerPairsImp)
end

function CityStateTileHandle:cornerPairsImp()
    self.cornerIdx = self.cornerIdx + 1
    if self.cornerIdx == 1 then
        return 0, 0
    elseif self.cornerIdx == 2 then
        return self.dataSource.sizeX, 0
    elseif self.cornerIdx == 3 then
        return 0, self.dataSource.sizeY
    elseif self.cornerIdx == 4 then
        return self.dataSource.sizeX, self.dataSource.sizeY
    end
end

function CityStateTileHandle:IgnoreInvervalTick(delta)
    if not self.dragging then return end
    local camera = self.city:GetCamera()
    if self.dragPlane then
        local h, v = 0, 0
        self.lastX, self.lastY = self.curX, self.curY
        for dx, dy in self:cornerPairs() do
            local worldCenter = self.city:GetWorldPositionFromCoord(self.curX + dx, self.curY + dy)
            local screenPos = camera.mainCamera:WorldToScreenPoint(worldCenter)
            local dh = camera:ScreenHorizontalBoard(screenPos, DragMoveCamera)
            local dv = camera:ScreenVerticalBoard(screenPos, DragMoveCamera)
            h = math.abs(dh) > math.abs(h) and dh or h
            v = math.abs(dv) > math.abs(v) and dv or v
        end
        
        self.curX = self.curX + h + v
        self.curY = self.curY - h + v
        self:UpdatePosition(self.curX, self.curY, false, true)
    else
        if not self.screenPos then return end
        if camera:IsOnScreenBoard(self.screenPos, DragMoveCamera) then
            local offset = camera:GetScrollingOffset(self.screenPos)
            self._dragCamTimer = self._dragCamTimer + delta
            local moveSpeed = math.lerp(
                DragMoveCamera.MinSpeed,
                DragMoveCamera.MaxSpeed,
                math.clamp01( self._dragCamTimer / 2.0)
            )
            camera:MoveCameraOffset(offset * moveSpeed  * delta)
            self:OnDragUpdate({position = self.screenPos})
        else
            self._dragCamTimer = 0
        end
    end
end

function CityStateTileHandle:ForceShowTiles()
    self.dataSource:ForceShowTile()
end

function CityStateTileHandle:CancelForceShow()
    self.dataSource:CancelForceShowTile()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateTileHandle:OnDragStart(gesture, forceDragging)
    local point = self.city:GetCamera():GetHitPoint(gesture.lastPosition);
    local x, y = self.city:GetCoordFromPosition(point);
    self.screenPos = gesture.position
    self.dragging = true

    if not forceDragging and not self:DragModel(gesture.position) and self:IsDragEmpty(x, y) then
        self.dragPlane = true
        self:ChangeAndCacheCameraSmoothing(0)
        self:AnchorLookAtPosition()
        self:RecoverCamera()
    else
        self:AnchorGesturePoint(gesture)
        self:BlockCamera()
    end
    self:ChangeAndCacheHudRootAlpha(0.2, true)
    self:HideCityCircleMenu(dontExitState)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateTileHandle:OnDragUpdate(gesture)
    self.screenPos = gesture.position
    if self.dragPlane then
        -- self:OnDragPlaneForMoving(gesture)
    else
        self:OnDragTileForMoving(gesture)
    end
    self:HideCityCircleMenu(dontExitState)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateTileHandle:OnDragEnd(gesture)
    self.screenPos = nil
    self.dragging = false
    if self.dragPlane then
        self:BlockCamera()
        self:RecoverCameraSmoothingFromCache()
        self.dragPlane = false
    else
        self:RecoverCamera();
    end
    self:RecoverHudRootAlphaFromCache(true)
    self:ShowCityCircleMenu()
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateTileHandle:OnDragPlaneForMoving(gesture)
    local point = self.city:GetCamera():GetLookAtPosition()
    local x, y = self.city:GetCoordFromPosition(point)
    if x ~= self.lastX or y ~= self.lastY then
        local offsetX, offsetY = x - self.lastX, y - self.lastY
        if not self.dataSource:SquareCheck(self.curX + offsetX, self.curY + offsetY, self.dataSource.sizeX, self.dataSource.sizeY) then
            local fixX, fixY = self.dataSource:FixCoord(self.curX + offsetX, self.curY + offsetY, self.dataSource.sizeX, self.dataSource.sizeY)
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
        self:UpdatePosition(self.curX, self.curY)
    end
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateTileHandle:OnDragTileForMoving(gesture)
    local point = self.city:GetCamera():GetHitPoint(gesture.position)
    local x, y = self.city:GetCoordFromPosition(point)
    if x ~= self.lastX or y ~= self.lastY then
        local offsetX, offsetY = x - self.lastX, y - self.lastY
        if not self.dataSource:SquareCheck(self.curX + offsetX, self.curY + offsetY, self.dataSource.sizeX, self.dataSource.sizeY) then
            local fixX, fixY = self.dataSource:FixCoord(self.curX + offsetX, self.curY + offsetY, self.dataSource.sizeX, self.dataSource.sizeY)
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
        self:UpdatePosition(self.curX, self.curY, false, true)
    end
end

function CityStateTileHandle:DragModel(screenPosition)
    return self.dataSource:IsPressOnModel(screenPosition)
end

---@return boolean
function CityStateTileHandle:IsDragEmpty(x, y)
    return not (x >= self.curX and x < self.curX + self.dataSource.sizeX and y >= self.curY and y < self.curY + self.dataSource.sizeY)
end

function CityStateTileHandle:ChangeAndCacheCameraSmoothing(value)
    local camera = self.city:GetCamera()
    if camera then
        self.smoothing, camera.smoothing = camera.smoothing, value
    end
end

function CityStateTileHandle:RecoverCameraSmoothingFromCache()
    local camera = self.city:GetCamera()
    if camera and self.smoothing then
        self.smoothing, camera.smoothing = nil, self.smoothing
    end
end

function CityStateTileHandle:AnchorLookAtPosition()
    local point = self.city:GetCamera():GetLookAtPosition()
    self.lastX, self.lastY = self.city:GetCoordFromPosition(point)
end

---@param gesture CS.DragonReborn.DragGesture
function CityStateTileHandle:AnchorGesturePoint(gesture)
    local screenPos = gesture.position
    local point = self.city:GetCamera():GetHitPoint(screenPos)
    self.lastX, self.lastY = self.city:GetCoordFromPosition(point)
end

function CityStateTileHandle:BlockCamera()
    local camera = self.city:GetCamera()
    if camera ~= nil then
        camera.enableDragging = false
    end
end

function CityStateTileHandle:RecoverCamera()
    local camera = self.city:GetCamera()
    if camera then
        camera.enableDragging = true
    end
end

function CityStateTileHandle:ShowCityCircleMenu()
    if self.circleRuntimeId then
        return
    end

    local param = self.cityState:GetCircleMenuUIParameter()
    self.circleRuntimeId = g_Game.UIManager:Open(UIMediatorNames.CityCircleMenuUIMediator, param)
end

function CityStateTileHandle:HideCityCircleMenu(param)
    if not self.circleRuntimeId then
        return
    end
    g_Game.UIManager:Close(self.circleRuntimeId, param)
    self.circleRuntimeId = nil
end

function CityStateTileHandle:RefreshCityCircleMenu()
    if not self.circleRuntimeId then
        return
    end
    local param = self.cityState:GetCircleMenuUIParameter()
    g_Game.EventManager:TriggerEvent(EventConst.UI_REFRESH_CITY_CIRCLE_MENU, self.circleRuntimeId, param)
end

function CityStateTileHandle:CreateSelector()
    self.handler = self.city.createHelper:Create(self.selectorDataWrap:GetSelectorPrefabName(), self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnSelectorCreated), nil, 0, true)
end

function CityStateTileHandle:DeleteSelector()
    if self.handler then
        self.city.createHelper:Delete(self.handler)
        self.handler = nil
    end
    self.selector = nil
    self.selectorDataWrap:DetachSelector()
end

---@param go CS.UnityEngine.GameObject
function CityStateTileHandle:OnSelectorCreated(go, userdata)
    if go == nil then
        g_Logger.Error("Load city_map_building_selector failed!")
        return
    end

    local behaviourName = self.selectorDataWrap:GetSelectorBehaviourName()
    ---@type CityFurnitureSelector
    self.selector = go:GetLuaBehaviour(behaviourName).Instance
    self.selector:Init(self.city, self.selectorDataWrap, true)
end

function CityStateTileHandle:ChangeAndCacheHudRootAlpha(value, tween)
    if self.alpha then
        self:RecoverHudRootAlphaFromCache(false)
    end

    local root = g_Game.UIManager:GetRootForType(g_Game.UIManager.UIMediatorType.Hud)
    if root then
        local canvasGroup = root:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        if canvasGroup then
            if self.alphaTweener then
                self.alphaTweener:Kill(true)
            end
            self.alpha = canvasGroup.alpha
            if tween then
                self.alphaTweener = CS.DOTweenExt.DOFloatTween(self.alpha, function(v)
                    if canvasGroup then
                        canvasGroup.alpha = v
                    end
                end, value, 0.2):OnComplete(function()
                    self.alphaTweener = nil
                end)
            else
                canvasGroup.alpha = value
            end
        end
    end
end

function CityStateTileHandle:RecoverHudRootAlphaFromCache(tween)
    local root = g_Game.UIManager:GetRootForType(g_Game.UIManager.UIMediatorType.Hud)
    if root then
        local canvasGroup = root:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        if canvasGroup and self.alpha then
            if self.alphaTweener then
                self.alphaTweener:Kill(true)
            end
            if tween then
                self.alphaTweener = CS.DOTweenExt.DOFloatTween(canvasGroup.alpha, function(v)
                    if canvasGroup then
                        canvasGroup.alpha = v
                    end
                end, self.alpha, 0.2):OnComplete(function()
                    self.alphaTweener = nil
                end)
            else
                canvasGroup.alpha = self.alpha
            end
            self.alpha = nil
        end
    end
end

function CityStateTileHandle:Rotate(anticlockwise)
    self.lastX, self.lastY = self.curX, self.curY
    self.dataSource:Rotate(anticlockwise)
    self.curX, self.curY = self.dataSource.x, self.dataSource.y
    self.selectorDataWrap:Rotate(anticlockwise)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_STATE_TILE_HANDLE_ROTATE, self)
    self:RefreshCityCircleMenu()
end

function CityStateTileHandle:SquareCheck()
    return self.dataSource:SquareCheck(self.curX, self.curY, self.dataSource.sizeX, self.dataSource.sizeY)
end

function CityStateTileHandle:NotChanged()
    return self.dataSource:NotChanged()
end

return CityStateTileHandle