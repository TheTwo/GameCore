local BaseUIComponent = require ('BaseUIComponent')
local Color = CS.UnityEngine.Color

---@class CityPetAssignProperty:BaseUIComponent
local CityPetAssignProperty = class('CityPetAssignProperty', BaseUIComponent)

function CityPetAssignProperty:OnCreate()
    ---属性图片
    self._p_icon_item = self:Image("p_icon_item")
    ---相关工作属性值
    self._p_text_buff_number = self:Text("p_text_buff_number")
    ---比当前岗位上的工作宠物更适合
    self._p_icon_up = self:GameObject("p_icon_up")
    ---比当前岗位上的工作宠物更差劲
    self._p_icon_down = self:GameObject("p_icon_down")
end

---@param data CityPetAssignPropertyData
function CityPetAssignProperty:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(data:GetIcon(), self._p_icon_item)
    self._p_text_buff_number.text = data:GetWorkRelativeBuffValue()
    local isBetter = data:IsBetterThanCurrentPet()
    self._p_icon_up:SetVisible(isBetter)
    local isWorse = data:IsWorseThanCurrentPet()
    self._p_icon_down:SetVisible(isWorse)
end

return CityPetAssignProperty