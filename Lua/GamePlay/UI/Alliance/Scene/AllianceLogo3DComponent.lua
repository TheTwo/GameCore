local AllianceModuleDefine = require("AllianceModuleDefine")
local Utils = require("Utils")

---@class AllianceLogo3DComponent
---@field spriteBackground CS.U2DSpriteMesh
---@field spriteIcon CS.U2DSpriteMesh
local AllianceLogo3DComponent = class("AllianceLogo3DComponent")

---@param appear number
---@param pattern number
function AllianceLogo3DComponent:FeedDataValue(appear, pattern)
    self.appearance, self.pattern, _ = AllianceModuleDefine.GetAllianceFlagDetailByValue(appear, pattern, 0)
    if Utils.IsNotNull(self.spriteBackground) then
        g_Game.SpriteManager:LoadSprite(self.appearance, self.spriteBackground)
    end
    if Utils.IsNotNull(self.spriteIcon) then
        g_Game.SpriteManager:LoadSprite(self.pattern, self.spriteIcon)
    end
end

return AllianceLogo3DComponent