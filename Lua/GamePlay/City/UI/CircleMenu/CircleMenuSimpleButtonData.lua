---@class CircleMenuSimpleButtonData
---@field new fun():CircleMenuSimpleButtonData
---@field buttonIcon string
---@field buttonBack string
---@field number number
---@field buttonEnable boolean
---@field onClick fun()
---@field onClickFailed fun()|nil
---@field extraData ImageTextPair[]
---@field activeNoticeAnim boolean
local CircleMenuSimpleButtonData = class("CircleMenuSimpleButtonData")

function CircleMenuSimpleButtonData:ctor(icon, back, enable, func, failedFunc, extraData, name, nodeName)
    self.buttonIcon = icon
    self.buttonBack = back
    self.buttonEnable = enable
    self.onClick = func
    self.onClickFailed = failedFunc
    self.extraData = extraData
    self.name = name
    self.nodeName = nodeName
    self.priority = 0
end

function CircleMenuSimpleButtonData:SetName(name)
    self.name = name
    return self
end

function CircleMenuSimpleButtonData:SetNodeName(nodeName)
    self.nodeName = nodeName
    return self
end

function CircleMenuSimpleButtonData:SetPriority(priority)
    self.priority = priority
    return self
end

return CircleMenuSimpleButtonData