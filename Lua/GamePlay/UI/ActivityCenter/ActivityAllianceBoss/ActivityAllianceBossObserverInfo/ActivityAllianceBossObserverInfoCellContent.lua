local BaseUIComponent = require("BaseUIComponent")
---@class ActivityAllianceBossObserverInfoCellContent : BaseUIComponent
local ActivityAllianceBossObserverInfoCellContent = class("ActivityAllianceBossObserverInfoCellContent", BaseUIComponent)

---@class ActivityAllianceBossObserverInfoCellContentParam
---@field member wrpc.AllianceMemberInfo

function ActivityAllianceBossObserverInfoCellContent:OnCreate()
    self.textName = self:Text("p_text_name")
    ---@see PlayerInfoComponent
    self.luaPlayerHead = self:LuaObject("child_ui_head_player")
end

---@param param ActivityAllianceBossObserverInfoCellContentParam
function ActivityAllianceBossObserverInfoCellContent:OnFeedData(param)
    self.member = param.member
    self.textName.text = self.member.Name
    self.luaPlayerHead:FeedData(self.member)
end

return ActivityAllianceBossObserverInfoCellContent