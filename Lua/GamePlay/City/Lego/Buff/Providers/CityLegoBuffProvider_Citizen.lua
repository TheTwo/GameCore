local CityLegoBuffProvider = require("CityLegoBuffProvider")
---@class CityLegoBuffProvider_Citizen:CityLegoBuffProvider
---@field new fun():CityLegoBuffProvider_Citizen
local CityLegoBuffProvider_Citizen = class("CityLegoBuffProvider_Citizen", CityLegoBuffProvider)
local ConfigRefer = require("ConfigRefer")
local CityLegoBuffProviderType = require("CityLegoBuffProviderType")
local ArtResourceUtils = require("ArtResourceUtils")

---@param citizenId number
---@param calculator CityLegoBuffCalculatorWds
function CityLegoBuffProvider_Citizen:ctor(citizenId, calculator)
    CityLegoBuffProvider.ctor(self)
    self.citizenId = citizenId
    self.calculator = calculator

    local castleCitizen = self.calculator.city:GetCastle().CastleCitizens[self.citizenId]
    local citizenCfg = ConfigRefer.Citizen:Find(castleCitizen.ConfigId)
    local heroCfg = ConfigRefer.Heroes:Find(citizenCfg:HeroId())
    for i = 1, heroCfg:RoomTagsLength() do
        local tagId = heroCfg:RoomTags(i)
        self.tagMap[tagId] = (self.tagMap[tagId] or 0) + 1
    end
end

function CityLegoBuffProvider_Citizen:GetTagCount(tagId)
    return self.tagMap[tagId] or 0
end

function CityLegoBuffProvider_Citizen:GetType()
    return CityLegoBuffProviderType.Citizen
end

function CityLegoBuffProvider_Citizen:GetImage()
    local castleCitizen = self.calculator.city:GetCastle().CastleCitizens[self.citizenId]
    local citizenCfg = ConfigRefer.Citizen:Find(castleCitizen.ConfigId)
    return ArtResourceUtils.GetItem(citizenCfg:CharacterImage())
end

return CityLegoBuffProvider_Citizen