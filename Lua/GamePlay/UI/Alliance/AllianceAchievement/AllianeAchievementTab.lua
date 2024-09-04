local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimerUtility = require('TimerUtility')
local ChatShareType = require("ChatShareType")
local AllianceLongTermTaskType = require('AllianceLongTermTaskType')
local EventConst = require('EventConst')
local NotificationType = require('NotificationType')

---@class AllianeAchievementTab : BaseUIComponent
local AllianeAchievementTab = class('AllianeAchievementTab', BaseUIComponent)

function AllianeAchievementTab:OnCreate()
    ---@type CommonChildTabLeftBtn
    self.child_tab_left_btn = self:LuaObject("child_tab_left_btn")
end

function AllianeAchievementTab:OnShow()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEADER_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshRedDot))
end

function AllianeAchievementTab:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEADER_TASK_CLAIMED, Delegate.GetOrCreate(self, self.RefreshRedDot))
end

function AllianeAchievementTab:RefreshRedDot()
    self.reddot = self.child_tab_left_btn:GetNotificationNode()
    self.reddot:SetVisible(true)
    local node
    if self.isLeaderTab then
        node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_Leader", NotificationType.ALLIANCE_ACHIEVEMENT_LEADER)
    else
        node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("AllianceAchievement_LongTerm", NotificationType.ALLIANCE_ACHIEVEMENT_LONG)
    end

    ModuleRefer.NotificationModule:AttachToGameObject(node, self.reddot.go, self.reddot.redTextGo, self.reddot.redText)
end

function AllianeAchievementTab:OnFeedData(param)
    self.isLeaderTab = param.index == 2
    self.child_tab_left_btn:FeedData(param)
    self:RefreshRedDot()
end

function AllianeAchievementTab:SetStatus(param)
    self.child_tab_left_btn:SetStatus(param)
end

return AllianeAchievementTab
