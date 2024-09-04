local BaseCultivateCalcProvider = require("BaseCultivateCalcProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CultivateCalcType = require("CultivateCalcType")
---@class HeroQualityCultivateCalcProvider : BaseCultivateCalcProvider
local HeroQualityCultivateCalcProvider = class("HeroQualityCultivateCalcProvider", BaseCultivateCalcProvider)

function HeroQualityCultivateCalcProvider:CalcCultivateValue()
    if not self.preset then
        return 0
    end
    local ret = 0
    for _, hero in pairs(self.preset.Heroes) do
        if hero.HeroCfgID > 0 then
            ret = ret + math.max(ConfigRefer.Heroes:Find(hero.HeroCfgID):Quality(), 1)
        end
    end
    return ret
end

return HeroQualityCultivateCalcProvider