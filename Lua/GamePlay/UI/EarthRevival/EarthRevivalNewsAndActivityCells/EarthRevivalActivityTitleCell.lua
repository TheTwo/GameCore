local BaseTableViewProCell = require("BaseTableViewProCell")
---@class EarthRevivalActivityTitleCell : BaseUIComponent
local EarthRevivalActivityTitleCell = class("EarthRevivalActivityTitleCell", BaseTableViewProCell)

function EarthRevivalActivityTitleCell:OnCreate()
    self.textTitle = self:Text("p_text_title")
end

---@param title string
function EarthRevivalActivityTitleCell:OnFeedData(title)
    self.textTitle.text = title
end

return EarthRevivalActivityTitleCell