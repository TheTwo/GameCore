local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityProcessV2UINormalRecipe:BaseTableViewProCell
local CityProcessV2UINormalRecipe = class('CityProcessV2UINormalRecipe', BaseTableViewProCell)


function CityProcessV2UINormalRecipe:OnCreate()
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_item_empty = self:GameObject("p_item_empty")
    self._p_item_production = self:GameObject("p_item_production")
    self._p_item_finish = self:GameObject("p_item_finish")
end

---@param data CityProcessV2UIRecipeData|CityProcessV2UIMatConvertRecipeData
function CityProcessV2UINormalRecipe:OnFeedData(data)
    self.data = data
    self._child_item_standard_s:FeedData(data:GetItemIconData())
    self._p_item_production:SetActive(data:IsUndergoing())
    self._p_item_finish:SetActive(data:IsWaitClaim())
end

return CityProcessV2UINormalRecipe