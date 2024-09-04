---@class StoryDialogUiOptionCellType
local StoryDialogUiOptionCellType = {}

---@class StoryDialogUiOptionCellType.enum
StoryDialogUiOptionCellType.enum = {
    None = 0,
    SE = 1,
    Food = 2,
    Deal = 3,
    Box = 4,
    Vote = 5,
}

---@class StoryDialogUiOptionCellType.typeIcon
StoryDialogUiOptionCellType.typeIcon = {
    [StoryDialogUiOptionCellType.enum.SE] = "sp_city_icon_task_se",
    [StoryDialogUiOptionCellType.enum.Food] = "sp_city_icon_task_food",
    [StoryDialogUiOptionCellType.enum.Deal] = "sp_city_icon_task_deal",
    [StoryDialogUiOptionCellType.enum.Box] = "sp_city_icon_task_box",
    [StoryDialogUiOptionCellType.enum.Vote] = "sp_common_icon_recommend",
}

return StoryDialogUiOptionCellType

