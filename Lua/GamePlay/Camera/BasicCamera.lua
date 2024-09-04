--警告：这个类会在多个功能场景中使用，不要把某个功能的特化逻辑写在这个类中，以免产生不必要的耦合！
---@class BasicCamera
---@field new fun():BasicCamera
---@field cameraDataPerspective CameraDataPerspective
---@field mainCamera CS.UnityEngine.Camera
---@field mainTransform CS.UnityEngine.Transform
---@field slidingTolerance number
---@field maxSlidingTolerance number
---@field deltaFactor number
---@field damping number
---@field strength number
---@field smoothing number
---@field enableDragging boolean
---@field enablePinch boolean
---@field lastPinchPivot CS.UnityEngine.Vector3
---@field anchoredPosition CS.UnityEngine.Vector3
---@field settings CS.Kingdom.BasicCameraSettings
---@field sunLightGameObj CS.UnityEngine.GameObject
---@field fullScreenBehavior CS.DragonReborn.LuaBehaviour
---@field activeBrain CS.Cinemachine.CinemachineBrain
---@field virtualCamera CS.Cinemachine.CinemachineVirtualCamera
local BasicCamera = class("BasicCamera")
local CameraConst = require("CameraConst")
local CameraDataPerspectiveProcessor = require("CameraDataPerspectiveProcessor")
local MathUtils = require("MathUtils")
local CameraUtils = require("CameraUtils")
local Spherical = require("Spherical")
local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")
local EventConst = require('EventConst')
local Utils = require("Utils")

local GesturePhase = CS.DragonReborn.GesturePhase
local Ease = CS.DG.Tweening.Ease
local invoke = function(call) if call then call() end end

local DEFAULT_MOVE_SPEED = 8
local DEFAULT_ZOOM_SPEED = 8
local MOVE_EASE_TYPE = Ease.OutExpo
local ZOOM_EASE_TYPE = Ease.Linear

---@type BasicCamera
BasicCamera.CurrentBasicCamera = nil

function BasicCamera:ctor()
    self.processor = CameraDataPerspectiveProcessor.new(CS.UnityEngine.LayerMask.GetMask("CityStatic"))
    self.lastOffset = CS.UnityEngine.Vector3.zero
    self.hasChanged = false

    self.tweenCacheDrag = nil
    self.dragIdx = 0
    self.tweenCachePinch = nil
    self.pinchIdx = 0

    self.sizeLock = false
    self.changedLock = false
    self.ignoreLimit = false
    self.frustumIdx = -1

    self.slidingTolerance = 0
    self.maxSlidingTolerance = 1

    self.ignorePinchTouchPos = false

    self.stackWeakRef = setmetatable({}, {__mode = "kv"})
    self:InitStateMachine()
end

function BasicCamera:InitStateMachine()
    self.cameraSM = require("StateMachine").new()
    self.cameraSM.allowReEnter = true
    self.cameraSM:AddState("DefaultCameraState", require("DefaultCameraState").new(self))
    self.cameraSM:AddState("CinemachineControlState", require("CinemachineControlState").new(self))
    self.cameraSM:AddState("FollowTransformState", require("FollowTransformState").new(self))
    self.cameraSM:ChangeState("DefaultCameraState")
end

---@return number
function BasicCamera:GetSize()
    local cameraData = self.cameraDataPerspective
    return self.processor:GetSize(cameraData, self)
end

---@param value number
function BasicCamera:SetSize(value)
    local oldValue = self:GetSize()
    local newValue = self:LimitSize(value)
    if oldValue == newValue then
        return
    end

    self:SetSizeImp(newValue)
end

function BasicCamera:SetSizeImp(newValue, skipProcessor)
    local oldValue = self:GetSize()
    local cameraData = self.cameraDataPerspective
    self:OnPreSizeChanged(oldValue, newValue)
    if not skipProcessor then
        self.processor:SetSize(cameraData, self, newValue)
    end
    self:OnSizeChanged(oldValue, newValue)
end

function BasicCamera:GetFov()
    return self.mainCamera.fieldOfView
end

function BasicCamera:SetFov(value)
    self.mainCamera.fieldOfView = value
    return value
end

function BasicCamera:LimitSize(size)
    if self.ignoreLimit then
        return size
    else
        return math.clamp(size, self.cameraDataPerspective.minSize, self.cameraDataPerspective.maxSize)
    end
end

function BasicCamera:GetAzimuth()
    local cameraData = self.cameraDataPerspective
    return self.processor:GetAzimuth(cameraData, self)
end

---@param value number
function BasicCamera:SetAzimuth(value)
    local oldValue = self:GetAzimuth()
    if oldValue == value then return end

    local oldPosition = self:GetLookAtPosition()
    local cameraData = self.cameraDataPerspective
    self.processor:SetAzimuth(cameraData, self, value)
    self:LookAt(oldPosition)
end

function BasicCamera:GetAltitude()
    local cameraData = self.cameraDataPerspective
    return self.processor:GetAltitude(cameraData, self)
end

---@param value number
function BasicCamera:SetAltitude(value)
    local oldValue = self:GetAltitude()
    if oldValue == value then return end

    local oldPosition = self:GetLookAtPosition()
    local cameraData = self.cameraDataPerspective
    self.processor:SetAltitude(cameraData, self, value)
    self:LookAt(oldPosition)
end

function BasicCamera:GetPositionAtSize(size)
    local transform = self.mainTransform.transform
    local ray = CS.UnityEngine.Ray(transform.position, transform.forward)
    local lookAt = self.processor:GetCameraHeightHitPoint(self, ray)
    local data = self.cameraDataPerspective
    local x, y, z = Spherical.Position(size, data.spherical.azimuth, data.spherical.altitude)
    return lookAt + CS.UnityEngine.Vector3(x, y, z)
end

function BasicCamera:SetMaxSlideIntensity(value)
    self.maxSlidingTolerance = value
end

function BasicCamera:SetDamping(value)
    self.damping = value
end

function BasicCamera:SetTolerance(value)
    self.slidingTolerance = value
end

