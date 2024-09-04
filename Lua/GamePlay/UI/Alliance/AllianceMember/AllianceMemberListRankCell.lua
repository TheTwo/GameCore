local AllianceModuleDefine = require("AllianceModuleDefine")
local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceMemberListRankCell:BaseTableViewProCell
---@field new fun():AllianceMemberListRankCell
---@field super BaseTableViewProCell
local AllianceMemberListRankCell = class('AllianceMemberListRankCell', BaseTableViewProCell)

function AllianceMemberListRankCell:OnCreate(param)
    self._p_base_position = self:Image("p_base_position")
    self._p_icon_position = self:Image("p_icon_position")
    self._p_text_position = self:Text("p_text_position")
    self._p_quantity_member = self:GameObject("p_quantity_member")
    self._p_text_quantity_member = self:Text("p_text_quantity_member")
    self._p_click_rect = self:Button("p_click_rect", Delegate.GetOrCreate(self, self.OnClickSelf))
end

---@param data AllianceMemberListRankCellData
function AllianceMemberListRankCell:OnFeedData(data)
    self._data = data
    self._p_quantity_member:SetVisible(data.Rank ~= AllianceModuleDefine.LeaderRank)
    local color = AllianceModuleDefine.RColor[data.Rank] or AllianceModuleDefine.DefaultRColor
    if data.Rank ~= AllianceModuleDefine.LeaderRank then
        if data.max < 0 then
            self._p_text_quantity_member.text = string.format("%s", data.count)
        else
            self._p_text_quantity_member.text = string.format("%s/%s", data.count, data.max or 0)
        end
    end
    self._p_base_position.color = color
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetRankIcon(data.Rank), self._p_icon_position)
    self._p_text_position.text = AllianceModuleDefine.GetRankName(data.Rank)
end

function AllianceMemberListRankCell:OnClickSelf()
    self._data:SetExpanded(not self._data:IsExpanded())
    self:GetTableViewPro():UpdateData(self._data)
end

return AllianceMemberListRankCell