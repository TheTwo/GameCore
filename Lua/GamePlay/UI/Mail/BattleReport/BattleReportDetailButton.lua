local BaseTableViewProCell = require("BaseTableViewProCell")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")

---@class BattleReportSimpleTeamCell : BaseTableViewProCell
local BattleReportDetailButton = class("BattleReportSimpleTeamCell", BaseTableViewProCell)

function BattleReportDetailButton:OnCreate(param)
    self.moreDetailButton = self:Button("p_base_btn", Delegate.GetOrCreate(self, self.OnDetailClick))
    self.moreDetailText = self:Text("p_text_details", "battlemessage_detail")
end

---@param data wds.Mail
function BattleReportDetailButton:OnFeedData(data)
    self.data = data
end

function BattleReportDetailButton:OnDetailClick()
    ---@type UIMailDetailData
    local data = {mail = self.data}
    g_Game.UIManager:Open(UIMediatorNames.UIMailDetailMediator, data)
end

return BattleReportDetailButton