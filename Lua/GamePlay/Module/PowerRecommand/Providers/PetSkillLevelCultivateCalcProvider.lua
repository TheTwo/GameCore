local BaseCultivateCalcProvider = require("BaseCultivateCalcProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CultivateCalcType = require("CultivateCalcType")
---@class PetSkillLevelCultivateCalcProvider : BaseCultivateCalcProvider
local PetSkillLevelCultivateCalcProvider = class("PetSkillLevelCultivateCalcProvider", BaseCultivateCalcProvider)

function PetSkillLevelCultivateCalcProvider:CalcCultivateValue()
    if not self.preset then
        return 0
    end
    local ret = 0
    for _, hero in pairs(self.preset.Heroes) do
        local id = hero.PetCompId
        local petData = ModuleRefer.PetModule:GetPetByID(id)
        if petData then
            for _, skillId in pairs(petData.PetInfoWrapper.LearnedSkill) do
                if skillId <= 0 then goto continue end
                local lvl = ModuleRefer.PetModule:GetSkillLevel(id, false, skillId)
                local quality = ConfigRefer.PetLearnableSkill:Find(skillId):Quality() + 1
                ret = ret + quality
                ret = ret + self.levelCoeff * lvl * quality
                ::continue::
            end
        end
    end
    return ret
end

return PetSkillLevelCultivateCalcProvider