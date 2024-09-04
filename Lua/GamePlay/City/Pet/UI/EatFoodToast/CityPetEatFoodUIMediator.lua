---Scene Name : scene_toast_pet_eat
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require("Delegate")
local TimerUtility = require("TimerUtility")

---@class CityPetEatFoodUIMediator:BaseUIMediator
local CityPetEatFoodUIMediator = class('CityPetEatFoodUIMediator', BaseUIMediator)

function CityPetEatFoodUIMediator:OnCreate()
    ---@type CommonPetIconSmall
    self._child_card_pet_circle_2 = self:LuaObject("child_card_pet_circle_2")
    self._p_mask = self:GameObject("p_mask")
    ---@type CommonPetIconSmall
    self._child_card_pet_circle_1 = self:LuaObject("child_card_pet_circle_1")

    self._p_text_eat = self:Text("p_text_eat")
    self._p_text_food = self:Text("p_text_food")
end

---@param param CityPetEatFoodUIParametor
function CityPetEatFoodUIMediator:OnOpened(param)
    self.param = param

    local petIds = param:GetEatingFoodPetIds()
    self._child_card_pet_circle_1:SetVisible(#petIds >= 1)
    self._child_card_pet_circle_2:SetVisible(#petIds >= 2)
    self._p_mask:SetActive(#petIds >= 2)

    if #petIds >= 1 then
        local pet = ModuleRefer.PetModule:GetPetByID(petIds[1])
        ---@type CommonPetIconBaseData
        local info = {
            id = petIds[1],
            cfgId = pet.ConfigId,
            onClick = nil,
            selected = false,
            level = pet.Level,
            rank = pet.RankLevel,
        }
        self._child_card_pet_circle_1:FeedData(info)
    end

    if #petIds >= 2 then
        local pet = ModuleRefer.PetModule:GetPetByID(petIds[2])
        ---@type CommonPetIconBaseData
        local info = {
            id = petIds[2],
            cfgId = pet.ConfigId,
            onClick = nil,
            selected = false,
            level = pet.Level,
            rank = pet.RankLevel,
        }
        self._child_card_pet_circle_2:FeedData(info)
    end

    self._p_text_eat.text = param:GetEatFoodHint()
    self._p_text_food.text = param:GetEatFoodCountText()

    TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.CloseSelf), 2)
end

return CityPetEatFoodUIMediator