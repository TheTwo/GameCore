local BaseUIComponent = require ('BaseUIComponent')

---@class CityPetDetailsTipFeature:BaseUIComponent
local CityPetDetailsTipFeature = class('CityPetDetailsTipFeature', BaseUIComponent)

function CityPetDetailsTipFeature:OnCreate()
    self._p_icon = self:Image("p_icon")
    self._p_text_lv = self:Text("p_text_lv")
end

---@param data {icon:string, level:number}
function CityPetDetailsTipFeature:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite( data.icon, self._p_icon)
    self._p_text_lv.text = tostring(data.level)
end

return CityPetDetailsTipFeature