function BasicCamera:Awake()
    self.gestureHandle = CS.LuaGestureListener(self)
    self.slidingIntencity = 0
    self.processor:UpdateTransform(self.cameraDataPerspective, self)

    self.sizeChangeListeners = {}
    self.sizeChangeQueue = {}
    self.preSizeChangeListeners = {}
    self.preSizeChangeQueue = {}
    self.transformChangeListeners = {}
    self.transformChangeQueue = {}
    BasicCamera.CurrentBasicCamera = self
end

function BasicCamera:Start()
    local size = self.cameraDataPerspective.normalSize
    self:SetSize(size)

    local center = CS.UnityEngine.Vector3(self:ScreenWidth() * 0.5, self.ScreenHeight() * 0.5, 0)
    local upOffset = CS.UnityEngine.Vector3(0, 100, 0)
    local rightOffset = CS.UnityEngine.Vector3(100, 0, 0)
    self.up = (self:GetPlaneHitPoint(center + upOffset) - self:GetPlaneHitPoint(center)).normalized
    self.right = (self:GetPlaneHitPoint(center + rightOffset) - self:GetPlaneHitPoint(center)).normalized
end

function BasicCamera:OnEnable()
    self.enabled = true
    g_Game.GestureManager:AddListener(self.gestureHandle)
end

function BasicCamera:OnDisable()
    g_Game.GestureManager:RemoveListener(self.gestureHandle)
    self.enabled = false
end

function BasicCamera:Release()
    if self.enabled then
        self:OnDisable()
    end

    if BasicCamera.CurrentBasicCamera == self then
        BasicCamera.CurrentBasicCamera = nil
    end
    self.gestureHandle = nil
    self.sizeChangeListeners = {}
    self.sizeChangeQueue = {}
    self.preSizeChangeListeners = {}
    self.preSizeChangeQueue = {}

    if self.posTweener then
        self.posTweener:Kill()
        self.posTweener.onComplete = nil
        self.posTweener = nil
    end

    if self.sizeTweener then
        self.sizeTweener:Kill()
        self.sizeTweener.onComplete = nil
        self.sizeTweener = nil
    end

    if self:IsControlledByCinemachine() then
        self.cameraSM:ChangeState("DefaultCameraState")
    end
    self:ClearCache()
end

function BasicCamera:Update()
    self.cameraSM:Tick(g_Game.RealTime.deltaTime)
    if self:IsControlledByCinemachine() then return end

    if self.slidingIntencity > self.slidingTolerance then
        local deltaTime = 1 / g_Game.PerformanceLevelManager.activeFps
        local offset, velocity = MathUtils.Dampen(self.slidingIntencity, self.damping, self.strength, deltaTime)
        self.slidingIntencity = velocity
        local oldPosition = self.mainTransform.position
        local newPosition = oldPosition + (offset * self.slidingDir)
        self:SetPosition(newPosition)

        if velocity <= self.slidingTolerance then
            g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_SPEEDUP_END)
        end
    else
        self.slidingIntencity = 0
    end
end

function BasicCamera:LateUpdate()
    self.cameraSM:LateTick(g_Game.RealTime.deltaTime)
    if self:IsControlledByCinemachine() then return end

    self.hasChanged = self.mainTransform.hasChanged
    self.mainTransform.hasChanged = false
    if self.hasChanged then
        self:OnTransformChanged()

        if self.borderLimit then
            self:KeepSelfClearOfBorder()
        end
    end
end

function BasicCamera:ScreenWidth()
    return CS.UnityEngine.Screen.width
end

function BasicCamera:ScreenHeight()
    return CS.UnityEngine.Screen.height
end

function BasicCamera:MoveCameraOffset(offset)
    local oldPosition = self.mainTransform.position
    local newPosition = oldPosition + offset
    self:SetPosition(newPosition)
    return self.mainTransform.position
end

---@param screenPos CS.UnityEngine.Vector2
function BasicCamera:IsOnScreenBoard(screenPos,screenBoard)
    local width = self:ScreenWidth()
    local height = self:ScreenHeight()
    return screenPos.x < width * screenBoard.MinX or screenPos.x > width * screenBoard.MaxX
        or screenPos.y < height * screenBoard.MinY or screenPos.y > height * screenBoard.MaxY
end

function BasicCamera:ScreenHorizontalBoard(screenPos, screenBoard)
    local width = self:ScreenWidth()
    if screenPos.x < width * screenBoard.MinX then
        return 1
    elseif screenPos.x > width * screenBoard.MaxX then
        return -1
    else
        return 0
    end
end

function BasicCamera:ScreenVerticalBoard(screenPos, screenBoard)
    local height = self:ScreenHeight()
    if screenPos.y < height * screenBoard.MinY then
        return 1
    elseif screenPos.y > height * screenBoard.MaxY then
        return -1
    else
        return 0
    end
end

function BasicCamera:GetScrollingOffset(screenPos)
    if not self.scrollingOffset then
        self.scrollingOffset = CS.UnityEngine.Vector3.zero
    end

    local lookAtPos = self:GetLookAtPosition()
    local pointerPos = self:GetPlaneHitPoint(screenPos)

    self.scrollingOffset.x = pointerPos.x - lookAtPos.x
    self.scrollingOffset.z = pointerPos.z - lookAtPos.z

    return self.scrollingOffset.normalized
end

---@param gesture CS.DragonReborn.DragGesture
function BasicCamera:OnPressDown(gesture)
    if self:IsControlledByCinemachine() then return end
    if not self.dragBusy then
        self:StopSlidingWithEvt()
    end
end

---@param gesture CS.DragonReborn.DragGesture
function BasicCamera:OnRelease(gesture)
    if self:IsControlledByCinemachine() then return end
end

---@param gesture CS.DragonReborn.DragGesture
function BasicCamera:OnDrag(gesture)
    if self:IsControlledByCinemachine() then return end
    if not self.enableDragging then
        return
    end
    self:DoDrag(gesture)
end

