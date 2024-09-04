--警告：这个类会在多个功能场景中使用，不要把某个功能的特化逻辑写在这个类中，以免产生不必要的耦合！
local CameraDataProcessor = require("CameraDataProcessor")
local CameraUtils = require("CameraUtils")
local Vector3 = CS.UnityEngine.Vector3

---@class CameraDataPerspectiveProcessor : CameraDataProcessor
---@field new fun():CameraDataPerspectiveProcessor
local CameraDataPerspectiveProcessor = class("CameraDataPerspectiveProcessor", CameraDataProcessor)

function CameraDataPerspectiveProcessor:ctor(layerMask)
    self.layerMask = layerMask
end

---@param cameraData CameraData
---@param camera BasicCamera
function CameraDataPerspectiveProcessor:GetSize(cameraData, camera)
    return cameraData.spherical.radius;
end

---@param cameraData CameraData
---@param camera BasicCamera
function CameraDataPerspectiveProcessor:SetSize(cameraData, camera, value)
    cameraData.spherical.radius = value;
    self:UpdateTransform(cameraData, camera);
end

---@param cameraData CameraData
function CameraDataPerspectiveProcessor:GetAzimuth(cameraData, camera)
    return cameraData.spherical.azimuth
end

---@param cameraData CameraData
---@param camera BasicCamera
function CameraDataPerspectiveProcessor:SetAzimuth(cameraData, camera, value)
    cameraData.spherical.azimuth = value;
    self:UpdateTransform(cameraData, camera);
end

---@param cameraData CameraData
function CameraDataPerspectiveProcessor:GetAltitude(cameraData, camera)
    return cameraData.spherical.altitude
end

---@param cameraData CameraData
---@param camera BasicCamera
function CameraDataPerspectiveProcessor:SetAltitude(cameraData, camera, value)
    cameraData.spherical.altitude = value;
    self:UpdateTransform(cameraData, camera);
end

function CameraDataPerspectiveProcessor:GetCameraHeightHitPoint(camera, ray)
    local hitPoint = CameraUtils.GetHitPointLinePlane(ray, camera:GetBasePlane())
    return hitPoint ~= nil and hitPoint or Vector3.zero
end

function CameraDataPerspectiveProcessor:GetHitPoint(camera, ray)
    local point = CameraUtils.GetHitPointOnMeshCollider(ray, self.layerMask)
    if point == nil then
        local hitPoint = CameraUtils.GetHitPointLinePlane(ray, camera:GetBasePlane())
        return hitPoint ~= nil and hitPoint or Vector3.zero
    end
    return point
end

return CameraDataPerspectiveProcessor