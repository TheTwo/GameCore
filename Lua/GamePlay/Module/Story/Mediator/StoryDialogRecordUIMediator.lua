--- scene:scene_story_record

local Delegate = require("Delegate" )

local BaseUIMediator = require("BaseUIMediator")

---@class StoryDialogRecordUIMediatorParameter
---@field record StoryDialogRecordCellData[]

---@class StoryDialogRecordUIMediator:BaseUIMediator
---@field new fun():StoryDialogRecordUIMediator
---@field super BaseUIMediator
local StoryDialogRecordUIMediator = class('StoryDialogRecordUIMediator', BaseUIMediator)

function StoryDialogRecordUIMediator:OnCreate(param)
    self._p_mask = self:GameObject("p_mask")
    self._p_table_record = self:TableViewPro("p_table_record")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
end

---@param param StoryDialogRecordUIMediatorParameter
function StoryDialogRecordUIMediator:OnOpened(param)
    self._p_table_record:Clear()
    for _, v in ipairs(param.record) do
        local cellDataType = v.type
        if cellDataType >0 and cellDataType < 4 then
            self._p_table_record:AppendData(v, cellDataType - 1)
        end
    end
end

return StoryDialogRecordUIMediator