---@param gesture CS.DragonReborn.DragGesture
function BasicCamera:DoDrag(gesture)
    if gesture.phase == GesturePhase.Started then
        self.lastDraggingPosition = self.mainTransform.position
        self.slidingIntencity = 0
        self.dragBusy = true
        g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_SPEEDUP_START)
    elseif gesture.phase == GesturePhase.Updated then
        local screenWidth = self:ScreenWidth()
        local screenHeight = self:ScreenHeight()
        local lastPosition = CameraUtils.ClampTouchPosition(gesture.lastPosition, screenWidth, screenHeight)
        local currentPosition = CameraUtils.ClampTouchPosition(gesture.position, screenWidth, screenHeight)
        lastPosition = self:GetPlaneHitPoint(lastPosition, true)
        currentPosition = self:GetPlaneHitPoint(gesture.position, true)
        local offset =  lastPosition - currentPosition
        local newPosition = self:MoveCameraOffset(offset)
        self.lastDraggingPosition = newPosition
        self.lastOffset = offset
        self.lastDraggingTick = g_Game.Time.frameCount
    elseif gesture.phase == GesturePhase.Pause then
        self.lastOffset = CS.UnityEngine.Vector3.zero
    else
        self.dragBusy = false
        if self.lastOffset and self.lastDraggingTick and self.lastDraggingTick + 30 >= g_Game.Time.frameCount then
            local strength = (self.lastDraggingTick + 30 - g_Game.Time.frameCount) / 30
            self.slidingDir = self.lastOffset.normalized
            self.slidingIntencity = math.clamp(self.lastOffset.magnitude, 0, self.maxSlidingTolerance or 1) * strength * self.smoothing
        end
        if self.slidingIntencity <= self.slidingTolerance then
            g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_SPEEDUP_END)
        end
    end
end

---@param gesture CS.DragonReborn.PinchGesture
function BasicCamera:OnPinch(gesture)
    if self:IsControlledByCinemachine() then return end
    if not self.enablePinch then
        return
    end

    if gesture.phase == GesturePhase.Started then
        self.pinchBusy = true
    elseif gesture.phase == GesturePhase.Ended then
        self.pinchBusy = false
    end

    if gesture.phase == GesturePhase.Started or gesture.phase == GesturePhase.Updated then
        local w = self:ScreenWidth()
        local h = self.ScreenHeight()
        local magnitude = math.sqrt(w * w + h * h)
        local factor = (0 - self.deltaFactor) * gesture.delta / magnitude + 1

        if self.anchoredPosition ~= nil then
            self:ZoomToWithAnchor(self:GetSize() * factor, self.anchoredPosition)
        else
            local screenPos = gesture.position
            if self.ignorePinchTouchPos then
                screenPos = CS.UnityEngine.Vector3(self:ScreenWidth() * 0.5, self.ScreenHeight() * 0.5, 0)
            end
            local pivot = self:GetPlaneHitPoint(screenPos)
            self.lastPinchPivot = pivot
            self:SetSize(self:GetSize() * factor)

            local pivotNew = self:GetPlaneHitPoint(screenPos)
            self:AdjustPivotOffset(pivot, pivotNew)
        end

    else
        self.lastPinchPivot = nil
    end
end

function BasicCamera:GetPlaneHitPoint(screenPosition, noClamp)
    local ray = self:GetRayFromScreenPosition(screenPosition, noClamp)
    local hitPoint = CameraUtils.GetHitPointLinePlane(ray, self:GetBasePlane())
    return hitPoint ~= nil and hitPoint or CS.UnityEngine.Vector3.zero
end

function BasicCamera:GetHitPoint(screenPosition, noClamp)
    local ray = self:GetRayFromScreenPosition(screenPosition, noClamp)
    return self.processor:GetHitPoint(self, ray)
end

---@return CS.UnityEngine.Ray
function BasicCamera:GetRayFromScreenPosition(screenPosition, noClamp)
    local x = noClamp and screenPosition.x or math.clamp(screenPosition.x, 0, (self:ScreenWidth() - 1))
    local y = noClamp and screenPosition.y or math.clamp(screenPosition.y, 0, (self.ScreenHeight() - 1))

    return self.mainCamera:ScreenPointToRay({x = x, y = y, z = screenPosition.z})
end

---@private
---@param oldPivot CS.UnityEngine.Vector3
---@param newPivot CS.UnityEngine.Vector3
function BasicCamera:AdjustPivotOffset(oldPivot, newPivot)
    local offset = newPivot - oldPivot
    local newPos = self.mainTransform.position - offset
    self:SetPosition(newPos)
end

---@private
function BasicCamera:GetLegalPos(pos)
    local ray = CS.UnityEngine.Ray(pos, self.mainTransform.forward)
    local point = self.processor:GetCameraHeightHitPoint(self, ray)
    local data = self.cameraDataPerspective
    local x, y, z = Spherical.Position(data.spherical.radius, data.spherical.azimuth, data.spherical.altitude)
    return point + CS.UnityEngine.Vector3(x, y, z)
end

---@private
function BasicCamera:SetPosition(pos)
    self.mainTransform.position = self:GetLegalPos(pos)
    if not self.skipPost then
        self:PostPositionUpdate()
    end
end

---@private
function BasicCamera:ForceSetPositionUpdateSize(pos)
    local y = pos.y + self:GetBasePlane().distance
    local size = Spherical.Radius(y, self.processor:GetAltitude(self.cameraDataPerspective, self))
    self.mainTransform.position = pos
    self:SetSize(size)
    self:PostPositionUpdate()
end

function BasicCamera:GetBasePlane()
    return CameraConst.PLANE
end

---@return CS.UnityEngine.Camera
function BasicCamera:GetUnityCamera()
    return self.mainCamera
end

---@param listener fun(oldValue:number, nowValue:number)
function BasicCamera:AddSizeChangeListener(listener)
    if self.sizeLock then
        self.sizeChangeQueue[listener] = true
    else
        self.sizeChangeListeners[listener] = listener
    end
end

---@param listener fun(oldValue:number, nowValue:number)
function BasicCamera:RemoveSizeChangeListener(listener)
    if self.sizeLock then
        self.sizeChangeQueue[listener] = false
    else
        self.sizeChangeListeners[listener] = nil
    end
end

---@param listener fun(oldValue:number, nowValue:number)
function BasicCamera:AddPreSizeChangeListener(listener)
    if self.sizeLock then
        self.preSizeChangeQueue[listener] = true
    else
        self.preSizeChangeListeners[listener] = listener
    end
end

