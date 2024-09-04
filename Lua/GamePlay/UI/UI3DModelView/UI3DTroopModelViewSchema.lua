local UI3DTroopModelViewSchema = {
    --Object
    { "heroRoots_Single", typeof(CS.System.Collections.Generic.List(CS.UnityEngine.Transform)) },
    { "petRoots_Single", typeof(CS.System.Collections.Generic.List(CS.UnityEngine.Transform)) },
    { "heroRoots_L", typeof(CS.System.Collections.Generic.List(CS.UnityEngine.Transform)) },
    { "petRoots_L", typeof(CS.System.Collections.Generic.List(CS.UnityEngine.Transform)) },
    { "heroRoots_R", typeof(CS.System.Collections.Generic.List(CS.UnityEngine.Transform)) },
    { "petRoots_R", typeof(CS.System.Collections.Generic.List(CS.UnityEngine.Transform)) },
    {"rootLeft", typeof(CS.UnityEngine.Transform)},
    {"rootRight", typeof(CS.UnityEngine.Transform)},
    {"rootSingle", typeof(CS.UnityEngine.Transform)},
    {"rootFlag", typeof(CS.UnityEngine.Transform)},
    --light ctrl
    { "lightTrans", typeof(CS.UnityEngine.Transform) },
    --lit init state
    {'litPosition',typeof(CS.UnityEngine.Vector3)},
    {'litRotate',typeof(CS.UnityEngine.Vector3)},

    { "envRoot", typeof(CS.UnityEngine.Transform) },
    { "virtualCam", typeof(CS.System.Collections.Generic.List(typeof(CS.Cinemachine.CinemachineVirtualCamera)))}
}

return UI3DTroopModelViewSchema