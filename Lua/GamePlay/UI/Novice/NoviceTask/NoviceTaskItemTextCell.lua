local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
---@class NoviceTaskItemTextCell : BaseTableViewProCell
local NoviceTaskItemTextCell = class('NoviceTaskItemTextCell', BaseTableViewProCell)

local FinishedColors = {
    [false] = ColorConsts.army_red,
    [true] = ColorConsts.army_green
}

function NoviceTaskItemTextCell:OnCreate()
    self.textTask = self:Text('')
end

function NoviceTaskItemTextCell:OnFeedData(param)
    if not param then
        return
    end
    local taskId = param.taskId
    local desc, infoParam = ModuleRefer.QuestModule:GetTaskNameByID(taskId)
    local numCurrent, numNeeded = ModuleRefer.QuestModule:GetTaskProgressByTaskID(taskId)
    local color = FinishedColors[numCurrent >= numNeeded]
    local coloredNumCurrent = UIHelper.GetColoredText(tostring(numCurrent), color)
    local taskStr
    if infoParam then
        taskStr = I18N.GetWithParamList(desc, infoParam)
    else
        taskStr = I18N.Get(desc)
    end
    self.textTask.text = string.format('<b>(%s/%d)</b> %s', coloredNumCurrent, numNeeded, taskStr)
end

return NoviceTaskItemTextCell