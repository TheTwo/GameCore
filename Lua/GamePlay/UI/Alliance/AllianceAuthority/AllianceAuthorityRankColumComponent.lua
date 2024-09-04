local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceAuthorityRankColumComponent:BaseUIComponent
---@field new fun():AllianceAuthorityRankColumComponent
---@field super BaseUIComponent
local AllianceAuthorityRankColumComponent = class('AllianceAuthorityRankColumComponent', BaseUIComponent)

function AllianceAuthorityRankColumComponent:OnCreate(param)
    self._p_icon = self:Image("p_icon")
    self._p_text = self:Text("p_text")
end

---@param rank number
function AllianceAuthorityRankColumComponent:OnFeedData(rank)
    self._p_text.text = AllianceModuleDefine.GetRankName(rank)
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetRankIcon(rank), self._p_icon)
end

return AllianceAuthorityRankColumComponent