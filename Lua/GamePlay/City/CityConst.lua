local CityConst = {
    --- City 最近CameraSize
    CITY_NEAR_CAMERA_SIZE = 37.5,
    --- City 最远CameraSize
    CITY_FAR_CAMERA_SIZE = 37.5,
    --- City 家具选中推荐CameraSize
    CITY_FURNITURE_CAMERA_SIZE = 37.5,

    -- --- 是否显示屋顶的CameraSize阈值
    -- CITY_ROOF_STATUS_THRESHOLD = 50,
    -- --- City从NormalState进入RoofHideState的阈值
    -- CITY_NORMAL_TO_ROOF_HIDE_THRESHOLD_CAMERA_SIZE = 100,

    -- CITY 单队探索模式聚焦高度最小值
    CITY_SE_FOCUS_EXPLORER_NEAR_CAMERA_SIZE = 37.5,
    -- CITY 单队探索模式聚焦高度最大值
    CITY_SE_FOCUS_EXPLORER_FAR_CAMERA_SIZE = 37.5,
    --- City 单队探索模式聚焦CameraSize
    CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE = 37.5,

    --- 室内编辑CameraSize
    CITY_INDOOR_EDIT_SIZE = 37.5,
    --- City的推荐CameraSize
    CITY_RECOMMEND_CAMERA_SIZE = 37.5,
    --- 是否处于鸟瞰City状态的CameraSize阈值
    AIR_VIEW_THRESHOLD = 50,
    --- 是否隐藏建筑墙壁或让其半透的CameraSize阈值
    CITY_HIDE_WALL_CAMERA_SIZE = 50,

    --- City内建筑的CameraSize显示阈值
    BUILDING_MAX_VIEW_SIZE = 800,
    --- City内资源点的CameraSize显示阈值
    RESOURCE_MAX_VIEW_SIZE = 600,
    --- City内NPC的CameraSize显示阈值
    NPC_MAX_VIEW_SIZE = 700,
    --- City内其他的CameraSize显示阈值
    OTHER_MAX_VIEW_SIZE = 400,

    --- 气泡类在相机上保持视口面积不变的区间
    CITY_ASSET_CAMERA_ZOOM_MIN = 5,
    CITY_ASSET_CAMERA_ZOOM_MAX = 10,

    GroundVfxYOffset = 0.01,

    -------------------STATE-------------------
    STATE_ENTRY = "STATE_ENTRY",
    STATE_EXIT = "STATE_EXIT",
    STATE_AIR_VIEW = "STATE_AIR_VIEW",
    STATE_NORMAL = "STATE_NORMAL",
    STATE_INDOOR = "STATE_INDOOR",
    STATE_BUILDING = "STATE_BUILDING",
    STATE_PLACE_ROOM_DOOR = "STATE_PLACE_ROOM_DOOR",
    STATE_PLACE_ROOM_FURNITURE = "STATE_PLACE_ROOM_FURNITURE",
    STATE_CHANGE_FLOOR = "STATE_CHANGE_FLOOR",
    STATE_BUILDING_SELECT = "STATE_BUILDING_SELECT",
    STATE_BUILDING_MOVING = "STATE_BUILDING_MOVING",
    STATE_FURNITURE_SELECT = "STATE_FURNITURE_SELECT",
    STATE_FURNITURE_MOVING = "STATE_FURNITURE_MOVING",
    STATE_UPGRADE_BUILDING_PREVIEW = "STATE_UPGRADE_BUILDING_PREVIEW",
    STATE_CITIZEN_MANAGE_UI = "STATE_CITIZEN_MANAGE_UI",
    STATE_CREEP_NODE_SELECT = "STATE_CREEP_NODE_SELECT",
    STATE_EXPLORER_TEAM_SELECT = "STATE_EXPLORER_TEAM_SELECT",
    STATE_REPAIR_BLOCK = "STATE_REPAIR_BLOCK",
    STATE_EDIT_IDLE = "STATE_EDIT_IDLE",
    STATE_ENTER_RADAR = "STATE_ENTER_RADAR",

    STATE_CREEP_SELECT = "STATE_CREEP_SELECT",
    STATE_CLEAR_CREEP = "STATE_CLEAR_CREEP",
    -- STATE_ROOF_HIDE = "STATE_ROOF_HIDE",
    -- STATE_NORMAL_TO_ROOF_HIDE = "STATE_NORMAL_TO_ROOF_HIDE"
    STATE_SAFE_AREA_WALL_SELECT = "STATE_SAFE_AREA_WALL_SELECT",
    STATE_FURNITURE_FARMLAND_SELECT = "STATE_FURNITURE_FARMLAND_SELECT",
    STATE_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECT = "STATE_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECT",
    STATE_LEGO_SELECT = "STATE_LEGO_SELECT",
    STATE_MOVING_LEGO_BUILDING = "STATE_MOVING_LEGO_BUILDING",
    STATE_LOCKED_BUILDING_SELECT = "STATE_LOCKED_BUILDING_SELECT",
    STATE_MAIN_BASE_UPGRADE = "STATE_MAIN_BASE_UPGRADE",
    STATE_CITY_SE_BATTLE_FOCUS = "STATE_CITY_SE_BATTLE_FOCUS",
    STATE_CITY_SE_EXPLORER_FOCUS = "STATE_CITY_SE_EXPLORER_FOCUS",
    STATE_CITY_ZONE_RECOVER_EFFECT = "STATE_CITY_ZONE_RECOVER_EFFECT",
    STATE_EXPLORER_TEAM_OPERATE_MENU = "STATE_EXPLORER_TEAM_OPERATE_MENU",

    --- 长按x秒进入读条
    CITY_PRESS_DELAY = 0.1,
    --- 读条x秒后抬起
    CITY_PRESS_DURATION = 0.25,
    --- 箭头淡出时间
    CITY_FADE_OUT_DURATION = 0.2,
    CITY_UI_CAMERA_FOCUS_TIME = 0.5,

    Quaternion = {
        [0] = CS.UnityEngine.Quaternion.identity,
        [90] = CS.UnityEngine.Quaternion.Euler(0, 90, 0),
        [180] = CS.UnityEngine.Quaternion.Euler(0, 180, 0),
        [270] = CS.UnityEngine.Quaternion.Euler(0, 270, 0),
    },

    TileHandleType = {
        None = 0, --- 无分类
        Furniture = 1, --- 家具
        LegoBuilding = 2, --- 建筑
    },

    RiseOffset = CS.UnityEngine.Vector3(0, 0.08, 0),

    FullScreenCameraSafeArea = {minX = 0, maxX = 1, minY = 0, maxY = 1},
    TopHalfScreenCameraSafeArea = {minX = 0, maxX = 1, minY = 0.5, maxY = 1},

    RoofHideCameraSize = 8,
    RoofShowCameraSize = 10,

    ZoneRecoverTime = 5,
    ZoneRecoverUnPollutedTimeDelay = 3,
    TransToSeStateResult = {
        Success = 0,
        NoNeed = 1,
        WaitExpeditionEntity = 2,
    },
}

