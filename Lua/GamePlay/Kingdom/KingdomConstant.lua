local Vector3 = CS.UnityEngine.Vector3

---@class KingdomConstant
local KingdomConstant = 
{
    --- 长按延迟
    LongTapDelay = 0.5,

    --- 长按多久后生效
    LongTapDuration = 1.5,

    --- 环形菜单在lod多少时自动消失
    TouchInfoDisappearLod = 2,

    --- 地表效果的Y轴偏移，防止z-fighting
    GroundVfxYOffset = 5,

    --- 大地图摄像机最低size
    CameraMinSize = 943.0127,

    --- 大地图摄像机聚焦耗时，单位s
    CameraFocusDuration = 0.3,

    --- 摄像机聚焦到建筑时的tile偏移量X
    CameraFocusBuildingTileOffsetX = 5,
    --- 摄像机聚焦到建筑时的tile偏移量Y
    CameraFocusBuildingTileOffsetY = -5,

    --- 摄像机viewport中心点
    CameraViewportCenter = Vector3(0.5, 0.5, 0.5),

    KingdomLodMin = 1,
    KingdomLodMax = 8,
    
    ServerLodMin = 1,
    ServerLodMax = 7,

    CityLod = 0,
    NormalLod = 1,
    LowLod = 2,
    MediumLod = 3,
    HighLod = 4,
    VeryHighLod = 5,
    Lod6 = 6,
    Lod7 = 7,
    Lod8 = 8,

    SymbolLod = 4,
    NoCullingLod = 7,
}

return KingdomConstant