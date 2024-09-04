local BaseUIComponent = require ('BaseUIComponent')
local CityFurniturePlaceI18N = require('CityFurniturePlaceI18N')
local Delegate = require('Delegate')

---@class CityFurniturePlacePadButton:BaseUIComponent
local CityFurniturePlacePadButton = class('CityFurniturePlacePadButton', BaseUIComponent)

function CityFurniturePlacePadButton:OnCreate()
    self._p_btn_left = self:Button("p_btn_left", Delegate.GetOrCreate(self, self.OnClick))
    self._child_switch = self:AnimTrigger("child_switch")
    self._p_text_view = self:Text("p_text_view", CityFurniturePlaceI18N.UI_HintShowPlaced)
end

---@param data CityFurniturePlaceUIParameter
function CityFurniturePlacePadButton:OnFeedData(data)
    self.data = data
    self:UpdateStatus()
end

function CityFurniturePlacePadButton:UpdateStatus()
    self._child_switch:PlayAll(not self.data.showPlaced and CS.FpAnimation.CommonTriggerType.Custom1 or CS.FpAnimation.CommonTriggerType.Custom2)
end

function CityFurniturePlacePadButton:OnClick()
    if not self.data then return end

    self.data.showPlaced = not self.data.showPlaced
    self:UpdateStatus()
    self:GetParentBaseUIMediator():UpdateByPlacedChange()
end

return CityFurniturePlacePadButton