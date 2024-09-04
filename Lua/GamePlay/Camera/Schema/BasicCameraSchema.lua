local CameraDataPerspectiveSchema = require("CameraDataPerspectiveSchema")

local BasicCameraSchema = {
    --Object
    { "mainCamera", typeof(CS.UnityEngine.Camera) },
    { "mainTransform", typeof(CS.UnityEngine.Transform) },

    --Enable
    { "enableDragging", typeof(CS.System.Boolean) },
    { "enablePinch", typeof(CS.System.Boolean) },
    -- { "enablePositionAdjustment", typeof(CS.System.Boolean) },

    --Camera
    { "cameraDataPerspective", CameraDataPerspectiveSchema},
    { "settings", typeof(CS.Kingdom.BasicCameraSettings)},

    ---Sun Light
    { "sunLightGameObj", typeof(CS.UnityEngine.GameObject)},
    
    { "fullScreenBehavior", typeof(CS.DragonReborn.LuaBehaviour)},
    { "virtualCamera", typeof(CS.Cinemachine.CinemachineVirtualCamera)},
}

return BasicCameraSchema