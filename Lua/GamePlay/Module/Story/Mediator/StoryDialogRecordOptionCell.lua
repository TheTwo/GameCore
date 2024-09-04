local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class StoryDialogRecordOptionCellData : StoryDialogRecordCellData

---@class StoryDialogRecordOptionCell:BaseTableViewProCell
---@field new fun():StoryDialogRecordOptionCell
---@field super BaseTableViewProCell
local StoryDialogRecordOptionCell = class('StoryDialogRecordOptionCell', BaseTableViewProCell)

function StoryDialogRecordOptionCell:OnCreate(param)
    self._p_btn_option = self:Button("p_btn_option", Delegate.GetOrCreate(self, self.OnClickBtn))
    self._p_text_option_info = self:Text("p_text_option_info")
end

---@param data StoryDialogRecordOptionCellData
function StoryDialogRecordOptionCell:OnFeedData(data)
    self._p_text_option_info.text = data.textContent
end

function StoryDialogRecordOptionCell:OnFeedData()
    g_Logger.Log("Click Option Cell Btn:%s", self._p_text_option_info.text)
end

return StoryDialogRecordOptionCell