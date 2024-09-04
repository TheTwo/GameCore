local BaseUIComponent = require ('BaseUIComponent')
local CityProcessV2UIMatConvertRecipeData = require("CityProcessV2UIMatConvertRecipeData")
local CityProcessV2UIRecipeData = require("CityProcessV2UIRecipeData")

---@class CityProcessV2UINormalRecipeList:BaseUIComponent
local CityProcessV2UINormalRecipeList = class('CityProcessV2UINormalRecipeList', BaseUIComponent)

function CityProcessV2UINormalRecipeList:OnCreate()
    ---@see CityWorkProcessUIRecipeItem
    self._p_table_process = self:TableViewPro("p_table_process")
end

---@param data {param:CityProcessV2UIParameter}
function CityProcessV2UINormalRecipeList:OnFeedData(data)
    self.data = data

    if self.data.param:IsMakingMaterial() then
        self:UpdateMaterialRecipeList()
    else
        self:UpdateNormalRecipeList()
    end
end

function CityProcessV2UINormalRecipeList:UpdateMaterialRecipeList()
    self._p_table_process:Clear()
    local list = self.data.param:GetAllMaterialRecipe()
    for i, v in ipairs(list) do
        local data = CityProcessV2UIMatConvertRecipeData.new(v, self.data.param)
        self._p_table_process:AppendData(data)
    end
end

function CityProcessV2UINormalRecipeList:UpdateNormalRecipeList()
    self._p_table_process:Clear()
    local list = self.data.param:GetAllRecipe()
    for i, v in ipairs(list) do
        local data = CityProcessV2UIRecipeData.new(v, self.data.param)
        self._p_table_process:AppendData(data)
    end
end

return CityProcessV2UINormalRecipeList