local ConfigRefer = require("ConfigRefer")
local BaseTableViewProCell = require ('BaseTableViewProCell')
---@class CityBuildUpgradeNewFurnitureCell:BaseTableViewProCell
local CityBuildUpgradeNewFurnitureCell = class('CityBuildUpgradeNewFurnitureCell', BaseTableViewProCell)

---@class CityBuildUpgradeNewFurnitureCellData
---@field id number Id-CityFurnitureLevelConfigCell
---@field from number 升级前可放置数量, 为0时代表新解锁
---@field to number 升级后可放置数量

function CityBuildUpgradeNewFurnitureCell:OnCreate()
    self._p_img_building = self:Image("p_img_building")

    ---数量提升---
    self._p_quantity = self:GameObject("p_quantity")
    self._p_text_add_now = self:Text("p_text_add_now")
    self._p_text_add_after = self:Text("p_text_add_after")

    ---新解锁---
    self._p_icon_unlock = self:GameObject("p_icon_unlock")
    self._p_reddot = self:GameObject("p_reddot")
    self._p_text_new = self:Text("p_text_new", "NEW")
end

---@param data CityBuildUpgradeNewFurnitureCellData
function CityBuildUpgradeNewFurnitureCell:OnFeedData(data)
    self.data = data    
    local typCell = ConfigRefer.CityFurnitureTypes:Find(data.id)
    g_Game.SpriteManager:LoadSprite(typCell:Image(), self._p_img_building)
    
    local isNew = data.from == 0
    self._p_quantity:SetActive(not isNew)
    self._p_icon_unlock:SetActive(isNew)
    self._p_reddot:SetActive(isNew)
    if not isNew then
        self._p_text_add_now.text = tostring(data.from)
        self._p_text_add_after.text = tostring(data.to)
    end
end

return CityBuildUpgradeNewFurnitureCell