local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateCanHatchPet:CityFurWorkBubbleStateBase
local CityFurWorkBubbleStateCanHatchPet = class("CityFurWorkBubbleStateCanHatchPet", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local CityHatchEggUIParameter = require("CityHatchEggUIParameter")
local UIMediatorNames = require("UIMediatorNames")

function CityFurWorkBubbleStateCanHatchPet:GetName()
    return CityFurWorkBubbleStateBase.Names.CanHatchPet
end

function CityFurWorkBubbleStateCanHatchPet:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

function CityFurWorkBubbleStateCanHatchPet:OnBubbleLoaded(bubble)
    bubble:Reset()

    bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
    bubble:ShowBubble("sp_city_icon_eggs")
end

function CityFurWorkBubbleStateCanHatchPet:OnClick()
    self.furniture:TryOpenHatchEggUI()
    self.city.petManager:BITraceBubbleClick(self.furnitureId, "hatch_egg")
    return true
end

return CityFurWorkBubbleStateCanHatchPet