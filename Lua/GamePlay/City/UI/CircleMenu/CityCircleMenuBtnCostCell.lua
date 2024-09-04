local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityCircleMenuBtnCostCell:BaseTableViewProCell
local CityCircleMenuBtnCostCell = class('CityCircleMenuBtnCostCell', BaseTableViewProCell)

function CityCircleMenuBtnCostCell:OnCreate()
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_quantity = self:Text("p_text_quantity")
end

---@alias ImageTextPair {image:string, text:string}
---@param data ImageTextPair
function CityCircleMenuBtnCostCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.image, self._p_icon_item)
    self._p_text_quantity.text = data.text
end

return CityCircleMenuBtnCostCell