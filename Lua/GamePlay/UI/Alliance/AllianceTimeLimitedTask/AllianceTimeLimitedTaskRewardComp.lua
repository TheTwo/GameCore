local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local Utils = require('Utils')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")

---@class AllianceTimeLimitedTaskRewardComp : BaseTableViewProCell
local AllianceTimeLimitedTaskRewardComp = class('AllianceTimeLimitedTaskRewardComp', BaseTableViewProCell)

function AllianceTimeLimitedTaskRewardComp:OnCreate()
    self.child_item_standard_s = self:LuaObject("child_item_standard_s")
end

function AllianceTimeLimitedTaskRewardComp:OnFeedData(param)
    self.child_item_standard_s:FeedData(param)
end
return AllianceTimeLimitedTaskRewardComp
