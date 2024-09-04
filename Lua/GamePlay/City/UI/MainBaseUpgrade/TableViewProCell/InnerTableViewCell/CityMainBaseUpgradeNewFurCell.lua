local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityMainBaseUpgradeNewFurCell:BaseTableViewProCell
local CityMainBaseUpgradeNewFurCell = class('CityMainBaseUpgradeNewFurCell', BaseTableViewProCell)
local CityMainBaseUpgradeI18N = require("CityMainBaseUpgradeI18N")

function CityMainBaseUpgradeNewFurCell:OnCreate()
    self._p_icon = self:Image("p_icon")
    self._p_text_num_before = self:Text("p_text_num_before")
    self._p_text_num = self:Text("p_text_num")
    -- self._p_text_new = self:Text("p_text_new")
end

---@param data FurnitureLevelUnlock
function CityMainBaseUpgradeNewFurCell:OnFeedData(data)
    local furnitureCfg = ConfigRefer.CityFurnitureTypes:Find(data:Type())
    g_Game.SpriteManager:LoadSprite(furnitureCfg:Image(), self._p_icon)

    self._p_text_num.text = tostring(data:To())
    self._p_text_num_before.text = tostring(data:From())
    -- self._p_text_new.text = I18N.Get(ConfigRefer.CityFurnitureTypes:Find(data:Type()):Name())
end

return CityMainBaseUpgradeNewFurCell