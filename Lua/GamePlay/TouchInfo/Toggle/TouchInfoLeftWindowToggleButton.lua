local BaseToggleButton = require("BaseToggleButton")
---@class TouchInfoLeftWindowToggleButton:BaseToggleButton
---@field new fun():TouchInfoLeftWindowToggleButton
local TouchInfoLeftWindowToggleButton = class("TouchInfoLeftWindowToggleButton", BaseToggleButton)
local Delegate = require("Delegate")

---@class TouchInfoLeftWindowToggleButtonData : BaseToggleButtonData
---@field imageId number

function TouchInfoLeftWindowToggleButton:OnCreate()
    self.button = self:Button('', Delegate.GetOrCreate(self,self.OnButtonClick))
    self._p_base = self:GameObject("p_base")
    self._p_selected = self:GameObject("p_selected")
    self._p_icon_base = self:Image("p_icon_base")
    self._p_icon_selected = self:Image("p_icon_selected")
end

function TouchInfoLeftWindowToggleButton:OnFeedData(data)
    self.groupCallback = data.onButtonClick
    self.data = data.data
    self:LoadSprite(self.data.imageId, self._p_icon_base)
    self:LoadSprite(self.data.imageId, self._p_icon_selected)
end

function TouchInfoLeftWindowToggleButton:OnSelected()
    self._p_selected:SetActive(true)
end

function TouchInfoLeftWindowToggleButton:OnDeselected()
    self._p_selected:SetActive(false)
end

return TouchInfoLeftWindowToggleButton