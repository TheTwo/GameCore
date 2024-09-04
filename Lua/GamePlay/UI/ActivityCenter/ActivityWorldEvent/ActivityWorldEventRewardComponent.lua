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

---@class ActivityWorldEventRewardComponent : BaseTableViewProCell
local ActivityWorldEventRewardComponent = class('ActivityWorldEventRewardComponent', BaseTableViewProCell)

function ActivityWorldEventRewardComponent:OnCreate()
    self.child_item_standard_s = self:LuaObject("child_item_standard_s")

end

function ActivityWorldEventRewardComponent:OnFeedData(param)
    local iconData = param
    iconData.showCount = false
    iconData.received = false
    iconData.claimable = false
    iconData.setTipsPos = true
    self.child_item_standard_s:FeedData(iconData)
end

function ActivityWorldEventRewardComponent:OnShow()
end

function ActivityWorldEventRewardComponent:OnHide()
end

return ActivityWorldEventRewardComponent
