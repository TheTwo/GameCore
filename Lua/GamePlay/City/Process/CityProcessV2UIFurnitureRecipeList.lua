local BaseUIComponent = require ('BaseUIComponent')
local CityProcessV2UIRecipeData = require('CityProcessV2UIRecipeData')
local FurnitureCategory = require("FurnitureCategory")
local ConfigRefer = require("ConfigRefer")

---@class CityProcessV2UIFurnitureRecipeList:BaseUIComponent
local CityProcessV2UIFurnitureRecipeList = class('CityProcessV2UIFurnitureRecipeList', BaseUIComponent)

function CityProcessV2UIFurnitureRecipeList:OnCreate()
    ---@see CityProcessV2UIFurnitureRecipeType
    self._p_table_type = self:TableViewPro("p_table_type")
    ---@see CityProcessV2UIFurnitureRecipe
    self._p_table_furniture = self:TableViewPro("p_table_furniture")
end

---@param data {param:CityProcessV2UIParameter}
function CityProcessV2UIFurnitureRecipeList:OnFeedData(data)
    self.data = data
    self._p_table_type:Clear(false, false)
    self._p_table_furniture:Clear(false, false)

    for name, category in pairs(FurnitureCategory) do
        for i = 1, ConfigRefer.CityConfig:CityFurnitureCategoryUILength() do
            local info = ConfigRefer.CityConfig:CityFurnitureCategoryUI(i)
            if info:Category() == category and data.param:HasAnyCategoryFurniture(category) then
                self._p_table_type:AppendData({category = category, param = data.param})
                break
            end
        end
    end

    for _, processCfg in pairs(self.data.param:GetAllFurnitureRecipes()) do
        local data = CityProcessV2UIRecipeData.new(processCfg, data.param)
        self._p_table_furniture:AppendData(data)
    end
end

return CityProcessV2UIFurnitureRecipeList