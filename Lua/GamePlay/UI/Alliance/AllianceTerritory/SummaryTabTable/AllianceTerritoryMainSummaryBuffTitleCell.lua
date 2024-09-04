
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryBuffTitleCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryBuffTitleCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryBuffTitleCell = class('AllianceTerritoryMainSummaryBuffTitleCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryBuffTitleCell:OnCreate(param)
    self._p_text_buff = self:Text("p_text_buff")
end

---@param data string
function AllianceTerritoryMainSummaryBuffTitleCell:OnFeedData(data)
    self._p_text_buff.text = data
end

return AllianceTerritoryMainSummaryBuffTitleCell