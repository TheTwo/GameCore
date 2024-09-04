local BaseTableViewProCell = require ('BaseTableViewProCell')
---@class ReplicaPVPPopupInfoTabCell : BaseTableViewProCell
local ReplicaPVPPopupInfoTabCell = class('ReplicaPVPPopupInfoTabCell', BaseTableViewProCell)

function ReplicaPVPPopupInfoTabCell:OnCreate()
    ---@see CommonButtonTab
    self.luaBtnTab = self:LuaObject('child_tab_btn_s')
end

---@param data CommonButtonTabParameter
function ReplicaPVPPopupInfoTabCell:OnFeedData(data)
    local cb = data.callback
    data.callback = function ()
        if cb then
            cb()
        end
        self:SelectSelf()
    end
    self.luaBtnTab:FeedData(data)
end

function ReplicaPVPPopupInfoTabCell:Select()
    self.luaBtnTab:ChangeSelectTab(true)
end

function ReplicaPVPPopupInfoTabCell:UnSelect()
    self.luaBtnTab:ChangeSelectTab(false)
end

return ReplicaPVPPopupInfoTabCell