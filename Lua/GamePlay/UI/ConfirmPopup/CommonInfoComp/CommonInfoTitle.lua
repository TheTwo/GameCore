local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require('I18N')

---@class CommonInfoTitle : BaseTableViewProCell
local CommonInfoTitle = class("CommonInfoTitle", BaseTableViewProCell)

function CommonInfoTitle:OnCreate()
    self.p_text_title = self:Text('p_text_title')
end

function CommonInfoTitle:OnFeedData(str)
    self.p_text_title.text = I18N.Get(str)
end

return CommonInfoTitle
