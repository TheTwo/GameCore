local ArtResourceUtils = require("ArtResourceUtils")

local BaseUIComponent = require ('BaseUIComponent')

---@class CityBuildUpgradeCitizenComp:BaseUIComponent
local CityBuildUpgradeCitizenComp = class('CityBuildUpgradeCitizenComp', BaseUIComponent)

function CityBuildUpgradeCitizenComp:OnCreate()
    self.gameObject = self.CSComponent.gameObject
    self._p_img_resident_a = self:Image("p_img_resident_a")
    self._p_text_name_resident = self:Text("p_text_name_resident")
end

---@param data CityCitizenData
function CityBuildUpgradeCitizenComp:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(data._config:Icon()), self._p_img_resident_a)
    self._p_text_name_resident.text = data._config:Name()
end

return CityBuildUpgradeCitizenComp