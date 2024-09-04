---@class CityPetEatFoodUIParametor
---@field new fun():CityPetEatFoodUIParametor
local CityPetEatFoodUIParametor = class("CityPetEatFoodUIParametor")
local NumberFormatter = require("NumberFormatter")
local I18N = require("I18N")

function CityPetEatFoodUIParametor:ctor(petIds, count)
    self.petIds = {}
    if petIds then
        for i = 1, #petIds do
            self.petIds[i] = petIds[i]
        end
    end
    self.count = count or 0
end

function CityPetEatFoodUIParametor:AddPetEat(petId, count)
    table.insert(self.petIds, petId)
    self.count = self.count + count
    return self
end

function CityPetEatFoodUIParametor:GetEatingFoodPetIds()
    return self.petIds
end

function CityPetEatFoodUIParametor:GetEatFoodHint()
    return I18N.Get("animal_work_eat_toast")
end

function CityPetEatFoodUIParametor:GetEatFoodCountText()
    return NumberFormatter.Normal(self.count)
end

return CityPetEatFoodUIParametor