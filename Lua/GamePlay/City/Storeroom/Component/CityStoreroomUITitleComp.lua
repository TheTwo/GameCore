local BaseUIComponent = require ('BaseUIComponent')

---@class CityStoreroomUITitleComp:BaseUIComponent
local CityStoreroomUITitleComp = class('CityStoreroomUITitleComp', BaseUIComponent)

function CityStoreroomUITitleComp:OnCreate()
    self._p_text_title = self:Text("p_text_title")
    self._p_blood = self:GameObject("p_blood")
    self._p_text_blood = self:Text("p_text_blood")
end

---@param data CityStoreroomUITitleData
function CityStoreroomUITitleComp:OnFeedData(data)
    self._p_text_title.text = data:GetTitle()
    local needShow = data:NeedShowBlood()
    self._p_blood:SetActive(needShow)
    if needShow then
        self._p_text_blood.text = data:GetBloodStr()
    end
end

return CityStoreroomUITitleComp