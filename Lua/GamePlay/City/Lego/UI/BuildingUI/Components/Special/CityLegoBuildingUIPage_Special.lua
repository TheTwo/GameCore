local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require("I18N")

---@class CityLegoBuildingUIPage_Special:BaseUIComponent
local CityLegoBuildingUIPage_Special = class('CityLegoBuildingUIPage_Special', BaseUIComponent)

function CityLegoBuildingUIPage_Special:OnCreate()
    self._p_img_special = self:Image("p_img_special")
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text_goto = self:Text("p_text_goto")
end

---@param data LegoUIPage_SpecialData
function CityLegoBuildingUIPage_Special:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(data.image, self._p_img_special)
    self._p_text_goto.text = I18N.Get(data.buttonI18N)
end

function CityLegoBuildingUIPage_Special:OnClick()
    if self.data.onClick then
        self.data.onClick()
    end
end

return CityLegoBuildingUIPage_Special