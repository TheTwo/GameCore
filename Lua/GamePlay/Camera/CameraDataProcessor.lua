--警告：这个类会在多个功能场景中使用，不要把某个功能的特化逻辑写在这个类中，以免产生不必要的耦合！
local Spherical = require("Spherical")
local CameraUtils = require("CameraUtils")

---@class CameraDataProcessor
local CameraDataProcessor = class("CameraDataProcessor")

---@param data CameraData
---@param camera BasicCamera
function CameraDataProcessor:UpdateTransform(data, camera)
    local plane = camera:GetBasePlane()
    local transform = camera.mainTransform.transform
    local ray = CS.UnityEngine.Ray(transform.position, transform.forward)
    local lookAt = CameraUtils.GetHitPointLinePlane(ray, plane)
    if not lookAt then return end
    local x, y, z = Spherical.Position(data.spherical.radius, data.spherical.azimuth, data.spherical.altitude)
    local rotation = Spherical.Rotation(data.spherical.azimuth, data.spherical.altitude)
    transform:SetPositionAndRotation(lookAt + CS.UnityEngine.Vector3(x, y, z), rotation)
    camera:PostPositionUpdate()
end

function CameraDataProcessor:GetSize(cameraData, camera)
    -- 重载这个函数
end

function CameraDataProcessor:SetSize(cameraData, camera, value)
    -- 重载这个函数
end

function CameraDataProcessor:GetAzimuth(cameraData, camera)
    -- 重载这个函数
end

function CameraDataProcessor:SetAzimuth(cameraData, camera, value)
    -- 重载这个函数
end

function CameraDataProcessor:GetAltitude(cameraData, camera)
    -- 重载这个函数
end

function CameraDataProcessor:SetAltitude(cameraData, camera, value)
    -- 重载这个函数
end

return CameraDataProcessor