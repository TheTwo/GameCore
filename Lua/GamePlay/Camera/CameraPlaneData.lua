local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")

local CameraUtils = CS.Grid.CameraUtils

---@class CameraPlaneData
---@field cameraBehaviour CS.DragonReborn.LuaBehaviour
---@field minFrustumLengthUnderGround number
---@field maxFrustumLengthUnderGround number
---@field nearToFarDistance number
---@field lod1Near number
local CameraPlaneData = class('CameraPlaneData')

function CameraPlaneData:ctor(basicCamera)
    ---@type BasicCamera
    self.basicCamera = basicCamera
    self.lod1Near = 1
    self.nearToFarDistance = 1
    self.minFrustumLengthUnderGround = 0
    self.maxFrustumLengthUnderGround = 0
end

function CameraPlaneData:Initialize()
    self.basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))
end

function CameraPlaneData:Release()
    self.basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))
end

function CameraPlaneData:OnSizeChanged(oldSize, newSize)
    if KingdomMapUtils.IsCityState() then
        self:UpdateNearFarPlanes()
    end
end

function CameraPlaneData:UpdateNearFarPlanes()
    local cameraData = self.basicCamera.cameraDataPerspective
    local camera = self.basicCamera.mainCamera

    local maxLength = cameraData.maxSize + cameraData.maxSizeBuffer
    local minLength = cameraData.minSize - cameraData.minSizeBuffer

    local num = cameraData.spherical.radius - minLength
    local den = maxLength - minLength
    local ratio = num / den
    local far = math.lerp(self.minFrustumLengthUnderGround, self.maxFrustumLengthUnderGround, ratio)
    far = far + cameraData.spherical.radius

    -- 为了保证最大限度利用shadowmap，要让near和far与场景物体的高度尽量贴合。所以随着摄像机拉高，把near也拉大。把场景物体限制在一个比较扁的梯台内。
    -- 但是在水平视角是例外。near需要保持一个比较小的值。
    -- 具体表现可以在Scene场景看basic camera的视椎体。
    camera.nearClipPlane = math.max(far - self.nearToFarDistance, self.lod1Near)
    camera.farClipPlane = far
end




return CameraPlaneData