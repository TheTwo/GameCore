local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require('I18N')

---@class CommonInfoHint : BaseTableViewProCell
local CommonInfoHint = class("CommonInfoHint", BaseTableViewProCell)

function CommonInfoHint:OnCreate()
    self.p_text_hint = self:Text('')
end

function CommonInfoHint:OnFeedData(str)
    self.p_text_hint.text = I18N.Get(str)
end

return CommonInfoHint
