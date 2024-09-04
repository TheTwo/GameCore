local BaseTableViewProCell = require("BaseTableViewProCell")

---@class StoryDialogRecordSubTitleCellData : StoryDialogRecordCellData

---@class StoryDialogRecordSubTitleCell:BaseTableViewProCell
---@field new fun():StoryDialogRecordSubTitleCell
---@field super BaseTableViewProCell
local StoryDialogRecordSubTitleCell = class('StoryDialogRecordSubTitleCell', BaseTableViewProCell)

function StoryDialogRecordSubTitleCell:OnCreate(param)
    self._p_text_subtitle = self:Text("p_text_subtitle")
end

---@param data StoryDialogRecordSubTitleCellData
function StoryDialogRecordSubTitleCell:OnFeedData(data)
    self._p_text_subtitle.text = data.textContent
end

return StoryDialogRecordSubTitleCell