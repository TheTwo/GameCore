local TimeFormatter = require("TimeFormatter")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationHistoryAllianceCellData
---@field flag wds.AllianceFlag
---@field allianceName string
---@field time number

---@class AllianceVillageOccupationHistoryAllianceCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationHistoryAllianceCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationHistoryAllianceCell = class('AllianceVillageOccupationHistoryAllianceCell', BaseTableViewProCell)

function AllianceVillageOccupationHistoryAllianceCell:OnCreate(param)
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_league_name = self:Text("p_text_league_name")
    self._p_text_time = self:Text("p_text_time")
end

---@param data AllianceVillageOccupationHistoryAllianceCellData
function AllianceVillageOccupationHistoryAllianceCell:OnFeedData(data)
    self._child_league_logo:FeedData(data.flag)
    self._p_text_league_name.text = data.allianceName
    self._p_text_time.text = TimeFormatter.TimeToDateTimeStringUseFormat(data.time, "yyyy/MM/dd HH:mm:ss")
end

return AllianceVillageOccupationHistoryAllianceCell