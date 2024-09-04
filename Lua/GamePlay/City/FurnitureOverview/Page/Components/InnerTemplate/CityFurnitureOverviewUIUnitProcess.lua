local CityFurnitureOverviewUIUnit = require("CityFurnitureOverviewUIUnit")
---@class CityFurnitureOverviewUIUnitProcess:CityFurnitureOverviewUIUnit
---@field new fun():CityFurnitureOverviewUIUnitProcess
---@field data CityFurnitureOverviewUnitData_Process
local CityFurnitureOverviewUIUnitProcess = class("CityFurnitureOverviewUIUnitProcess", CityFurnitureOverviewUIUnit)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local Delegate = require("Delegate")

function CityFurnitureOverviewUIUnitProcess:OnCreate()
    self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._statusRecord = self:StatusRecordParent("")
    self._p_icon_furniture_process = self:Image("p_icon_furniture_process")
    self._p_progress_process = self:Slider("p_progress_process")
    self._p_text_time_process = self:Text("p_text_time_process")
    self._p_text_process = self:Text("p_text_process")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._base_sort = self:GameObject("base_sort")
    self._p_icon_sort_process = self:Image("p_icon_sort_process")
    self._p_text_process = self:Text("p_text_process")
end

function CityFurnitureOverviewUIUnitProcess:OnClick()
    if not self.data then return end
    self.data:OnClick(self)
end

function CityFurnitureOverviewUIUnitProcess:OnClose()
    if not self.data then return end
    self.data:OnClose(self)
end

return CityFurnitureOverviewUIUnitProcess