local BaseUIComponent = require ('BaseUIComponent')

---@class CityPetDetailsTipWorkBenefit:BaseUIComponent
local CityPetDetailsTipWorkBenefit = class('CityPetDetailsTipWorkBenefit', BaseUIComponent)

function CityPetDetailsTipWorkBenefit:OnCreate()
    self._p_icon_work = self:Image("p_icon_work")
    self._p_text_work_info_number = self:Text("p_text_work_info_number")
end

---@param data {icon:string, value:string}
function CityPetDetailsTipWorkBenefit:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_work)
    self._p_text_work_info_number.text = data.value
end

return CityPetDetailsTipWorkBenefit