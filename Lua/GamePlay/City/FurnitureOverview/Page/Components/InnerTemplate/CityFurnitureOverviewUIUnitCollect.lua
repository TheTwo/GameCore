local CityFurnitureOverviewUIUnit = require("CityFurnitureOverviewUIUnit")
---@class CityFurnitureOverviewUIUnitCollect:CityFurnitureOverviewUIUnit
---@field new fun():CityFurnitureOverviewUIUnitCollect
---@field data CityFurnitureOverviewUnitData_ResCollect
local CityFurnitureOverviewUIUnitCollect = class("CityFurnitureOverviewUIUnitCollect", CityFurnitureOverviewUIUnit)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local Delegate = require("Delegate")

function CityFurnitureOverviewUIUnitCollect:OnCreate()
    self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._statusRecord = self:StatusRecordParent("")
    self._p_icon_furniture_collect = self:Image("p_icon_furniture_collect")
    self._p_progress_collect = self:Slider("p_progress_collect")
    self._p_text_time_collect = self:Text("p_text_time_collect")
    self._p_text_collect = self:Text("p_text_collect", FurnitureOverview_I18N.FurnitureResCollectText)
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._base_sort = self:GameObject("base_sort")
    self._p_icon_sort_collect = self:Image("p_icon_sort_collect")

    self._p_text_collect = self:Text("p_text_collect")
end

function CityFurnitureOverviewUIUnitCollect:OnClick()
    if not self.data then return end
    self.data:OnClick(self)
end

return CityFurnitureOverviewUIUnitCollect