---@param listener fun(oldValue:number, nowValue:number)
function BasicCamera:RemovePreSizeChangeListener(listener)
    if self.sizeLock then
        self.preSizeChangeQueue[listener] = false
    else
        self.preSizeChangeListeners[listener] = nil
    end
end

function BasicCamera:AddTransformChangeListener(listener)
    if self.changedLock then
        self.transformChangeQueue[listener] = true
    else
        self.transformChangeListeners[listener] = listener
    end
end

function BasicCamera:RemoveTransformChangeListener(listener)
    if self.changedLock then
        self.transformChangeQueue[listener] = false
    else
        self.transformChangeListeners[listener] = nil
    end
end

---@private
function BasicCamera:OnSizeChanged(oldSize, newSize)
    self.sizeLock = true
    for k, v in pairs(self.sizeChangeListeners) do
        k(oldSize, newSize)
    end
    self.sizeLock = false
    for k, v in pairs(self.sizeChangeQueue) do
        if v then
            self:AddSizeChangeListener(k)
        else
            self:RemoveSizeChangeListener(k)
        end
    end
    table.clear(self.sizeChangeQueue)
end

---@private
function BasicCamera:OnPreSizeChanged(oldSize, newSize)
    self.sizeLock = true
    for k, v in pairs(self.preSizeChangeListeners) do
        k(oldSize, newSize)
    end
    self.sizeLock = false
    for k, v in pairs(self.preSizeChangeQueue) do
        if v then
            self:AddPreSizeChangeListener(k)
        else
            self:RemovePreSizeChangeListener(k)
        end
    end
    table.clear(self.sizeChangeQueue)
end

---@private
function BasicCamera:OnTransformChanged()
    self.changedLock = true
    for _, v in pairs(self.transformChangeListeners) do
        v(self)
    end
    self.changedLock = false
    for k, v in pairs(self.transformChangeQueue) do
        if v then
            self:AddTransformChangeListener(k)
        else
            self:RemoveTransformChangeListener(k)
        end
    end
    table.clear(self.transformChangeQueue)
end

---@private
function BasicCamera:GetPlanePosInCameraForward(pos)
    if pos.y <= 0 then return pos end

    local ray = CS.UnityEngine.Ray(pos, self.mainTransform.forward)
    return CameraUtils.GetHitPointLinePlane(ray, self:GetBasePlane())
end

---@param position CS.UnityEngine.Vector3 世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:LookAt(position, duration, callback)
    if self:IsControlledByCinemachine() then return end
    if self.posTweener and self.posTweener:IsPlaying() then
        return
    end
    self:StopSlidingWithEvt()
    duration = duration or -1
    self:MarkStackInterrupt()
    local planePos = self:GetPlanePosInCameraForward(position)
    local lookAtPos = self:GetLookAtPlanePosition()
    local originOffset = planePos - lookAtPos
    local offset = CS.UnityEngine.Vector3(originOffset.x, 0, originOffset.z)
    local mainTransform = self.mainTransform
    if duration < 0 then
        self:SetPosition(mainTransform.position + offset)
        invoke(callback)
    else
        self:PushEnableDragCache()
        self:PushEnablePinchCache()
        self.enableDragging, self.enablePinch = false, false
        duration = self:GetSuitableDuration(duration, offset.magnitude)
        self.posTweener = mainTransform:DOBlendableMoveBy(offset, duration, false):OnComplete(function()
            self.enableDragging = self:PopEnableDragCache()
            self.enablePinch = self:PopEnablePinchCache()
            self.posTweener.onComplete = nil
            self.posTweener = nil
            invoke(callback)
        end):OnUpdate(function()
            self:SetPosition(mainTransform.position)
        end):SetEase(MOVE_EASE_TYPE)
    end
end

---@param position CS.UnityEngine.Vector3 世界坐标
---@param speed number 速度
---@param callback function 完成时的回调
function BasicCamera:LookAtBySpeed(position, speed, callback)
    if self:IsControlledByCinemachine() then return end
    if self.posTweener and self.posTweener:IsPlaying() then
        invoke(callback)
        return
    end
    self:StopSlidingWithEvt()

    if speed == nil or speed <= 0 then
        speed = DEFAULT_MOVE_SPEED
    end

    self:MarkStackInterrupt()
    local planePos = self:GetPlanePosInCameraForward(position)
    local originOffset = planePos - self:GetLookAtPlanePosition()
    local offset = CS.UnityEngine.Vector3(originOffset.x, 0, originOffset.z)
    local mainTransform = self.mainTransform
    local duration = offset.magnitude / speed
    if duration < 0.001 then
        self:SetPosition(mainTransform.position + offset)
        invoke(callback)
    else
        self:PushEnableDragCache()
        self:PushEnablePinchCache()
        self.enableDragging, self.enablePinch = false, false
        self.posTweener = mainTransform:DOBlendableMoveBy(offset, duration, false):OnComplete(function()
            self.enableDragging = self:PopEnableDragCache()
            self.enablePinch = self:PopEnablePinchCache()
            self.posTweener.onComplete = nil
            self.posTweener = nil
            invoke(callback)
        end):OnUpdate(function()
            self:SetPosition(mainTransform.position)
        end):SetEase(MOVE_EASE_TYPE)
    end
end

---@param position CS.UnityEngine.Vector3 世界坐标
---@param rangeSize number
---@param duration number
---@param callback fun()
function BasicCamera:LookAtRange(position, rangeSize, duration, callback)
    if self:IsControlledByCinemachine() then return end
    local cameraSize = rangeSize / math.tan(math.angle2radian(self.mainCamera.fieldOfView / 2)) + 100
    self:LookAt(position)
    self:ZoomTo(cameraSize, duration, callback)
end

