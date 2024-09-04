local ModuleRefer = require("ModuleRefer")
local ColorUtility = CS.UnityEngine.ColorUtility

---@class PvPTileAssetHUDFightingBehavior
---@field icon_l CS.U2DSpriteMesh
---@field icon_r CS.U2DSpriteMesh
---@field trigger CS.FpAnimation.FpAnimationCommonTrigger
local PvPTileAssetHUDFightingBehavior = class("PvPTileAssetHUDFightingBehavior")

function PvPTileAssetHUDFightingBehavior:SetColor(isDeclaredByMyAlliance)
    local _, blue = ColorUtility.TryParseHtmlString("#84D8FF")
    local _, red = ColorUtility.TryParseHtmlString("#E03B2A")

    if isDeclaredByMyAlliance then
        self.icon_l.color = blue
        self.icon_r.color = blue
    else
        self.icon_l.color = red
        self.icon_r.color = red
    end
    self.icon_l:UpdateImmediate()
    self.icon_r:UpdateImmediate()
end

function PvPTileAssetHUDFightingBehavior:VXTrigger()
    self.trigger:PlayAll(CS.FpAnimation.CommonTriggerType.OnEnable)
end

return PvPTileAssetHUDFightingBehavior