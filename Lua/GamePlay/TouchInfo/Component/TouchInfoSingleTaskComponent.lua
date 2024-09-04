local BaseUIComponent = require ('BaseUIComponent')

---@class TouchInfoSingleTaskComponent:BaseUIComponent
local TouchInfoSingleTaskComponent = class('TouchInfoSingleTaskComponent', BaseUIComponent)

---@class TouchInfoSingleTaskCompData
---@field desc string
---@field finished boolean

function TouchInfoSingleTaskComponent:OnCreate()
    self._p_icon_finish = self:GameObject("p_icon_finish")
    self._p_text_task = self:Text("p_text_task")
end

---@param data TouchInfoSingleTaskCompData
function TouchInfoSingleTaskComponent:OnFeedData(data)
    self._p_text_task.text = data.desc
    self._p_icon_finish:SetActive(data.finished)
end

return TouchInfoSingleTaskComponent