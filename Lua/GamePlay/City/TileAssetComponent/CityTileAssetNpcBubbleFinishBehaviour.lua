
local CityTileAsset = require("CityTileAsset")

---@class CityTileAssetNpcBubbleFinishBehaviour:CityTileAsset
---@field new fun():CityTileAssetNpcBubbleFinishBehaviour
---@field super CityTileAsset
---@field p_icon_status CS.U2DSpriteMesh
---@field p_click_trigger CS.DragonReborn.LuaBehaviour
local CityTileAssetNpcBubbleFinishBehaviour = class('CityTileAssetNpcBubbleFinishBehaviour', CityTileAsset)

function CityTileAssetNpcBubbleFinishBehaviour:SetupIcon(icon)
    if not string.IsNullOrEmpty(icon) then
        g_Game.SpriteManager:LoadSpriteAsync(icon, self.p_icon_status)
    end
end

---@param tile CityTileBase
function CityTileAssetNpcBubbleFinishBehaviour:SetupClickTrigger(callback, tile, isUI)
    ---@type CityTrigger
    local cityTrigger = self.p_click_trigger.Instance
    if cityTrigger then
        cityTrigger:SetOnTrigger(callback, tile, isUI)
    end
end

return CityTileAssetNpcBubbleFinishBehaviour