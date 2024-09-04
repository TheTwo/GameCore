local BaseUIComponent = require ('BaseUIComponent')

---@class CityFurnitureDeployPetFeature:BaseUIComponent
local CityFurnitureDeployPetFeature = class('CityFurnitureDeployPetFeature', BaseUIComponent)

function CityFurnitureDeployPetFeature:OnCreate()
    self._p_icon_type = self:Image("p_icon_type")
    self._p_text_pet_name = self:Text("p_text_pet_name")
end

---@param data {icon:string, value:string}
function CityFurnitureDeployPetFeature:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_type)
    self._p_text_pet_name.text = data.value
end

return CityFurnitureDeployPetFeature