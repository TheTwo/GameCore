---@class EarthRevivalDefine.EarthRevivalTabType
local EarthRevivalDefine = {}

---@class EarthRevivalDefine.EarthRevivalTabType
EarthRevivalDefine.EarthRevivalTabType = {
    News = 1,
    Map = 2,
    Task = 3,
    Shop = 4,
}
EarthRevivalDefine.WorldTrendFurnitureId = 1022

EarthRevivalDefine.EarthRevivalShopId = 6

--region News
---@class EarthRevivalDefine.EarthRevivalNews_Weather
EarthRevivalDefine.EarthRevivalNews_WeatherIcon = {
    "sp_comp_icon_weather_sunny",
    "sp_comp_icon_weather_snowy",
    "sp_comp_icon_weather_cloudy",
    "sp_comp_icon_weather_lightning",
}


EarthRevivalDefine.EarthRevivalNews_CanClaimRewardIcon = "sp_task_icon_box_5"
EarthRevivalDefine.EarthRevivalNews_HasClaimRewardIcon = "sp_task_icon_box_5_open"

--endregion

--region Map
---@class EarthRevivalDefine.EarthRevivalMap_ItemType
EarthRevivalDefine.EarthRevivalMap_ItemType = {
    Monster = 1,
    Building = 2,
    WorldEvent = 3,
    Ecology = 4,
}
EarthRevivalDefine.EarthRevivalMap_ProcessingSliderColor = "#607dc5"
EarthRevivalDefine.EarthRevivalMap_CompleteWinSliderColor = "#59A902"
EarthRevivalDefine.EarthRevivalMap_CompleteLoseSliderColor = "#AEB4B6"
-- EarthRevivalDefine.EarthRevivalMap_ProcessingSliderColor = "#F60FCE"

--endregion

--region Task
---@class EarthRevivalDefine.EarthRevivalTaskTabType
EarthRevivalDefine.TaskTabType = {
    Player = 1,
    Alliance = 2,
}

EarthRevivalDefine.ProgressItemId = 80003

--endregion

return EarthRevivalDefine