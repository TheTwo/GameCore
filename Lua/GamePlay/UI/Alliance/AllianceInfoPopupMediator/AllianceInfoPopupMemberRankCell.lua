local AllianceModuleDefine = require("AllianceModuleDefine")
local Utils = require("Utils")
local Delegate = require("Delegate")
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceInfoPopupMemberRankCell:BaseTableViewProCell
---@field new fun():AllianceInfoPopupMemberRankCell
---@field super BaseTableViewProCell
local AllianceInfoPopupMemberRankCell = class('AllianceInfoPopupMemberRankCell', BaseTableViewProCell)

function AllianceInfoPopupMemberRankCell:OnCreate(param)
    self._p_icon_position = self:Image("p_icon_position")
    self._p_text_position = self:Text("p_text_position")
    self._p_text_number = self:Text("p_text_number")
    self._p_click_rect = self:Button("p_click_rect", Delegate.GetOrCreate(self, self.OnClickSelf))
end

---@param data AllianceMemberListRankCellData
function AllianceInfoPopupMemberRankCell:OnFeedData(data)
    self._data = data
    if Utils.IsNotNull(self._p_text_number) then
        if data.Rank ~= AllianceModuleDefine.LeaderRank then
            if data.max < 0 then
                self._p_text_number.text = string.format("%s", data.count)
            else
                self._p_text_number.text = string.format("%s/%s", data.count, data.max or 0)
            end
            self._p_text_number:SetVisible(true)
        else
            self._p_text_number:SetVisible(false)
        end
    end
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetRankIcon(data.Rank), self._p_icon_position)
    self._p_text_position.text = AllianceModuleDefine.GetRankName(data.Rank)
end

function AllianceInfoPopupMemberRankCell:OnClickSelf()
    self._data:SetExpanded(not self._data:IsExpanded())
    self:GetTableViewPro():UpdateData(self._data)
end

return AllianceInfoPopupMemberRankCell