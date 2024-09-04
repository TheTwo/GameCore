local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceFlagSetupPatternCell:BaseTableViewProCell
---@field new fun():AllianceFlagSetupPatternCell
---@field super BaseTableViewProCell
local AllianceFlagSetupPatternCell = class('AllianceFlagSetupPatternCell', BaseTableViewProCell)

function AllianceFlagSetupPatternCell:OnCreate(data)
    self._p_btn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_icon = self:Image("p_icon")
    self._p_img_select_pattern = self:Image("p_img_select")
end

---@param data AllianceBadgePatternConfigCell
function AllianceFlagSetupPatternCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(data:Asset()), self._p_icon)
end

function AllianceFlagSetupPatternCell:Select(param)
    self._p_img_select_pattern:SetVisible(true)
end

function AllianceFlagSetupPatternCell:UnSelect(param)
    self._p_img_select_pattern:SetVisible(false)
end

function AllianceFlagSetupPatternCell:OnClickSelf()
    self:SelectSelf()
end

return AllianceFlagSetupPatternCell