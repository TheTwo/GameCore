local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class TouchMenuCellPairSpecial:BaseUIComponent
---@field new fun():TouchMenuCellPairSpecial
---@field super BaseUIComponent
local TouchMenuCellPairSpecial = class('TouchMenuCellPairSpecial', BaseUIComponent)

function TouchMenuCellPairSpecial:OnCreate(param)
    self._p_icon = self:Image("p_icon")
    self._p_text = self:Text("p_text")
    self._p_text_1 = self:Text("p_text_1")
end

---@param data TouchMenuCellPairSpecialDatum
function TouchMenuCellPairSpecial:OnFeedData(data)
    self.data = data
    self.data:BindUICell(self)
end

function TouchMenuCellPairSpecial:OnClose()
    if self.data then
        self.data:UnbindUICell()
        self.data = nil
    end
end

function TouchMenuCellPairSpecial:UpdateLeftLabel(label)
    self._p_text.text = label
end

function TouchMenuCellPairSpecial:UpdateRightLabel(label)
    self._p_text_1.text = label
end

function TouchMenuCellPairSpecial:UpdateSprite(sprite)
    local show = not string.IsNullOrEmpty(sprite)
    self._p_icon:SetVisible(show)
    if show then
        g_Game.SpriteManager:LoadSprite(sprite, self._p_icon)
    end
end

return TouchMenuCellPairSpecial