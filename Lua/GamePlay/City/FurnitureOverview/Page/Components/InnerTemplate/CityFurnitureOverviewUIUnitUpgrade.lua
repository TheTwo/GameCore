local CityFurnitureOverviewUIUnit = require("CityFurnitureOverviewUIUnit")
---@class CityFurnitureOverviewUIUnitUpgrade:CityFurnitureOverviewUIUnit
---@field new fun():CityFurnitureOverviewUIUnitUpgrade
local CityFurnitureOverviewUIUnitUpgrade = class("CityFurnitureOverviewUIUnitUpgrade", CityFurnitureOverviewUIUnit)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local Delegate = require("Delegate")

function CityFurnitureOverviewUIUnitUpgrade:OnCreate()
    self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._statusRecord = self:StatusRecordParent("")
    self._p_icon_furniture_upgrade = self:Image("p_icon_furniture_upgrade")
    self._p_progress_upgrade = self:Slider("p_progress_upgrade")
    self._p_text_time_upgrade = self:Text("p_text_time_upgrade")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_text_lock_upgrade = self:Text("p_text_lock_upgrade", FurnitureOverview_I18N.LevelUpLockText)
    self._child_status_free = self:GameObject("child_status_free")
end

---@param data CityFurnitureOverviewUnitData_LevelUp|CityFurnitureOverviewUnitData_LevelUpEmpty|CityFurnitureOverviewUnitData_LevelUpExpandSlot
function CityFurnitureOverviewUIUnitUpgrade:OnClick()
    if not self.data then return end
    self.data:OnClick(self)
end

return CityFurnitureOverviewUIUnitUpgrade