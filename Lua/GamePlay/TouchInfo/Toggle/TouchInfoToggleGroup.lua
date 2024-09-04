local ToggleGroup = require("ToggleGroup")
---@class TouchInfoToggleGroup:ToggleGroup
---@field new fun():TouchInfoToggleGroup
local TouchInfoToggleGroup = class("TouchInfoToggleGroup", ToggleGroup)

function TouchInfoToggleGroup:OnCreate()
    ---@type TouchInfoLeftWindowToggleButton
    self.toggleBtn1 = self:LuaObject("p_toggle_btn_1")
    ---@type TouchInfoLeftWindowToggleButton
    self.toggleBtn2 = self:LuaObject("p_toggle_btn_2")
end

return TouchInfoToggleGroup