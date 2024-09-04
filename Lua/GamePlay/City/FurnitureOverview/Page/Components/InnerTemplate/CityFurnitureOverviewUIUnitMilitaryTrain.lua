local CityFurnitureOverviewUIUnit = require("CityFurnitureOverviewUIUnit")
local Delegate = require("Delegate")
---@class CityFurnitureOverviewUIUnitMilitaryTrain:CityFurnitureOverviewUIUnit
---@field new fun():CityFurnitureOverviewUIUnitMilitaryTrain
local CityFurnitureOverviewUIUnitMilitaryTrain = class("CityFurnitureOverviewUIUnitMilitaryTrain", CityFurnitureOverviewUIUnit)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")

function CityFurnitureOverviewUIUnitMilitaryTrain:OnCreate()
    self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._statusRecord = self:StatusRecordParent("")
    self._p_icon_furniture_soldier = self:Image("p_icon_furniture_soldier")
    self._p_text_quantity_soldier = self:Text("p_text_quantity_soldier")
    self._p_progress_soldier = self:Slider("p_progress_soldier")
    self._p_text_time_soldier = self:Text("p_text_time_soldier")
    self._p_text_soldier = self:Text("p_text_soldier", "recruit_info_nofood")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
end

function CityFurnitureOverviewUIUnitMilitaryTrain:OnClick()
    if not self.data then return end
    self.data:OnClick(self)
end

return CityFurnitureOverviewUIUnitMilitaryTrain