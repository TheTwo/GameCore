local UI3DModelViewSchema = {
    --Object
    { "moduleRoot", typeof(CS.UnityEngine.Transform) },
    { "unitShadow", typeof(CS.UnityEngine.Transform)},
    --moduleRoot init state
    {'moduleRootPosition',typeof(CS.UnityEngine.Vector3)},
    {'moduleRootRotate',typeof(CS.UnityEngine.Vector3)},
    {'moduleRootScale',typeof(CS.System.Double)},
    --light ctrl
    { "lightTrans", typeof(CS.UnityEngine.Transform) },
    --lit init state
    {'litPosition',typeof(CS.UnityEngine.Vector3)},
    {'litRotate',typeof(CS.UnityEngine.Vector3)},

    { "envRoot", typeof(CS.UnityEngine.Transform) },
    { "defaultBack", typeof(CS.UnityEngine.MeshRenderer) },
    { "virtualCam1", typeof(CS.Cinemachine.CinemachineVirtualCamera) },
    { "virtualCam2", typeof(CS.Cinemachine.CinemachineVirtualCamera) },
}

return UI3DModelViewSchema