local Color = CS.UnityEngine.Color

local BaseToggleButton = require("BaseToggleButton")


---@class CityConstructionToggleButton:BaseToggleButton
---@field new fun():CityConstructionToggleButton
local CityConstructionToggleButton = class("CityConstructionToggleButton", BaseToggleButton)
local Delegate = require("Delegate")

function CityConstructionToggleButton:OnCreate()
    self.btn = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_tab_a = self:GameObject("p_tab_a")
    self._p_tab_b = self:GameObject("p_tab_b")

    self.child_reddot_default = self:GameObject("child_reddot_default")
    self._p_type_3 = self:GameObject("p_type_3")
    self._p_text_new = self:Text("p_text_new")
    
    self.icon = self._p_tab_a:GetComponentInChildren(typeof(CS.UnityEngine.UI.Image))
end

function CityConstructionToggleButton:FeedData(data)
    self.data = data
end

function CityConstructionToggleButton:OnSelected()
    self._p_tab_a:SetActive(false)
    self._p_tab_b:SetActive(true)
end

function CityConstructionToggleButton:OnDeselected()
    self._p_tab_a:SetActive(true)
    self._p_tab_b:SetActive(false)
end

function CityConstructionToggleButton:OnClick()
    if self.data and self.data.onButtonClick then
        self.data.onButtonClick(self)
    end
end

function CityConstructionToggleButton:OnEnable()
    local originColor = self.icon.color ---@type CS.UnityEngine.Color
    self.icon.color = Color(originColor.r, originColor.g, originColor.b, 1)
end

function CityConstructionToggleButton:OnDisable()
    local originColor = self.icon.color ---@type CS.UnityEngine.Color
    self.icon.color = Color(originColor.r, originColor.g, originColor.b, 120/255)
end


return CityConstructionToggleButton