---@class CityProcessV2UIMatConvertRecipeData
---@field new fun():CityProcessV2UIMatConvertRecipeData
local CityProcessV2UIMatConvertRecipeData = class("CityProcessV2UIMatConvertRecipeData")
local ConfigRefer = require("ConfigRefer")

---@param matConvertProcessCfg CityWorkMatConvertProcessConfigCell
---@param param CityMaterialProcessV2UIParameter
function CityProcessV2UIMatConvertRecipeData:ctor(matConvertProcessCfg, param)
    self.matConvertProcessCfg = matConvertProcessCfg
    self.param = param
end

---@return ItemIconData
function CityProcessV2UIMatConvertRecipeData:GetItemIconData()
    if self.matConvertProcessCfg:RecipesLength() == 0 then
        return nil
    end

    local recipeId = self.param:GetFirstRecipeIdInConvertCfg(self.matConvertProcessCfg)
    local recipeCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
    if recipeCfg then
        local itemCfg = ConfigRefer.Item:Find(recipeCfg:Output())
        return {configCell = itemCfg, showCount = false, showRecommend = false, showSelect = self.param:IsMatConvertRecipeSelected(self.matConvertProcessCfg:Id()), onClick = function()
            if self.param:IsMatConvertRecipeSelected(self.matConvertProcessCfg:Id()) then return end
            self.param:SelectMatConvertRecipe(self.matConvertProcessCfg)
        end}
    end
    return nil
end

function CityProcessV2UIMatConvertRecipeData:IsUndergoing()
    if self.param:IsUndergoing() then
        local info = self.param:GetProcessInfo()
        return self.matConvertProcessCfg:Id() == self.param:GetConvertCfgIdByRecipeId(info.ConfigId)
    end
    return false
end

function CityProcessV2UIMatConvertRecipeData:IsWaitClaim()
    if self.param:IsWaitClaim() then
        local info = self.param:GetProcessInfo()
        return self.matConvertProcessCfg:Id() == self.param:GetConvertCfgIdByRecipeId(info.ConfigId)
    end
    return false
end

return CityProcessV2UIMatConvertRecipeData