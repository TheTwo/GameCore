---@class UI3DButton
---@field trigger CS.DragonReborn.LuaBehaviour
---@field collider CS.UnityEngine.BoxCollider
---@field icon CS.U2DSpriteMesh
---@field text CS.U2DTextMesh
local UI3DButton = sealedClass("UI3DButton")

function UI3DButton:EnableTrigger(flag)
    self.collider.enabled = flag
end

function UI3DButton:SetOnTrigger(callback, tile, blockRaycast)
    self.trigger.Instance:SetOnTrigger(callback, tile, blockRaycast)
end

function UI3DButton:SetIcon(path)
    g_Game.SpriteManager:LoadSprite(path, self.icon)
end

function UI3DButton:SetText(text)
    self.text.text = text
end

return UI3DButton