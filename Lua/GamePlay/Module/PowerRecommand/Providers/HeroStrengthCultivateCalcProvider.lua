local BaseCultivateCalcProvider = require("BaseCultivateCalcProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CultivateCalcType = require("CultivateCalcType")
---@class HeroStrengthCultivateCalcProvider : BaseCultivateCalcProvider
local HeroStrengthCultivateCalcProvider = class("HeroStrengthCultivateCalcProvider", BaseCultivateCalcProvider)

function HeroStrengthCultivateCalcProvider:CalcCultivateValue()
    if not self.preset then
        return 0
    end
    local ret = 0
    for _, hero in pairs(self.preset.Heroes) do
        local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(hero.HeroCfgID)
        if heroData then
            ret = ret + heroData.dbData.StarLevel
        end
    end
    return ret
end

return HeroStrengthCultivateCalcProvider