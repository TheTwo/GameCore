--警告：这个类会在多个功能场景中使用，不要把某个功能的特化逻辑写在这个类中，以免产生不必要的耦合！

local CameraUtils = require("CameraUtils")
local Spherical = require("Spherical")
local CameraDataPerspectiveProcessor = require("CameraDataPerspectiveProcessor")
---@class CityCameraDataPerspectiveProcessor:CameraDataPerspectiveProcessor
---@field new fun():CityCameraDataPerspectiveProcessor
local CityCameraDataPerspectiveProcessor = class("CityCameraDataPerspectiveProcessor", CameraDataPerspectiveProcessor)

function CityCameraDataPerspectiveProcessor:UpdateTransform(data, camera)
    local transform = camera.mainTransform.transform
    local ray = CS.UnityEngine.Ray(transform.position, transform.forward)
    local lookAt = CameraUtils.GetHitPointOnMeshCollider(ray, layerMask)
    if lookAt == nil then
        local plane = camera:GetBasePlane()
        lookAt = CameraUtils.GetHitPointLinePlane(ray, plane)
    end
    local x, y, z = Spherical.Position(data.spherical.radius, data.spherical.azimuth, data.spherical.altitude)
    transform.position = lookAt + CS.UnityEngine.Vector3(x, y, z);
    transform:LookAt(lookAt, CS.UnityEngine.Vector3.up)
end

function CityCameraDataPerspectiveProcessor:GetCameraHeightHitPoint(camera, ray)
    return CameraDataPerspectiveProcessor.GetHitPoint(self, camera, ray)
end

return CityCameraDataPerspectiveProcessor