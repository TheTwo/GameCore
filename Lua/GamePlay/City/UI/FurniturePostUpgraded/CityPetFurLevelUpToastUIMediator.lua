---Scene Name : sceneName
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')

---@class CityPetFurLevelUpToastUIMediator:BaseUIMediator
local CityPetFurLevelUpToastUIMediator = class('CityPetFurLevelUpToastUIMediator', BaseUIMediator)

function CityPetFurLevelUpToastUIMediator:OnCreate()
    self._p_text_title = self:Text("p_text_title", "pet_fountain_level_up_name")
    self._p_text_desc = self:Text("p_text_desc", "pet_entire_object_level_name")
    self._p_text_lv_before = self:Text("p_text_lv_before")
    self._p_text_lv_after = self:Text("p_text_lv_after")

    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param param CityFurniture
function CityPetFurLevelUpToastUIMediator:OnOpened(param)
    self.furniture = param

    self._p_text_lv_before.text = tostring(self.furniture.level - 1)
    self._p_text_lv_after.text = tostring(self.furniture.level)
    self.keepSeconds = 2.2

    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function CityPetFurLevelUpToastUIMediator:OnClose(param)
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function CityPetFurLevelUpToastUIMediator:OnSecondTick(delta)
    self.keepSeconds = self.keepSeconds - delta
    if self.keepSeconds <= 0 then
        self:CloseSelf()
    end
end

return CityPetFurLevelUpToastUIMediator