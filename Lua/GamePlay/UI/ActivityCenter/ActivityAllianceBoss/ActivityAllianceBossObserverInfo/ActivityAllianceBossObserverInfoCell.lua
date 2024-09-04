local BaseTableViewProCell = require("BaseTableViewProCell")
---@class ActivityAllianceBossObserverInfoCell : BaseTableViewProCell
local ActivityAllianceBossObserverInfoCell = class("ActivityAllianceBossObserverInfoCell", BaseTableViewProCell)

---@class ActivityAllianceBossObserverInfoCellParam
---@field members wrpc.AllianceMemberInfo[]

function ActivityAllianceBossObserverInfoCell:OnCreate()
    ---@see ActivityAllianceBossObserverInfoCellContent
    self.luaContentLeft = self:LuaObject("p_group_1")
    ---@see ActivityAllianceBossObserverInfoCellContent
    self.luaContentRight = self:LuaObject("p_group_2")
end

---@param param ActivityAllianceBossObserverInfoCellParam
function ActivityAllianceBossObserverInfoCell:OnFeedData(param)
    self.members = param.members
    self.luaContentLeft:SetVisible(self.members[1] ~= nil)
    self.luaContentRight:SetVisible(self.members[2] ~= nil)
    if self.members[1] then
        self.luaContentLeft:FeedData({member = self.members[1]})
    end
    if self.members[2] then
        self.luaContentLeft:FeedData({member = self.members[2]})
    end
end

return ActivityAllianceBossObserverInfoCell