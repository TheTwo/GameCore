---@class FormulaItem
---@field new fun():FormulaItem
---@field p_icon_resource CS.U2DSpriteMesh
---@field p_icon_check CS.UnityEngine.GameObject
local FormulaItem = class("FormulaItem")

function FormulaItem:UpdateUI(icon, isPlaced)
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_resource)
    self.p_icon_check:SetActive(isPlaced)
end

return FormulaItem