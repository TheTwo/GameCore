local BaseUIComponent = require ('BaseUIComponent')

---@class CityPetDetailsTipWorkRemainTime:BaseUIComponent
local CityPetDetailsTipWorkRemainTime = class('CityPetDetailsTipWorkRemainTime', BaseUIComponent)

function CityPetDetailsTipWorkRemainTime:OnCreate()
    self._p_text_work_info_number = self:Text("p_text_work_info_number")
end

---@param data string
function CityPetDetailsTipWorkRemainTime:OnFeedData(data)
    self._p_text_work_info_number.text = data
end

return CityPetDetailsTipWorkRemainTime