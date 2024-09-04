local CityFurnitureOverviewUIUnit = require("CityFurnitureOverviewUIUnit")
---@class CityFurnitureOverviewUIUnitProduce:CityFurnitureOverviewUIUnit
---@field new fun():CityFurnitureOverviewUIUnitProduce
---@field data CityFurnitureOverviewUnitData_Produce
local CityFurnitureOverviewUIUnitProduce = class("CityFurnitureOverviewUIUnitProduce", CityFurnitureOverviewUIUnit)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local Delegate = require("Delegate")

function CityFurnitureOverviewUIUnitProduce:OnCreate()
    self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._statusRecord = self:StatusRecordParent("")
    self._p_icon_furniture_plant = self:Image("p_icon_furniture_plant")
    self._p_progress_plant = self:Slider("p_progress_plant")
    self._p_text_time_plant = self:Text("p_text_time_plant")
    self._p_text_plant = self:Text("p_text_plant", "FAILURE_REASON_POLLUTED")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._base_sort = self:GameObject("base_sort")
    self._p_icon_sort_plant = self:Image("p_icon_sort_plant")
end

function CityFurnitureOverviewUIUnitProduce:OnClick()
    if not self.data then return end
    self.data:OnClick(self)
end

return CityFurnitureOverviewUIUnitProduce