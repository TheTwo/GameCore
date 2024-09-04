local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')

---@class AllianceAchievementLeaderComp : BaseTableViewProCell
local AllianceAchievementLeaderComp = class('AllianceAchievementLeaderComp', BaseTableViewProCell)

function AllianceAchievementLeaderComp:OnCreate()

end

function AllianceAchievementLeaderComp:OnShow()
end

function AllianceAchievementLeaderComp:OnHide()
end

function AllianceAchievementLeaderComp:OnFeedData(param)
end


return AllianceAchievementLeaderComp
