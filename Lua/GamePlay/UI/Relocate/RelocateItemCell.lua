local BaseUIComponent = require ('BaseUIComponent')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class RelocateItemCell:BaseUIComponent
local RelocateItemCell = class('RelocateItemCell', BaseUIComponent)

---@class RelocateItemParam
---@field id number

function RelocateItemCell:OnCreate()
    self._p_img_select = self:GameObject("p_img_select")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_icon_base = self:Image("base")
end

---@param data RelocateItemParam
function RelocateItemCell:OnFeedData(data)
    self.data = data
    local itemConfig = ConfigRefer.Item:Find(self.data.id)
    if not itemConfig then
        return
    end
    if not string.IsNullOrEmpty(itemConfig:BackIcon()) then
        g_Game.SpriteManager:LoadSprite(itemConfig:Icon(), self._p_icon_item)
    end
    if not string.IsNullOrEmpty(itemConfig:BackIcon()) then
        g_Game.SpriteManager:LoadSprite(itemConfig:BackIcon(), self._p_icon_base)
    end
    self._p_img_select:SetActive(false)
end

function RelocateItemCell:Selected()
    self._p_img_select:SetActive(true)
end

function RelocateItemCell:Unselected()
    self._p_img_select:SetActive(false)
end

return RelocateItemCell