local TimeFormatter = require("TimeFormatter")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationHistoryCellData
---@field flag wds.AllianceFlag
---@field allianceName string
---@field time number

---@class AllianceVillageOccupationHistoryCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationHistoryCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationHistoryCell = class('AllianceVillageOccupationHistoryCell', BaseTableViewProCell)

function AllianceVillageOccupationHistoryCell:OnCreate(param)
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_league_name_history = self:Text("p_text_league_name_history")
    self._p_text_time_history = self:Text("p_text_time_history")
    self._p_text_league_occupation_history = self:Text("p_text_league_occupation_history", "village_info_First_conquest_7")
end

---@param data AllianceVillageOccupationHistoryCellData
function AllianceVillageOccupationHistoryCell:OnFeedData(data)
    self._child_league_logo:FeedData(data.flag)
    self._p_text_league_name_history.text = data.allianceName
    self._p_text_time_history.text = TimeFormatter.TimeToDateTimeStringUseFormat(data.time, "yyyy/MM/dd HH:mm:ss")
end

return AllianceVillageOccupationHistoryCell