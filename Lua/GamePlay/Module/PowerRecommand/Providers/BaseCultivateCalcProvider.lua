---@class BaseCultivateCalcProvider
local BaseCultivateCalcProvider = class("BaseCultivateCalcProvider")

---@param preset wds.TroopPreset
---@param calcType number
---@param levelCoeff number
function BaseCultivateCalcProvider:ctor(preset, calcType, levelCoeff)
    self.preset = preset
    self.calcType = calcType
    self.levelCoeff = levelCoeff
end

function BaseCultivateCalcProvider:CalcCultivateValue()
    return 0
end

return BaseCultivateCalcProvider