local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityConstructionModeUIToggleCell:BaseTableViewProCell
local CityConstructionModeUIToggleCell = class('CityConstructionModeUIToggleCell', BaseTableViewProCell)

function CityConstructionModeUIToggleCell:OnCreate()
    self._p_tab_a = self:GameObject("p_tab_a")
    self._p_icon_tab_a = self:Image("p_icon_tab_a")
    self._p_tab_b = self:GameObject("p_tab_b")
    self._p_icon_tab_b = self:Image("p_icon_tab_b")

    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
end

---@param data CityConstructionBuildingToggleData|CityConstructionFurnitureToggleData|CityConstructionTowerToggleData|CityConstructionDecorationToggleData|CityConstructionRoomToggleData
function CityConstructionModeUIToggleCell:OnFeedData(data)
    self.data = data
    self.data:FeedCell(self)
end

function CityConstructionModeUIToggleCell:OnClose()
    if self.data then
        self.data:OnClose(self)
    end
end

function CityConstructionModeUIToggleCell:OnClick()
    if self.data then
        self.data:OnClick()
    end
end

return CityConstructionModeUIToggleCell