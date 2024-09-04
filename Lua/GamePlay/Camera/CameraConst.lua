local CameraConst = {
    ---@type CS.UnityEngine.Plane
    PLANE = CS.UnityEngine.Plane(CS.UnityEngine.Vector3.up, CS.UnityEngine.Vector3.zero),

    CITY_LOD = 0,
    KINGDOM_LOD = 1,
    MOUNTAIN_ONLY_LOD = 3,
    GROUND_ONLY_LOD = 5,

    MapShadowCascadeSizeThreshold = 1200,
    MapShadowCascadeSplit2 = 800,
 
    MapShadowCascades = 1,

    TransitionZoomDuration = 0.5,
    TransitionCitySize = 2,
    TransitionMapSize = 500,
}

return CameraConst;