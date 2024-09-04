local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')

---@class CityWorkFurnitureUpgradePetComp : BaseUIComponent
local CityWorkFurnitureUpgradePetComp = class('CityWorkFurnitureUpgradePetComp', BaseUIComponent)

function CityWorkFurnitureUpgradePetComp:OnCreate()
    self.p_icon_pet = self:Image('p_icon_pet')
    self.p_btn_pet = self:Button('p_icon_pet', Delegate.GetOrCreate(self, self.OnBtnClick))
end

function CityWorkFurnitureUpgradePetComp:OnShow()
end

function CityWorkFurnitureUpgradePetComp:OnHide()

end

function CityWorkFurnitureUpgradePetComp:OnFeedData(param)
    local petTypeId = tonumber(param.petTypeId)
    local cfg = ConfigRefer.PetType:Find(petTypeId)
    self:LoadSprite(cfg:Icon(), self.p_icon_pet)
end
function CityWorkFurnitureUpgradePetComp:OnBtnClick()
end

return CityWorkFurnitureUpgradePetComp
