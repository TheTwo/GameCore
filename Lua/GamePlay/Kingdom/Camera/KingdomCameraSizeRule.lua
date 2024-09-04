local KingdomMapUtils = require("KingdomMapUtils")
local Delegate = require("Delegate")
local CameraUtils = require("CameraUtils")
local ConfigRefer = require("ConfigRefer")
local KingdomConstant = require("KingdomConstant")

local layerMask = CS.UnityEngine.LayerMask.GetMask("MapTerrain", "CityStatic")

---@class KingdomCameraSizeRule
---@field new fun():KingdomCameraSizeRule
---@field lastMinSize number
---@field minSizeChangeTimer number
---@field settings CS.Kingdom.MapCameraSettings
---@field smoothMin number
---@field smoothMax number
---@field dampingMin number
---@field dampingMax number
---@field NearOffsetMin number
---@field NearOffsetMax number
---@field FarOffsetMin number
---@field FarOffsetMax number
---@field minSize number
---@field maxSize number
local KingdomCameraSizeRule = sealedClass("KingdomCameraSizeRule")

local minSizeChangeDelay = 0.5
local minSizeChangeDuration = 0.3
local minSizeChangeThreshold = 50

function KingdomCameraSizeRule:ctor()
    self.gestureHandle = CS.LuaGestureListener(self)
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self.lastMinSize = 0
    self.minSizeChangeTimer = 0

    minSizeChangeDelay = ConfigRefer.ConstBigWorld:MinSizeChangeDelay() or 0.5
    minSizeChangeDuration = ConfigRefer.ConstBigWorld:MinSizeChangeDuration() or 0.3
    minSizeChangeThreshold = ConfigRefer.ConstBigWorld:MinSizeChangeThreshold() or 50
end

function KingdomCameraSizeRule:Initialize()
    self.minSize = KingdomMapUtils.GetCameraLodData():GetSizeByLod(KingdomConstant.KingdomLodMin - 1)
    self.maxSize = KingdomMapUtils.GetCameraLodData():GetSizeByLod(KingdomConstant.KingdomLodMax)
    
    g_Game.GestureManager:AddListener(self.gestureHandle)
    self.basicCamera:AddPreSizeChangeListener(Delegate.GetOrCreate(self, self.OnPreSizeChange))
    self.basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChange))
    self.basicCamera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.OnCameraMove))

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function KingdomCameraSizeRule:Release()
    g_Game.GestureManager:RemoveListener(self.gestureHandle)
    self.basicCamera:RemovePreSizeChangeListener(Delegate.GetOrCreate(self, self.OnPreSizeChange))
    self.basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChange))
    self.basicCamera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.OnCameraMove))

    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    
    self.settings = nil
end

function KingdomCameraSizeRule:SetBlock(flag)
    self.block = flag
end

function KingdomCameraSizeRule:OnCameraMove(camera)
    if self.block then
        return
    end

    self:UpdateMinSize()
end

function KingdomCameraSizeRule:Tick(dt)
    self:TickMinSize(dt)
end


function KingdomCameraSizeRule:OnPreSizeChange(oldSize, newSize)
    if self.block then
        return
    end

    local cameraData = self.basicCamera.cameraDataPerspective
    cameraData.spherical.altitude = self:GetLookAltitude(newSize)
end

function KingdomCameraSizeRule:OnSizeChange(oldSize, newSize)
    if self.block then
        return
    end

    if not self.basicCamera then
        return
    end

    if not self:LateInitSettings() then
        return
    end
        
    local t = (newSize - self.minSize) / (self.maxSize - self.minSize)
    local basicCamera = self.basicCamera
    basicCamera.damping = math.lerp(self.dampingMin, self.dampingMax, t)
    basicCamera.smoothing = math.lerp(self.smoothMin, self.smoothMax, t)
    basicCamera.maxSlidingTolerance = math.lerp(self.slidingToleranceMin, self.slidingToleranceMax, t)
    
    self:UpdateNearFarPlanes()
end

function KingdomCameraSizeRule:LateInitSettings()
    if not self.settings then
        local settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Kingdom.MapCameraSettings))
        if not settings then
            return false
        end
        self.settings = settings

        self.smoothMin = self.settings.SmoothMin
        self.smoothMax = self.settings.SmoothMax
        self.dampingMin = self.settings.DampingMin
        self.dampingMax = self.settings.DampingMax
        self.slidingToleranceMin = self.settings.SlidingToleranceMin
        self.slidingToleranceMax = self.settings.SlidingToleranceMax

        self.NearOffsetMin = self.settings.NearOffsetMin
        self.NearOffsetMax = self.settings.NearOffsetMax
        self.FarOffsetMin = self.settings.FarOffsetMin
        self.FarOffsetMax = self.settings.FarOffsetMax
    end
    return true