function CityConst.OnConfigLoaded()
    local ConfigRefer = require("ConfigRefer")
    local minSize = ConfigRefer.CityConfig:CityCameraHeightMin()
    if minSize > 0 then
        CityConst.CITY_NEAR_CAMERA_SIZE = minSize
        CityConst.CITY_SE_FOCUS_EXPLORER_NEAR_CAMERA_SIZE = minSize
        CityConst.CITY_SE_FOCUS_EXPLORER_FAR_CAMERA_SIZE = minSize
        CityConst.CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE = minSize
    end
    local maxSize = ConfigRefer.CityConfig:CityCameraHeightMax()
    if maxSize > 0 then
        CityConst.CITY_FAR_CAMERA_SIZE = maxSize
    end
    local recommendSize = ConfigRefer.CityConfig:CityCameraHeightRecommend()
    if recommendSize > 0 then
        CityConst.CITY_RECOMMEND_CAMERA_SIZE = recommendSize
    end
    local seExplorerFocusMinSize = ConfigRefer.CityConfig.CityCameraHeightSeExplorerFocusMin and ConfigRefer.CityConfig:CityCameraHeightSeExplorerFocusMin()
    if seExplorerFocusMinSize and seExplorerFocusMinSize > 0 then
        CityConst.CITY_SE_FOCUS_EXPLORER_NEAR_CAMERA_SIZE = seExplorerFocusMinSize
    end
    local seExplorerFocusMaxSize = ConfigRefer.CityConfig.CityCameraHeightSeExplorerFocusMax and ConfigRefer.CityConfig:CityCameraHeightSeExplorerFocusMax()
    if seExplorerFocusMaxSize and seExplorerFocusMaxSize > 0 then
        CityConst.CITY_SE_FOCUS_EXPLORER_FAR_CAMERA_SIZE = seExplorerFocusMaxSize
    end
    local seExplorerFocusSize = ConfigRefer.CityConfig.CityCameraHeightSeExplorerRecommend and ConfigRefer.CityConfig:CityCameraHeightSeExplorerRecommend()
    if seExplorerFocusSize and seExplorerFocusSize > 0 then
        CityConst.CITY_SE_FOCUS_EXPLORER_RECOMMEND_CAMERA_SIZE = seExplorerFocusSize
    end
    local innerEditSize = ConfigRefer.CityConfig:CityCameraBuildingHeightRecommend()
    if innerEditSize > 0 then
        CityConst.CITY_INDOOR_EDIT_SIZE = innerEditSize
    end
    local airViewSize = ConfigRefer.CityConfig:CityCameraBirdsEyeViewHeight()
    if airViewSize > 0 then
        CityConst.AIR_VIEW_THRESHOLD = airViewSize
    end
    local hideWallViewSize = ConfigRefer.CityConfig:CityCameraHideWallViewHeight()
    if hideWallViewSize > 0 then
        CityConst.CITY_HIDE_WALL_CAMERA_SIZE = hideWallViewSize
    end
    local furnitureViewSize = ConfigRefer.CityConfig:CityCameraFurnitureViewHeight()
    if furnitureViewSize > 0 then
        CityConst.CITY_FURNITURE_CAMERA_SIZE = furnitureViewSize
    end

    CityConst.CITY_ASSET_CAMERA_ZOOM_MIN = CityConst.CITY_NEAR_CAMERA_SIZE
    local assetCameraZoomMax = ConfigRefer.CityConfig:CityAssetCameraZoomMaxHeight()
    if assetCameraZoomMax > 0 then
        CityConst.CITY_ASSET_CAMERA_ZOOM_MAX = assetCameraZoomMax
    end

    local hideRoofCameraSize = ConfigRefer.CityConfig:HideRoofCameraSize()
    if hideRoofCameraSize > 0 then
        CityConst.RoofHideCameraSize = hideRoofCameraSize
        g_Logger.TraceChannel("CityConst", "HideRoofCameraSize: %.1f", hideRoofCameraSize)
    end

    local showRoofCameraSize = ConfigRefer.CityConfig:ShowRoofCameraSize()
    if showRoofCameraSize > 0 then
        CityConst.RoofShowCameraSize = showRoofCameraSize
        g_Logger.TraceChannel("CityConst", "ShowRoofCameraSize: %.1f", showRoofCameraSize)
    end
end

return CityConst