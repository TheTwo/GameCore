local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityLegoBuildingUIPageToggleButtonData
---@field onClick fun()
---@field name string
---@field selected boolean
---@field showUpgrade boolean
---@field payload any

---@class CityLegoBuildingUIPageToggleButton:BaseUIComponent
local CityLegoBuildingUIPageToggleButton = class('CityLegoBuildingUIPageToggleButton', BaseUIComponent)

function CityLegoBuildingUIPageToggleButton:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_status_upgrade_n = self:GameObject("p_status_upgrade_n")
    self._p_text_upgrade_n = self:Text("p_text_upgrade_n")

    self._p_status_upgrade_selected = self:GameObject("p_status_upgrade_selected")
    self._p_text_upgrade_selected = self:Text("p_text_upgrade_selected")

    self._p_upgrade = self:GameObject("p_upgrade")
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIPageToggleButton:OnFeedData(data)
    self.data = data

    self._p_text_upgrade_n.text = I18N.Get(data.name)
    self._p_text_upgrade_selected.text = I18N.Get(data.name)

    self._p_status_upgrade_n:SetActive(not data.selected)
    self._p_status_upgrade_selected:SetActive(data.selected)

    self._p_upgrade:SetActive(data.showUpgrade)
end

function CityLegoBuildingUIPageToggleButton:OnClick()
    if self.data.onClick ~= nil then
        self.data.onClick(self.data)
    end
end

return CityLegoBuildingUIPageToggleButton