---@param viewport CS.UnityEngine.Vector3 期望focus视口位置
---@param worldPosition CS.UnityEngine.Vector3 期望focus的世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:MoveWithFocus(viewport, worldPosition, duration, callback)
    if self:IsControlledByCinemachine() then return end
    self:StopSlidingWithEvt()
    self:MarkStackInterrupt()
    local plane = self:GetBasePlane()
    local originRay = self.mainCamera:ViewportPointToRay(viewport)
    local ray = nil
    local isPlanePoint = false
    if worldPosition.y < -plane.distance then
        ray = CS.UnityEngine.Ray(worldPosition, -originRay.direction)
    elseif worldPosition.y > -plane.distance then
        ray = CS.UnityEngine.Ray(worldPosition, originRay.direction)
    else
        isPlanePoint = true
    end

    local planePoint = isPlanePoint and worldPosition or CameraUtils.GetHitPointLinePlane(ray, plane)
    if planePoint == nil then
        g_Logger.ErrorChannel("BasicCamera", "BasicCamera:MoveWithFocus planePoint is nil")
        return
    end
    local originPlanePoint = CameraUtils.GetHitPointLinePlane(originRay, plane)
    local newCameraPos = self.mainTransform.position + (planePoint - originPlanePoint)
    self:ForceMoveTo(newCameraPos, duration, callback)
end

---@return CS.UnityEngine.Vector3
function BasicCamera:GetLookAtPosition()
    local ray = CS.UnityEngine.Ray(self.mainTransform.position, self.mainTransform.forward)
    local hitPoint = self.processor:GetHitPoint(self, ray)
    return hitPoint or CS.UnityEngine.Vector3.zero
end

function BasicCamera:GetLookAtPlanePosition()
    local ray = CS.UnityEngine.Ray(self.mainTransform.position, self.mainTransform.forward)
    return CameraUtils.GetHitPointLinePlane(ray, self:GetBasePlane())
end

function BasicCamera:GetLookAtPlaneAABB()
    local cameraBox = CS.Grid.CameraUtils.ProjectionOnPlaneThenGetAABB(self.mainCamera, self.mainCamera.nearClipPlane,
        self.mainCamera.farClipPlane, self:GetBasePlane())
    local min, max = cameraBox.min, cameraBox.max
    return min.x, min.z, max.x, max.z
end

function BasicCamera:ZoomToMaxSize(duration, callback)
    if self:IsControlledByCinemachine() then return end
    local size = self.cameraDataPerspective.maxSize * 3
    self:ZoomTo(size, duration, callback)
end

function BasicCamera:GetMaxSize()
    return self.cameraDataPerspective.maxSize
end

function BasicCamera:ZoomToMinSize(duration, callback)
    if self:IsControlledByCinemachine() then return end
    local size = self.cameraDataPerspective.minSize
    self:ZoomTo(size, duration, callback)
end

function BasicCamera:GetMinSize()
    return self.cameraDataPerspective.minSize
end

---@param to number 目标size
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ZoomTo(to, duration, callback)
    if self:IsControlledByCinemachine() then return end
    local delta = to - self:GetSize()
    self:Zoom(delta, duration, callback)
end

---@param delta number Size变化值
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:Zoom(delta, duration, callback)
    if self:IsControlledByCinemachine() then return end
    if self.sizeTweener and self.sizeTweener:IsPlaying() then
        return
    end

    if delta == 0 then
        self:SetSizeImp(self:GetSize())
        invoke(callback)
        return
    end

    self:StopSlidingWithEvt()
    duration = duration or -1
    local oldSize = self:GetSize()
    local newSize = self:LimitSize(oldSize + delta)
    if oldSize ~= newSize then
        if duration < 0 then
            self:SetSize(newSize)
            invoke(callback)
        else
            self:PushEnableDragCache()
            self:PushEnablePinchCache()
            self.enableDragging, self.enablePinch = false, false
            duration = self:GetSuitableZoomDuration(duration, math.abs(oldSize - newSize))
            self.sizeTweener = CS.DOTweenExt.DOFloatTween(oldSize, function(value)
                self:SetSize(value)
            end, newSize, duration):OnComplete(function()
                self.enableDragging = self:PopEnableDragCache()
                self.enablePinch = self:PopEnablePinchCache()
                self.sizeTweener.onComplete = nil
                self.sizeTweener = nil
                invoke(callback)
            end):SetEase(ZOOM_EASE_TYPE)
        end
    else
        invoke(callback)
    end
end

---@param delta number Size变化值
---@param speed number 速度
---@param callback function 完成时的回调
function BasicCamera:ZoomBySpeed(delta, speed, callback)
    if self:IsControlledByCinemachine() then return end
    if self.sizeTweener and self.sizeTweener:IsPlaying() then
        return
    end

    if delta == 0 then
        self:SetSizeImp(self:GetSize())
        invoke(callback)
        return
    end

    self:StopSlidingWithEvt()
    local oldSize = self:GetSize()
    local newSize = self:LimitSize(oldSize + delta)
    if oldSize ~= newSize then
        if speed == nil or speed <= 0 then
            speed = DEFAULT_ZOOM_SPEED
        end

        local duration = math.abs(newSize - oldSize) / speed
        if duration < 0 then
            self:SetSize(newSize)
            invoke(callback)
        else
            self:PushEnableDragCache()
            self:PushEnablePinchCache()
            self.enableDragging, self.enablePinch = false, false

            self.sizeTweener = CS.DOTweenExt.DOFloatTween(oldSize, function(value)
                self:SetSize(value)
            end, newSize, duration):OnComplete(function()
                self.enableDragging = self:PopEnableDragCache()
                self.enablePinch = self:PopEnablePinchCache()
                self.sizeTweener.onComplete = nil
                self.sizeTweener = nil
                invoke(callback)
            end):SetEase(ZOOM_EASE_TYPE)
        end
    end
end

---@param position CS.UnityEngine.Vector3
function BasicCamera:SetAnchoredPosition(position)
    self.anchoredPosition = position
end

function BasicCamera:ForceGiveUpTween()
    if self.posTweener then
        self.posTweener:Kill(true)
        if self.posTweener then
            self.posTweener.onComplete = nil
        end
        self.posTweener = nil
    end
    if self.sizeTweener then
        self.sizeTweener:Kill(true)
        if self.sizeTweener then
            self.sizeTweener.onComplete = nil
        end
        self.sizeTweener = nil
    end
    if self.tweenTimer then
        TimerUtility.StopAndRecycle(self.tweenTimer)
        self.tweenTimer = nil
    end
end

