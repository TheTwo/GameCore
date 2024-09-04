local BaseCultivateCalcProvider = require("BaseCultivateCalcProvider")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CultivateCalcType = require("CultivateCalcType")
---@class PetRarityCultivateCalcProvider : BaseCultivateCalcProvider
local PetRarityCultivateCalcProvider = class("PetRarityCultivateCalcProvider", BaseCultivateCalcProvider)

local Rarity2Value = {
    [0] = 1,
    [1] = 2,
    [2] = 3,
    [3] = 4,
    [4] = 5
}

function PetRarityCultivateCalcProvider:CalcCultivateValue()
    if not self.preset then
        return 0
    end
    local ret = 0
    for _, hero in pairs(self.preset.Heroes) do
        local id = hero.PetCompId
        local petData = ModuleRefer.PetModule:GetPetByID(id)
        if petData then
            local petCfg = ConfigRefer.Pet:Find(petData.ConfigId)
            ret = ret + (Rarity2Value[petCfg:Rarity()] or 1)
        end
    end
    ret = (1 + self.levelCoeff) * ret
    return ret
end

return PetRarityCultivateCalcProvider