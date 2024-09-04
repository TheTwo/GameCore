local Utils = require("Utils")

---@class PlayerTileAssetHUDBehavior
---@field p_trigger CS.DragonReborn.LuaBehaviour
---@field p_icon CS.U2DSpriteMesh
---@field p_bubble CS.U2DSpriteMesh
---@field p_frame CS.U2DSpriteMesh
---@field p_light CS.U2DSpriteMesh
local PlayerTileAssetHUDBehavior = class("PlayerTileAssetHUDBehavior")

local QualityBubbleSprites =
{
    "sp_radar_img_bubble_01",
    "sp_radar_img_bubble_02",
    "sp_radar_img_bubble_03",
    "sp_radar_img_bubble_04",
    "sp_climbtower_img_bubble_2",
}

local QualityFrameSprites =
{
    "sp_radar_farme_01",
    "sp_radar_farme_02",
    "sp_radar_farme_03",
    "sp_radar_farme_04",
    "sp_climbtower_img_bubble_1",
}

local QualityLightSprites =
{
    "sp_radar_img_light_01",
    "sp_radar_img_light_02",
    "sp_radar_img_light_03",
    "sp_radar_img_light_04",
}

---@param enable boolean
function PlayerTileAssetHUDBehavior:EnableTrigger(enable)
    if Utils.IsNull(self.p_trigger) then return end
    ---@type MapUITrigger
    local trigger = self.p_trigger.Instance
    trigger:SetEnable(enable)
end

function PlayerTileAssetHUDBehavior:SetTrigger(callback)
    if Utils.IsNull(self.p_trigger) then return end
    self.p_trigger.Instance:SetTrigger(callback)
end

function PlayerTileAssetHUDBehavior:SetIcon(icon, refresh)
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon)
    if refresh then
        self.p_icon:UpdateImmediate()
    end
end

function PlayerTileAssetHUDBehavior:SetIconLod(icon, refresh)
    g_Game.SpriteManager:LoadSprite(icon, self.p_iconLod)
    if refresh then
        self.p_iconLod:UpdateImmediate()
    end
end

function PlayerTileAssetHUDBehavior:ShowBubble(state)
    -- self.p_bubble:SetVisible(state)
    self.goBubble:SetActive(state)
end

function PlayerTileAssetHUDBehavior:ShowLodIcon(state)
    -- self.p_frame:SetVisible(state)
    self.goLodIcon:SetActive(state)
end

---@param quality number
function PlayerTileAssetHUDBehavior:SetQuality(quality, refresh)
    if quality then
        self.p_light:SetVisible(true)
        quality = math.clamp(quality, 1, #QualityLightSprites)
        
        local lightSprite = QualityLightSprites[quality + 1]
        if not string.IsNullOrEmpty(lightSprite) then
            g_Game.SpriteManager:LoadSprite(lightSprite, self.p_light)
        end

        local bubbleSprite = QualityBubbleSprites[quality + 1]
        if not string.IsNullOrEmpty(bubbleSprite) then
            g_Game.SpriteManager:LoadSprite(bubbleSprite, self.p_bubble)
        end

        local frameSprite = QualityFrameSprites[quality + 1]
        if not string.IsNullOrEmpty(frameSprite) then
            g_Game.SpriteManager:LoadSprite(frameSprite, self.p_frame)
        end
        if refresh then
            self.p_light:UpdateImmediate()
        end
    else
        self.p_light:SetVisible(false)
    end
end

function PlayerTileAssetHUDBehavior:RefreshAll()
    self.p_icon:UpdateImmediate()
    self.p_bubble:UpdateImmediate()
    self.p_light:UpdateImmediate()
end

return PlayerTileAssetHUDBehavior