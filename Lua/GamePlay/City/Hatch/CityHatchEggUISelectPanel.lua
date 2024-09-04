local BaseUIComponent = require ('BaseUIComponent')
local CityHatchEggUICellData = require('CityHatchEggUICellData')
local CityHatchI18N = require('CityHatchI18N')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityHatchEggUISelectPanel:BaseUIComponent
local CityHatchEggUISelectPanel = class('CityHatchEggUISelectPanel', BaseUIComponent)

function CityHatchEggUISelectPanel:OnCreate()
    ---@see CityHatchEggUICell
    self._p_table_egg = self:TableViewPro("p_table_egg")

    self._pading_attribute = self:GameObject("pading_attribute")
    self._p_btn_all = self:Button("p_btn_all", Delegate.GetOrCreate(self, self.OnClickTypeAll))

    self._p_text_choose = self:Text("p_text_choose", "animal_work_interface_desc17")
    self._p_close = self:Button("p_close", Delegate.GetOrCreate(self, self.OnClickClose))
    -- self._p_close:SetVisible(false)

    self._p_group_empty = self:GameObject("p_group_empty")
    self._p_text_egg_empty = self:Text("p_text_egg_empty", CityHatchI18N.UIHint_NoEggCanBeHatched)
    self._p_btn_empty_goto = self:Button("p_btn_empty_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
end

---@param data CityHatchEggUIParameter
function CityHatchEggUISelectPanel:OnFeedData(data)
    self.param = data

    self._p_table_egg:Clear(false, false, false)
    self.recipeCount = 0
    if self.param:OnlyShowCanHatchImmediately() then
        local unlockedRecipes, _ = self.param:GetAllRecipeOrdered()
        for i, v in ipairs(unlockedRecipes) do
            if self.param:GetTargetRecipeOriginCostTime(v) <= 0 and self.param:GetCostEnoughTimes(v) > 0 then
                local data = CityHatchEggUICellData.new(v, self.param)
                self._p_table_egg:AppendData(data)
                self.recipeCount = self.recipeCount + 1
            end
        end
    else
        for i, v in ipairs(self.param:GetAllRecipe()) do
            if self.param:GetCostEnoughTimes(v) > 0 then
                local data = CityHatchEggUICellData.new(v, self.param)
                self._p_table_egg:AppendData(data)
                self.recipeCount = self.recipeCount + 1
            end
        end
    end

    self._p_group_empty:SetActive(self.recipeCount == 0)
    self._p_text_choose:SetVisible(self.recipeCount > 0)
end

function CityHatchEggUISelectPanel:RefreshTable()
    self._p_table_egg:UpdateOnlyAllDataImmediately()
end

function CityHatchEggUISelectPanel:OnClickClose()
    self.param:CloseSelectPanel()
end

function CityHatchEggUISelectPanel:OnClickGoto()
    self.param.city.petManager:GotoEarnPetEgg()
end

return CityHatchEggUISelectPanel