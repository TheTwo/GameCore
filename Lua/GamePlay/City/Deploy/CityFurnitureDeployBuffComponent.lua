local BaseUIComponent = require ('BaseUIComponent')

---@class CityFurnitureDeployBuffComponent:BaseUIComponent
local CityFurnitureDeployBuffComponent = class('CityFurnitureDeployBuffComponent', BaseUIComponent)

function CityFurnitureDeployBuffComponent:OnCreate()
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_buff_number = self:Text("p_text_buff_number")
end

---@param data {icon:string, value:string}
function CityFurnitureDeployBuffComponent:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_item)
    self._p_text_buff_number.text = data.value
end

return CityFurnitureDeployBuffComponent