local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require("I18N")
---@class ActivityAllianceBossRegisterRewardPreviewTitleCell : BaseTableViewProCell
local ActivityAllianceBossRegisterRewardPreviewTitleCell = class("ActivityAllianceBossRegisterRewardPreviewTitleCell", BaseTableViewProCell)

---@class ActivityAllianceBossRegisterRewardPreviewTitleCellParam
---@field title string

function ActivityAllianceBossRegisterRewardPreviewTitleCell:OnCreate()
    self.textTitle = self:Text("p_text_type")
end

function ActivityAllianceBossRegisterRewardPreviewTitleCell:OnFeedData(param)
    self.textTitle.text = I18N.Get(param.title)
end

return ActivityAllianceBossRegisterRewardPreviewTitleCell