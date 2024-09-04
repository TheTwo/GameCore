local BaseUIComponent = require ('BaseUIComponent')
local CityPetUtils = require("CityPetUtils")

---@class CityPetAssignWorkType:BaseUIComponent
local CityPetAssignWorkType = class('CityPetAssignWorkType', BaseUIComponent)

function CityPetAssignWorkType:OnCreate()
    self._p_icon_type = self:Image("p_icon_type")
    self._p_text_type_level = self:Text("p_text_type_level")
end

---@param data PetWorkConfigCell
function CityPetAssignWorkType:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(CityPetUtils.GetFeatureIcon(data:Type()), self._p_icon_type)
    self._p_text_type_level.text = ("%.0f"):format(data:Level())
end

return CityPetAssignWorkType