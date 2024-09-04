local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class TouchMenuCellTask:BaseUIComponent
local TouchMenuCellTask = class('TouchMenuCellTask', BaseUIComponent)

function TouchMenuCellTask:OnCreate()
    self._p_icon_n = self:GameObject("p_icon_n")
    self._p_icon_finish = self:GameObject("p_icon_finish")
    self._p_text_task = self:Text("p_text_task")
end

---@param data TouchMenuCellTaskDatum
function TouchMenuCellTask:OnFeedData(data)
    self.data = data

    local isFinish = data:IsFinish()
    self._p_icon_n:SetActive(not isFinish)
    self._p_icon_finish:SetActive(isFinish)
    self._p_text_task.text = data:GetTaskDesc()
end

return TouchMenuCellTask