local BaseCultivateCalcProvider = require("BaseCultivateCalcProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CultivateCalcType = require("CultivateCalcType")
---@class PetLevelCultivateCalcProvider : BaseCultivateCalcProvider
local PetLevelCultivateCalcProvider = class("PetLevelCultivateCalcProvider", BaseCultivateCalcProvider)

function PetLevelCultivateCalcProvider:CalcCultivateValue()
    if not self.preset then
        return 0
    end
    local ret = 0
    for _, hero in pairs(self.preset.Heroes) do
        local id = hero.PetCompId
        local petData = ModuleRefer.PetModule:GetPetByID(id)
        if petData then
            ret = ret + petData.Level
        end
    end
    return ret
end

return PetLevelCultivateCalcProvider