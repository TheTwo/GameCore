local BaseUIComponent = require ('BaseUIComponent')

---@class CityPetDetailsTipProperty:BaseUIComponent
local CityPetDetailsTipProperty = class('CityPetDetailsTipProperty', BaseUIComponent)

function CityPetDetailsTipProperty:OnCreate()
    self._p_base = self:GameObject("p_base")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_text_detail_number = self:Text("p_text_detail_number")
end

---@param data {index:number, name:string, value:string}
function CityPetDetailsTipProperty:OnFeedData(data)
    self._p_base:SetVisible(data.index % 2 == 0)
    self._p_text_detail.text = data.name
    self._p_text_detail_number.text = data.value
end

return CityPetDetailsTipProperty