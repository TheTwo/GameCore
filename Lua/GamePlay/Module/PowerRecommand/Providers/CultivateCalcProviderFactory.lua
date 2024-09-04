local HeroLevelCultivateCalcProvider = require("HeroLevelCultivateCalcProvider")
local HeroStrengthCultivateCalcProvider = require("HeroStrengthCultivateCalcProvider")
local HeroQualityCultivateCalcProvider = require("HeroQualityCultivateCalcProvider")
local PetLevelCultivateCalcProvider = require("PetLevelCultivateCalcProvider")
local PetRarityCultivateCalcProvider = require("PetRarityCultivateCalcProvider")
local PetSkillLevelCultivateCalcProvider = require("PetSkillLevelCultivateCalcProvider")
local CultivateCalcKeys = require("CultivateCalcKeys")
---@class CultivateCalcProviderFactory
local CultivateCalcProviderFactory = class("CultivateCalcProviderFactory")

---@param cultivateType number
---@param preset wds.TroopPreset
---@param calcType number
---@param levelCoeff number
---@return BaseCultivateCalcProvider
function CultivateCalcProviderFactory.CreateProvider(cultivateType, preset, calcType, levelCoeff)
    if cultivateType == CultivateCalcKeys.HeroLevel then
        return HeroLevelCultivateCalcProvider.new(preset, calcType, levelCoeff)
    elseif cultivateType == CultivateCalcKeys.HeroStrengthLevel then
        return HeroStrengthCultivateCalcProvider.new(preset, calcType, levelCoeff)
    elseif cultivateType == CultivateCalcKeys.HeroQuality then
        return HeroQualityCultivateCalcProvider.new(preset, calcType, levelCoeff)
    elseif cultivateType == CultivateCalcKeys.PetLevel then
        return PetLevelCultivateCalcProvider.new(preset, calcType, levelCoeff)
    elseif cultivateType == CultivateCalcKeys.PetRarity then
        return PetRarityCultivateCalcProvider.new(preset, calcType, levelCoeff)
    elseif cultivateType == CultivateCalcKeys.PetSkill then
        return PetSkillLevelCultivateCalcProvider.new(preset, calcType, levelCoeff)
    end
    return nil
end

return CultivateCalcProviderFactory