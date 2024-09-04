---@class CityHatchEggOpenUIParameter
---@field new fun(resultParam, recipeId):CityHatchEggOpenUIParameter
local CityHatchEggOpenUIParameter = class("CityHatchEggOpenUIParameter")
local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")
local ModuleRefer = require("ModuleRefer")

---@param resultParam CatchPetResultMediatorParameter
function CityHatchEggOpenUIParameter:ctor(resultParam, recipeId)
    self.resultParam = resultParam
    self.recipeId = recipeId
end

function CityHatchEggOpenUIParameter:IsOnlyOneAndNew()
    if self.resultParam.result.RewardPets:Count() == 1 then
        local rewardPet = self.resultParam.result.RewardPets[1]
        local pet = ModuleRefer.PetModule:GetPetByID(rewardPet.PetCompId)
        if pet and pet.TypeIndex == 1 then
            return true
        end
    end
    return false
end

function CityHatchEggOpenUIParameter:IsOnlyOneAndNotNew()
    if self.resultParam.result.RewardPets:Count() == 1 then
        local rewardPet = self.resultParam.result.RewardPets[1]
        local pet = ModuleRefer.PetModule:GetPetByID(rewardPet.PetCompId)
        if pet and pet.TypeIndex ~= 1 then
            return true
        end
    end
    return false
end

function CityHatchEggOpenUIParameter:GetEggIcon()
    local processCfg = ConfigRefer.CityWorkProcess:Find(self.recipeId or 0)
    if processCfg then
        local itemGroup = ConfigRefer.ItemGroup:Find(processCfg:Cost())
        local valid, icon = ItemGroupHelper.GetItemIcon(itemGroup)
        if valid then
            return icon
        end
    end

    return "sp_icon_item_pet_cap_shop_2"
end

return CityHatchEggOpenUIParameter