local BaseTableViewProCell = require ('BaseTableViewProCell')
---@class CityBuildUpgradeSuccCell:BaseTableViewProCell
local CityBuildUpgradeSuccCell = class('CityBuildUpgradeSuccCell', BaseTableViewProCell)

---@class CityBuildUpgradeNewFurnitureCellData
---@field id number Id-CityFurnitureLevelConfigCell
---@field from number 升级前可放置数量, 为0时代表新解锁
---@field to number 升级后可放置数量

function CityBuildUpgradeSuccCell:OnCreate()
    self.imgIcon = self:Image('p_icon')
    self.textName = self:Text('p_text_name')
    self.textNum = self:Text('p_text_num')
    self.goType = self:GameObject('p_type')
end

---@param data CityBuildUpgradeNewFurnitureCellData
function CityBuildUpgradeSuccCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIcon)
    self.textName.text = data.name
    if data.textNum then
        self.textNum.text = data.textNum
    end
    self.textNum.gameObject:SetActive(data.textNum ~= nil)
    self.goType:SetActive(data.isNew == true)
end

return CityBuildUpgradeSuccCell