end

function KingdomCameraSizeRule:UpdateMinSize()
    if KingdomMapUtils.GetLOD() >= KingdomConstant.SymbolLod then
        return
    end
    
    local position = KingdomMapUtils.GetBasicCamera().mainTransform.position
    local heightOffset = KingdomMapUtils.SampleHeight(position.x, position.z)
    if heightOffset <= 0 then
        return
    end
    
    local minSize = KingdomMapUtils.GetCameraLodData():GetSizeByLod(0) + heightOffset
    if self.lastMinSize == 0 then
        self.lastMinSize = minSize
    else
        if math.abs(self.lastMinSize - minSize) > minSizeChangeThreshold then
            self.lastMinSize = minSize
            if self.basicCamera:GetSize() < minSize then
                self.minSizeChangeTimer = minSizeChangeDelay
            end
        end
    end
    self.basicCamera.cameraDataPerspective.minSize = minSize
end

function KingdomCameraSizeRule:TickMinSize(dt)
    if self.minSizeChangeTimer > 0 then
        self.minSizeChangeTimer = self.minSizeChangeTimer - dt
        if self.minSizeChangeTimer < 0 then
            self.basicCamera.enablePinch = false
            self.basicCamera.ignoreLimit = true
            self.basicCamera:ZoomToMinSize(minSizeChangeDuration, function()
                self.basicCamera.enablePinch = true
                self.basicCamera.ignoreLimit = false
            end)
        end
    end
end

---@param camera CS.UnityEngine.Camera
function KingdomCameraSizeRule:GetHeightOffset(camera)
    if not self.block then
        -- 以摄像机近平面的bottom-middle点向Vector3.down打射线。
        -- 采样到的地表高度如果高于bottom-middle，则做偏移。保证摄像机不与地表穿插。
        -- 山的prefab也添加了碰撞体。与地表一样的处理。
        local nearPlaneDown = camera.nearClipPlane * math.tan(math.rad(camera.fieldOfView / 2)) * (-camera.transform.up)
        local bottomMiddle = camera.transform.position + camera.transform.forward * camera.nearClipPlane + nearPlaneDown
        local ray = CS.UnityEngine.Ray(bottomMiddle, CS.UnityEngine.Vector3.down)
        local hitPoint = CameraUtils.GetHitPointOnMeshCollider(ray, layerMask)
        if hitPoint then
            return hitPoint.y - bottomMiddle.y + 100
        end
    end
    return 0
end

---@param newCameraSize number
---@return number
function KingdomCameraSizeRule:GetLookAltitude(newCameraSize)
    local lodData = KingdomMapUtils.GetCameraLodData()
    local altitudeCurve = lodData.altitudeCurve
    if altitudeCurve == nil then
        return 135
    end

    local minSize = lodData.mapCameraSizeList[1]
    local maxSize = lodData.mapCameraSizeList[#lodData.mapCameraSizeList]
    local t = math.clamp01((newCameraSize - minSize) / (maxSize - minSize))
    local altitude = altitudeCurve:Evaluate(t)
    --g_Logger.Log(string.format("%s, %s", t, altitude))
    return 180 - altitude
end

function KingdomCameraSizeRule:UpdateNearFarPlanes()
    local cameraData = self.basicCamera.cameraDataPerspective
    local camera = self.basicCamera.mainCamera
    local size = self.basicCamera:GetSize()
    local near, far = CS.Grid.CameraUtils.CalculateProperNearFarPlane(camera, size)

    local maxLength = cameraData.maxSize + cameraData.maxSizeBuffer
    local minLength = cameraData.minSize - cameraData.minSizeBuffer
    local num = cameraData.spherical.radius - minLength
    local den = maxLength - minLength
    local ratio = math.clamp01(num / den)
    local nearOffset = math.lerp(self.NearOffsetMin, self.NearOffsetMax, ratio)
    local farOffset = math.lerp(self.FarOffsetMin, self.FarOffsetMax, ratio)

    camera.nearClipPlane = math.max(near - nearOffset, 200)
    camera.farClipPlane = far + farOffset
end

return KingdomCameraSizeRule