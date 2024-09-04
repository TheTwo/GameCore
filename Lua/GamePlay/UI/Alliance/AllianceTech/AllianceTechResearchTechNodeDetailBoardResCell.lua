
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTechResearchTechNodeDetailBoardResCell:BaseTableViewProCell
---@field new fun():AllianceTechResearchTechNodeDetailBoardResCell
---@field super BaseTableViewProCell
local AllianceTechResearchTechNodeDetailBoardResCell = class('AllianceTechResearchTechNodeDetailBoardResCell', BaseTableViewProCell)

function AllianceTechResearchTechNodeDetailBoardResCell:OnCreate(param)
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
end

---@param data ItemIconData
function AllianceTechResearchTechNodeDetailBoardResCell:OnFeedData(data)
    self._child_item_standard_s:FeedData(data)
end

return AllianceTechResearchTechNodeDetailBoardResCell