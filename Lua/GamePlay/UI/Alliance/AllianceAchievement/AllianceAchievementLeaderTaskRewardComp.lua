local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')

---@class AllianceAchievementLeaderTaskRewardComp : BaseTableViewProCell
local AllianceAchievementLeaderTaskRewardComp = class('AllianceAchievementLeaderTaskRewardComp', BaseTableViewProCell)

function AllianceAchievementLeaderTaskRewardComp:OnCreate()
    self.child_item_standard_s = self:LuaObject('child_item_standard_s')
end

function AllianceAchievementLeaderTaskRewardComp:OnShow()
end

function AllianceAchievementLeaderTaskRewardComp:OnHide()
end

function AllianceAchievementLeaderTaskRewardComp:OnFeedData(param)
    self.child_item_standard_s:FeedData(param)
end

return AllianceAchievementLeaderTaskRewardComp
