local CityFurnitureOverviewUnitDataBase = require("CityFurnitureOverviewUnitDataBase")
---@class CityFurnitureOverviewUnitData_LevelUpExpandSlot:CityFurnitureOverviewUnitDataBase
---@field new fun():CityFurnitureOverviewUnitData_LevelUpExpandSlot
local CityFurnitureOverviewUnitData_LevelUpExpandSlot = class("CityFurnitureOverviewUnitData_LevelUpExpandSlot", CityFurnitureOverviewUnitDataBase)
local CityFurnitureOverviewUIUnitType = require("CityFurnitureOverviewUIUnitType")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")

---@param cell CityFurnitureOverviewUIUnitUpgrade
function CityFurnitureOverviewUnitData_LevelUpExpandSlot:FeedCell(cell)
    cell._statusRecord:ApplyStatusRecord(4)
    cell._child_reddot_default:HideAllRedDot()
end

function CityFurnitureOverviewUnitData_LevelUpExpandSlot:GetPrefabIndex()
    return CityFurnitureOverviewUIUnitType.p_item_upgrade
end

function CityFurnitureOverviewUnitData_LevelUpExpandSlot:GetWorkType()
    return CityWorkType.FurnitureLevelUp
end

function CityFurnitureOverviewUnitData_LevelUpExpandSlot:OnClick(cell)
    cell:GetParentBaseUIMediator():CloseSelf()

    local tabCfgId = ConfigRefer.CityConfig:UpgradeQueuePackagePayTabs()
    local params = nil
    if tabCfgId ~= 0 then
        params = {tabId = tabCfgId}
    end
    g_Game.UIManager:Open(UIMediatorNames.ActivityShopMediator, params)
end

return CityFurnitureOverviewUnitData_LevelUpExpandSlot