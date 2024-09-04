local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")
local ArtResourceUtils = require("ArtResourceUtils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceFlagSetupAppearanceCell:BaseTableViewProCell
---@field new fun():AllianceFlagSetupAppearanceCell
---@field super BaseTableViewProCell
local AllianceFlagSetupAppearanceCell = class('AllianceFlagSetupAppearanceCell', BaseTableViewProCell)

function AllianceFlagSetupAppearanceCell:OnCreate(data)
    self._p_btn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_icon = self:Image("p_icon")
    self._p_img_select_logo = self:Image("p_img_select")
end

---@param data AllianceBadgeAppearanceConfigCell
function AllianceFlagSetupAppearanceCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(data:Asset()), self._p_icon)
end

function AllianceFlagSetupAppearanceCell:Select(param)
    self._p_img_select_logo:SetVisible(true)
end

function AllianceFlagSetupAppearanceCell:UnSelect(param)
    self._p_img_select_logo:SetVisible(false)
end

function AllianceFlagSetupAppearanceCell:OnClickSelf()
    self:SelectSelf()
end

return AllianceFlagSetupAppearanceCell