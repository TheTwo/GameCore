
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothCageOccupationGainTitleCell:BaseTableViewProCell
---@field new fun():AllianceBehemothCageOccupationGainTitleCell
---@field super BaseTableViewProCell
local AllianceBehemothCageOccupationGainTitleCell = class('AllianceBehemothCageOccupationGainTitleCell', BaseTableViewProCell)

function AllianceBehemothCageOccupationGainTitleCell:OnCreate(param)
    self._p_text_gain = self:Text("p_text_gain")
end

---@param data string
function AllianceBehemothCageOccupationGainTitleCell:OnFeedData(data)
    self._p_text_gain.text = data
end

return AllianceBehemothCageOccupationGainTitleCell