function BasicCamera:StopTween()
    if self.posTweener then
        self.posTweener:Kill(false)
        if self.posTweener then
            self.posTweener.onComplete = nil
        end
        self.posTweener = nil
    end
    if self.sizeTweener then
        self.sizeTweener:Kill(false)
        self.sizeTweener.onComplete = nil
        self.sizeTweener = nil
        self.enableDragging = self:PopEnableDragCache()
        self.enablePinch = self:PopEnablePinchCache()
    end
    if self.tweenTimer then
        TimerUtility.StopAndRecycle(self.tweenTimer)
        self.tweenTimer = nil
    end
end

---@param to number 目标size
---@param anchorPosition CS.UnityEngine.Vector3 锚定的世界坐标点,保持其屏幕坐标不变化
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ZoomToWithAnchor(to, anchorPosition, duration, callback)
    if self:IsControlledByCinemachine() then return end
    local delta = to - self:GetSize()
    self:ZoomWithAnchor(delta, anchorPosition, duration, callback)
end

---@param delta number Size变化值
---@param anchorPosition CS.UnityEngine.Vector3 锚定的世界坐标点,保持其屏幕坐标不变化
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ZoomWithAnchor(delta, anchorPosition, duration, callback)
    if self:IsControlledByCinemachine() then return end
    local viewport = self.mainCamera:WorldToViewportPoint(anchorPosition)
    return self:ZoomWithFocus(delta, viewport, anchorPosition, duration, callback)
end

---@param to number 目标size
---@param anchorPosition CS.UnityEngine.Vector3 锚定的世界坐标点,保持其屏幕坐标不变化
---@param speed number 速度
---@param callback function 完成时的回调
function BasicCamera:ZoomToWithAnchorBySpeed(to, anchorPosition, speed, callback)
    if self:IsControlledByCinemachine() then return end
    local viewport = self.mainCamera:WorldToViewportPoint(anchorPosition)
    return self:ZoomToWithFocusBySpeed(to, viewport, anchorPosition, speed, callback)
end

---@param delta number Size变化值
---@param anchorPosition CS.UnityEngine.Vector3 锚定的世界坐标点,保持其屏幕坐标不变化
---@param speed number 速度
---@param callback function 完成时的回调
function BasicCamera:ZoomWithAnchorBySpeed(delta, anchorPosition, speed, callback)
    if self:IsControlledByCinemachine() then return end
    local to = self:GetSize() + delta
    self:ZoomToWithAnchorBySpeed(to, anchorPosition, speed, callback)
end

---@param to number 目标size
---@param viewport CS.UnityEngine.Vector3 期望focus视口位置
---@param worldPosition CS.UnityEngine.Vector3 期望focus的世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ZoomToWithFocus(to, viewport, worldPosition, duration, callback)
    if self:IsControlledByCinemachine() then return end
    local delta = to - self:GetSize()
    self:ZoomWithFocus(delta, viewport, worldPosition, duration, callback)
end

---@class ZoomToWithFocusStackStatus
---@field originSize number
---@field originPosition CS.UnityEngine.Vector3
---@field duration number
---@field camera BasicCamera
---@field back fun(self:ZoomToWithFocusStackStatus)

---@param to number 目标size
---@param viewport CS.UnityEngine.Vector3 期望focus视口位置
---@param worldPosition CS.UnityEngine.Vector3 期望focus的世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
---@return ZoomToWithFocusStackStatus
function BasicCamera:ZoomToWithFocusStack(to, viewport, worldPosition, duration, callback)
    local ret = self:RecordCurrentCameraStatus(duration)
    if self:IsControlledByCinemachine() then return ret end
    self:ZoomToWithFocus(to, viewport, worldPosition, duration, callback)
    ret.interrupt = nil
    return ret
end

---@return ZoomToWithFocusStackStatus
function BasicCamera:RecordCurrentCameraStatus(duration)
    ---@type ZoomToWithFocusStackStatus
    local ret = {}
    ret.camera = self
    ret.originPosition = self:GetLookAtPosition()
    ret.originSize = self:GetSize()
    ret.duration = duration
    ret.back = function(stackStatus)
        if ret.interrupt then return end
        stackStatus.camera.stackWeakRef[ret] = nil
        stackStatus.camera:ForceGiveUpTween()
        stackStatus.camera:ZoomToWithFocus(stackStatus.originSize, CS.UnityEngine.Vector3(0.5, 0.5, 0),stackStatus.originPosition, stackStatus.duration)
    end
    self.stackWeakRef[ret] = ret
    return ret
end

---@param delta number Size变化值
---@param viewport CS.UnityEngine.Vector3 期望focus视口位置
---@param worldPosition CS.UnityEngine.Vector3 期望focus的世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ZoomWithFocus(delta, viewport, worldPosition, duration, callback)
    if self:IsControlledByCinemachine() then return end
    if self.sizeTweener and self.sizeTweener:IsPlaying() then
        return
    end

    local plane = self:GetBasePlane()
    duration = duration or -1

    local oldSize = self:GetSize()
    local newSize =self:LimitSize(oldSize + delta)
    if oldSize == newSize then
        self:SetSizeImp(newSize)
        return self:MoveWithFocus(viewport, worldPosition, duration, callback)
    end

    self:StopSlidingWithEvt()
    self:MarkStackInterrupt()
    local originPos = self.mainTransform.position
    local originRotation = self.mainTransform.rotation
    self:SetSize(newSize)
    local dummyRay = self.mainCamera:ViewportPointToRay(viewport)
    dummyRay = CS.UnityEngine.Ray(self.mainTransform.position, dummyRay.direction)
    local newSizePos = self.mainTransform.position
    local newRotation = self.mainTransform.rotation
    local originRay = dummyRay--CS.UnityEngine.Ray(originPos, dummyRay.direction)
    local ray = nil
    local isPlanePoint = false
    if worldPosition.y < -plane.distance then
        ray = CS.UnityEngine.Ray(worldPosition, -originRay.direction)
    elseif worldPosition.y > -plane.distance then
        ray = CS.UnityEngine.Ray(worldPosition, originRay.direction)
    else
        isPlanePoint = true
    end

    local planePoint = isPlanePoint and worldPosition or CameraUtils.GetHitPointLinePlane(ray, plane)
    local originPlanePoint = CameraUtils.GetHitPointLinePlane(originRay, plane)
    local vector = newSizePos - originPlanePoint
    local newCameraPos = planePoint + vector
    local Offset = newCameraPos - originPos
    if duration < 0 then
        self:SetPosition(newCameraPos)
        self:SetSize(newSize)
        invoke(callback)
    else
        self:SetSize(oldSize)
        self:PushEnableDragCache()
        self:PushEnablePinchCache()
        self.enableDragging, self.enablePinch = false, false
        duration = math.max(self:GetSuitableDuration(duration, Offset.magnitude), self:GetSuitableZoomDuration(duration, math.abs(oldSize - newSize)))
        self.sizeTweener = self.mainTransform:DOBlendableMoveBy(Offset, duration)
        local rotChange = originRotation ~= newRotation
        local data = {from = oldSize, to = newSize, rotChange = rotChange, fromRot = originRotation, toRot = newRotation, tween = self.sizeTweener}
        self.tweenTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnZoomWithFocusTick), 1, -1, false, data)
        self.sizeTweener:OnComplete(function()
            self.enableDragging = self:PopEnableDragCache()
            self.enablePinch = self:PopEnablePinchCache()
            self:OnZoomWithFocusTick(data)
            self:SetSizeImp(newSize)
            self.sizeTweener.onComplete = nil
            self.sizeTweener = nil
            TimerUtility.StopAndRecycle(self.tweenTimer)
            self.tweenTimer = nil
            invoke(callback)
        end):SetEase(MOVE_EASE_TYPE)
    end
