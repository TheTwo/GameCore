local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityProcessV2UIFurnitureRecipeType:BaseTableViewProCell
local CityProcessV2UIFurnitureRecipeType = class('CityProcessV2UIFurnitureRecipeType', BaseTableViewProCell)

function CityProcessV2UIFurnitureRecipeType:OnCreate()
    self._p_btn_pet = self:Button("p_btn_pet", Delegate.GetOrCreate(self, self.OnClick))
    self._p_icon_n = self:Image("p_icon_n")
    self._p_icon = self:Image("p_icon")

    self._p_selected = self:GameObject("p_selected")

    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param data {category:number, param:CityProcessV2UIParameter}
function CityProcessV2UIFurnitureRecipeType:OnFeedData(data)
    self.data = data

    local icon = "sp_comp_icon_city"
    for i = 1, ConfigRefer.CityConfig:CityFurnitureCategoryUILength() do
        local info = ConfigRefer.CityConfig:CityFurnitureCategoryUI(i)
        if info:Category() == data.category then
            icon = info:Image()
            break
        end
    end

    g_Game.SpriteManager:LoadSprite(icon, self._p_icon_n)
    g_Game.SpriteManager:LoadSprite(icon, self._p_icon)
    self._p_selected:SetActive(data.param:IsFurnitureCategorySelected(data.category))
end

function CityProcessV2UIFurnitureRecipeType:OnClick()
    self.data.param:SelectFurnitureCategory(self.data.category)
end

return CityProcessV2UIFurnitureRecipeType