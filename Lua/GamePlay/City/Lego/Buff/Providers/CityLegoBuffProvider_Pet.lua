local CityLegoBuffProvider = require("CityLegoBuffProvider")
---@class CityLegoBuffProvider_Pet:CityLegoBuffProvider
---@field new fun():CityLegoBuffProvider_Pet
local CityLegoBuffProvider_Pet = class("CityLegoBuffProvider_Pet", CityLegoBuffProvider)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityLegoBuffProviderType = require("CityLegoBuffProviderType")
local ArtResourceUtils = require("ArtResourceUtils")

---@param petId number
---@param calculator CityLegoBuffCalculatorWds
function CityLegoBuffProvider_Pet:ctor(petId, calculator)
    CityLegoBuffProvider.ctor(self)
    self.petId = petId
    self.calculator = calculator
    local pet = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetInfos[petId]
    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    for i = 1, petCfg:RoomTagsLength() do
        local tagId = petCfg:RoomTags(i)
        self.tagMap[tagId] = (self.tagMap[tagId] or 0) + 1
    end
end

function CityLegoBuffProvider_Pet:GetTagCount(tagId)
    return self.tagMap[tagId] or 0
end

function CityLegoBuffProvider_Pet:GetType()
    return CityLegoBuffProviderType.Pet
end

function CityLegoBuffProvider_Pet:GetImage()
    local pet = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerPet.PetInfos[self.petId]
    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    return ArtResourceUtils.GetItem(petCfg:Icon())
end

return CityLegoBuffProvider_Pet