end

function BasicCamera:OnZoomWithFocusTick(data)
    local percent = data.tween:ElapsedPercentage(false)
    local curSize = math.lerp(data.from, data.to, percent)
    self:SetSizeImp(curSize, true)
    if data.rotChange then
        self.mainTransform.rotation = data.toRot
    end
end

---@param to number 目标size
---@param viewport CS.UnityEngine.Vector3 期望focus视口位置
---@param worldPosition CS.UnityEngine.Vector3 期望focus的世界坐标
---@param moveSpeed number 位移速度
---@param callback function 完成时的回调
function BasicCamera:ZoomToWithFocusBySpeed(to, viewport, worldPosition, moveSpeed, callback)
    if self:IsControlledByCinemachine() then return end
    if self.sizeTweener and self.sizeTweener:IsPlaying() then
        return
    end

    local oldSize = self:GetSize()
    local delta = to - oldSize
    if delta == 0 then
        self:SetSizeImp(oldSize)
        local screenPos = self.mainCamera:ViewportToScreenPoint(viewport)
        local hitPoint = self:GetPlaneHitPoint(screenPos)
        local offset = worldPosition - hitPoint
        self:ForceMoveToBySpeed(self.mainTransform.position + offset, moveSpeed, callback)
        return
    end

    local newSize = self:LimitSize(to)
    if oldSize == newSize then
        self:SetSizeImp(oldSize)
        local screenPos = self.mainCamera:ViewportToScreenPoint(viewport)
        local hitPoint = self:GetPlaneHitPoint(screenPos)
        local offset = worldPosition - hitPoint
        self:ForceMoveToBySpeed(self.mainTransform.position + offset, moveSpeed, callback)
        return
    end

    self:StopSlidingWithEvt()
    self:MarkStackInterrupt()
    local oldPos = self.mainTransform.position
    self:SetSize(newSize)
    local screenPos = self.mainCamera:ViewportToScreenPoint(viewport)
    local hitPoint = self:GetPlaneHitPoint(screenPos)
    self:AdjustPivotOffset(worldPosition, hitPoint)
    local endPos = self.mainTransform.position

    if moveSpeed == nil or moveSpeed <= 0 then
        moveSpeed = DEFAULT_MOVE_SPEED
    end

    local moveDuration = (endPos - oldPos).magnitude / moveSpeed
    if moveDuration < 0.001 then
        invoke(callback)
    else
        self:PushEnableDragCache()
        self:PushEnablePinchCache()
        self.enableDragging, self.enablePinch = false, false

        self.mainTransform.position = oldPos
        self.sizeTweener = CS.DOTweenExt.MoveToByDuration(self.mainTransform, endPos, moveDuration, MOVE_EASE_TYPE, function()
            self.enableDragging = self:PopEnableDragCache()
            self.enablePinch = self:PopEnablePinchCache()
            self.sizeTweener.onComplete = nil
            self.sizeTweener = nil
            invoke(callback)
        end)
    end
end

---@param pos CS.UnityEngine.Vector3 世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ForceMoveTo(pos, duration, callback)
    if self:IsControlledByCinemachine() then return end
    duration = duration or -1
    self:MarkStackInterrupt()
    local y = pos.y + self:GetBasePlane().distance
    local size = Spherical.Radius(y, self.processor:GetAltitude(self.cameraDataPerspective, self))
    if duration < 0 then
        self:SetPosition(pos)
        self:SetSize(size)
        invoke(callback)
    else
        self:PushEnableDragCache()
        self:PushEnablePinchCache()
        self.enableDragging, self.enablePinch = false, false
        local realPos = self:GetLegalPos(pos)
        duration = self:GetSuitableDuration(duration, (realPos - self.mainTransform.position).magnitude)
        self.posTweener = CS.DOTweenExt.MoveToByDuration(self.mainTransform, realPos, duration, MOVE_EASE_TYPE, function()
            self.enableDragging = self:PopEnableDragCache()
            self.enablePinch = self:PopEnablePinchCache()
            self.posTweener.onComplete = nil
            self.posTweener = nil
            self:SetSize(size)
            invoke(callback)
        end)
    end
end

---@param ovx number @视口移动水平偏移
---@param ovy number @视口移动垂直偏移
function BasicCamera:MoveViewportOffset(ovx, ovy, duration, callback)
    if self:IsControlledByCinemachine() then return end
    local screenPosX = (0.5 + ovx) * self:ScreenWidth()
    local screenPosY = (0.5 + ovy) * self:ScreenHeight()
    local afterMove = self:GetPlaneHitPoint({x = screenPosX, y = screenPosY, z = 0}, true)
    self:MoveWithFocus({x=0.5, y=0.5, z=0}, afterMove, duration, callback)
end

