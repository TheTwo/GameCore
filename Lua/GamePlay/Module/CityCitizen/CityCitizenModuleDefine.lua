---@class CityCitizenModuleDefine
local CityCitizenModuleDefine = {}
CityCitizenModuleDefine.FormulaKeyFormat = "CityFurnitureProcessFormula_%d"
CityCitizenModuleDefine.SaveKeyFormat = "PLAYER_%d_CITY_PROCESS_FORMULA_CHECKED"

---@param id number
---@return string
function CityCitizenModuleDefine.GetNotifyFormulaKey(id)
    return string.format(CityCitizenModuleDefine.FormulaKeyFormat, id)
end

return CityCitizenModuleDefine

