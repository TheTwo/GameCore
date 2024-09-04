local BaseUIComponent = require('BaseUIComponent')

---@class TouchInfoResidentCompData
---@field icon string
---@field name string

---@class TouchInfoResidentComponent : BaseUIComponent
local TouchInfoResidentComponent = class("TouchInfoResidentComponent", BaseUIComponent)

function TouchInfoResidentComponent:OnCreate()
    self._p_img_resident = self:Image("p_img_resident")
    self._p_text_name_resident = self:Text("p_text_name_resident")
end

---@param data TouchInfoResidentCompData
function TouchInfoResidentComponent:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_img_resident)
    self._p_text_name_resident.text = data.name
end

return TouchInfoResidentComponent