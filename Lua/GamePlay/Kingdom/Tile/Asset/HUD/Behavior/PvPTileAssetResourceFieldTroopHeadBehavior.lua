---@class PvPTileAssetResourceFieldTroopHeadBehavior
---@field p_img_hero CS.U2DSpriteMesh
---@field p_icon_troop_state CS.U2DSpriteMesh
---@field p_base_troop CS.U2DSpriteMesh
---@field p_health_front CS.U2DSpriteMesh
---@field p_icon CS.DragonReborn.LuaBehaviour
local PvPTileAssetResourceFieldTroopHeadBehavior = class("PvPTileAssetResourceFieldTroopHeadBehavior")

function PvPTileAssetResourceFieldTroopHeadBehavior:SetIcon(icon)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_img_hero)
end

function PvPTileAssetResourceFieldTroopHeadBehavior:SetStateIcon(icon, baseIcon)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_troop_state)
    g_Game.SpriteManager:LoadSpriteAsync(baseIcon, self.p_base_troop)
end

function PvPTileAssetResourceFieldTroopHeadBehavior:SetHP(ratio)
    self.p_health_front.fillAmount = ratio
end

function PvPTileAssetResourceFieldTroopHeadBehavior:SetClick(click)
    ---@type MapUITrigger
    local trigger = self.p_icon.Instance
    trigger:SetTrigger(click)
end

return PvPTileAssetResourceFieldTroopHeadBehavior