---@param pos CS.UnityEngine.Vector3 世界坐标
---@param duration number 小于0则立刻到达,否则平滑插值,默认为-1
---@param callback function 完成时的回调
function BasicCamera:ForceMoveToBySpeed(pos, speed, callback)
    if self:IsControlledByCinemachine() then return end
    if speed == nil or speed <= 0 then
        speed = DEFAULT_MOVE_SPEED
    end

    local duration = (pos - self.mainTransform.position).magnitude / speed
    self:ForceMoveTo(pos, duration, callback)
end

function BasicCamera:PushEnableDragCache()
    if self.dragIdx == 0 then
        self.tweenCacheDrag = self.enableDragging
    end
    self.dragIdx = self.dragIdx + 1
end

function BasicCamera:PopEnableDragCache()
    local ret = self.tweenCacheDrag
    self.dragIdx = self.dragIdx - 1
    if self.dragIdx == 0 then
        self.tweenCacheDrag = nil
    end
    return ret
end

function BasicCamera:PushEnablePinchCache()
    if self.pinchIdx == 0 then
        self.tweenCachePinch = self.enablePinch
    end
    self.pinchIdx = self.pinchIdx + 1
end

function BasicCamera:PopEnablePinchCache()
    local ret = self.tweenCachePinch
    self.pinchIdx = self.pinchIdx - 1
    if self.pinchIdx == 0 then
        self.tweenCachePinch = nil
    end
    return ret
end

function BasicCamera:ForceResetPinchAndDrag()
    if self.tweenCacheDrag ~= nil then
        self.tweenCacheDrag = true
    else
        self.enableDragging = true
    end

    if self.tweenCachePinch ~= nil then
        self.tweenCachePinch = true
    else
        self.enablePinch = true
    end
end

function BasicCamera:ClearCache()
    self.tweenCacheDrag = nil
    self.dragIdx = 0
    self.tweenCachePinch = nil
    self.pinchIdx = 0
end

function BasicCamera:Idle()
    return self.slidingIntencity == 0 and not self.dragBusy and not self.pinchBusy and self.posTweener == nil and self.sizeTweener == nil
end

function BasicCamera:SetSunlightEnable(flag)
    if self.sunLightGameObj == nil then return end

    self.sunLightGameObj:SetActive(flag)
end

function BasicCamera:MarkStackInterrupt()
    for k, v in pairs(self.stackWeakRef) do
        k.interrupt = true
    end
end

function BasicCamera:EnableBorderCheck(minX, minZ, maxX, maxZ)
    self.borderMinX, self.borderMinZ = minX, minZ
    self.borderMaxX, self.borderMaxZ = maxX, maxZ
    self.borderLimit = true
    self:KeepSelfClearOfBorder()
end

function BasicCamera:DisableBorderCheck()
    self.borderLimit = false
end

---@private
function BasicCamera:KeepSelfClearOfBorder()
    local minX, minZ, maxX, maxZ = self:GetLookAtPlaneAABB()
    local lookAt = self:GetLookAtPlanePosition()
    local offsetX, offsetZ = 0, 0

    if minX < self.borderMinX and maxX > self.borderMaxX then
        offsetX = (self.borderMinX + self.borderMaxX) / 2 - lookAt.x
    elseif (self.borderMaxX - self.borderMinX) < (maxX - minX) then
        offsetX = (self.borderMinX + self.borderMaxX) / 2 - lookAt.x
    elseif minX < self.borderMinX then
        offsetX = self.borderMinX - minX
    elseif maxX > self.borderMaxX then
        offsetX = self.borderMaxX - maxX
    end

    if minZ < self.borderMinZ and maxZ > self.borderMaxZ then
        offsetZ = (self.borderMinZ + self.borderMaxZ) / 2 - lookAt.z
    elseif (self.borderMaxZ - self.borderMinZ) < (maxZ - minZ) then
        offsetZ = (self.borderMinZ + self.borderMaxZ) / 2 - lookAt.z
    elseif minZ < self.borderMinZ then
        offsetZ = self.borderMinZ - minZ
    elseif maxZ > self.borderMaxZ then
        offsetZ = self.borderMaxZ - maxZ
    end

    if offsetX ~= 0 or offsetZ ~= 0 then
        self.skipPost = true
        self:MoveCameraOffset(CS.UnityEngine.Vector3(offsetX, 0, offsetZ))
        self.skipPost = false
        self.slidingIntencity = 0
    end
end

function BasicCamera:PostPositionUpdate()
    if self.borderLimit then
        self:KeepSelfClearOfBorder()
    end
end

function BasicCamera:GetSuitableDuration(duration, distance)
    return math.min(duration, distance / DEFAULT_MOVE_SPEED)
end

function BasicCamera:GetSuitableZoomDuration(duration, sizeDelta)
    return math.min(duration, sizeDelta / DEFAULT_ZOOM_SPEED)
end

function BasicCamera:IsControlledByCinemachine()
    return self.cameraSM and self.cameraSM:IsCurrentState("CinemachineControlState")
end

---@param brain CS.Cinemachine.CinemachineBrain
function BasicCamera:ControlledByCinemachine(brain)
    if self:IsControlledByCinemachine() then
        if self.activeBrain == brain then
            return
        end
    end

    self.cameraSM:WriteBlackboard("CinemachineBrain", brain)
    self.cameraSM:ChangeState("CinemachineControlState")
end

function BasicCamera:StopSlidingWithEvt()
    if self.slidingIntencity > self.slidingTolerance then
        g_Game.EventManager:TriggerEvent(EventConst.RENDER_FRAME_RATE_SPEEDUP_END)
    end
    self.slidingIntencity = 0
end

---@param transform CS.UnityEngine.Transform
function BasicCamera:SetFollowTarget(transform)
    if Utils.IsNotNull(transform) then
        self.cameraSM:WriteBlackboard("FollowTargetTransform", transform, true)
        self.cameraSM:ChangeState("FollowTransformState")
    else
        self.cameraSM:ChangeState("DefaultCameraState")
    end
end

function BasicCamera:SetFollowCallback(position)
    if type(position) == "function" then
        self.cameraSM:WriteBlackboard("GetTargetPosition", position, true)
        self.cameraSM:ChangeState("FollowTransformState")
    else
        self.cameraSM:ChangeState("DefaultCameraState")
    end
end

return BasicCamera