local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityHatchEggUICell:BaseTableViewProCell
local CityHatchEggUICell = class('CityHatchEggUICell', BaseTableViewProCell)

function CityHatchEggUICell:OnCreate()
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_img_selected = self:GameObject("p_img_selected")
    self._p_btn_item = self:Button("p_btn_item", Delegate.GetOrCreate(self, self.OnClick))
end

---@param data CityHatchEggUICellData
function CityHatchEggUICell:OnFeedData(data)
    self.data = data

    local output = ConfigRefer.Item:Find(data.processCfg:Output())
    self._child_item_standard_s:FeedData(
    ---@type ItemIconData
    {
        configCell = output,
        showCount = true,
        count = self.data.param:GetCostEnoughTimes(data.processCfg),
        showRecommend = false,
        onClick = Delegate.GetOrCreate(self, self.OnClick),
        isEggCrack = self.data.param:GetTargetRecipeOriginCostTime(data.processCfg) <= 0
    })
    self._p_text_name.text = I18N.Get(output:NameKey())
    self._p_img_selected:SetActive(self.data.param:IsRecipeSelected(data.processCfg))
end

function CityHatchEggUICell:OnClick()
    if self.data.isTipsCell then
        self.data.param:SelectRecipeInOwnedEggsTips(self.data.processCfg)
    else
        self.data.param:SelectRecipe(self.data.processCfg)
    end
end

return CityHatchEggUICell