local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require('I18N')
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")

---@class CommonInfoRule : BaseTableViewProCell
local CommonInfoRule = class("CommonInfoRule", BaseTableViewProCell)

function CommonInfoRule:OnCreate()
    self.p_text_rule = self:Text('p_text_rule')
end

---@param param CommonPlainTextContentCell
function CommonInfoRule:OnFeedData(param)
    local color
    if param.isSelected then
        color = ColorConsts.reminder_yellow
    else
        color = ColorConsts.dark_grey_1
    end
    self.p_text_rule.text = ("<color=%s>%s</color>"):format(color, param.rule)
end

return CommonInfoRule
