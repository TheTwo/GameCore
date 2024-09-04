local Utils = require("Utils")

---@class LuaTextPicImageProvider
---@field new fun():LuaTextPicImageProvider
local LuaTextPicImageProvider = class('LuaTextPicImageProvider')

---@param spriteName string
---@param target CS.UnityEngine.UI.Image
---@return boolean,CS.UnityEngine.Vector2,CS.UnityEngine.Vector2
function LuaTextPicImageProvider:SetSpriteTextPicImage(spriteName, target)
    if Utils.IsNotNull(target) then
        g_Game.SpriteManager:LoadSprite(spriteName, target)
        return true,CS.UnityEngine.Vector2.zero,CS.UnityEngine.Vector2.one
    end
    return false,CS.UnityEngine.Vector2.zero,CS.UnityEngine.Vector2.one
end

return LuaTextPicImageProvider