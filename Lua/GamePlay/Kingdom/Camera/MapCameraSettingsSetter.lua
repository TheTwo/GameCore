local ModuleRefer = require("ModuleRefer")

---@class MapCameraSettingsSetter
local MapCameraSettingsSetter = class("MapCameraSettingsSetter")

---@param settings CS.Kingdom.BasicCameraSettings
---@param basicCamera BasicCamera
---@param lodData CameraLodData
---@param planeData CameraPlaneData
function MapCameraSettingsSetter.Set(settings, basicCamera, lodData, planeData)
    basicCamera:SetAzimuth(settings:GetValue("azimuth"))
    basicCamera.slidingTolerance = settings:GetValue("slidingTolerance")
    basicCamera.maxSlidingTolerance = settings:GetValue("maxSlidingTolerance")
    basicCamera.damping = settings:GetValue("damping")
    
    settings:SetFloatTable("mapDecorationScaleList", lodData.mapDecorationScaleList)

    if ModuleRefer.MapPreloadModule:BaseMapAssetsDownloadFinished() then
        basicCamera.cameraDataPerspective.maxSize = settings:GetValue("maxSize")
    else
        basicCamera.cameraDataPerspective.maxSize = settings:GetValue("maxSizeWithoutBaseMap")
    end


    lodData.mapCameraMistTaskSize = settings:GetValue("mapCameraMistTaskSize")
    lodData.planeDecorationSize = settings:GetValue("planeDecorationSize")
    
    planeData.minFrustumLengthUnderGround = settings:GetValue("minFrustumLengthUnderGround")
    planeData.maxFrustumLengthUnderGround = settings:GetValue("maxFrustumLengthUnderGround")
    planeData.nearToFarDistance = settings:GetValue("nearToFarDistance")
    planeData.lod1Near = settings:GetValue("lod1Near")
    planeData:UpdateNearFarPlanes()
end

return MapCameraSettingsSetter